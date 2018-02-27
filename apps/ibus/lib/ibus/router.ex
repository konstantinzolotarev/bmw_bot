defmodule Ibus.Router do
  use GenServer

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_), do: {:ok, []}

  #
  # Callbacks
  #

  def handle_cast({:handle, dst, pid}, list) when is_binary(dst) do
    case Enum.member?(list, dst) do
      true ->
        join_pid(dst, pid)
        {:noreply, list}

      false ->
        :ok = :pg2.create(dst)
        :ok = :pg2.join(dst, pid)
        {:noreply, list ++ [dst]}
    end
  end

  #
  # Client function
  #

  @doc """
  Add a handler for messages by it's destination
  """
  @spec handle(binary, pid) :: :ok
  def handle(dst, pid) when is_binary(dst),
    do: GenServer.cast(__MODULE__, {:handle, dst, pid})

  def handle(_, _), do: :error

  def notify(%ExIbus.Message{} = msg) do
    IO.inspect(msg)
    broadcast(msg)
  end

  def notify(_), do: :ok

  #
  # Private functions
  #

  defp join_pid(dst, pid) do
    has =
      dst
      |> :ps2.get_members()
      |> Enum.member?(pid)

    unless has do
      :ok = :pg2.join(dst, pid)
    end

    :ok
  end

  defp broadcast(%ExIbus.Message{dst: dst} = msg) do
    case :pg2.get_members(dst) do
      {:error, _} ->
        :ok

      [] ->
        :ok

      list when is_list(list) ->
        list
        |> Enum.map(&Task.async(fn -> send(&1, msg) end))
        |> Enum.map(&Task.await/1)

        :ok
    end
  end
end
