defmodule KrakenX.Spot.Client do
  @moduledoc """
  Handles HTTP requests to the Kraken Futures / Cryptofacilities API
  """
  @api_rest "/0/"

  def get_public(url, params \\ %{}) do
    (base_endpoint() <> @api_rest <> "public/" <> url)
    |> add_url_params(params)
    |> HTTPoison.get()
    |> parse_response()
  end

  def get_private(url, public_api_key, private_api_key, params \\ %{}) do
    endpoint_path = "/0/private/" <> url
    url = add_url_params(@api_rest <> "private/" <> url, params)
    headers = authorization_headers(endpoint_path, params, public_api_key, private_api_key)

    (base_endpoint() <> url)
    |> HTTPoison.get(headers)
    |> IO.inspect()
    |> parse_response()
  end

  defp authorization_headers(endpoint_path, params, public_api_key, private_api_key) do
    uri = endpoint_path

    %{
      "Content-Type" => "application/x-www-form-urlencoded",
      "API-Key" => public_api_key,
      "API-Sign" => signature(uri, nonce(), params, private_api_key)
    }
  end

  defp signature(path, nonce, form_data, secret) do
    params = URI.encode_query(form_data)
    sha_sum = :crypto.hash(:sha256, nonce <> params)
    mac_sum = :crypto.hmac(:sha512, secret, path <> sha_sum)
    Base.encode64(mac_sum)
  end

  defp add_url_params(url, params) when params == %{} do
    nonce = nonce()
    form_data = params |> Map.put(:nonce, nonce) |> process_params()
    url <> "?" <> URI.encode_query(form_data)
  end

  defp add_url_params(url, params) do
    nonce = nonce()
    form_data = params |> Keyword.put(:nonce, nonce) |> process_params()

    url <> "?" <> URI.encode_query(form_data)
  end

  defp process_params(params) do
    Enum.map(params, fn {k, v} ->
      case v do
        v when is_list(v) ->
          {k, Enum.join(v, ",")}

        _ ->
          {k, v}
      end
    end)
    |> Enum.reject(&is_empty/1)
  end

  defp is_empty({_, v}) when v in [nil, ""], do: true
  defp is_empty(_), do: false

  defp nonce do
    :os.system_time(:micro_seconds) |> to_string()
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: Jason.decode(body)

  defp parse_response({:ok, %HTTPoison.Response{status_code: status, body: body}}),
    do: {:error, {status, body}}

  defp parse_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}

  defp base_endpoint do
    case Application.get_env(:kraken_x, :test) do
      true -> "https://api.cryptofacilities.com"
      _ -> "https://api.kraken.com"
    end
  end
end
