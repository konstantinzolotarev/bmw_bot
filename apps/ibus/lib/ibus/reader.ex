defmodule Ibus.Reader do
  use GenServer

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %State{}, opts)
  end

  @doc false
  def init(state) do
    {:ok, pid} = ExIbus.Reader.start_link()
    {:ok, state}
  end
end
