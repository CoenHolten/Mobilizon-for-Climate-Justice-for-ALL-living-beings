defmodule Mobilizon.Web.FeedController do
  @moduledoc """
  Controller to serve RSS, ATOM and iCal Feeds
  """
  use Mobilizon.Web, :controller
  plug(:put_layout, false)
  action_fallback(Mobilizon.Web.FallbackController)
  alias Mobilizon.Config
  require Logger

  @spec instance(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def instance(conn, %{"format" => format}) do
    if Config.get([:instance, :enable_instance_feeds], false) do
      return_data(conn, format, "instance", Config.instance_name())
    else
      send_resp(conn, 401, "Instance feeds are not enabled.")
    end
  end

  @spec actor(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def actor(conn, %{"format" => format, "name" => name}) do
    return_data(conn, format, "actor_" <> name, name)
  end

  def actor(_conn, _) do
    {:error, :not_found}
  end

  @spec event(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def event(conn, %{"uuid" => uuid, "format" => "ics"}) do
    return_data(conn, "ics", "event_" <> uuid, "event")
  end

  def event(_conn, _) do
    {:error, :not_found}
  end

  @spec going(Plug.Conn.t(), map()) :: Plug.Conn.t() | {:error, :not_found}
  def going(conn, %{"token" => token, "format" => format}) do
    return_data(conn, format, "token_" <> token, "events")
  end

  def going(_conn, _) do
    {:error, :not_found}
  end

  @spec return_data(Plug.Conn.t(), String.t(), String.t(), String.t()) ::
          Plug.Conn.t() | {:error, :not_found}
  defp return_data(conn, "atom", key, filename) do
    case Cachex.fetch(:feed, key) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("application/atom+xml")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{filename}.atom\""
        )
        |> send_resp(200, data)

      # No need to log these two
      {:ignore, :actor_not_found} ->
        {:error, :not_found}

      {:ignore, :actor_not_public} ->
        {:error, :not_found}

      err ->
        Logger.warning("Unable to find feed data cached for key #{key}, returned #{inspect(err)}")
        {:error, :not_found}
    end
  end

  defp return_data(conn, "ics", key, filename) do
    case Cachex.fetch(:ics, key) do
      {status, data} when status in [:commit, :ok] ->
        conn
        |> put_resp_content_type("text/calendar")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{filename}.ics\""
        )
        |> send_resp(200, data)

      # No need to log these two
      {:ignore, :actor_not_found} ->
        {:error, :not_found}

      {:ignore, :actor_not_public} ->
        {:error, :not_found}

      err ->
        Logger.warning("Unable to find feed data cached for key #{key}, returned #{inspect(err)}")
        {:error, :not_found}
    end
  end

  defp return_data(_conn, _, _, _) do
    {:error, :not_found}
  end
end
