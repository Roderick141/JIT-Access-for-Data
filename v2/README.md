# JIT Access v2

Clean reworked project tree for database, backend (FastAPI), and frontend (React + Tailwind).

## Structure

- `database/` SQL schema, procedures, jobs, test data
- `backend/` FastAPI API calling SQL Server stored procedures
- `frontend/` Vite React app consuming `/api/*`

## Setup

1. Deploy database scripts from `database/schema` and `database/procedures`.
2. Backend:
   - Copy `backend/.env.example` to `backend/.env` and fill values.
   - `pip install -r backend/requirements.txt`
   - Run `uvicorn main:app --host 127.0.0.1 --port 8000 --reload` from `backend/`.
3. Frontend:
   - `npm install` in `frontend/`
   - `npm run dev`
   - Vite proxies `/api` to `http://127.0.0.1:8000`.

## Notes

- API auth uses `X-Remote-User` header or `JIT_FAKE_USER` in backend `.env`.
- Manager endpoints require admin or data steward.
- Business logic remains in SQL stored procedures.

