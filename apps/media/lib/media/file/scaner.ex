defmodule Media.File.Scaner do
  @moduledoc """
  File scanner for media application.
  """

  require Logger

  # list of file extensions to pick in path
  @files [".mp3", ".wav", ".m4a"]

  #
  # Client functions
  #

  @doc """
  Scan path for MP3 files

  And return path to playlist
  """
  @spec scan(binary) :: binary | {:error, term}
  def scan(path) when is_binary(path) do
    Logger.debug("#{__MODULE__}: Started to scan files into #{inspect(path)}")
    abs_path = path |> Path.expand()

    case File.dir?(abs_path) do
      false ->
        {:error, "Passed path is not directory"}

      true ->
        scan_dir(abs_path)
        |> Enum.map(&normalize_path/1)
        |> store_playlist()
    end
  end

  def scan(_), do: {:error, "Wrong path for scaning"}

  #
  # Private functions
  #

  defp scan_dir(path, list \\ []) do
    path
    |> File.ls!()
    |> Enum.map(fn file ->
      fname = "#{path}/#{file}"

      case File.dir?(fname) do
        false ->
          case String.ends_with?(fname, @files) do
            true -> list ++ [fname]
            _ -> list
          end

        true ->
          scan_dir(fname, list)
      end
    end)
    |> List.flatten()
  end

  defp normalize_path(path) do
    path
    |> String.replace("''", "\\'")
    |> String.replace("\"", "\\\"")
  end

  # Store list of found files into playerlist
  defp store_playlist(files) do
    tmp = System.tmp_dir!()
    file_name = tmp <> "playlist.m3a"
    content = files |> Enum.join("\n")
    :ok = File.write(file_name, content)
    file_name
  end
end
