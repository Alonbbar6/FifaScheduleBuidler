#!/usr/bin/env python3
"""
FIFA 2026 Schedule Builder - Local Backend Server
FastAPI REST API for iOS Swift app
"""
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import json
import sqlite3
import jwt
import hashlib
import os
from pathlib import Path

# Configuration
SECRET_KEY = "fifa-2026-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

# Initialize FastAPI
app = FastAPI(
    title="FIFA 2026 Schedule Builder API",
    description="Local backend for FIFA World Cup 2026 iOS app",
    version="1.0.0"
)

# Enable CORS for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your iOS app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
DB_PATH = Path(__file__).parent / "fifa_2026.db"

def init_database():
    """Initialize SQLite database with tables"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Users table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            full_name TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Schedules table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS schedules (
            schedule_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            schedule_name TEXT NOT NULL,
            match_ids TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
    """)
    
    # Push notification tokens
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS push_tokens (
            user_id TEXT PRIMARY KEY,
            device_token TEXT NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
    """)
    
    conn.commit()
    conn.close()

# Initialize DB on startup
init_database()

# Pydantic Models
class UserRegister(BaseModel):
    email: str
    password: str
    full_name: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: str

class Schedule(BaseModel):
    schedule_id: Optional[str] = None
    schedule_name: str
    match_ids: List[int]

class PushToken(BaseModel):
    device_token: str

# Helper functions
def hash_password(password: str) -> str:
    """Hash password using SHA256"""
    return hashlib.sha256(password.encode()).hexdigest()

def create_access_token(user_id: str) -> str:
    """Create JWT access token"""
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": user_id, "exp": expire}
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> str:
    """Verify JWT token and return user_id"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_db():
    """Get database connection"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

# Load stadium and match data
STADIUM_DATA_DIR = Path(__file__).parent.parent / "stadium_data"
MATCH_DATA_FILE = Path(__file__).parent.parent / "match_data" / "fifa_2026_matches.json"

def load_stadiums() -> Dict[str, Any]:
    """Load all stadium JSON files"""
    stadiums = {}
    for file in STADIUM_DATA_DIR.glob("*.json"):
        with open(file, 'r') as f:
            data = json.load(f)
            stadiums[data["stadium_id"]] = data
    return stadiums

def load_matches() -> Dict[str, Any]:
    """Load match schedule data"""
    with open(MATCH_DATA_FILE, 'r') as f:
        return json.load(f)

# API Endpoints

@app.get("/")
def root():
    """API root endpoint"""
    return {
        "message": "FIFA 2026 Schedule Builder API",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

# Authentication Endpoints

@app.post("/api/auth/register", response_model=Token)
def register(user: UserRegister, conn=Depends(get_db)):
    """Register new user"""
    cursor = conn.cursor()
    
    # Check if email exists
    cursor.execute("SELECT user_id FROM users WHERE email = ?", (user.email,))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create user
    user_id = hashlib.md5(user.email.encode()).hexdigest()
    password_hash = hash_password(user.password)
    
    cursor.execute(
        "INSERT INTO users (user_id, email, password_hash, full_name) VALUES (?, ?, ?, ?)",
        (user_id, user.email, password_hash, user.full_name)
    )
    conn.commit()
    
    # Create token
    access_token = create_access_token(user_id)
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user_id
    }

@app.post("/api/auth/login", response_model=Token)
def login(user: UserLogin, conn=Depends(get_db)):
    """Login user"""
    cursor = conn.cursor()
    password_hash = hash_password(user.password)
    
    cursor.execute(
        "SELECT user_id FROM users WHERE email = ? AND password_hash = ?",
        (user.email, password_hash)
    )
    result = cursor.fetchone()
    
    if not result:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    user_id = result["user_id"]
    access_token = create_access_token(user_id)
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user_id
    }

# Match Endpoints

@app.get("/api/matches")
def get_matches():
    """Get all FIFA 2026 matches"""
    return load_matches()

@app.get("/api/matches/{match_id}")
def get_match(match_id: int):
    """Get specific match by ID"""
    matches_data = load_matches()
    match = next((m for m in matches_data["matches"] if m["match_id"] == match_id), None)
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    return match

@app.get("/api/matches/stadium/{stadium_id}")
def get_matches_by_stadium(stadium_id: str):
    """Get all matches for a specific stadium"""
    matches_data = load_matches()
    stadium_matches = [m for m in matches_data["matches"] if m.get("stadium_id") == stadium_id]
    return {"stadium_id": stadium_id, "matches": stadium_matches}

# Stadium Endpoints

@app.get("/api/stadiums")
def get_stadiums():
    """Get all stadium data"""
    return load_stadiums()

@app.get("/api/stadiums/{stadium_id}")
def get_stadium(stadium_id: str):
    """Get specific stadium by ID"""
    stadiums = load_stadiums()
    if stadium_id not in stadiums:
        raise HTTPException(status_code=404, detail="Stadium not found")
    return stadiums[stadium_id]

# Schedule Endpoints (requires authentication)

@app.post("/api/schedules")
def create_schedule(
    schedule: Schedule,
    token: str,
    conn=Depends(get_db)
):
    """Create new schedule (requires auth token in header)"""
    user_id = verify_token(token)
    cursor = conn.cursor()
    
    schedule_id = hashlib.md5(f"{user_id}{datetime.utcnow()}".encode()).hexdigest()
    match_ids_json = json.dumps(schedule.match_ids)
    
    cursor.execute(
        "INSERT INTO schedules (schedule_id, user_id, schedule_name, match_ids) VALUES (?, ?, ?, ?)",
        (schedule_id, user_id, schedule.schedule_name, match_ids_json)
    )
    conn.commit()
    
    return {
        "schedule_id": schedule_id,
        "schedule_name": schedule.schedule_name,
        "match_ids": schedule.match_ids
    }

@app.get("/api/schedules/{user_id}")
def get_user_schedules(user_id: str, token: str, conn=Depends(get_db)):
    """Get all schedules for a user (requires auth)"""
    verify_token(token)
    cursor = conn.cursor()
    
    cursor.execute(
        "SELECT schedule_id, schedule_name, match_ids, created_at, updated_at FROM schedules WHERE user_id = ?",
        (user_id,)
    )
    
    schedules = []
    for row in cursor.fetchall():
        schedules.append({
            "schedule_id": row["schedule_id"],
            "schedule_name": row["schedule_name"],
            "match_ids": json.loads(row["match_ids"]),
            "created_at": row["created_at"],
            "updated_at": row["updated_at"]
        })
    
    return {"user_id": user_id, "schedules": schedules}

@app.delete("/api/schedules/{schedule_id}")
def delete_schedule(schedule_id: str, token: str, conn=Depends(get_db)):
    """Delete a schedule (requires auth)"""
    user_id = verify_token(token)
    cursor = conn.cursor()
    
    cursor.execute(
        "DELETE FROM schedules WHERE schedule_id = ? AND user_id = ?",
        (schedule_id, user_id)
    )
    conn.commit()
    
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Schedule not found")
    
    return {"message": "Schedule deleted successfully"}

# Push Notification Endpoints

@app.post("/api/notifications/register")
def register_push_token(
    push_token: PushToken,
    token: str,
    conn=Depends(get_db)
):
    """Register device token for push notifications"""
    user_id = verify_token(token)
    cursor = conn.cursor()
    
    cursor.execute(
        "INSERT OR REPLACE INTO push_tokens (user_id, device_token, updated_at) VALUES (?, ?, ?)",
        (user_id, push_token.device_token, datetime.utcnow())
    )
    conn.commit()
    
    return {"message": "Push token registered successfully"}

# Crowd Intelligence Endpoint (mock data for now)

@app.get("/api/crowds/{stadium_id}")
def get_crowd_data(stadium_id: str, match_id: Optional[int] = None):
    """Get crowd density forecast for stadium"""
    # Mock crowd data - integrate with real APIs later
    return {
        "stadium_id": stadium_id,
        "match_id": match_id,
        "crowd_level": "moderate",
        "crowd_percentage": 65,
        "peak_times": ["2 hours before kickoff", "30 minutes before kickoff"],
        "recommended_arrival": "3 hours before kickoff",
        "parking_availability": "limited",
        "updated_at": datetime.utcnow().isoformat()
    }

# Weather Endpoint (mock data - integrate OpenWeatherMap later)

@app.get("/api/weather/{stadium_id}")
def get_weather(stadium_id: str, date: Optional[str] = None):
    """Get weather forecast for stadium"""
    stadiums = load_stadiums()
    if stadium_id not in stadiums:
        raise HTTPException(status_code=404, detail="Stadium not found")
    
    stadium = stadiums[stadium_id]
    
    # Mock weather data
    return {
        "stadium_id": stadium_id,
        "location": stadium["location"]["city"],
        "date": date or datetime.utcnow().strftime("%Y-%m-%d"),
        "temperature": 75,
        "temperature_unit": "F",
        "condition": "Partly Cloudy",
        "precipitation_chance": 20,
        "humidity": 65,
        "wind_speed": 8,
        "updated_at": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting FIFA 2026 Schedule Builder API...")
    print("📍 Server running at: http://localhost:8000")
    print("📚 API docs at: http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
