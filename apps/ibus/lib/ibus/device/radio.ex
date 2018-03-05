defmodule Ibus.Device.Radio do
  @moduledoc """
  Radio messages handler

  Also has list of functions for triggering functions
  """
  use GenServer

  defmodule Message do
    
  end

  def send_text(text), do: :ok 

  def clear_display(), do: :ok
end
