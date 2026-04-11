import os
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
import logging
from fastapi import HTTPException
from app.db import check_db_connection

app = FastAPI(title="Todo DevOps Demo")

todos = []


class TodoItem(BaseModel):
    title: str
    done: bool = False


logger = logging.getLogger(__name__)


@app.get("/db-health")
def db_health():
    try:
        info = check_db_connection()
        return {
            "database": "up",
            "db_name": info["database"],
            "db_user": info["user"],
        }
    except Exception:
        logger.exception("Database connectivity check failed")
        raise HTTPException(status_code=503, detail="Database unavailable")

@app.get("/")
def root():
    return {"message": "Todo API is running"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/version")
def version():
    return {
        "app": "fastapi-todo-devops",
        "commit_sha": os.getenv("APP_COMMIT_SHA", "unknown"),
        "release": os.getenv("APP_RELEASE", "dev")
    }


@app.get("/todos")
def get_todos():
    return todos


@app.post("/todos")
def create_todo(todo: TodoItem):
    todos.append(todo.model_dump())
    return {"message": "todo created", "todo": todo}

instrumentator = Instrumentator(
    excluded_handlers=["/metrics"],
)

instrumentator.instrument(app).expose(
    app,
    include_in_schema=False,
    should_gzip=True,
)
