defmodule Media.Song do
  @moduledoc """
  Default Song structure for player
  """

  @type t :: %__MODULE__{
          album: binary,
          artist: binary,
          filename: binary,
          title: binary,
          track: binary,
          year: binary
        }

  defstruct album: "", artist: "", filename: "", title: "", track: "", year: ""

  @doc """
  Format song title for displaying into screen
  """
  @spec display(Media.Song.t()) :: binary
  def display(%__MODULE__{} = song) do
    [song.artist, song.album, song.title, song.track, song.year, song.filename]
    |> Enum.join(" ")
    |> String.trim()
  end

  def display(_), do: "Unknown song... Sorry..."
end
