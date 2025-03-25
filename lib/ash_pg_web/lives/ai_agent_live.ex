defmodule AshPgWeb.AiAgentLive do
  use AshPgWeb, :live_view

  alias AshPg.Ai.Agent
  alias AshPg.Ai.Message
  alias AshPg.Markdown

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_agent()
      |> stream(:messages, [
        Message.new(%{
          role: :assistant,
          type: :message,
          contents: [%{type: :text, content: "Hello! May I help you?"}]
        })
      ])
      |> assign(new_message: nil)
      |> allow_upload(:files,
        accept: ["image/*", "application/pdf"],
        max_entries: 10
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>AI Chat</h1>

      <div
        id="chat-log"
        class="overflow-y-scroll h-96 border border-gray-300 rounded p-4 mb-4 space-y-4"
      >
        <div id="messages" class="space-y-4" phx-update="stream">
          <.message :for={{dom_id, message} <- @streams.messages} dom_id={dom_id} message={message} />
        </div>
        <ol>
          <li :if={@new_message} class="text-left">
            <span class="prose">
              <span :if={@new_message == ""}>
                <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
              </span>
              <span :if={@new_message != ""}>{@new_message |> Markdown.html() |> raw()}</span>
            </span>
          </li>
        </ol>
      </div>

      <div class="border border-gray-300 rounded-xl">
        <form phx-change="validate" phx-submit="send_message">
          <.live_file_input upload={@uploads.files} />
          <div>
            <article :for={entry <- @uploads.files.entries} class="upload-entry">
              <figure>
                <.live_img_preview :if={content_type(entry.client_type) == :image} entry={entry} />
                <figcaption>{entry.client_name}</figcaption>
              </figure>
              <progress value={entry.progress} max="100">{entry.progress}%</progress>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
              >
                &times;
              </button>
            </article>
          </div>
          <input
            type="text"
            name="message"
            placeholder="Type your message..."
            class="w-full p-2 border-0"
          />
          <button
            type="submit"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mt-2"
          >
            Send
          </button>
        </form>
      </div>

      <%!-- <div :for={tool <- @agent.tools} class="whitespace-pre-wrap">
        {tool.parameters_schema |> Jason.encode!(pretty: true)}
      </div> --%>

      <%!-- <div :for={message <- @messages} class="whitespace-pre-wrap">
        {message.content |> Jason.encode!(pretty: true)}
      </div> --%>
    </div>
    """
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message_content}, socket) do
    file_content_parts =
      consume_uploaded_entries(
        socket,
        :files,
        fn %{path: path},
           %{
             client_name: client_name,
             client_type: client_type
           } ->
          file_content = path |> File.read!() |> Base.encode64()
          type = content_type(client_type)

          result =
            case type do
              :image ->
                %{
                  type: type,
                  content: file_content,
                  opts: [media: client_type]
                }

              :file ->
                [
                  %{type: type, content: file_content, opts: [filename: client_name]},
                  %{type: :text, content: "위의 파일 내용을 이용해서", hidden: true}
                ]
            end

          {:ok, result}
        end
      )
      |> List.flatten()

    message = Message.user(file_content_parts ++ [%{type: :text, content: message_content}])

    agent = socket.assigns.agent
    {:ok, _} = agent |> Agent.run(message)

    socket =
      socket
      |> stream_insert(:messages, message)
      |> assign(new_message: "")
      |> push_event("scroll-to", %{selector: "#chat-log", to: "bottom"})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl true
  def handle_info({:new_message, content}, socket) do
    socket =
      socket
      |> update(:new_message, fn
        nil -> content
        message -> message <> content
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_processed, message}, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)
      |> assign(:new_message, nil)

    {:noreply, socket}
  end

  defp assign_agent(socket) do
    pid = self()

    handler = %{
      on_llm_new_delta: fn _chain, %{content: message_content} ->
        if message_content do
          send(pid, {:new_message, message_content})
        end
      end,
      on_message_processed: fn _chain, langchain_message ->
        message = Message.from_langchain(langchain_message)

        if message.type == :message do
          send(pid, {:message_processed, message})
        end
      end
    }

    # TODO(jinkyou): init with last messages
    {:ok, agent} = Agent.start_link(handler: handler)

    socket
    |> assign(:agent, agent)
  end

  defp content_type(mime_type) do
    case mime_type do
      "image/" <> _ -> :image
      "application/pdf" -> :file
    end
  end

  ## Components

  attr :dom_id, :any, required: true
  attr :message, Message, required: true

  defp message(%{message: %{role: :user, type: :message}} = assigns) do
    ~H"""
    <div id={@dom_id} class="relative w-full flex flex-col items-end">
      <div class="max-w-[70%] py-2 px-4 bg-gray-200 rounded-xl prose">
        <.content :for={content <- @message.contents} content={content} />
      </div>
    </div>
    """
  end

  defp message(%{message: %{role: :assistant, type: :message}} = assigns) do
    ~H"""
    <div id={@dom_id} class="prose">
      <.content :for={content <- @message.contents} content={content} />
    </div>
    """
  end

  defp message(assigns) do
    ~H"""
    """
  end

  attr :content, Message.ContentPart, required: true

  defp content(%{content: %Message.ContentPart{hidden: true}} = assigns) do
    ~H"""
    """
  end

  defp content(%{content: %Message.ContentPart{type: :text}} = assigns) do
    ~H"""
    <p>{@content.content |> Markdown.html() |> raw()}</p>
    """
  end

  defp content(%{content: %Message.ContentPart{type: :image}} = assigns) do
    ~H"""
    <img src={"data:#{@content.opts[:media]};base64,#{@content.content}"} />
    """
  end

  defp content(%{content: %Message.ContentPart{type: :file}} = assigns) do
    ~H"""
    <div>{@content.opts[:filename]}</div>
    """
  end

  defp content(assigns) do
    ~H"""
    """
  end
end
