defmodule VapiServerWeb.ChatJSON do
  @moduledoc """
  Rendering internal chat completions into VAPI Format

  """

  def completions(%{answer: answer}) do
    answer
  end
end
