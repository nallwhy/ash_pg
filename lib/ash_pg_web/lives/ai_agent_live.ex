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
      |> stream(:messages, [])
      |> assign(new_message: nil)

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
        <ol id="messages" class="space-y-4" phx-update="stream">
          <li
            :for={{dom_id, message} <- @streams.messages}
            :if={message_role(message) != :system and message_type(message) == :message}
            id={dom_id}
            class={"#{if user?(message), do: "text-right", else: "text-left"}"}
          >
            <span class={"font-bold #{if user?(message), do: "text-blue-500", else: "text-green-500"}"}>
              {if user?(message), do: "You", else: "AI"}:
            </span>
            <span class="prose">
              {message.contents
              |> Enum.map(fn %Message.ContentPart{type: :text, content: content} ->
                content |> Markdown.html() |> raw()
              end)}
            </span>
          </li>
        </ol>
        <ol>
          <li :if={@new_message} class="text-left">
            <span class="font-bold text-green-500">AI:</span>
            <span class="prose">
              <span :if={@new_message == ""}>
                <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
              </span>
              <span :if={@new_message != ""}>{@new_message |> Markdown.html() |> raw()}</span>
            </span>
          </li>
        </ol>
      </div>

      <form phx-submit="send_message">
        <input
          type="text"
          name="message"
          placeholder="Type your message..."
          class="w-full p-2 border border-gray-300 rounded"
        />
        <button
          type="submit"
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mt-2"
        >
          Send
        </button>
      </form>

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
  def handle_event("send_message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message_content}, socket) do
    message = Message.user(message_content)

    agent = socket.assigns.agent
    {:ok, _} = agent |> Agent.run(message)

    socket =
      socket
      |> stream_insert(:messages, message)
      |> assign(new_message: "")
      |> push_event("scroll-to", %{selector: "#chat-log", to: "bottom"})

    {:noreply, socket}
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

        case message_type(message) do
          :message -> send(pid, {:message_processed, message})
          _ -> nil
        end
      end
    }

    # TODO(jinkyou): init with last messages
    {:ok, agent} = Agent.start_link(handler: handler)

    socket
    |> assign(:agent, agent)
  end

  defp user?(message), do: message_role(message) == :user

  defp message_role(%{role: role}), do: role

  defp message_type(message) do
    message.type
  end
end
