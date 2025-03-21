defmodule AshPg.Ai.Chatbot do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI

  def iex_chat(actor \\ nil) do
    %{
      llm:
        ChatOpenAI.new!(%{
          api_key: Application.fetch_env!(:ash_pg, :openai)[:api_key],
          model: "gpt-4o-mini",
          stream: true
        }),
      verbose?: true
    }
    |> LLMChain.new!()
    |> AshAi.iex_chat(actor: actor, otp_app: :ash_pg)
  end
end
