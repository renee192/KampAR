@echo off
cd /d D:\FYP\KampAR\fyp_kampar_backend
.venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause