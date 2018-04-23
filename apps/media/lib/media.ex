defmodule Media do
  @moduledoc """
  Documentation for Media.
  """

  require Logger

  @doc """
  Scan a new given folder for music in it.
  And after scaning start playing
  """
  def scan(path) do
    Logger.debug("#{__MODULE__}: Starting new media library in here: #{path}")
    Media.MplayerPort.rescan(path)
  end

  @doc """
  Forsing Mplayer to stop playing and quit
  """
  def quit() do
    Logger.debug("#{__MODULE__}: Stoping player")
    Media.MplayerPort.quit()
  end
end
