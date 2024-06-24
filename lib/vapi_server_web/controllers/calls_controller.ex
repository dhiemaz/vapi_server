defmodule VapiServerWeb.CallController do
  @moduledoc """
  Entrypoint for VAPI communication.
  Will associate requests with the write chat and wait for answers.
  """
  use VapiServerWeb, :controller

  require Logger

  def createcall(conn, %{"phone_number" => phone_number}) do
    case VapiClient.call(phone_number) do
      {:ok, response} ->
        conn
        |> put_status(:created)
        |> json(response)

      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})
    end
  end

  def createcall(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing phone_number parameter"})
  end

  def buyphone_number(conn, _params) do
    case VapiClient.buy_phone_number("US") do
        {:ok, response} ->
          conn
          |> put_status(:created)
          |> json(response)

        {:error, error} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: error})
    end
  end
end
