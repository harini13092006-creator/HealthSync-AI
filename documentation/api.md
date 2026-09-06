# HealthSync AI — REST API Specification

**Interactive Documentation**:  
- Swagger UI: `http://127.0.0.1:8000/api/docs/`  
- OpenAPI Schema: `http://127.0.0.1:8000/api/schema/`  
- ReDoc: `http://127.0.0.1:8000/api/redoc/`

---

## 1. Authentication & Headers

Except for registration and login endpoints, all REST requests require a valid JWT Bearer token:
```http
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
```

---

## 2. API Endpoints Contract

### 2.1 Authentication (`accounts`)

#### `POST /api/auth/register/`
Registers a new user account and returns credentials with JWT tokens.
- **Request Body**:
  ```json
  {
    "username": "johndoe",
    "email": "john@example.com",
    "password": "SecurePassword@123",
    "first_name": "John",
    "last_name": "Doe"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "user": {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "name": "John Doe"
    },
    "tokens": {
      "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
  ```

#### `POST /api/auth/login/`
Authenticates user with email and password.
- **Request Body**:
  ```json
  {
    "email": "john@example.com",
    "password": "SecurePassword@123"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "user": {
      "id": 1,
      "email": "john@example.com",
      "name": "John Doe",
      "is_onboarded": true
    },
    "tokens": {
      "access": "eyJhbGciOiJIUzI1Ni...",
      "refresh": "eyJhbGciOiJIUzI1Ni..."
    }
  }
  ```

#### `POST /api/auth/token/refresh/`
Refreshes an expired access token using the refresh token.
- **Request Body**:
  ```json
  { "refresh": "eyJhbGciOiJIUzI1Ni..." }
  ```
- **Response (200 OK)**:
  ```json
  { "access": "eyJhbGciOiJIUzI1Ni..." }
  ```

---

### 2.2 Profile & Onboarding (`profiles`)

#### `GET /api/profile/`
Returns the user's complete physical and lifestyle baseline profile.
- **Response (200 OK)**:
  ```json
  {
    "id": 1,
    "age": 28,
    "gender": "MALE",
    "height_cm": 178.0,
    "weight_kg": 72.5,
    "bmi": 22.9,
    "activity_level": "MODERATELY_ACTIVE",
    "wake_up_time": "06:30:00",
    "sleep_time": "22:30:00",
    "work_start_time": "09:00:00",
    "work_end_time": "17:30:00",
    "is_onboarded": true
  }
  ```

#### `POST /api/profile/onboarding/`
Submits multi-step onboarding payload in a single atomic transaction.
- **Request Body**:
  ```json
  {
    "personal_info": {
      "age": 28,
      "gender": "MALE",
      "height_cm": 178.0,
      "weight_kg": 72.5
    },
    "lifestyle": {
      "activity_level": "MODERATELY_ACTIVE",
      "wake_up_time": "06:30:00",
      "sleep_time": "22:30:00",
      "work_start_time": "09:00:00",
      "work_end_time": "17:30:00"
    },
    "goals": ["ROUTINE", "HYDRATION", "BETTER_SLEEP"],
    "food_preferences": {
      "diet_type": "VEGETARIAN",
      "allergies": "None",
      "cuisine": "Indian"
    },
    "exercise_preferences": {
      "preferred_types": "Walking, Yoga, Mobility",
      "preferred_duration_minutes": 30,
      "fitness_level": "BEGINNER"
    },
    "availability": [
      { "label": "College Lectures", "start": "09:00:00", "end": "12:30:00" }
    ]
  }
  ```
- **Response (200 OK)**:
  ```json
  { "status": "success", "message": "Onboarding completed successfully." }
  ```

---

### 2.3 Tasks & Daily Routine (`tasks`)

#### `GET /api/tasks/today/`
Retrieves all scheduled routine items for the current day.
- **Response (200 OK)**:
  ```json
  [
    {
      "id": 101,
      "title": "Morning Sunlight Walk",
      "category": "EXERCISE",
      "priority": "HIGH",
      "scheduled_start": "07:00:00",
      "scheduled_end": "07:30:00",
      "duration_minutes": 30,
      "status": "COMPLETED",
      "is_mvt": false,
      "notes": "Optimal morning circadian alignment."
    },
    {
      "id": 102,
      "title": "Balanced Breakfast",
      "category": "MEAL",
      "priority": "HIGH",
      "scheduled_start": "08:00:00",
      "scheduled_end": "08:30:00",
      "duration_minutes": 30,
      "status": "PENDING",
      "is_mvt": false,
      "notes": "Oats with nuts and fruit."
    }
  ]
  ```

#### `POST /api/tasks/generate-routine/`
Executes the AI routine scheduling engine to construct a conflict-free day.
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "tasks_created": 5,
    "tasks": [ ... ]
  }
  ```

#### `PUT /api/tasks/{id}/complete/`
Marks a task as completed and records a positive behavioral training signal.
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "task": { "id": 101, "status": "COMPLETED" }
  }
  ```

#### `PUT /api/tasks/{id}/skip/`
Marks a task as skipped.
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "task": { "id": 101, "status": "SKIPPED" }
  }
  ```

#### `PUT /api/tasks/{id}/reschedule/`
Re-schedules a task to an alternate time slot.
- **Request Body**:
  ```json
  {
    "new_time": "18:00:00",
    "reason": "Unexpected meeting"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "task": { "id": 101, "scheduled_start": "18:00:00", "status": "RESCHEDULED" }
  }
  ```

---

### 2.4 Health Monitoring (`health_monitoring`)

#### `GET /api/health/`
Provides unified dashboard metrics for activity, sleep, hydration, and meditation.
- **Response (200 OK)**:
  ```json
  {
    "activity": { "steps": 6200, "active_minutes": 45, "exercise_minutes": 30 },
    "sleep": { "duration": 7.5, "quality_rating": 4 },
    "hydration": { "current_ml": 1750, "target_ml": 2500, "percentage": 0.70 },
    "meditation_minutes": 10
  }
  ```

#### `POST /api/health/water/`
Logs water intake.
- **Request Body**: `{ "quantity_ml": 250 }`
- **Response (200 OK)**: `{ "current_ml": 2000, "target_ml": 2500 }`

#### `POST /api/health/sleep/`
Logs sleep duration and subjective rating.
- **Request Body**: `{ "duration": 8.0, "quality_rating": 5 }`
- **Response (200 OK)**: `{ "status": "recorded", "duration": 8.0 }`

---

### 2.5 AI Recommendations & XAI (`recommendations`)

#### `GET /api/recommendations/food/?meal_type=LUNCH`
Generates ranked nutrition recommendations using cosine similarity against the user's macronutrient targets.
- **Response (200 OK)**:
  ```json
  {
    "meal_type": "LUNCH",
    "recommendations": [
      {
        "name": "Moong Dal Tadka with Brown Rice & Cucumber Salad",
        "calories": 420,
        "protein_g": 18,
        "carbs_g": 62,
        "fat_g": 9,
        "diet_type": "Vegetarian",
        "cuisine": "Indian",
        "similarity_score": 0.94,
        "explanation": "High protein content and complex carbs match your target for midday sustained focus."
      }
    ]
  }
  ```

#### `POST /api/recommendations/mvt/`
Generates a 10-minute Minimum Viable Task fallback.
- **Request Body**: `{ "minutes": 10, "activity": "Walking & Mobility" }`
- **Response (200 OK)**:
  ```json
  {
    "title": "10-Minute Mobility & Sunlight Break",
    "duration_minutes": 10,
    "description": "Brisk paced outdoor walk combined with joint rotations.",
    "is_mvt": true,
    "explanation": "Maintaining daily habit rhythm with lower friction is proven to protect long-term adherence."
  }
  ```

---

### 2.6 Analytics & Scoring (`analytics`)

#### `GET /api/analytics/wellness-score/`
Returns the synthesized Daily Wellness Score.
- **Response (200 OK)**:
  ```json
  {
    "date": "2026-09-06",
    "score": 84.5,
    "status": "OPTIMAL",
    "breakdown": {
      "routine_tasks": 0.80,
      "hydration": 0.70,
      "sleep": 0.90,
      "activity": 0.85,
      "mindfulness": 1.00
    },
    "disclaimer": "Non-medical wellness metric only."
  }
  ```

#### `GET /api/analytics/weekly/`
Returns 7-day adherence history for bar charts and trend lines.
- **Response (200 OK)**:
  ```json
  {
    "days": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    "adherence_rates": [75.0, 85.0, 60.0, 90.0, 80.0, 70.0, 88.0],
    "average_adherence": 78.3
  }
  ```
