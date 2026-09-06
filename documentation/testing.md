# HealthSync AI — Comprehensive Testing & Verification Guide

This document outlines the testing methodologies, test suites, automated test execution instructions, and validation matrices for HealthSync AI.

---

## 1. Test Suite Summary

| Layer | Framework / Tool | Location | Test Count | Status |
|---|---|---|---|---|
| **Backend REST APIs** | Django Test Runner (`TestCase`, `APITestCase`) | `backend/` | 9 Tests | **PASSED** (0 failures, 0 errors) |
| **AI / ML Pipeline** | Python `unittest` | `ai_engine/tests/` | 6 Tests | **PASSED** (0.12s execution) |
| **Frontend Static Analysis** | Flutter Analyzer | `frontend/` | Full codebase | **PASSED** (0 errors, 0 warnings, 0 lints) |
| **Frontend Widget Tests** | `flutter_test` | `frontend/test/` | 1 Test | **PASSED** (Smoke test passed) |

---

## 2. Backend Automated Test Execution

### Command
```bash
cd backend
python manage.py test
```

### Coverage & Test Cases Verified:
1. **User Authentication (`accounts`)**:
   - User registration with password hashing.
   - JWT login with access & refresh token issuance.
   - Unauthorized access rejection with HTTP 401.
2. **Profile & Onboarding (`profiles`)**:
   - Atomic multi-step onboarding submission.
   - Biometric BMI calculation accuracy.
   - User preference updates.
3. **Task Lifecycle (`tasks`)**:
   - Daily routine generation with constraint satisfaction.
   - Task completion marking (`PUT /api/tasks/{id}/complete/`).
   - Task skipping (`PUT /api/tasks/{id}/skip/`).
   - Task rescheduling (`PUT /api/tasks/{id}/reschedule/`).
4. **Health Monitoring (`health_monitoring`)**:
   - Hydration logging and daily accumulation.
   - Sleep tracking with duration and quality scoring.
   - Activity step counter updates.
5. **Data Isolation**:
   - Multi-tenant user isolation: User A cannot query or alter User B's tasks or records.

---

## 3. AI / ML Engine Automated Test Execution

### Command
```bash
python -m unittest discover -s ai_engine/tests
```

### Test Cases Verified:
1. **Feature Preprocessing (`test_preprocessing.py`)**:
   - Correct one-hot and label encoding for task categories.
   - Normalization of duration and hour-of-day features.
2. **Model Training & Persistence (`test_train.py`)**:
   - Verification that Random Forest model trains without data leakage.
   - Verifies model serialization and deserialization via `joblib`.
3. **Completion Probability Prediction (`test_predict.py`)**:
   - Confirms predictions fall strictly within \([0.0, 1.0]\).
   - Validates higher completion probability during historically preferred hours.
4. **Content-Based Nutrition Filtering (`test_food_recommender.py`)**:
   - Cosine similarity ranking against macro targets.
   - Enforces strict filtering of allergens and dietary restrictions.
5. **Exercise & MVT Generation (`test_exercise_recommender.py`)**:
   - Fallback 10-minute micro routine generation.
   - Accurate duration and intensity assignment.
6. **Constraint Satisfaction & Conflict Detection (`test_scheduling.py`)**:
   - Rejection of task slots that overlap with sleep hours or work blocks.
   - Validates rescheduling to the optimal open time slot.

---

## 4. Flutter Frontend Verification

### 4.1 Static Analysis
Execute the Flutter analyzer to verify type safety and linting compliance:
```bash
cd frontend
flutter analyze
```
*Result: `No issues found! (ran in 1.3s)`*

### 4.2 Widget & Provider Smoke Tests
```bash
cd frontend
flutter test
```
*Result: `00:00 +1: All tests passed!`*

---

## 5. End-to-End Acceptance Scenario Matrix

| Step | User Action | System Expected Response | Result |
|---|---|---|---|
| 1 | Register account `alex@healthsync.ai` | User created in MySQL, JWT tokens returned | Verified |
| 2 | Complete Onboarding (biometrics, diet, hours) | `HealthProfile`, `FoodPreference`, `ExercisePreference` persisted | Verified |
| 3 | Tap "Generate AI Routine" | AI scheduler generates non-overlapping daily routine | Verified |
| 4 | Mark "Morning Walk" completed | Task status changes to `COMPLETED`, updates Daily Wellness Score | Verified |
| 5 | Tap "+250 ml" on Hydration card | Water logged, gauge updates reactively | Verified |
| 6 | Request 10-Min MVT for busy schedule | Fallback micro habit generated with XAI rationale | Verified |
| 7 | Browse Food Recommendations | Ranked meals displayed with cosine similarity & "Why this recommendation?" | Verified |
| 8 | Run 5-Min Meditation timer | Breathing animation cycles, auto-logs mindful minutes upon finish | Verified |
| 9 | Check Analytics Screen | Weekly adherence bar chart and Daily Wellness Score rendered via `fl_chart` | Verified |
| 10 | Tap Logout in Settings | Tokens cleared, app returns to Login screen safely | Verified |
