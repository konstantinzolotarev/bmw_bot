defmodule Ibus.Device.Tel do
  @moduledoc """
  Radio messages handler

  Also has list of functions for triggering functions
  """
  use GenServer
  alias Ibus.Devices

  require Logger

  @tel Devices.tel()

  defmodule Message do

    @spec text(binary) :: ExIbus.Message.t()
    def text(text), do: ExIbus.Message.create(Devices.tel(), Devices.ike(), <<0x23, 0x42, 0x30>> <> text)

    @spec clear_display() :: ExIbus.Message.t()
    def clear_display(), do: ExIbus.Message.create(Devices.tel(), Devices.ike(), <<0x23, 0x41, 0x20>>)
  end

  @doc false
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  @doc false
  def init(_state) do
    Ibus.Router.subscribe(@tel, self())
    {:ok, []}
  end

  #
  # Callback functions
  #

  def handle_info(msg, state) do
    Logger.debug("#{__MODULE__}: Handled message #{inspect(msg)}")
    {:noreply, state}
  end
  # def handle_info(_, state), do: {:noreply, state}


  #
  # Client functions
  #

  @doc """
  Send set text to IKE.
  In my car text will be set into Radio display
  """
  @spec send_text(binary) :: :ok
  def send_text(text) do
    text
    |> Message.text()
    |> Ibus.UART.send()
  end

  @doc """
  Send clear display message to IKE (works for radios also)

  Know That actually it wouldn't clean screen
  But it will set default Radio display to work
  """
  @spec clear_display() :: :ok
  def clear_display() do
    Message.clear_display()
    |> Ibus.UART.send()
  end
end
