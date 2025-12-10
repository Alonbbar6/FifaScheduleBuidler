"""
Traffic API Integration Service
Integrates with Google Maps Distance Matrix API for real-time traffic data
"""
import os
import requests
from typing import Dict, Any, List, Optional
from datetime import datetime

class TrafficService:
    """Service for fetching real-time traffic and travel time data"""
    
    def __init__(self):
        # Get API key from environment variable
        self.api_key = os.getenv("GOOGLE_MAPS_API_KEY", "")
        self.base_url = "https://maps.googleapis.com/maps/api/distancematrix/json"
        
    def get_travel_time(
        self,
        origin_lat: float,
        origin_lon: float,
        dest_lat: float,
        dest_lon: float,
        mode: str = "driving"
    ) -> Dict[str, Any]:
        """
        Get travel time and distance from origin to destination
        
        Args:
            origin_lat: Origin latitude
            origin_lon: Origin longitude
            dest_lat: Destination latitude
            dest_lon: Destination longitude
            mode: Travel mode (driving, walking, transit)
            
        Returns:
            Travel time data dictionary
        """
        if not self.api_key:
            return self._mock_traffic_data()
        
        try:
            params = {
                "origins": f"{origin_lat},{origin_lon}",
                "destinations": f"{dest_lat},{dest_lon}",
                "mode": mode,
                "departure_time": "now",
                "traffic_model": "best_guess",
                "key": self.api_key
            }
            
            response = requests.get(self.base_url, params=params, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            if data["status"] == "OK" and data["rows"]:
                element = data["rows"][0]["elements"][0]
                
                if element["status"] == "OK":
                    duration = element["duration"]["value"]  # seconds
                    duration_in_traffic = element.get("duration_in_traffic", {}).get("value", duration)
                    distance = element["distance"]["value"]  # meters
                    
                    # Calculate traffic level
                    traffic_ratio = duration_in_traffic / duration if duration > 0 else 1.0
                    if traffic_ratio < 1.1:
                        traffic_level = "light"
                    elif traffic_ratio < 1.3:
                        traffic_level = "moderate"
                    else:
                        traffic_level = "heavy"
                    
                    return {
                        "distance_meters": distance,
                        "distance_miles": round(distance * 0.000621371, 1),
                        "duration_seconds": duration,
                        "duration_minutes": round(duration / 60),
                        "duration_in_traffic_seconds": duration_in_traffic,
                        "duration_in_traffic_minutes": round(duration_in_traffic / 60),
                        "traffic_level": traffic_level,
                        "traffic_delay_minutes": round((duration_in_traffic - duration) / 60),
                        "mode": mode,
                        "updated_at": datetime.utcnow().isoformat()
                    }
            
            return self._mock_traffic_data()
            
        except Exception as e:
            print(f"Traffic API error: {e}")
            return self._mock_traffic_data()
    
    def get_stadium_traffic(
        self,
        stadium_lat: float,
        stadium_lon: float,
        origins: List[Dict[str, float]]
    ) -> List[Dict[str, Any]]:
        """
        Get traffic data from multiple origins to stadium
        
        Args:
            stadium_lat: Stadium latitude
            stadium_lon: Stadium longitude
            origins: List of origin coordinates [{"lat": ..., "lon": ...}, ...]
            
        Returns:
            List of travel time data for each origin
        """
        results = []
        
        for origin in origins:
            travel_data = self.get_travel_time(
                origin["lat"],
                origin["lon"],
                stadium_lat,
                stadium_lon
            )
            travel_data["origin"] = origin
            results.append(travel_data)
        
        return results
    
    def _mock_traffic_data(self) -> Dict[str, Any]:
        """Return mock traffic data when API is unavailable"""
        return {
            "distance_meters": 15000,
            "distance_miles": 9.3,
            "duration_seconds": 1200,
            "duration_minutes": 20,
            "duration_in_traffic_seconds": 1500,
            "duration_in_traffic_minutes": 25,
            "traffic_level": "moderate",
            "traffic_delay_minutes": 5,
            "mode": "driving",
            "updated_at": datetime.utcnow().isoformat()
        }


class CrowdForecastService:
    """Service for crowd density forecasting"""
    
    def __init__(self):
        # This would integrate with stadium WiFi/cellular data or historical patterns
        pass
    
    def get_crowd_forecast(
        self,
        stadium_id: str,
        match_id: Optional[int] = None,
        target_time: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Get crowd density forecast for stadium
        
        Args:
            stadium_id: Stadium identifier
            match_id: Match ID if applicable
            target_time: Target datetime for forecast
            
        Returns:
            Crowd forecast data
        """
        # Mock implementation - in production, integrate with:
        # - Google Places API (Popular Times)
        # - Stadium WiFi/cellular data
        # - Historical attendance patterns
        # - Ticket sales data
        
        if target_time is None:
            target_time = datetime.utcnow()
        
        # Simple time-based mock logic
        hour = target_time.hour
        
        if 8 <= hour < 12:
            crowd_level = "light"
            crowd_percentage = 25
        elif 12 <= hour < 16:
            crowd_level = "moderate"
            crowd_percentage = 55
        elif 16 <= hour < 20:
            crowd_level = "heavy"
            crowd_percentage = 85
        else:
            crowd_level = "light"
            crowd_percentage = 15
        
        return {
            "stadium_id": stadium_id,
            "match_id": match_id,
            "crowd_level": crowd_level,
            "crowd_percentage": crowd_percentage,
            "peak_times": [
                "2 hours before kickoff",
                "30 minutes before kickoff"
            ],
            "recommended_arrival": "3 hours before kickoff",
            "parking_availability": "limited" if crowd_percentage > 60 else "available",
            "estimated_wait_times": {
                "security": f"{crowd_percentage // 10} minutes",
                "concessions": f"{crowd_percentage // 8} minutes",
                "restrooms": f"{crowd_percentage // 15} minutes"
            },
            "updated_at": datetime.utcnow().isoformat()
        }


# Usage examples:
# traffic_service = TrafficService()
# travel_time = traffic_service.get_travel_time(40.7128, -74.0060, 40.8128, -74.0742)
#
# crowd_service = CrowdForecastService()
# crowd_data = crowd_service.get_crowd_forecast("metlife-stadium", match_id=104)
