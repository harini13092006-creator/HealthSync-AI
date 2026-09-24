# HealthSync AI Deployment Guide

## 1. Local setup

### Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py check
python manage.py runserver 127.0.0.1:8000
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

For local API override:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Firebase Authentication

The Flutter app uses Firebase Authentication for email/password accounts and
session persistence. The provider configuration is stored in
`frontend/firebase.json` and can be deployed with:

```bash
cd frontend
firebase deploy --only auth --project healthsyncai-847d9
```

The Django API accepts Firebase ID tokens and links users to existing health
records by email. Deploy the backend changes to Render after updating the
repository. `FIREBASE_PROJECT_ID` defaults to `healthsyncai-847d9` and only needs
to be set in Render if using another Firebase project. Existing Django-only
users must create a Firebase account once with the same email; after the backend
is redeployed, their existing health records will be linked by email.

---

## 2. Production API URL

The production backend is:

https://healthsync-ai-2.onrender.com

Flutter production builds must use this base URL via `API_BASE_URL` or a runtime override.

---

## 3. Flutter production build command

```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://healthsync-ai-2.onrender.com
```

If deploying to Firebase Hosting, upload the generated `build/web` folder.

---

## 4. Render environment variables

Set these in the Render dashboard for the Django service:

```env
SECRET_KEY=your-production-secret-key
DEBUG=False
ALLOWED_HOSTS=healthsync-ai-2.onrender.com,localhost,127.0.0.1
DATABASE_URL=postgres://user:password@host:5432/dbname
CORS_ALLOWED_ORIGINS=https://healthsync-ai-2.onrender.com,https://healthsyncai-847d9.web.app,https://healthsyncai-847d9.firebaseapp.com
CSRF_TRUSTED_ORIGINS=https://healthsync-ai-2.onrender.com,https://healthsyncai-847d9.web.app,https://healthsyncai-847d9.firebaseapp.com
JWT_ACCESS_TOKEN_LIFETIME_MINUTES=60
JWT_REFRESH_TOKEN_LIFETIME_DAYS=7
```

For a local SQLite fallback, the project accepts:

```env
DB_ENGINE=sqlite
```

---

## 5. Django configuration

The project is configured for:

- Django settings in `backend/config/settings.py`
- JWT auth via `rest_framework_simplejwt`
- CORS via `django-cors-headers`
- CSRF trusted origins via `CSRF_TRUSTED_ORIGINS`
- database selection via `DATABASE_URL` first, then local SQLite/MySQL fallbacks

Render must provide a valid hosted database via `DATABASE_URL`.

---

## 6. Database setup

### Local SQLite fallback

No extra setup is required for local development when `DB_ENGINE=sqlite` is present.

### Production PostgreSQL on Render

Create a PostgreSQL database on Render, then set `DATABASE_URL` in the service environment variables.

---

## 7. Migration commands

```bash
cd backend
python manage.py migrate
python manage.py check
```

---

## 8. Deployment commands

Render web service:

```bash
gunicorn config.wsgi:application
```

If using a Python buildpack, ensure requirements are installed from `backend/requirements.txt` and the correct working directory is the backend project.

---

## 9. How to test the backend

Check the health route:

```bash
curl https://healthsync-ai-2.onrender.com/
```

Check auth routes:

```bash
curl -X POST https://healthsync-ai-2.onrender.com/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Password123!"}'
```

---

## 10. How to test Flutter Web

Run the app against production:

```bash
cd frontend
flutter run -d chrome --release --dart-define=API_BASE_URL=https://healthsync-ai-2.onrender.com
```

Then sign in, validate the dashboard, tasks, and profile APIs.

---

## 11. Common errors and solutions

### Mixed content / HTTPS issue

Cause: Flutter Web running over HTTPS calls an HTTP backend URL.

Fix: Use `https://healthsync-ai-2.onrender.com` and never downgrade to `http://` in production.

### 500 responses from login or protected endpoints

Cause: backend database or model initialization issue in production.

Fix: set `DATABASE_URL` correctly and ensure migrations are applied.

### CORS failures

Cause: frontend origin is not included in `CORS_ALLOWED_ORIGINS`.

Fix: add the production frontend origin, such as the Firebase Hosting or other frontend URL.

### Host header rejected

Cause: `ALLOWED_HOSTS` does not include the Render hostname.

Fix: add `healthsync-ai-2.onrender.com` to `ALLOWED_HOSTS`.

### Local development breakage

Cause: editing the project to hardcode production URLs everywhere.

Fix: keep `http://127.0.0.1:8000` for local dev and `https://healthsync-ai-2.onrender.com` for production via `API_BASE_URL`.
