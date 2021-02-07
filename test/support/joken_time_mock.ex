defmodule PixelForum.Test.JokenTimeMock do
  @moduledoc """
  Allow mocking Joken time function for testing.
  """
  use Agent
  @behaviour Joken.CurrentTime

  @type timestamp :: pos_integer()

  @impl true
  @spec current_time() :: timestamp()
  def current_time do
    try do
      case Agent.get(agent_name(), & &1) do
        nil -> now()
        time -> time
      end
    catch
      # Return now if the agent is not started.
      :exit, {:noproc, _} -> now()
    end
  end

  def child_spec(_args) do
    %{
      id: PixelForum.Test.JokenTimeMock,
      start: {PixelForum.Test.JokenTimeMock, :start_link, [agent_name()]}
    }
  end

  def start_link(name), do: Agent.start_link(fn -> nil end, name: name)

  @spec freeze() :: :ok
  def freeze(), do: set_time(now())

  @spec set_time(timestamp()) :: :ok
  def set_time(timestamp), do: Agent.update(agent_name(), fn _ -> timestamp end)

  @spec advance(pos_integer()) :: :ok
  def advance(seconds), do: Agent.update(agent_name(), fn t -> advance(t, seconds) end)

  @spec release() :: :ok
  def release(), do: Agent.update(agent_name(), fn _ -> nil end)

  # Generates a name unique for each process, to keep tests independent.
  defp agent_name(), do: "#{__MODULE__}_#{inspect(self())}" |> String.to_atom()

  defp now(), do: :os.system_time(:second)

  defp advance(nil, amount), do: now() + amount
  defp advance(current_time, amount), do: current_time + amount
end
