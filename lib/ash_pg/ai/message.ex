defmodule AshPg.Ai.Message do
  defmodule ContentPart do
    @type t :: %__MODULE__{
            type: :text | :image_url | :image | :file,
            content: any(),
            opts: keyword(),
            hidden: :boolean
          }

    defstruct [:type, :content, opts: [], hidden: false]

    def new(attrs) do
      struct(__MODULE__, attrs)
    end

    def text(text) do
      new(%{type: :text, content: text})
    end

    def file(file, opts) do
      new(%{type: :file, content: file, opts: opts})
    end
  end

  @type t :: %__MODULE__{
          id: String.t(),
          role: :user | :assistant | :system | :tool,
          type: :message | :tool_call | :tool_result,
          contents: list()
        }

  defstruct [
    :id,
    :role,
    :type,
    :contents
  ]

  alias AshPg.Utils, as: U

  def new(attrs) do
    new_attrs =
      attrs
      |> Map.update(:contents, [], fn content -> content |> Enum.map(&ContentPart.new/1) end)
      |> Map.merge(%{id: U.UUID.v7()})

    struct(__MODULE__, new_attrs)
  end

  def user(contents) do
    new(%{role: :user, type: :message, contents: contents})
  end

  def from_langchain(%LangChain.Message{} = langchain_message) do
    type =
      cond do
        not is_nil(langchain_message.content) -> :message
        not Enum.empty?(langchain_message.tool_calls) -> :tool_call
        not is_nil(langchain_message.tool_results) -> :tool_result
      end

    contents =
      case langchain_message.content do
        content when is_binary(content) ->
          [%{type: :text, content: content}]

        content when is_list(content) ->
          content
          |> Enum.map(fn %LangChain.Message.ContentPart{} = langchain_content_part ->
            %{
              type: langchain_content_part.type,
              content: langchain_content_part.content
            }
          end)

        nil ->
          []
      end

    # TODO: replace id from Message
    new(%{
      role: langchain_message.role,
      type: type,
      contents: contents
    })
  end
end
