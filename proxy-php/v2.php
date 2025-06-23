<?php

header('Content-Type: application/json');

// Get latitude and longitude from request parameters
$lat = isset($_GET['lat']) ? $_GET['lat'] : '55.7121627';
$lon = isset($_GET['lon']) ? $_GET['lon'] : '12.5889604';

// Define the API URL with dynamic latitude and longitude
$url = "https://api.met.no/weatherapi/oceanforecast/2.0/complete?lat={$lat}&lon={$lon}";

// Fetch data from the API
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_USERAGENT, 'Helloface/1.0 (davidat@gmail.com)'); // Required by the API
$response = curl_exec($ch);
curl_close($ch);

// Decode the JSON response
$data = json_decode($response, true);

// Prepare the response format
$result = [
    "requestPosition" => ["lat" => (float)$lat, "lon" => (float)$lon],
    "forecastPosition" => isset($data['geometry']['coordinates']) ? [
        "lat" => $data['geometry']['coordinates'][1],
        "lon" => $data['geometry']['coordinates'][0]
    ] : null,
    "requestTime" => time(),
    "forecast" => []
];

if (isset($data['properties']['meta']['error'])) {
    $result['error'] = $data['properties']['meta']['error'];
}

// Extract the first 24 hours of sea water temperature forecasts
if (isset($data['properties']['timeseries'])) {
    $count = 0;
    foreach ($data['properties']['timeseries'] as $entry) {
        if (isset($entry['data']['instant']['details']['sea_water_temperature'])) {
            $result['forecast'][] = [
                "time" => strtotime($entry['time']),
                "temperature" => $entry['data']['instant']['details']['sea_water_temperature']
            ];
            $count++;
        }
        if ($count >= 24) break; // Limit to the first 24 hours
    }
} else {
    $result['error'] = $response;
}

echo json_encode($result);


?>

