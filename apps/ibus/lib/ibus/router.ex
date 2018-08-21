defmodule Ibus.Router do
  use GetServer

  @doc false
  def start_link(_) do
    GetServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc false
  def init(_), do: {:ok, %{}}

  #
  # Callbacks
  #

  def handle_cast({:subscribe, dst, pid}, list) when is_binary(dst) do
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

  def handle_cast({:notify, %Message{dst: dst} = msg}, state) do
    {:noreply, state}
  end

  #
  # Client function
  #

  @doc """
  Add a handler for messages by it's destination
  """
  @spec subscribe(binary, pid) :: :ok
  def subscribe(dst, pid) when is_binary(dst),
    do: GenServer.cast(__MODULE__, {:subscribe, dst, pid})

  def subscribe(_, _), do: :error

  @doc """
  Notifies all listeners with a received message
  """
  @spec notify(ExIbus.Message.t()) :: :ok | {:error, term}
  def notify(%ExIbus.Message{} = msg), do: GenServer.cast(__MODULE__, {:notify, msg})

  def notify(_), do: :ok

  #
  # Private functions
  #

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
