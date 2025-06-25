### **YR Ocean Forecast Proxy: API Specification**

#### **1. Overview**

This document specifies a proxy service that sits in front of the MET Norway Ocean Forecast API. The proxy's main purpose is to simplify the complex data structure provided by the MET API and reduce the overall payload size, making it more efficient for clients with limited resources, such as embedded devices.

#### **2. Upstream Service**

*   **API**: MET Norway Ocean Forecast API
*   **Endpoint**: `https://api.met.no/weatherapi/oceanforecast/2.0/complete`
*   **Authentication**: The proxy must include a descriptive `User-Agent` header in its requests to the upstream API.
    *   Example: `User-Agent: Helloface/1.0 (yourapp@example.com)`

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
    "lat": 55.7324,
    "lon": 12.5926
  },
  "requestTime": 1750700771,
  "forecast": [
    {
      "time": 1750698000,
      "temperature": 17.0
    }
  ],
  "error": null
}
```

**Fields**:

*   `requestPosition` (`object`): An object containing the latitude and longitude sent in the request.
    *   `lat` (`float`): The request latitude.
    *   `lon` (`float`): The request longitude.
*   `forecastPosition` (`object | null`): An object containing the actual latitude and longitude used by the MET API for the forecast. This may differ slightly from the requested position. It will be `null` if not provided by the upstream API.
    *   `lat` (`float`): The forecast latitude.
    *   `lon` (`float`): The forecast longitude.
*   `requestTime` (`integer`): The Unix timestamp (in seconds) indicating when the proxy processed the request.
*   `forecast` (`array`): An array of forecast data points, containing a maximum of 24 hourly entries.
    *   `time` (`integer`): The Unix timestamp (in seconds) for the forecast data point.
    *   `temperature` (`float`): The sea water temperature in degrees Celsius.
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
    *   The proxy iterates through the `properties.timeseries` array.
    *   For each of the first 24 entries, it creates a `forecast` object by:
        *   Converting the `time` field (an RFC3339 string) to a Unix timestamp (seconds).
        *   Extracting the `sea_water_temperature` from `data.instant.details`.
5.  If the MET API returns a non-successful status code or a non-JSON response, the proxy captures the error content and places it in the `error` field of its own response.

#### **6. Deployment**

The service is designed to be a self-contained, stateless application.

*   **Packaging**: It should be packaged as a Docker container.
*   **Configuration**: It listens for HTTP traffic on the port specified by the `PORT` environment variable, defaulting to `8080`. 