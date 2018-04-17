defmodule Media.MplayerPort do
  @moduledoc """
  Default genServer working with mplayer instance
  """
  use GenServer

  alias Media.File.Scaner
  require Logger

  @player "mplayer"
  @default_args [
    "-nogui",
    "-quiet",
    "-idle",
    "-slave",
    "-noar",
    "-nojoystick",
    "-nomouseinput",
    "-nosub",
    "-novideo"
  ]

  defmodule State do
    @moduledoc """
    Default state for `mplayer` port
    """

    @type status :: :stoped | :playing | :paused
    @type t :: %__MODULE__{
            path: binary,
            port: port,
            monitor_ref: reference(),
            status: status(),
            playlist: binary
          }

    defstruct path: "", port: nil, monitor_ref: nil, status: :stoped, playlist: ""
  end

  @doc false
  def start_link(path \\ "") when is_binary(path) do
    GenServer.start_link(__MODULE__, %State{path: path}, name: __MODULE__)
  end

  @doc false
  def init(state), do: {:ok, state}

  def terminate(_reason, %State{port: nil}), do: :normal

  def terminate(_reason, state) do
    Logger.debug("Send terminate")
    send_command(state, "quit")
    :normal
  end

  #
  # Callback functions
  #

  # Handle new folder connection
  def handle_call({:rescan, path}, _from, state) when is_binary(path) do
    case Scaner.scan(path) do
      {:error, err} ->
        Logger.error("#{__MODULE__}: Got error due to scaning media library #{inspect(err)}")
        {:reply, {:error, err}, state}

      playlist when is_binary(playlist) ->
        Logger.debug("#{__MODULE__}: Everything good. Library loaded")
        {:reply, :ok, %State{state | path: path, playlist: playlist}}
    end
  end

  def handle_cast(:play, %State{port: nil} = state) do
    state
    |> start_port()
    |> load_meta_info()
  end

  def handle_cast(:play, %State{status: :paused} = state),
    do: send_command(%State{state | status: :playing}, "pause")

  def handle_cast(:play, state), do: {:noreply, state}

  def handle_cast(:pause, %State{status: :playing} = state),
    do: send_command(%State{state | status: :paused}, "pause")

  def handle_cast(:pause, %State{status: :paused} = state),
    do: send_command(%State{state | status: :playing}, "pause")

  def handle_cast(:pause, %State{status: :stoped} = state), do: {:noreply, state}

  def handle_cast(:next, state), do: send_command(state, "pt_step 1")

  def handle_cast(:prev, state), do: send_command(state, "pt_step -1")

  def handle_cast(:stop, state), do: send_command(%State{state | status: :stoped}, "stop")

  def handle_cast(:mute, state), do: send_command(state, "mute")

  def handle_cast(:seek_forward, state), do: send_command(state, "seek +10 0")

  def handle_cast(:seek_backward, state), do: send_command(state, "seek -10 0")

  # Run set of commands to find out meta information about song
  def handle_cast(:load_meta, state), do: load_meta_info(state)

  #
  # Handling messages from mplayer daemon
  #

  #
  # Loading track meta info
  #

  def handle_info({_port, {:data, data}}, state) when is_binary(data) do
    data
    |> String.replace("\n", "")
    |> handle_data(state)
  end

  #
  # Handle playing new song
  #

  # Handle mplayer stoped
  def handle_info({:DOWN, _ref, :port, _port, :normal}, %State{monitor_ref: ref} = state) do
    Logger.debug("#{__MODULE__}: Mplayer exited normally")
    Port.demonitor(ref)
    {:noreply, %State{state | port: nil, monitor_ref: nil, status: :stoped}}
  end

  # Handle mplayer stoped with non normal reason
  def handle_info({:DOWN, _ref, :port, _port, reason}, %State{monitor_ref: ref} = state) do
    Logger.error("#{__MODULE__}: Mplayer port failed with reason: #{inspect(reason)}")
    Port.demonitor(ref)
    {:noreply, start_port(state)}
  end

  def handle_info({:EXIT, _from, reason}, state) do
    Logger.debug("#{__MODULE__}: Exit signal catched #{inspect(reason)}")
    send_command(state, "quit")
    # see GenServer docs for other return types
    {:stop, reason, state}
  end

  # Handling everything else
  def handle_info(_, state), do: {:noreply, state}

  #
  # Client functions
  #

  @doc """
  Rescanning new music files path and prepare new playlist form this folder
  """
  @spec rescan(binary) :: :ok | {:error, term}
  def rescan(path) when is_binary(path) and byte_size(path) > 0,
    do: GenServer.call(__MODULE__, {:rescan, path})

  def rescan(_), do: {:error, "Wrong path passed"}

  def play(), do: GenServer.cast(__MODULE__, :play)

  def pause(), do: GenServer.cast(__MODULE__, :pause)

  def stop(), do: GenServer.cast(__MODULE__, :stop)

  def next(), do: GenServer.cast(__MODULE__, :next)

  def prev(), do: GenServer.cast(__MODULE__, :prev)

  def mute(), do: GenServer.cast(__MODULE__, :mute)

  def seek_forward(), do: GenServer.cast(__MODULE__, :seek_forward)

  def seek_backward(), do: GenServer.cast(__MODULE__, :seek_backward)

  #
  # Private functions
  #

  defp handle_data(<<"ANS_FILENAME='", data::binary>>, state) do
    Logger.debug(data)
    {:noreply, state}
  end

  # defp handle_data(<<"ANS_META_TITLE='", data::binary>>, state) do
  #   Logger.debug(data)
  #   {:noreply, state}
  # end
  #
  # defp handle_data(<<"ANS_META_ALBUM='", data::binary>>, state) do
  #   Logger.debug(data)
  #   {:noreply, state}
  # end
  #
  # defp handle_data(<<"ANS_META_ARTIST='", data::binary>>, state) do
  #   Logger.debug(data)
  #   {:noreply, state}
  # end
  #
  # defp handle_data(<<"ANS_META_TRACK='", data::binary>>, state) do
  #   Logger.debug(data)
  #   {:noreply, state}
  # end
  #
  # defp handle_data(<<"ANS_META_YEAR='", data::binary>>, state) do
  #   Logger.debug(data)
  #   {:noreply, state}
  # end

  defp handle_data(<<"Playing ", _name::binary>>, state) do
    Logger.debug("#{__MODULE__}: Playing new song")
    load_meta_info(state)
  end

  # handle Mplayer exit
  defp handle_data("Exiting... (Quit)", state) do
    Logger.debug("#{__MODULE__}: Mplayer exited... Waiting for details")
    {:noreply, state}
  end

  defp handle_data(_, state), do: {:noreply, state}

  # Send set of commands for fetching metadata
  defp load_meta_info(state) do
    send_command(state, "get_file_name")
    send_command(state, "get_meta_album")
    send_command(state, "get_meta_artist")
    send_command(state, "get_meta_title")
    send_command(state, "get_meta_track")
    send_command(state, "get_meta_year")
    # send_command(state, "get_time_length")
    # send_command(state, "get_time_pos")
  end

  # Create new port for mplayer executable
  defp start_port(%State{playlist: ""} = state), do: state

  defp start_port(%State{playlist: playlist} = state) do
    executable = System.find_executable(@player)

    port =
      Port.open({:spawn_executable, executable}, [
        :binary,
        args: @default_args ++ ["-playlist", playlist]
      ])

    ref = Port.monitor(port)
    %State{state | port: port, monitor_ref: ref}
  end

  # Send command to mplayer
  defp send_command(%State{port: nil} = state, _), do: {:noreply, state}

  defp send_command(%State{port: port} = state, command) do
    true =
      port
      |> Port.command(command <> "\n")

    {:noreply, state}
  end
end
