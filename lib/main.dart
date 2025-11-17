import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.deepOrange,
          surface: Colors.black,
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          elevation: 4,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange.shade700),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      home: const WeatherDashboard(),
    );
  }
}

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  final TextEditingController _indexController = TextEditingController(text: '224042H');
  
  double? _latitude;
  double? _longitude;
  String? _requestUrl;
  String? _lastUpdated;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;
  
  // Weather data
  double? _temperature;
  double? _windSpeed;
  int? _weatherCode;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }

  // Load cached weather data
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('weather_data');
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        setState(() {
          _temperature = data['temperature'];
          _windSpeed = data['windSpeed'];
          _weatherCode = data['weatherCode'];
          _latitude = data['latitude'];
          _longitude = data['longitude'];
          _lastUpdated = data['lastUpdated'];
          _requestUrl = data['requestUrl'];
          _isCached = true;
        });
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Save weather data to cache
  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'temperature': _temperature,
        'windSpeed': _windSpeed,
        'weatherCode': _weatherCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'lastUpdated': _lastUpdated,
        'requestUrl': _requestUrl,
      });
      await prefs.setString('weather_data', data);
    } catch (e) {
      // Ignore cache save errors
    }
  }

  // Calculate coordinates from student index
  void _calculateCoordinates(String index) {
    // Remove any non-digit characters except the last letter
    final cleaned = index.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.length < 4) {
      setState(() {
        _errorMessage = 'Invalid index format. Please enter at least 4 digits.';
        _latitude = null;
        _longitude = null;
      });
      return;
    }

    try {
      final firstTwo = int.parse(cleaned.substring(0, 2));
      final nextTwo = int.parse(cleaned.substring(2, 4));
      
      setState(() {
        _latitude = 5.0 + (firstTwo / 10.0);
        _longitude = 79.0 + (nextTwo / 10.0);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing index: $e';
        _latitude = null;
        _longitude = null;
      });
    }
  }

  // Fetch weather data from API
  Future<void> _fetchWeather() async {
    final index = _indexController.text.trim();
    if (index.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your student index';
      });
      return;
    }

    _calculateCoordinates(index);
    
    if (_latitude == null || _longitude == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCached = false;
    });

    final url = 'https://api.open-meteo.com/v1/forecast?latitude=${_latitude!.toStringAsFixed(1)}&longitude=${_longitude!.toStringAsFixed(1)}&current_weather=true';
    
    setState(() {
      _requestUrl = url;
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data['current_weather'];
        
        setState(() {
          _temperature = currentWeather['temperature']?.toDouble();
          _windSpeed = currentWeather['windspeed']?.toDouble();
          _weatherCode = currentWeather['weathercode']?.toInt();
          _lastUpdated = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          _isLoading = false;
          _errorMessage = null;
        });

        // Save successful result to cache
        await _saveCachedData();
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch weather: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personalized Weather Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Index Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _indexController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., 224042H',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.school, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fetch Weather Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchWeather,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download),
              label: Text(_isLoading ? 'Fetching...' : 'Fetch Weather'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Coordinates Display
            if (_latitude != null && _longitude != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Computed Coordinates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Latitude: ${_latitude!.toStringAsFixed(2)}°',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Text(
                            'Longitude: ${_longitude!.toStringAsFixed(2)}°',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Weather Data Display
            if (_temperature != null && _windSpeed != null && _weatherCode != null)
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Weather',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          if (_isCached)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '(cached)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(color: Colors.orange),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.thermostat, size: 24, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Temperature: ${_temperature!.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.air, size: 24, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Wind Speed: ${_windSpeed!.toStringAsFixed(1)} km/h',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny, size: 24, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Weather Code: $_weatherCode',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                      if (_lastUpdated != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 20, color: Colors.orange.shade300),
                            const SizedBox(width: 8),
                            Text(
                              'Last Updated: $_lastUpdated',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Request URL Display
            if (_requestUrl != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request URL:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _requestUrl!,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.orange.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
