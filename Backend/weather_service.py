"""
Weather API Integration Service
Integrates with OpenWeatherMap API for real weather data
"""
import os
import requests
from typing import Dict, Any, Optional
from datetime import datetime

class WeatherService:
    """Service for fetching real-time weather data"""
    
    def __init__(self):
        # Get API key from environment variable
        self.api_key = os.getenv("OPENWEATHER_API_KEY", "")
        self.base_url = "https://api.openweathermap.org/data/2.5"
        
    def get_current_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        """
        Get current weather for coordinates
        
        Args:
            lat: Latitude
            lon: Longitude
            
        Returns:
            Weather data dictionary
        """
        if not self.api_key:
            return self._mock_weather_data()
        
        try:
            url = f"{self.base_url}/weather"
            params = {
                "lat": lat,
                "lon": lon,
                "appid": self.api_key,
                "units": "imperial"  # Fahrenheit
            }
            
            response = requests.get(url, params=params, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            return {
                "temperature": int(data["main"]["temp"]),
                "temperature_unit": "F",
                "condition": data["weather"][0]["main"],
                "description": data["weather"][0]["description"],
                "precipitation_chance": 0,  # Not available in current weather
                "humidity": data["main"]["humidity"],
                "wind_speed": int(data["wind"]["speed"]),
                "feels_like": int(data["main"]["feels_like"]),
                "updated_at": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            print(f"Weather API error: {e}")
            return self._mock_weather_data()
    
    def get_forecast(self, lat: float, lon: float, date: Optional[str] = None) -> Dict[str, Any]:
        """
        Get weather forecast for coordinates
        
        Args:
            lat: Latitude
            lon: Longitude
            date: Target date (YYYY-MM-DD)
            
        Returns:
            Forecast data dictionary
        """
        if not self.api_key:
            return self._mock_weather_data()
        
        try:
            url = f"{self.base_url}/forecast"
            params = {
                "lat": lat,
                "lon": lon,
                "appid": self.api_key,
                "units": "imperial"
            }
            
            response = requests.get(url, params=params, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            # Get first forecast item (closest to current time)
            if data["list"]:
                forecast = data["list"][0]
                return {
                    "temperature": int(forecast["main"]["temp"]),
                    "temperature_unit": "F",
                    "condition": forecast["weather"][0]["main"],
                    "description": forecast["weather"][0]["description"],
                    "precipitation_chance": int(forecast.get("pop", 0) * 100),
                    "humidity": forecast["main"]["humidity"],
                    "wind_speed": int(forecast["wind"]["speed"]),
                    "feels_like": int(forecast["main"]["feels_like"]),
                    "updated_at": datetime.utcnow().isoformat()
                }
            
            return self._mock_weather_data()
            
        except Exception as e:
            print(f"Forecast API error: {e}")
            return self._mock_weather_data()
    
    def _mock_weather_data(self) -> Dict[str, Any]:
        """Return mock weather data when API is unavailable"""
        return {
            "temperature": 72,
            "temperature_unit": "F",
            "condition": "Partly Cloudy",
            "description": "partly cloudy",
            "precipitation_chance": 20,
            "humidity": 65,
            "wind_speed": 8,
            "feels_like": 70,
            "updated_at": datetime.utcnow().isoformat()
        }


# Usage example:
# weather_service = WeatherService()
# weather = weather_service.get_current_weather(lat=40.8128, lon=-74.0742)
