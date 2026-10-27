# Grocery Scanner API (FastAPI)

A FastAPI backend for scanning grocery items, analyzing ingredients, preservatives, diabetic-friendly scores, and managing user plans.

---

## Local Development

1. **Create and activate a virtual environment**:
   - **Windows (PowerShell)**:
     ```powershell
     python -m venv venv
     .\venv\Scripts\Activate.ps1
     ```
   - **Linux / macOS**:
     ```bash
     python -m venv venv
     source venv/bin/activate
     ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the server**:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

4. **API Documentation**:
   - Swagger UI: `http://localhost:8000/docs`
   - ReDoc: `http://localhost:8000/redoc`
   - Health check: `http://localhost:8000/health`

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `SECRET_KEY` | Secret key for JWT auth token generation | `"change-me-in-production"` |
| `DATABASE_URL` | PostgreSQL or SQLite database URL | `"sqlite:///./scanner.db"` |
| `GATEWAY_KEY_ID` | Payment gateway API key | `"rzp_test_xxx"` |
| `GATEWAY_KEY_SECRET` | Payment gateway secret key | `"secret"` |
| `PREMIUM_PRICE_PAISE` | Cost of premium plan in paise | `9900` (₹99) |

---

## Deploying to Render

### Option A: Automatic Blueprint Deploy (Recommended)
1. Push this repository to GitHub or GitLab.
2. In the [Render Dashboard](https://dashboard.render.com), click **New +** > **Blueprint**.
3. Select your repository. Render will automatically detect `render.yaml` and configure:
   - **Runtime**: Python
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path**: `/health`
   - Auto-generate a secure `SECRET_KEY`.
4. Click **Apply**.

### Option B: Manual Web Service Deploy
1. Push this repository to GitHub or GitLab.
2. In [Render Dashboard](https://dashboard.render.com), click **New +** > **Web Service**.
3. Connect your repository.
4. Set the following settings:
   - **Name**: `grocery-scanner-api` (or your preferred name)
   - **Region**: Choose the closest region (e.g. Singapore, Frankfurt, Oregon)
   - **Branch**: `main`
   - **Root Directory**: Leave blank (root of repo)
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Under **Advanced** > **Environment Variables**, add:
   - `SECRET_KEY`: (A random secure string)
   - `PYTHON_VERSION`: `3.12.6`
   - *(Optional)* `DATABASE_URL`: Your Render PostgreSQL Internal Database URL if you attach a Postgres database.
6. Under **Health Check Path**, enter `/health`.
7. Click **Create Web Service**.
