defmodule Ibus.Reader do

  use GenServer
  alias Ibus.Message

  @moduledoc """
  This module is responsible for reading and fetching messages from data that it receives.
  Data could be sent byte by byte or message by message.
  """

  defmodule State do

    @moduledoc false
    @opaque t :: %__MODULE__{buffer: binary, controlling_process: pid, is_active: boolean}
    @doc false

    # buffer: list of bytes to process
    # messages: list of already parsed messages waiting to be sent
    # controlling_process: pid send messages to
    # is_active: active or passive mode
    defstruct buffer: "", 
      messages: [],
      controlling_process: nil,
      is_active: true

  end

  @type reader_options :: 
          {:active, boolean}
          | {:listener, pid}

  @spec start_link([term]) :: {:ok, pid} | {:error, term}
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %State{}, opts)

  @spec read() :: {:ok, [Ibus.Message.t]} | {:error, term}
  def read() do
    []
  end

  @doc """
  Send data to Module for processing
  """
  @spec write(GenServer.server, binary) :: :ok | {:error, term}
  def write(pid, msg) do
    GenServer.cast(pid, {:message, msg})
  end


  @doc false
  @spec init(State.t) :: {:ok, State.t}
  def init(state), do: {:ok, state}

  @doc """
  Handle new part of message or message
  Message will be places in buffer and sytem will try to get a valid message from it

  On success message fetching message will be avaliable into `Ibus.Reader.read()` function
  or will be sent to pid in case of `:active` mode

  ```elixir
  iex> send(pid, {:message, <<0x18, 0x04, 0x68, 0x01, 0x00>>})
  iex> Ibus.Reader.read(pid)
  [<<0x18, 0x04, 0x68, 0x01, 0x00>>]
  ```
  """
  @spec handle_info({:message, binary}, State.t) :: {:noreply, State.t} | {:error, term}
  def handle_info({:message, msg}, state) do
  
    {:noreply, state}
  end

  # handle message 
  def handle_cast({:message, msg}, state) do

    {:noreply, state}
  end

  # Process buffer that was received by module
  # And try to fetch all messages from it
  defp process_new_message(msg, %State{messages: messages, buffer: buffer} = state) do
    new_buff = buffer <> msg
    case byte_size(new_buff) do
      x when x in 0..5 -> %State{state | buffer: new_buff}
      x -> fetch_messages(%State{state | buffer: new_buff})
      _ -> state
    end
  end

  # Will try to fetch a valid message from buffer in state
  defp fetch_messages(%State{messages: messages, buffer: buffer} = state) do
    case process_buffer(buffer) do
      {:error, _} -> %State{state | buffer: ""}
      {:ok, rest, []} -> state
      {:ok, rest, new_messages} -> %State{state | messages: messages ++ new_messages, buffer: rest}
    end
  end

  # Function will process given binary buffer and fetch all available messages
  # from buffer
  defp process_buffer(buffer, messages \\ [])
  defp process_buffer("", messages), do: {:ok, "", messages}
  defp process_buffer(buffer, messages) when is_binary(buffer) do
    with true <- byte_size(buffer) >= 5,
         {:ok, msg, rest} <- pick_message(buffer) do

          process_buffer(rest, messages ++ [msg])
    else
      false -> {:ok, buffer, messages}
      {:error, _} -> 
        buffer
        |> :binary.part(1, byte_size(buffer) - 1)
        |> process_buffer(messages)
    end
  end
  defp process_buffer(_, _), do: {:error, "Wrong input buffer passed"}

  # Will try to get message in beginning of given buffer
  # On success funciton will return `{:ok, message, rest_of_buffer}`
  # otherwise it will return `{:error, term}`
  #
  # Note that rest of buffer might be an empty binary
  defp pick_message(<< src :: size(8), lng :: size(8), tail :: binary >>) do
    with true          <- byte_size(tail) >= lng,
         msg           <- :binary.part(tail, 0, lng),
         full          <- <<src>> <> <<lng>> <> msg,
         true          <- Message.valid?(full),
         {:ok, result} <- Message.parse(full),
         rest          <- :binary.part(tail, lng, byte_size(tail) - lng) do
           {:ok, result, rest}
    else
      _ -> {:error, "No valid message in message exist"}
    end
  end
  
  # Send list of messages one by one to controlling process
  defp send_messages(%State{messages: messages, controlling_process: cp}) do

  end

end
