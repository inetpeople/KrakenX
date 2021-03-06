#####
## orignial by: https://github.com/edennis/krakex/
## modified by: e_fu
## Licence MIT
#####

defmodule Krakex.HTTPClient do
  @moduledoc false

  @type response :: {:ok, term} | {:error, term}

  @client HTTPoison
  @headers [{"accept", "application/json"}]
  @post_headers @headers ++ [{"content-type", "application/x-www-form-urlencoded"}]

  @spec get(url :: String.t(), params :: keyword, headers :: list, client :: module) :: response
  def get(url, params, headers, client \\ @client)
      when is_binary(url) and is_list(params) and is_list(headers) do
    response = client.get(url, headers ++ @headers, params: params)
    handle_response(response)
  end

  @spec post(url :: String.t(), form_data :: keyword, headers :: list, client :: module) ::
          response
  def post(url, form_data, headers, client \\ @client)
      when is_binary(url) and is_list(form_data) and is_list(headers) do
    response = client.post(url, {:form, form_data}, headers ++ @post_headers)
    handle_response(response)
  end

  defp handle_response({:ok, response}), do: handle_http_response(response)
  defp handle_response({:error, %{reason: reason}}), do: {:error, reason}

  defp handle_http_response(%{status_code: status_code, body: body})
       when status_code in 200..206 do
    case Jason.decode(body) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, %Jason.DecodeError{}} ->
        {:error, {:invalid, body}}
    end
  end

  defp handle_http_response(%{status_code: status_code, body: body}),
    do: {:error, {status_code, body}}
end
