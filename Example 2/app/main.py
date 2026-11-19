from fastapi import FastAPI, Response
from sqlalchemy import text

from app.db import get_engine

app = FastAPI()


@app.get("/health")
def health(response: Response):
    try:
        with get_engine().connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception:
        response.status_code = 503
        return {"status": "unhealthy"}
    return {"status": "ok"}
