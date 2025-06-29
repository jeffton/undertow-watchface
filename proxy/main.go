package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

// OceanYrResponse matches the structure of the response from the MET Norway OceanForecast API.
type OceanYrResponse struct {
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
						SeaWaterTemperature         float64 `json:"sea_water_temperature"`
						SeaSurfaceWaveHeight        float64 `json:"sea_surface_wave_height"`
						SeaSurfaceWaveFromDirection float64 `json:"sea_surface_wave_from_direction"`
					} `json:"details"`
				} `json:"instant"`
			} `json:"data"`
		} `json:"timeseries"`
	} `json:"properties"`
}

// WeatherYrResponse matches the structure of the LocationForecast API response.
type WeatherYrResponse struct {
	Geometry struct {
		Coordinates []float64 `json:"coordinates"`
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
						AirTemperature    float64 `json:"air_temperature"`
						CloudAreaFraction float64 `json:"cloud_area_fraction"`
						WindFromDirection float64 `json:"wind_from_direction"`
						WindSpeed         float64 `json:"wind_speed"`
					} `json:"details"`
				} `json:"instant"`
				Next1Hours struct {
					Summary struct {
						SymbolCode string `json:"symbol_code"`
					} `json:"summary"`
				} `json:"next_1_hours"`
			} `json:"data"`
		} `json:"timeseries"`
	} `json:"properties"`
}

// Position represents a geographical position.
type Position struct {
	Lat float64 `json:"lat"`
	Lon float64 `json:"lon"`
}

// Forecast represents a combined forecast entry.
type Forecast struct {
	Time           int64    `json:"time"`
	SeaTemperature *float64 `json:"seaTemperature,omitempty"`
	WaveHeight     *float64 `json:"waveHeight,omitempty"`
	WaveDirection  *float64 `json:"waveDirection,omitempty"`
	Temperature    *float64 `json:"temperature,omitempty"`
	WindSpeed      *float64 `json:"windSpeed,omitempty"`
	WindDirection  *float64 `json:"windDirection,omitempty"`
	CloudCover     *float64 `json:"cloudCover,omitempty"`
	Condition      *string  `json:"condition,omitempty"`
}

// ApiResponse is the structure of the JSON response we will serve.
type ApiResponse struct {
	RequestPosition       Position    `json:"requestPosition"`
	ForecastPosition      *Position   `json:"forecastPosition,omitempty"`
	OceanForecastPosition *Position   `json:"oceanForecastPosition,omitempty"`
	RequestTime           int64       `json:"requestTime"`
	Forecast              []Forecast  `json:"forecast,omitempty"`
	Error                 interface{} `json:"error,omitempty"`
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

func getOceanData(pos Position) (*OceanYrResponse, []byte, error) {
	apiURL := fmt.Sprintf("https://api.met.no/weatherapi/oceanforecast/2.0/complete?lat=%f&lon=%f", pos.Lat, pos.Lon)

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create request for ocean data: %w", err)
	}
	req.Header.Set("User-Agent", "Helloface/1.0 (davidat@gmail.com)")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to fetch ocean data from MET API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to read ocean response body: %w", err)
	}

	var metData OceanYrResponse
	if err := json.Unmarshal(body, &metData); err != nil {
		// Return the raw body on unmarshal error, as it may contain a plain string error from the API.
		return nil, body, fmt.Errorf("failed to unmarshal ocean MET API response: %w", err)
	}

	return &metData, nil, nil
}

func getWeatherForecastData(pos Position) (*WeatherYrResponse, []byte, error) {
	apiURL := fmt.Sprintf("https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=%f&lon=%f", pos.Lat, pos.Lon)
	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create request for weather data: %w", err)
	}
	req.Header.Set("User-Agent", "Helloface/1.0 (davidat@gmail.com)")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to fetch weather data from MET API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to read weather response body: %w", err)
	}

	var metData WeatherYrResponse
	if err := json.Unmarshal(body, &metData); err != nil {
		return nil, body, fmt.Errorf("failed to unmarshal weather MET API response: %w", err)
	}

	return &metData, nil, nil
}

func mapSymbolToCondition(symbolCode string) string {
	symbol := strings.Split(symbolCode, "_")[0]
	switch symbol {
	case "clearsky":
		return "clear"
	case "fair", "partlycloudy":
		return "partly cloudy"
	case "cloudy":
		return "cloudy"
	case "lightrain":
		return "light rain"
	case "rain", "heavyrain":
		return "rain"
	case "lightrainshowers", "rainshowers", "heavyrainshowers":
		if strings.Contains(symbolCode, "thunder") {
			return "thunder"
		}
		if symbol == "lightrainshowers" {
			return "light rain"
		}
		return "rain"
	case "lightsleet", "sleet", "heavysleet", "lightsnow", "snow", "heavysnow":
		return "snow"
	case "lightssleetandthunder", "sleetandthunder", "heavysleetandthunder", "lightssnowandthunder", "snowandthunder", "heavysnowandthunder":
		return "thunder"
	case "fog":
		return "fog"
	case "hail", "lighthail", "heavyhail":
		return "hail"
	default:
		return "unknown"
	}
}

func buildApiResponse(oceanData *OceanYrResponse, weatherData *WeatherYrResponse, requestPos Position, errors []string) ApiResponse {
	apiResponse := ApiResponse{
		RequestPosition: requestPos,
		RequestTime:     time.Now().Unix(),
	}

	if len(errors) > 0 {
		apiResponse.Error = strings.Join(errors, "; ")
	}

	// Use a map to merge forecasts by timestamp
	forecasts := make(map[int64]*Forecast)

	if oceanData != nil {
		if len(oceanData.Geometry.Coordinates) >= 2 {
			apiResponse.OceanForecastPosition = &Position{
				Lat: oceanData.Geometry.Coordinates[1],
				Lon: oceanData.Geometry.Coordinates[0],
			}
		}

		if oceanData.Properties.Meta.Error != nil {
			if apiResponse.Error != nil {
				apiResponse.Error = fmt.Sprintf("%v; ocean API error: %v", apiResponse.Error, oceanData.Properties.Meta.Error)
			} else {
				apiResponse.Error = oceanData.Properties.Meta.Error
			}
		} else if len(oceanData.Properties.Timeseries) > 0 {
			for _, entry := range oceanData.Properties.Timeseries {
				t, err := time.Parse(time.RFC3339, entry.Time)
				if err != nil {
					log.Printf("Skipping ocean forecast due to invalid time format: %v", err)
					continue
				}
				ts := t.Unix()
				if _, ok := forecasts[ts]; !ok {
					forecasts[ts] = &Forecast{Time: ts}
				}
				st := entry.Data.Instant.Details.SeaWaterTemperature
				forecasts[ts].SeaTemperature = &st
				wh := entry.Data.Instant.Details.SeaSurfaceWaveHeight
				forecasts[ts].WaveHeight = &wh
				wd := entry.Data.Instant.Details.SeaSurfaceWaveFromDirection
				forecasts[ts].WaveDirection = &wd
			}
		}
	}

	if weatherData != nil {
		if len(weatherData.Geometry.Coordinates) >= 2 {
			apiResponse.ForecastPosition = &Position{
				Lat: weatherData.Geometry.Coordinates[1],
				Lon: weatherData.Geometry.Coordinates[0],
			}
		}

		if weatherData.Properties.Meta.Error != nil {
			if apiResponse.Error != nil {
				apiResponse.Error = fmt.Sprintf("%v; weather API error: %v", apiResponse.Error, weatherData.Properties.Meta.Error)
			} else {
				apiResponse.Error = weatherData.Properties.Meta.Error
			}
		} else if len(weatherData.Properties.Timeseries) > 0 {
			for _, entry := range weatherData.Properties.Timeseries {
				t, err := time.Parse(time.RFC3339, entry.Time)
				if err != nil {
					log.Printf("Skipping weather forecast due to invalid time format: %v", err)
					continue
				}
				ts := t.Unix()
				if _, ok := forecasts[ts]; !ok {
					forecasts[ts] = &Forecast{Time: ts}
				}
				temp := entry.Data.Instant.Details.AirTemperature
				forecasts[ts].Temperature = &temp
				ws := entry.Data.Instant.Details.WindSpeed
				forecasts[ts].WindSpeed = &ws
				wd := entry.Data.Instant.Details.WindFromDirection
				forecasts[ts].WindDirection = &wd
				cc := entry.Data.Instant.Details.CloudAreaFraction
				forecasts[ts].CloudCover = &cc
				cond := mapSymbolToCondition(entry.Data.Next1Hours.Summary.SymbolCode)
				if cond != "unknown" {
					forecasts[ts].Condition = &cond
				}
			}
		}
	}

	// Convert map to slice
	var forecastSlice []Forecast
	for _, f := range forecasts {
		forecastSlice = append(forecastSlice, *f)
	}

	// Sort slice by time
	sort.Slice(forecastSlice, func(i, j int) bool {
		return forecastSlice[i].Time < forecastSlice[j].Time
	})

	if len(forecastSlice) > 24 {
		apiResponse.Forecast = forecastSlice[:24]
	} else {
		apiResponse.Forecast = forecastSlice
	}

	if apiResponse.Error == nil && len(apiResponse.Forecast) == 0 {
		apiResponse.Error = "No timeseries data available from any source"
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

	var wg sync.WaitGroup
	wg.Add(2)

	var oceanData *OceanYrResponse
	var weatherData *WeatherYrResponse
	var errors []string
	var mu sync.Mutex

	go func() {
		defer wg.Done()
		oData, rawBody, err := getOceanData(pos)
		if err != nil {
			mu.Lock()
			errMsg := fmt.Sprintf("Error getting ocean data: %v", err)
			if rawBody != nil {
				errMsg = fmt.Sprintf("%s, body: %s", errMsg, string(rawBody))
			}
			errors = append(errors, errMsg)
			mu.Unlock()
		}
		oceanData = oData
	}()

	go func() {
		defer wg.Done()
		wData, rawBody, err := getWeatherForecastData(pos)
		if err != nil {
			mu.Lock()
			errMsg := fmt.Sprintf("Error getting weather data: %v", err)
			if rawBody != nil {
				errMsg = fmt.Sprintf("%s, body: %s", errMsg, string(rawBody))
			}
			errors = append(errors, errMsg)
			mu.Unlock()
		}
		weatherData = wData
	}()

	wg.Wait()

	apiResponse := buildApiResponse(oceanData, weatherData, pos, errors)

	responseLog, err := json.Marshal(apiResponse)
	if err != nil {
		log.Printf("Failed to marshal response for logging: %v", err)
	} else {
		log.Println(string(responseLog))
	}

	if err := json.NewEncoder(w).Encode(apiResponse); err != nil {
		log.Printf("Failed to encode response: %v", err)
	}
}
