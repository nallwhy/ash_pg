defmodule AshPg.Ai.Agent do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message
  alias LangChain.MessageDelta

  @default_system_prompt """
  You are a helpful assistant.
  Your purpose is to operate the application on behalf of the user.
  Before using the tool, explain in words what command you are going to execute.
  List the key values or parameters you will use in bullet points.
  Only proceed when I explicitly confirm the execution.
  """

  def init(opts \\ []) do
    model =
      ChatOpenAI.new!(%{
        api_key: Application.fetch_env!(:ash_pg, :openai)[:api_key],
        model: "gpt-4o-mini",
        stream: true
      })

    system_message = LangChain.Message.new_system!(opts[:system_prompt] || @default_system_prompt)

    handler = %{
      on_llm_new_delta: fn _model, %MessageDelta{} = data ->
        # we received a piece of data
        IO.write(data.content)
      end,
      on_message_processed: fn _chain, %Message{} = data ->
        IO.inspect(data, label: "COMPLETED MESSAGE")
        IO.write("\n--\n")
      end
    }

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
  end

  def run(chain, message, opts \\ []) do
    chain
    |> LLMChain.add_message(LangChain.Message.new_user!(message))
    |> LLMChain.run(mode: :while_needs_response)
  end
end
