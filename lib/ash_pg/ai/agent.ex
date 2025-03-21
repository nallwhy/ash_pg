defmodule AshPg.Ai.Agent do
  use GenServer
  require Logger

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  alias LangChain.MessageDelta

  @timeout :timer.seconds(60)

  @default_system_prompt """
  You are a helpful assistant.
  Your purpose is to operate the application on behalf of the user.
  Always respond in the same language the user used in their input.

  You must not perform any task or function that is not supported, not allowed, or cannot be executed.
  Always politely refuse such requests, clearly stating that they cannot be completed.

  Before responding to any request, carefully evaluate whether it aligns with your defined purpose.
  If a request falls outside of your purpose, politely refuse it and explain that it is beyond the scope of your role.

  When retrieving or displaying information, you may internally use IDs if necessary.
  You may proceed immediately with retrieving or displaying information without requiring confirmation.
  It is within your role to format, organize, or simplify the retrieved information to make it clearer and easier to understand, as long as the underlying data is not modified.

  Before performing any action that modifies data, changes state, or executes commands, clearly explain what you are going to do.
  List key values or parameters in bullet points.
  Use plain, simple language — avoid technical or developer-specific terms.
  Only proceed with such actions when I explicitly confirm.

  When displaying data, avoid showing IDs.
  Instead, focus on attributes that have strong representative value among multiple attributes.
  """

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def run(agent, message, opts \\ []) do
    GenServer.call(agent, {:run, message, opts}, @timeout)
  end

  def list_messages(agent) do
    GenServer.call(agent, :list_messages, @timeout)
  end

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
    new_chain =
      chain
      |> LLMChain.add_message(LangChain.Message.new_user!(message))

    {:reply, {:ok, %{messages: new_chain.messages}}, %{state | chain: new_chain},
     {:continue, {:run, opts}}}
  end

  @impl true
  def handle_call(:list_messages, _from, %{chain: chain} = state) do
    messages = chain.messages

    {:reply, {:ok, messages}, state}
  end

  @impl true
  def handle_continue({:run, _opts}, %{chain: chain} = state) do
    new_chain =
      chain
      |> LLMChain.run(mode: :while_needs_response)
      |> case do
        {:ok, new_chain} ->
          new_chain

        {:error, error} ->
          Logger.warning("Error running chain: #{inspect(error)}")
          chain
      end

    {:noreply, %{state | chain: new_chain}}
  end
end
