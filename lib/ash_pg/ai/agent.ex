defmodule AshPg.Ai.Agent do
  use GenServer
  require Logger

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  alias LangChain.MessageDelta

  @timeout :timer.seconds(60)

  @default_system_prompt """
  You are an assistant responsible for operating the application on behalf of the user. Follow the guidelines below:

  # Role & Scope
  - Your primary role is to perform supported actions within the application as requested by the user.
  - If a request falls outside your role or involves unsupported or prohibited actions, politely decline and clearly explain why the task cannot be completed.

  # Response Rules
  - Always reply in the language used by the user.
  - Use clear, simple language. Avoid overly technical or developer-specific terms unless absolutely necessary.

  # Retrieving & Displaying Information
  - You may retrieve and display data (e.g., file contents, database records) immediately, without additional confirmation from the user.
  - When presenting information, display without IDs. Instead, use representative attributes.
  - If needed, you may use IDs internally for data retrieval, but never expose them to the user.

  # Executing Actions
  - For any actions that modify the system state (e.g., creating, editing, or deleting files), you must follow these steps:
    A. Summarize the action you intend to perform (e.g., “I will delete the file”) and list all key parameters in bullet points.
      - Clearly distinguish between required and optional parameters.
    B. Explicitly ask the user for confirmation to proceed.
    C. Proceed with the action only after the user has explicitly approved it (e.g., “Yes, please go ahead”).
  - Under no circumstances should you perform system-altering actions without following the above confirmation process.
  - If optional parameters are missing, do not re-prompt for them. Instead, apply default values or disregard them.

  # Display Rules
  When displaying information for specific resources, you must show the following fields only. Do not expose internal IDs.
  If a field has no available data, still include the field name and set its value to "Unknown".

  ## Artist
  - name
  - bio.birth

  ## Album
  - title
  - artists.name
  """

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def run(agent, message, opts \\ []) do
    GenServer.call(agent, {:run, message, opts}, @timeout)
  end

  # def list_messages(agent) do
  #   GenServer.call(agent, :list_messages, @timeout)
  # end

  @impl true
  def init(opts) do
    model =
      ChatOpenAI.new!(%{
        api_key: Application.fetch_env!(:ash_pg, :openai)[:api_key],
        model: "gpt-4o-mini",
        stream: true
      })

    system_message = LangChain.Message.new_system!(opts[:system_prompt] || @default_system_prompt)

    handler =
      case opts[:handler] do
        nil ->
          %{
            on_llm_new_delta: fn _chain, %MessageDelta{} = data ->
              IO.write(data.content)
            end,
            on_message_processed: fn _chain, %Message{} ->
              IO.write("\n--\n")
            end
          }

        handler ->
          handler
      end

    chain =
      %{llm: model, verbose?: true}
      |> LLMChain.new!()
      |> LLMChain.add_message(system_message)
      |> AshAi.setup_ash_ai(otp_app: :ash_pg)
      |> LLMChain.add_callback(handler)
      |> then(fn llm_chain ->
        case opts[:actor] do
          nil -> llm_chain
          actor -> LLMChain.update_custom_context(llm_chain, %{actor: actor})
        end
      end)

    {:ok, %{chain: chain}}
  end

  @impl true
  def handle_call({:run, %{contents: contents}, opts}, _from, %{chain: chain} = state) do
    langchain_contents =
      contents
      |> Enum.map(fn %{type: type, content: content, opts: opts} ->
        LangChain.Message.ContentPart.new!(%{type: type, content: content, options: opts})
      end)

    new_chain =
      chain
      |> LLMChain.add_message(LangChain.Message.new_user!(langchain_contents))

    {:reply, {:ok, nil}, %{state | chain: new_chain}, {:continue, {:run, opts}}}
  end

  # @impl true
  # def handle_call(:list_messages, _from, %{chain: chain} = state) do
  #   messages = chain.messages

  #   {:reply, {:ok, messages}, state}
  # end

  @impl true
  def handle_continue({:run, _opts}, %{chain: chain} = state) do
    new_chain =
      chain
      |> LLMChain.run(mode: :while_needs_response)
      |> case do
        {:ok, new_chain} ->
          new_chain

        {:error, new_chain, error} ->
          Logger.warning("Error running chain: #{inspect(error)}")
          new_chain
      end

    {:noreply, %{state | chain: new_chain}}
  end
end
