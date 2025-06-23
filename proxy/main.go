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

// MetNoResponse matches the structure of the response from the MET Norway API.
type MetNoResponse struct {
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

func proxyHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

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
		http.Error(w, "Invalid latitude", http.StatusBadRequest)
		return
	}
	lon, err := strconv.ParseFloat(lonStr, 64)
	if err != nil {
		http.Error(w, "Invalid longitude", http.StatusBadRequest)
		return
	}

	apiURL := fmt.Sprintf("https://api.met.no/weatherapi/oceanforecast/2.0/complete?lat=%f&lon=%f", lat, lon)

	client := &http.Client{}
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	req.Header.Set("User-Agent", "Helloface/1.0 (davidat@gmail.com)")

	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Failed to fetch data from MET API", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Failed to read response body", http.StatusInternalServerError)
		return
	}

	var metData MetNoResponse
	if err := json.Unmarshal(body, &metData); err != nil {
		// If unmarshaling fails, it might be because the API returned an error as a plain string
		// as seen in the PHP script.
		response := ApiResponse{
			Error: string(body),
		}
		json.NewEncoder(w).Encode(response)
		return
	}

	apiResponse := ApiResponse{
		RequestPosition: Position{Lat: lat, Lon: lon},
		RequestTime:     time.Now().Unix(),
	}

	if len(metData.Geometry.Coordinates) == 2 {
		apiResponse.ForecastPosition = &Position{
			Lat: metData.Geometry.Coordinates[1],
			Lon: metData.Geometry.Coordinates[0],
		}
	}

	if metData.Properties.Meta.Error != nil {
		apiResponse.Error = metData.Properties.Meta.Error
	} else if len(metData.Properties.Timeseries) > 0 {
		for _, entry := range metData.Properties.Timeseries {
			if len(apiResponse.Forecast) >= 24 {
				break
			}
			t, err := time.Parse(time.RFC3339, entry.Time)
			if err != nil {
				continue // Skip if time format is invalid
			}
			apiResponse.Forecast = append(apiResponse.Forecast, Forecast{
				Time:        t.Unix(),
				Temperature: entry.Data.Instant.Details.SeaWaterTemperature,
			})
		}
	} else {
		apiResponse.Error = "No timeseries data available"
	}

	if err := json.NewEncoder(w).Encode(apiResponse); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}
