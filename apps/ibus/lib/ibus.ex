defmodule Ibus do
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
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, @name, active: true, speed: 9600, parity: :even)
    {:ok, %State{state | pid: pid}}
  end

  def handle_info({:nerves_uart, _, data}, state) when is_binary(data) do
    IO.inspect(data)
    {:noreply, state}
  end
  def handle_call({:nerves_uart, _, _}, state), do: {:noreply, state}

end
