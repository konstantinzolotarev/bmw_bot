defmodule Ibus.Devices do

  @moduledoc """
  List of BMW device addresses
  """

  def body_module, do: <<0x00>>
  def sunroof_control, do: <<0x08>>
  def dme, do: <<0x12>>
  # CD Changer
  def cdc, do: <<0x18>>
  def radio_controlled_clock, do: <<0x28>>
  def diagnostic, do: <<0x3F>>
  def immobiliser, do: <<0x44>>
  # Multi function steering wheel
  def mfl, do: <<0x50>>
  # Integrated Heating And Air Conditioning
  def ihka, do: <<0x5B>>
  def rad, do: <<0x68>>
  def ike, do: <<0x80>>
  def mid, do: <<0xC0>>
  def tel, do: <<0xC8>>
  def broadcast, do: <<0xFF>>

end
