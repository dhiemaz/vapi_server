defmodule VapiServer.Groq do
  @moduledoc """
  Wrapper around the Groq API. Supports stream mode
  """

  @groq_url "https://api.groq.com/openai/v1/chat/completions"

  @allowed_tokens ~w(max_tokens messages model stream temperature)
  @models ["llama3-8b-8192", "llama3-70b-8192", "gemma-7b-it", "mixtral-8x7b32768"]
  @default_model "llama3-8b-8192"

  def config, do: Application.get_env(:vapi_server, __MODULE__)

  def build(body) do
    body =
      body
      |> Enum.filter(fn {k, _v} -> k in @allowed_tokens end)
      |> Map.new()

    if Map.get(body, "model") in @models, do: body, else: Map.put(body, "model", @default_model)

    Finch.build(
      :post,
      @groq_url,
      [
        {"Authorization", "Bearer " <> config()[:api_key]},
        {"Content-Type", "application/json"}
      ],
      Jason.encode!(body)
    )
  end

  def stream_while(body, acc, fun) do
    build(body)
    |> Finch.stream_while(VapiServer.Finch, acc, fun)
  end

  @doc """
  Returns a finch response from the Model API
  """
  def request(body) do
    build(body)
    |> Finch.request(VapiServer.Finch)
  end
end
