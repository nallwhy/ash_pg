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
  Before using any tool, explain clearly what command you are going to execute, listing key values or parameters in bullet points.
  Use plain, simple language — avoid technical or developer-specific terms. Imagine explaining things to a non-technical person.
  Only proceed when I explicitly confirm the execution.
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

    {:reply, {:ok, %{messages: new_chain.messages}}, %{state | chain: new_chain}, {:continue, {:run, opts}}}
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
