defmodule Audio.MplayerPort do
  @moduledoc """
  Default genServer working with mplayer instance
  """
  use GenServer

  @player "mplayer"
  @default_args ["-nogui", "-quiet", "-nojoystick", "-nomouseinput", "-nosub", "-novideo", "-loop 0"]

  defmodule State do
    @moduledoc """
    Default state for `mplayer` port
    """

    @type state :: :stoped | :playing | :paused
    @type t :: %__MODULE__{path: binary, port: port, state: state}

    defstruct path: "", port: nil, state: :stoped
  end

  @doc false
  def start_link(path) when is_binary(path) do
    GenServer.start_link(__MODULE__, %State{path: path}, name: __MODULE__)
  end

  @doc false
  def init(%State{path: path} = state) do
    {:ok, state}
  end

  #
  # Callback functions
  #

  #
  # Client functions
  #

  #
  # Private functions
  #

  # Create new port for mplayer executable
  defp start_port(path) do
    executable = System.find_executable(@player)
    Port.open({:spawn_executable, executable}, [:binary, args: @default_args ++ [path]])
  end
end
