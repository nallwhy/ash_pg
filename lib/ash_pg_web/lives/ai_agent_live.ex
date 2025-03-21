defmodule AshPgWeb.AiAgentLive do
  use AshPgWeb, :live_view

  alias AshPg.Ai.Agent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_agent()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>AI Chat</h1>

      <div id="chat-log" class="overflow-y-scroll h-96 border border-gray-300 rounded p-4 mb-4">
        <ol id="messages">
          <%= for message <- @agent.messages do %>
            <li
              :if={message_role(message) != :system and message_type(message) == :message}
              class={"#{if user?(message), do: "text-right", else: "text-left"}"}
            >
              <span class={"font-bold #{if user?(message), do: "text-blue-500", else: "text-green-500"}"}>
                {if user?(message), do: "You", else: "AI"}:
              </span>
              {message.content}
            </li>
          <% end %>
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

      <div :for={tool <- @agent.tools} class="whitespace-pre-wrap">
        {tool.parameters_schema |> Jason.encode!(pretty: true)}
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("send_message", %{"message" => ""}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    agent = socket.assigns.agent

    socket =
      case agent |> Agent.run(message) do
        {:ok, agent} ->
          socket
          |> assign(:agent, agent)

        {:error, reason} ->
          socket
          |> put_flash(:error, "Error: #{reason}")
      end

    {:noreply, socket}
  end

  defp assign_agent(socket) do
    socket
    |> assign(:agent, Agent.init())
  end

  defp user?(message), do: message_role(message) == :user

  defp message_role(%{role: role}), do: role

  defp message_type(message) do
    cond do
      not is_nil(message.content) -> :message
      not Enum.empty?(message.tool_calls) -> :tool_call
      not is_nil(message.tool_results) -> :tool_result
    end
  end
end
