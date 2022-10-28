defmodule Mobilizon.Federation.ActivityStream.Converter.Address do
  @moduledoc """
  Address converter.

  This module allows to convert reports from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Addresses.Address, as: AddressModel

  alias Mobilizon.Federation.ActivityStream.Converter

  @behaviour Converter

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map
  def as_to_model_data(object) do
    res = %{
      "description" => object["name"],
      "url" => object["url"]
    }

    res =
      if is_nil(object["address"]) or not is_map(object["address"]) do
        res
      else
        Map.merge(res, %{
          "country" => object["address"]["addressCountry"],
          "postal_code" => object["address"]["postalCode"],
          "region" => object["address"]["addressRegion"],
          "street" => object["address"]["streetAddress"],
          "locality" => object["address"]["addressLocality"]
        })
      end

    latitude = Map.get(object, "latitude")
    longitude = Map.get(object, "longitude")

    if is_float(latitude) and is_float(longitude) do
      Map.put(res, "geom", %Geo.Point{
        coordinates: {longitude, latitude},
        srid: 4326
      })
    else
      res
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation.
  """
  @impl Converter
  @spec model_to_as(AddressModel.t()) :: map
  def model_to_as(%AddressModel{} = address) do
    res = %{
      "type" => "Place",
      "name" => address.description,
      "id" => address.url,
      "address" => %{
        "type" => "PostalAddress",
        "streetAddress" => address.street,
        "postalCode" => address.postal_code,
        "addressLocality" => address.locality,
        "addressRegion" => address.region,
        "addressCountry" => address.country
      }
    }

    if is_nil(address.geom) do
      res
    else
      res
      |> Map.put("longitude", address.geom.coordinates |> elem(0))
      |> Map.put("latitude", address.geom.coordinates |> elem(1))
    end
  end
end
