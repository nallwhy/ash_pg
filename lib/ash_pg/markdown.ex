defmodule AshPg.Markdown do
  def html(markdown) do
    markdown
    |> MDEx.parse_document!(
      extension: [
        strikethrough: true,
        table: true,
        tasklist: true
      ]
    )
    |> MDEx.to_html!(render: [unsafe_: true])
  end
end
