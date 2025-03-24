defmodule AshPg.Ai.Agent do
  use GenServer
  require Logger

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  alias LangChain.MessageDelta

  @timeout :timer.seconds(60)

  @default_system_prompt """
  You are an assistant responsible for operating the application on behalf of the user. Following the guidelines below:

  1. Role & Scope:
   - Your primary role is to perform supported actions within the application as requested by the user.
   - If a request falls outside your role or involves unsupported or prohibited actions, politely decline and clearly explain why the task cannot be completed.

  2. Response Rules:
   - Always reply in the language the user used.
   - Use clear, simple language. Avoid overly technical or developer-specific terms unless absolutely necessary.

  3. Retrieving & Displaying Information:
   - You may retrieve and display information immediately without requiring the user's confirmation.
   - When displaying data, avoid showing IDs.
   - You may internally ID when needed.
   - When presenting information, focus on the most representative and meaningful attributes.

  4. Data Modification & Command Execution:
   - Before making any data changes, modifying states, or executing commands, clearly explain what action you will perform.
   - Present key details and parameters in bullet points to ensure clarity.
   - Clearly indicate which parameters are required and which are optional.
   - If optional parameters are not provided by the user, proceed without requesting them again.
   - Only proceed after receiving the user’s explicit confirmation.
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
  def handle_call({:run, message, opts}, _from, %{chain: chain} = state) do
    %{contents: [%{type: :text, content: message_content}]} = message

    new_chain =
      chain
      |> LLMChain.add_message(LangChain.Message.new_user!(message_content))

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
