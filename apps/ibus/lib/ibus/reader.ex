defmodule Ibus.Reader do
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
    :ok = ExIbus.Reader.configure(Ibus.MessageReader, active: true, listener: __MODULE__, name: @name)
    {:ok, %State{}}
  end

  def handle_info({:nerves_uart, _, data}, state) when is_binary(data) do
    IO.inspect(data)
    ExIbus.Reader.write(Ibus.MessageReader, data)
    {:noreply, state}
  end
  def handle_info({:nerves_uart, _, _}, state), do: {:noreply, state}

  def handle_info({:ex_ibus, @name, data}, state) do
    IO.inspect(data)
  end


end
