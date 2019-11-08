defmodule KrakenX.Futures.Client do
  @moduledoc """
  Handles HTTP requests to the Kraken Futures / Cryptofacilities API
  """
  @api_v3 "/derivatives/api/v3/"
  def get_public(url, params \\ %{}) do
    (base_endpoint() <> @api_v3 <> url)
    |> add_url_params(params)
    |> HTTPoison.get()
    |> parse_response()
  end

  def get_private(url, public_api_key, private_api_key, params \\ %{}) do
    endpoint_path = "/api/v3/" <> url
    url = add_url_params(@api_v3 <> url, params)
    headers = authorization_headers(endpoint_path, params, public_api_key, private_api_key)

    (base_endpoint() <> url)
    |> HTTPoison.get(headers)
    |> parse_response()
  end

  defp authorization_headers(endpoint_path, params, public_api_key, private_api_key) do
    postData = URI.encode_query(params)
    nonce = get_timestamp() |> to_string()
    concatenate = postData <> nonce <> endpoint_path
    hash = :crypto.hash(:sha256, concatenate)
    secret = Base.decode64!(private_api_key)
    signature = :crypto.hmac(:sha512, secret, hash) |> Base.encode64()

    [
      APIKey: public_api_key,
      Nonce: nonce,
      Authent: "#{signature}"
    ]
  end

  defp get_timestamp, do: DateTime.utc_now() |> DateTime.to_unix() |> Kernel.*(1000)

  defp add_url_params(url, params) when params == %{}, do: url
  defp add_url_params(url, params), do: url <> "?" <> URI.encode_query(params)

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: Jason.decode(body)

  defp parse_response({:ok, %HTTPoison.Response{status_code: status, body: body}}),
    do: {:error, {status, Jason.decode!(body)}}

  defp parse_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}

  defp base_endpoint do
    case Application.get_env(:kraken_x, :whitelisted_futures) do
      true -> "https://api.cryptofacilities.com"
      _ -> "https://futures.kraken.com"
    end
  end
end
