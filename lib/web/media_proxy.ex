# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.MediaProxy do
  @moduledoc """
  Module to proxify remote media
  """
  alias Mobilizon.Config
  alias Mobilizon.Web

  @base64_opts [padding: false]

  @spec url(String.t() | nil) :: String.t() | nil
  def url(url) when is_nil(url) or url == "", do: nil
  def url("/" <> _ = url), do: url

  def url(url) do
    if enabled?() and url_proxiable?(url) do
      encode_url(url)
    else
      url
    end
  end

  @spec url_proxiable?(String.t()) :: boolean()
  def url_proxiable?(url) do
    not local?(url)
  end

  @spec enabled? :: boolean()
  def enabled?, do: Config.get([:media_proxy, :enabled], false)

  def local?(url), do: String.starts_with?(url, Web.Endpoint.url())

  @spec base64_sig64(String.t()) :: {String.t(), String.t()}
  defp base64_sig64(url) do
    base64 = Base.url_encode64(url, @base64_opts)

    sig64 =
      base64
      |> signed_url()
      |> Base.url_encode64(@base64_opts)

    {base64, sig64}
  end

  @spec encode_url(String.t()) :: String.t()
  def encode_url(url) do
    {base64, sig64} = base64_sig64(url)

    build_url(sig64, base64, filename(url))
  end

  @spec decode_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, :invalid_signature}
  def decode_url(sig, url) do
    with {:ok, sig} <- Base.url_decode64(sig, @base64_opts),
         signature when signature == sig <- signed_url(url) do
      {:ok, Base.url_decode64!(url, @base64_opts)}
    else
      _ -> {:error, :invalid_signature}
    end
  end

  @spec signed_url(String.t()) :: String.t()
  defp signed_url(url) do
    sha_hmac(Config.get([Web.Endpoint, :secret_key_base]), url)
  end

  @spec sha_hmac(String.t(), String.t()) :: String.t()
  @compile {:no_warn_undefined, {:crypto, :mac, 4}}
  @compile {:no_warn_undefined, {:crypto, :hmac, 3}}
  defp sha_hmac(key, url) do
    :crypto.mac(:hmac, :sha, key, url)
  end

  @spec filename(String.t()) :: String.t() | nil
  def filename(url_or_path) do
    if path = URI.parse(url_or_path).path, do: Path.basename(path)
  end

  @spec base_url :: String.t()
  def base_url do
    Web.Endpoint.url()
  end

  @spec proxy_url(String.t(), String.t(), String.t(), String.t() | nil) :: String.t()
  defp proxy_url(path, sig_base64, url_base64, filename) do
    [
      base_url(),
      path,
      sig_base64,
      url_base64,
      filename
    ]
    |> Enum.filter(& &1)
    |> Path.join()
  end

  @spec build_url(String.t(), String.t(), String.t() | nil) :: String.t()
  def build_url(sig_base64, url_base64, filename \\ nil) do
    proxy_url("proxy", sig_base64, url_base64, filename)
  end

  @spec verify_request_path_and_url(Plug.Conn.t() | String.t(), String.t()) ::
          :ok | {:wrong_filename, String.t()}
  def verify_request_path_and_url(
        %Plug.Conn{params: %{"filename" => _}, request_path: request_path},
        url
      ) do
    verify_request_path_and_url(request_path, url)
  end

  def verify_request_path_and_url(request_path, url) when is_binary(request_path) do
    filename = filename(url)

    if filename && not basename_matches?(request_path, filename) do
      {:wrong_filename, filename}
    else
      :ok
    end
  end

  def verify_request_path_and_url(_, _), do: :ok

  @spec basename_matches?(String.t(), String.t()) :: boolean()
  defp basename_matches?(path, filename) do
    basename = Path.basename(path)
    basename == filename or URI.decode(basename) == filename or URI.encode(basename) == filename
  end
end
