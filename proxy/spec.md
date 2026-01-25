### **YR Ocean Forecast Proxy: API Specification**

#### **1. Overview**

This document specifies a proxy service that sits in front of the MET Norway Ocean Forecast API. The proxy's main purpose is to simplify the complex data structure provided by the MET API and reduce the overall payload size, making it more efficient for clients with limited resources, such as embedded devices.

#### **2. Upstream Service**

*   **API**: MET Norway Ocean Forecast API
*   **Endpoint**: `https://api.met.no/weatherapi/oceanforecast/2.0/complete`
*   **Authentication**: The proxy must include a descriptive `User-Agent` header in its requests to the upstream API.
    *   Example: `User-Agent: Helloface/1.0 (yourapp@example.com)`

##### **Upstream Service: Weather Forecast**

*   **API**: MET Norway Location Forecast API
*   **Endpoint**: `https://api.met.no/weatherapi/locationforecast/2.0/complete`
*   **Authentication**: Same `User-Agent` as the Ocean Forecast.

#### **3. Proxy Endpoint**

The proxy exposes a single endpoint.

*   **Method**: `GET`
*   **Path**: `/`
*   **Query Parameters**:
    *   `lat` (float, optional): The latitude for the forecast. The value is rounded to four decimal places.
        *   **Default**: `55.7122`
    *   `lon` (float, optional): The longitude for the forecast. The value is rounded to four decimal places.
        *   **Default**: `12.5890`

#### **4. Response Payload**

The service returns a JSON object.

##### **4.1. Success Response**

**Status Code**: `200 OK`

**Body**:

```json
{
  "requestPosition": [55.7122, 12.5890],
  "forecastPosition": [55.71, 12.58],
  "oceanForecastPosition": [55.7324, 12.5926],
  "requestTime": 1750700771,
  "forecast": [
    [1750698000, 17.0, 2.5, 180.0, 15.2, 3.4, 240.1, [80.5, 65.0, 55.0, 45.0], "cloudy", 5.0, 45.5],
    [1750701600, 17.0, 2.3, 175.0, 14.8, 3.2, 235.0, [90.1], "cloudy", 4.5, 38.2]
  ],
  "error": null
}
```

**Fields**:

*   `requestPosition` (`array<float, float>`): `[lat, lon]` pair echoing the rounded request coordinates.
*   `forecastPosition` (`array<float, float> | null`): `[lat, lon]` used by the MET Location Forecast API, or `null` if unavailable.
*   `oceanForecastPosition` (`array<float, float> | null`): `[lat, lon]` used by the Ocean Forecast API grid, or `null`.
*   `requestTime` (`integer`): The Unix timestamp (in seconds) indicating when the proxy processed the request.
*   `forecast` (`array`): An array of forecast data points, containing a maximum of 24 hourly entries. Each entry is itself an array with fixed indexes. Values that are not applicable for a time step use `null`.
    *   `[0] time` (`integer`): Unix timestamp (seconds) for the forecast entry.
    *   `[1] seaTemperature` (`float | null`): Sea water temperature in °C.
    *   `[2] waveHeight` (`float | null`): Significant wave height in meters.
    *   `[3] waveDirection` (`float | null`): Wave direction in degrees.
    *   `[4] temperature` (`float | null`): Air temperature in °C.
    *   `[5] windSpeed` (`float | null`): Wind speed in meters per second (m/s).
    *   `[6] windDirection` (`float | null`): Wind direction in degrees.
    *   `[7] cloudCover` (`array<float> | null`): Cloud cover percentages ordered `[total, low, medium, high]`. If only the total is available the array contains one element.
    *   `[8] condition` (`string | null`): Simplified condition string. Possible values: `clear`, `fair`, `partly cloudy`, `cloudy`, `light rain`, `rain`, `thunder`, `snow`, `hail`, `fog`.
    *   `[9] uvIndex` (`float | null`): UV index value.
    *   `[10] precipitation` (`float | null`): Probability of precipitation over the next 12 hours as a percentage.
*   `error` (`object | string | null`): Will be `null` on a successful response.

##### **4.2. Error Response**

If the proxy encounters an internal error or receives an error from the upstream API, it will return a non-200 status code. The response body will maintain the same structure, but the `error` field will be populated.

**Body**:

```json
{
  "requestPosition": [55.7122, 12.5890],
  "forecastPosition": null,
  "oceanForecastPosition": null,
  "requestTime": 1750700771,
  "forecast": [],
  "error": "Details about the error go here."
}
```

**Fields**:

*   `requestPosition` (`array<float, float>`): Always populated `[lat, lon]` echo of the request coordinates.
*   `error` (`object | string`): Contains details about the error. This could be a simple string (e.g., if the upstream API is unreachable) or a JSON object if the upstream API provides a structured error.

#### **5. Data Transformation Logic**

1.  The proxy receives a request and parses the `lat` and `lon` query parameters, using default values if they are not provided. The coordinates are rounded to four decimal places.
2.  It constructs the request URL for the upstream MET API.
3.  It populates the `requestPosition` and `requestTime` fields for its own response.
4.  Upon receiving a successful response from the MET API, it parses the JSON.
    *   The `forecastPosition` is extracted from `geometry.coordinates` and serialized as `[lat, lon]` (the MET response is `[lon, lat]`).
*   The proxy fetches data from both the Ocean and Weather APIs and merges their `properties.timeseries` arrays based on the `time` field.
*   For each of the first 24 hourly entries, it creates a `forecast` array using the indexes described above.
    *   The `cloudCover` field is assembled from the Location Forecast's `cloud_area_fraction` values, yielding `[total, low, medium, high]` when the layered fractions are provided; otherwise it contains only the total value.
    *   The `precipitation` value is sourced from the Location Forecast `next_12_hours.details` block when available. When the upstream data omits a precipitation probability, the proxy inspects the 12-hour `symbol_code`: if it contains precipitation keywords (`rain`, `sleet`, `snow`, `shower`, `thunder`, `hail`) the probability is set to `100`; otherwise it is set to `0`.
    *   Time fields (RFC3339 strings) are converted to a Unix timestamp (seconds).
5.  If the MET API returns a non-successful status code or a non-JSON response, the proxy captures the error content and places it in the `error` field of its own response.

#### **6. Deployment**

The service is designed to be a self-contained, stateless application.

*   **Packaging**: Build a Go binary (`go build -o yrproxy`) and run it under a process manager (e.g. systemd).
*   **Configuration**: It listens for HTTP traffic on the port specified by the `PORT` environment variable, defaulting to `8080`.
