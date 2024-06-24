defmodule VapiServerWeb.ChatController do
  @moduledoc """
  Entrypoint for VAPI communication.
  Will associate requests with the write chat and wait for answers.
  """
  use VapiServerWeb, :controller

  require Logger

  def completions(conn, %{"stream" => true} = params) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> send_chunked(200)

    with {:ok, conn} <-
           params
           |> Map.put("model", "llama3-8b-8192")
           |> VapiServer.Groq.stream_while(conn, fn
             {:data, data}, conn ->
               # Logger.info(data)

               case chunk(conn, data) do
                 {:ok, conn} -> {:cont, conn}
                 {:error, _} -> {:halt, conn}
               end

             _data, conn ->
               # Logger.debug(inspect(data))
               {:cont, conn}
           end) do
      conn
    end

    # conn
    # |> stream_response(
    # id,
    # "Thank you. Unfortunalty we are not yet ready and I cannot answer you."
    # )
  end

  def completions(conn, params) do
    case params
         |> Map.put("model", "llama3-8b-8192")
         |> VapiServer.Groq.request() do
      {:ok, resp} ->
        send_resp(conn, resp.status, resp.body)

      _ ->
        send_resp(conn, 500, "Error")
    end

    # Returns {:ok, conn}, or {:error, conn} if sending failedp
  end
end
