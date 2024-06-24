defmodule VapiServer.VapiConnection do
  @moduledoc """
  Dev Connection to spawn NGROK and put it into a defined dev assistant
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Ngrok, port: 4000, name: VapiServer.Ngrok},
      VapiServer.VapiConnection.StartUp
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

# TODO: Move the Agent Setup into a more central module to reuse in client setup later.
defmodule VapiServer.VapiConnection.StartUp do
  use GenServer, restart: :transient

  require Logger

  @initial_prompt """
  You are a voice assistant for Mary's Dental, a dental office located at 123 North Face Place, Anaheim, California. The hours are 8 AM to 5PM daily, but they are closed on Sundays.

  Mary's dental provides dental services to the local Anaheim community. The practicing dentist is Dr. Mary Smith.

  You are tasked with answering questions about the business, and booking appointments. If they wish to book an appointment, your goal is to gather necessary information from callers in a friendly and efficient manner like follows:

  1. Ask for their full name.
  2. Ask for the purpose of their appointment.
  3. Request their preferred date and time for the appointment.
  4. Confirm all details with the caller, including the date and time of the appointment.

  - Be sure to be kind of funny and witty!
  - Keep all your responses short and simple. Use casual language, phrases like "Umm...", "Well...", and "I mean" are preferred.
  - This is a voice conversation, so keep your responses short, like in a real conversation. Don't ramble for too long.
  """
  @vapi_url "https://api.vapi.ai"

  def config, do: Application.get_env(:vapi_server, VapiServer.Vapi)

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, %{}, {:continue, :sync}}
  end

  @impl true
  def handle_continue(:sync, state) do
    ngrok_url = Ngrok.public_url(VapiServer.Ngrok)

    IO.inspect(config())
    IO.inspect({@vapi_url, config()[:dev_assistant_id]})

    case Finch.build(
           :patch,
           @vapi_url <> "/assistant/" <> config()[:dev_assistant_id],
           [
             {"Authorization", "Bearer " <> config()[:private_key]},
             {"Content-Type", "application/json"}
           ],
           Jason.encode!(%{
             llmRequestDelaySeconds: 0.1,
             model: %{
               url: ngrok_url,
               provider: "custom-llm",
               urlRequestMetadataEnabled: true,
               model: "lla3-8b-8192",
               messages: [%{content: @initial_prompt, role: :system}]
             }
           })
         )
         |> Finch.request(VapiServer.Finch) do
      {:ok, resp} when resp.status < 300 and resp.status >= 200 ->
        body = Jason.decode!(resp.body)

        Logger.info(
          "Vapi Assistant #{Map.get(body, "name", "<Unknown>")} (id: #{Map.get(body, "id")}) is now connected to your local server."
        )

      # TODO: Print Webcall link for testing or print phone number
      {:ok, resp} ->
        Logger.error(
          "Could not update assistant (#{config()[:dev_assistant_id]}), reason #{Jason.decode!(resp.body)}"
        )

      {:error, _resp} ->
        Logger.error("Could not call VAPI Server for local setup")
    end

    {:stop, :normal, state}
  end
end

defmodule VapiClient do
  require Logger

  @base_url "https://api.vapi.ai"

  def config, do: Application.get_env(:vapi_server, VapiServer.Vapi)

  # function for buy a phone number
  def buy_phone_number(country, name) do
    IO.inspect(config())
    headers = [
        {"Authorization", "Bearer "<> config()[:private_key]},
        {"Content-Type", "application/json"}
    ]

    body = %{areaCode: country,
             name: name,
             assistantId: <> config()[:dev_assistant_id] # this should get from config
            } |> Jason.encode!

    request = Finch.build(:post, @base_url <> "/phone-number/buy", headers, body)

    case Finch.request(request, VapiServer.Finch) do
      {:ok, %Finch.Response{status: 201, body: response_body}} ->
        Logger.info("Phone number bought successfully")
        {:ok, Jason.decode!(response_body)}

      {:ok, %Finch.Response{status: 400, body: response_body}} ->
        Logger.info("Failed bought phone number")
        {:ok, Jason.decode!(response_body)}

      {:error, resp} ->
        Logger.error("HTTP request failed: #{inspect(resp)}")
        {:error, Jason.decode!(resp)}
    end
  end

  # function for create a call
  def call(phone_number) do
    IO.inspect(config())
    headers = [
        {"Authorization", "Bearer "<> config()[:private_key]},
        {"Content-Type", "application/json"}
    ]

    body = %{
                phoneNumberId: "09dd14d8-6a59-49b7-82a4-62177c13ba12",
                assistantId: config()[:dev_assistant_id],
                customer: %{
                    number: phone_number
                }
            } |> Jason.encode!

    request = Finch.build(:post, @base_url <> "/call/phone", headers, body)

    case Finch.request(request, VapiServer.Finch) do
      {:ok, %Finch.Response{status: 201, body: response_body}} ->
        Logger.info("Call created successfully")
        {:ok, Jason.decode!(response_body)}

      {:ok, %Finch.Response{status: 400, body: response_body}} ->
        Logger.info("Failed create a call")
        {:ok, Jason.decode!(response_body)}

      {:error, resp} ->
        Logger.error("Unknown error")
        {:error, Jason.decode!(resp)}
    end
  end
end
