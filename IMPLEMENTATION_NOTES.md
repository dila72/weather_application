# Personalized Weather Dashboard - Implementation Notes

## Project Overview
A Flutter application that derives geographic coordinates from a student index number and fetches real-time weather data using the Open-Meteo API.

## Features Implemented

### ✅ Core Requirements
1. **Student Index Input**
   - Text field pre-filled with "224042H"
   - Accepts any format (e.g., 194174B, 224042H)

2. **Coordinate Derivation**
   - Extracts first two digits → latitude calculation: `5 + (firstTwo / 10.0)`
   - Extracts next two digits → longitude calculation: `79 + (nextTwo / 10.0)`
   - Displays computed coordinates with 2 decimal precision

3. **Weather API Integration**
   - Uses Open-Meteo API (no API key required)
   - URL format: `https://api.open-meteo.com/v1/forecast?latitude=LAT&longitude=LON&current_weather=true`
   - Displays:
     - Temperature (°C)
     - Wind Speed (km/h)
     - Weather Code (raw number)

4. **User Interface**
   - "Fetch Weather" button with loading indicator
   - Displays exact request URL at bottom for verification
   - Shows last updated timestamp (device clock)
   - Error handling with user-friendly messages

5. **Caching Implementation**
   - Uses `shared_preferences` package
   - Saves last successful weather result
   - Shows "(cached)" tag when displaying offline data
   - Persists across app restarts

## Dependencies Added
```yaml
http: ^1.1.0              # For API calls
shared_preferences: ^2.2.2 # For local caching
intl: ^0.19.0             # For date formatting
```

## Example Calculation
For student index **224042H**:
- First two digits: 22
- Next two digits: 40
- **Latitude**: 5 + (22 / 10.0) = **7.20°**
- **Longitude**: 79 + (40 / 10.0) = **83.00°**

## API Response Example
```json
{
  "current_weather": {
    "temperature": 28.5,
    "windspeed": 12.3,
    "weathercode": 3
  }
}
```

## Error Handling
- Network timeout (10 seconds)
- Invalid index format validation
- HTTP error status codes
- API unavailability
- Graceful fallback to cached data

## Testing
The application has been tested on:
- ✅ Chrome (Web)
- ✅ Windows (requires Developer Mode enabled)
- Available for: Android, iOS, Linux, macOS

## File Structure
```
lib/
└── main.dart          # Complete application code
pubspec.yaml           # Dependencies configuration
```

## How to Run
```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on connected Android device
flutter run -d <device-id>
```

## Weather Code Reference (WMO)
- 0: Clear sky
- 1-3: Partly cloudy
- 45, 48: Fog
- 51-67: Rain
- 71-77: Snow
- 80-99: Thunderstorms

## Future Enhancements (Optional)
- Decode weather codes to descriptive text
- Add weather icons
- Support multiple student indices
- Historical weather data
- Refresh button for manual updates
