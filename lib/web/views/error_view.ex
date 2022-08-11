defmodule Mobilizon.Web.ErrorView do
  @moduledoc """
  View for errors
  """
  use Mobilizon.Web, :view

  @spec render(String.t(), map()) :: map() | String.t() | Plug.Conn.t()
  def render("404.html", _assigns) do
    render("index.html")
  end

  def render("404.json", _assigns) do
    %{msg: "Resource not found"}
  end

  def render("404.activity-json", _assigns) do
    %{msg: "Resource not found"}
  end

  def render("404.ics", _assigns) do
    "Bad feed"
  end

  def render("404.atom", _assigns) do
    "Bad feed"
  end

  def render("invalid_request.json", _assigns) do
    %{errors: "Invalid request"}
  end

  def render("not_found.json", %{details: details}) do
    %{
      msg: "Resource not found",
      details: details
    }
  end

  def render("406.json", _assigns) do
    %{msg: "Not acceptable"}
  end

  def render("500.json", assigns) do
    render("500.html", assigns)
  end

  def render("500.activity-json", assigns) do
    render("500.html", assigns)
  end

  def render("500.html", assigns) do
    locale =
      Mobilizon.Config.instance_config()
      |> Keyword.get(:default_language, "en")

    Gettext.put_locale(locale)

    assigns =
      assigns
      |> Map.update(:details, [], & &1)
      |> Map.put(:instance, Mobilizon.Config.instance_name())
      |> Map.put(:contact, Mobilizon.Config.contact())
      |> Map.put(:locale, locale)

    render("500_page.html", assigns)
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(template, assigns) do
    require Logger
    Logger.warn("Template #{inspect(template)} not found")
    render("500.html", assigns)
  end
end
