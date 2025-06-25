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
    *   `lat` (float, optional): The latitude for the forecast.
        *   **Default**: `55.7121627`
    *   `lon` (float, optional): The longitude for the forecast.
        *   **Default**: `12.5889604`

#### **4. Response Payload**

The service returns a JSON object.

##### **4.1. Success Response**

**Status Code**: `200 OK`

**Body**:

```json
{
  "requestPosition": {
    "lat": 55.7121627,
    "lon": 12.5889604
  },
  "forecastPosition": {
    "lat": 55.71,
    "lon": 12.58
  },
  "oceanForecastPosition": {
    "lat": 55.7324,
    "lon": 12.5926
  },
  "requestTime": 1750700771,
  "forecast": [
    {
      "time": 1750698000,
      "seaTemperature": 17.0,
      "waveHeight": 2.5,
      "temperature": 15.2,
      "windSpeed": 3.4,
      "windDirection": 240.1,
      "cloudCover": 80.5,
      "condition": "cloudy"
    },
    {
      "time": 1750701600,
      "seaTemperature": 17.0,
      "waveHeight": 2.3,
      "temperature": 14.8,
      "windSpeed": 3.2,
      "windDirection": 235.0,
      "cloudCover": 90.1,
      "condition": "cloudy"
    }
  ],
  "error": null
}
```

**Fields**:

*   `requestPosition` (`object`): An object containing the latitude and longitude sent in the request.
    *   `lat` (`float`): The request latitude.
    *   `lon` (`float`): The request longitude.
*   `forecastPosition` (`object | null`): The latitude and longitude used by the MET API for the weather forecast.
    *   `lat` (`float`): The forecast latitude.
    *   `lon` (`float`): The forecast longitude.
*   `oceanForecastPosition` (`object | null`): The latitude and longitude used by the MET API for the ocean forecast. This may differ from the `forecastPosition` as the API snaps to the nearest ocean grid point.
    *   `lat` (`float`): The ocean forecast latitude.
    *   `lon` (`float`): The ocean forecast longitude.
*   `requestTime` (`integer`): The Unix timestamp (in seconds) indicating when the proxy processed the request.
*   `forecast` (`array`): An array of forecast data points, containing a maximum of 24 hourly entries. Fields that are not applicable for a given time step (e.g., `seaTemperature`) will be omitted from the entry.
    *   `time` (`integer`): The Unix timestamp (in seconds) for the forecast data point.
    *   `seaTemperature` (`float`, optional): The sea water temperature in degrees Celsius.
    *   `waveHeight` (`float`, optional): The significant wave height in meters.
    *   `temperature` (`float`, optional): The air temperature in degrees Celsius.
    *   `windSpeed` (`float`, optional): The wind speed in meters per second (m/s).
    *   `windDirection` (`float`, optional): The wind direction in degrees.
    *   `cloudCover` (`float`, optional): The cloud cover as a percentage.
    *   `condition` (`string`, optional): A simplified weather condition string. Possible values are: `clear`, `partly cloudy`, `cloudy`, `light rain`, `rain`, `thunder`, `snow`, `hail`, `fog`.
*   `error` (`object | string | null`): Will be `null` on a successful response.

##### **4.2. Error Response**

If the proxy encounters an internal error or receives an error from the upstream API, it will return a non-200 status code. The response body will maintain the same structure, but the `error` field will be populated.

**Body**:

```json
{
  "requestPosition": {
    "lat": 55.7121627,
    "lon": 12.5889604
  },
  "forecastPosition": null,
  "oceanForecastPosition": null,
  "requestTime": 1750700771,
  "forecast": [],
  "error": "Details about the error go here."
}
```

**Fields**:

*   `requestPosition` (`object`): Will always be populated with the user-supplied latitude and longitude, as long as they are valid numbers.
*   `error` (`object | string`): Contains details about the error. This could be a simple string (e.g., if the upstream API is unreachable) or a JSON object if the upstream API provides a structured error.

#### **5. Data Transformation Logic**

1.  The proxy receives a request and parses the `lat` and `lon` query parameters, using default values if they are not provided.
2.  It constructs the request URL for the upstream MET API.
3.  It populates the `requestPosition` and `requestTime` fields for its own response.
4.  Upon receiving a successful response from the MET API, it parses the JSON.
    *   The `forecastPosition` is extracted from `geometry.coordinates`. Note that the order in the MET API response is `[longitude, latitude]`.
    *   The proxy fetches data from both the Ocean and Weather APIs and merges their `properties.timeseries` arrays based on the `time` field.
    *   For each of the first 24 hourly entries, it creates a `forecast` object containing the combined data.
    *   Time fields (RFC3339 strings) are converted to a Unix timestamp (seconds).
5.  If the MET API returns a non-successful status code or a non-JSON response, the proxy captures the error content and places it in the `error` field of its own response.

#### **6. Deployment**

The service is designed to be a self-contained, stateless application.

*   **Packaging**: It should be packaged as a Docker container.
*   **Configuration**: It listens for HTTP traffic on the port specified by the `PORT` environment variable, defaulting to `8080`. 