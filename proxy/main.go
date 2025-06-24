package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

// YrResponse matches the structure of the response from the MET Norway API.
type YrResponse struct {
	Geometry struct {
		Coordinates []float64 `json:"coordinates"` // [lon, lat]
	} `json:"geometry"`
	Properties struct {
		Meta struct {
			Error map[string]interface{} `json:"error"`
		} `json:"meta"`
		Timeseries []struct {
			Time string `json:"time"`
			Data struct {
				Instant struct {
					Details struct {
						SeaWaterTemperature float64 `json:"sea_water_temperature"`
					} `json:"details"`
				} `json:"instant"`
			} `json:"data"`
		} `json:"timeseries"`
	} `json:"properties"`
}

// Position represents a geographical position.
type Position struct {
	Lat float64 `json:"lat"`
	Lon float64 `json:"lon"`
}

// Forecast represents a single forecast entry.
type Forecast struct {
	Time        int64   `json:"time"`
	Temperature float64 `json:"temperature"`
}

// ApiResponse is the structure of the JSON response we will serve.
type ApiResponse struct {
	RequestPosition  Position    `json:"requestPosition"`
	ForecastPosition *Position   `json:"forecastPosition"`
	RequestTime      int64       `json:"requestTime"`
	Forecast         []Forecast  `json:"forecast"`
	Error            interface{} `json:"error,omitempty"`
}

func main() {
	http.HandleFunc("/", proxyHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func getPosition(r *http.Request) (Position, error) {
	latStr := r.URL.Query().Get("lat")
	if latStr == "" {
		latStr = "55.7121627"
	}
	lonStr := r.URL.Query().Get("lon")
	if lonStr == "" {
		lonStr = "12.5889604"
	}

	lat, err := strconv.ParseFloat(latStr, 64)
	if err != nil {
		return Position{}, fmt.Errorf("invalid latitude: %w", err)
	}
	lon, err := strconv.ParseFloat(lonStr, 64)
	if err != nil {
		return Position{}, fmt.Errorf("invalid longitude: %w", err)
	}

	return Position{Lat: lat, Lon: lon}, nil
}

func getWeatherData(pos Position) (*YrResponse, []byte, error) {
	apiURL := fmt.Sprintf("https://api.met.no/weatherapi/oceanforecast/2.0/complete?lat=%f&lon=%f", pos.Lat, pos.Lon)

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", "Helloface/1.0 (davidat@gmail.com)")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to fetch data from MET API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to read response body: %w", err)
	}

	var metData YrResponse
	if err := json.Unmarshal(body, &metData); err != nil {
		// Return the raw body on unmarshal error, as it may contain a plain string error from the API.
		return nil, body, fmt.Errorf("failed to unmarshal MET API response: %w", err)
	}

	return &metData, nil, nil
}

func buildApiResponse(yrData *YrResponse, requestPos Position, rawErrorBody []byte) ApiResponse {
	apiResponse := ApiResponse{
		RequestPosition: requestPos,
		RequestTime:     time.Now().Unix(),
	}

	if yrData == nil {
		apiResponse.Error = string(rawErrorBody)
		return apiResponse
	}

	if len(yrData.Geometry.Coordinates) == 2 {
		apiResponse.ForecastPosition = &Position{
			Lat: yrData.Geometry.Coordinates[1],
			Lon: yrData.Geometry.Coordinates[0],
		}
	}

	if yrData.Properties.Meta.Error != nil {
		apiResponse.Error = yrData.Properties.Meta.Error
	} else if len(yrData.Properties.Timeseries) > 0 {
		for _, entry := range yrData.Properties.Timeseries {
			if len(apiResponse.Forecast) >= 24 {
				break
			}
			t, err := time.Parse(time.RFC3339, entry.Time)
			if err != nil {
				log.Printf("Skipping forecast due to invalid time format: %v", err)
				continue
			}
			apiResponse.Forecast = append(apiResponse.Forecast, Forecast{
				Time:        t.Unix(),
				Temperature: entry.Data.Instant.Details.SeaWaterTemperature,
			})
		}
	} else {
		apiResponse.Error = "No timeseries data available"
	}

	return apiResponse
}

func proxyHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	pos, err := getPosition(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	yrData, rawBody, err := getWeatherData(pos)
	// A non-nil rawBody indicates a JSON unmarshaling error, which we handle gracefully.
	if err != nil && rawBody == nil {
		log.Printf("Error getting weather data: %v", err)
		http.Error(w, "Failed to fetch weather data", http.StatusInternalServerError)
		return
	}

	apiResponse := buildApiResponse(yrData, pos, rawBody)

	if err := json.NewEncoder(w).Encode(apiResponse); err != nil {
		// The response may have already been partially sent, so we can't send a new HTTP error.
		// We log the error and hope for the best.
		log.Printf("Failed to encode response: %v", err)
	}
}
