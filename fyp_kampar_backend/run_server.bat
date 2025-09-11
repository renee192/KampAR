@echo off
REM Run FastAPI with uvicorn, accessible from phone
echo Starting FastAPI server...
uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
