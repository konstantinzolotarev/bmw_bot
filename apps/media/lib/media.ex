defmodule Media do
  @moduledoc """
  Documentation for Media.
  """

  require Logger

  @doc """
  Start new media system with music library into given path
  """
  def start(path) do
    Logger.debug("#{__MODULE__}: Starting new media library in here: #{path}")
    Media.MplayerPort.rescan(path)
  end

  def play() do
    Media.MplayerPort.play()
  end
end
