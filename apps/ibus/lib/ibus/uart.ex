defmodule Ibus.UART do
  use GenServer

  @name Application.get_env(:ibus, :interface_name)

  defmodule State do
    defstruct pid: nil
  end

  @doc false
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  @doc false
  def init(state) do
    {:ok, _pid} = Nerves.UART.start_link(name: Ibus.Serial)
    :ok = Nerves.UART.open(Ibus.Serial, @name, active: true, speed: 9600, parity: :even)
    {:ok, _pid} = ExIbus.Reader.start_link(name: Ibus.MessageReader)

    :ok =
      ExIbus.Reader.configure(Ibus.MessageReader, active: true, listener: __MODULE__, name: @name)

    {:ok, %State{}}
  end

  #
  # Callback functions
  #

  @doc """
  Handle send action to Ibus
  """
  def handle_cast({:send, %ExIbus.Message{} = msg}, state) do
    Nerves.UART.write(Ibus.Serial, ExIbus.Message.raw(msg))
    {:noreply, state}
  end

  @doc """
  Handler function for Nerves message
  After handling something from Nerves we have to send it into reader.

  After all work on messages/buffers reader will send us back a correct message.
  """
  def handle_info({:nerves_uart, _, data}, state) when is_binary(data) do
    ExIbus.Reader.write(Ibus.MessageReader, data)
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _, _}, state), do: {:noreply, state}

  @doc """
  Handle message from `ExIbus.Reader` combined and working.
  """
  def handle_info({:ex_ibus, _name, data}, state) do
    Ibus.Router.notify(data)
    {:noreply, state}
  end

  #
  # Client functions
  #

  def send(%ExIbus.Message{} = msg), do: GenServer.cast(__MODULE__, {:send, msg})
end
