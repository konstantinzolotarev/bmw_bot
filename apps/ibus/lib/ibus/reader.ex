defmodule Ibus.Reader do
  use GenServer

  defmodule State do

    defstruct pid: nil
  end

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %State{}, opts)
  end

  @doc false
  def init(state) do
    {:ok, pid} = ExIbus.Reader.start_link()
    {:ok, %State{state | pid: pid}}
  end
end
