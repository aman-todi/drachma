# Single image for both ECS Fargate services (api, sync-worker).
# Task definitions select the process via `command`, not separate images.
#
# NOTE for the build session: adjust the COPY/entrypoint paths once the
# FastAPI app and sync worker packages exist. Placeholders below assume
# a `src/` layout with `src/api/main.py` (FastAPI ASGI app) and
# `src/worker/main.py` (sync worker entrypoint), per the settled shell
# in the spec (map.md Notes).

FROM python:3.12-slim AS base

WORKDIR /app

COPY pyproject.toml poetry.lock* requirements.txt* ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

# ECS task definitions override `command`:
#   api:          uvicorn src.api.main:app --host 0.0.0.0 --port 8000
#   sync-worker:  python -m src.worker.main
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
