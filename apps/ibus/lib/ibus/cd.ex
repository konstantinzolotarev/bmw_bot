defmodule Ibus.CD do
  use GenServer
  alias Ibus.Devices

  @cdc Devices.cdc()

  defmodule Message do
    @doc """
    Announce cdc message
    """
    @spec announce() :: ExIbus.Message.t()
    def announce, do: ExIbus.Message.create(Devices.cdc(), Devices.broadcast(), <<0x02, 0x01>>)

    @doc """
    Response on cdc request message
    """
    @spec poll_respose() :: ExIbus.Message.t()
    def poll_respose,
      do: ExIbus.Message.create(Devices.cdc(), Devices.broadcast(), <<0x02, 0x00>>)
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    Ibus.Router.handle(@cdc, self())
    {:ok, []}
  end

  @doc """
  Handling CD poll request and send correct reply
  """
  def handle_info(%ExIbus.Message{dst: @cdc, msg: <<0x01>>} = msg, state) do
    Ibus.UART.send(Message.poll_respose())
    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.inspect "CDC"
    IO.inspect msg
    {:noreply, state}
  end
  def handle_info(_, state), do: {:noreply, state}
end
