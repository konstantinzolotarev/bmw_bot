defmodule Ibus.Device.CD do
  use GenServer
  alias Ibus.Devices

  require Logger
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

    @spec status_not_playing(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_not_playing(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x00, 0x02, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    @spec status_playing(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_playing(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x00, 0x09, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    @spec status_start_playing(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_start_playing(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x02, 0x09, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    @spec status_scan_forward(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_scan_forward(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x03, 0x09, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    @spec status_scan_backward(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_scan_backward(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x04, 0x09, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    @spec status_end_of_title(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_end_of_title(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x07, 0x09, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    @spec status_cd_changed(non_neg_integer, non_neg_integer) :: ExIbus.Message.t()
    def status_cd_changed(cd, track),
      do: %ExIbus.Message{
        src: Devices.cdc(),
        dst: Devices.rad(),
        msg: <<0x39, 0x08, 0x09, 0x00, 0x3f>> <> cd_track_to_binary(cd, track)
      }

    # Convert integer number to binary
    defp cd_track_to_binary(cd, track),
      do: Integer.to_string(cd) <> Integer.to_string(track)
  end

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_state) do
    Ibus.Router.handle(@cdc, self())
    Ibus.Device.CD.send_announce()
    {:ok, []}
  end

  @doc false
  def handle_cast(:send_announce, state) do
    Logger.debug("#{__MODULE__}: Sending annoounce message")
    Ibus.UART.send(Message.announce())
    {:noreply, state}
  end

  @doc """
  Handling CD poll request and send correct reply
  """
  def handle_info(%ExIbus.Message{dst: @cdc, msg: <<0x01>>}, state) do
    Ibus.UART.send(Message.poll_respose())
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("#{__MODULE__}: Handled message #{inspect(msg)}")
    {:noreply, state}
  end
  # def handle_info(_, state), do: {:noreply, state}

  #
  # Client functions
  #
  def send_announce() do
    GenServer.cast(__MODULE__, :send_announce)
  end
end
