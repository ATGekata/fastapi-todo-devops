import logging
import os

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import check_db_connection, get_db
from app.models import Todo


logger = logging.getLogger(__name__)

app = FastAPI(title="Todo DevOps Demo")

class TodoCreate(BaseModel):
    title: str
    done: bool = False


class TodoUpdate(BaseModel):
    title: str
    done: bool


def serialize_todo(todo: Todo) -> dict:
    return {
        "id": todo.id,
        "title": todo.title,
        "done": todo.done,
    }


def get_todo_or_404(db: Session, todo_id: int) -> Todo:
    todo = db.get(Todo, todo_id)
    if todo is None:
        raise HTTPException(status_code=404, detail="Todo not found")
    return todo


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
        "release": os.getenv("APP_RELEASE", "dev"),
    }


@app.get("/todos")
def get_todos(db: Session = Depends(get_db)):
    items = db.execute(select(Todo).order_by(Todo.id)).scalars().all()
    return [serialize_todo(item) for item in items]


@app.get("/todos/{todo_id}")
def get_todo(todo_id: int, db: Session = Depends(get_db)):
    todo = get_todo_or_404(db, todo_id)
    return serialize_todo(todo)


@app.post("/todos", status_code=201)
def create_todo(todo: TodoCreate, db: Session = Depends(get_db)):
    db_todo = Todo(title=todo.title, done=todo.done)
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)

    return serialize_todo(db_todo)


@app.put("/todos/{todo_id}")
def update_todo(todo_id: int, payload: TodoUpdate, db: Session = Depends(get_db)):
    db_todo = get_todo_or_404(db, todo_id)

    db_todo.title = payload.title
    db_todo.done = payload.done

    db.commit()
    db.refresh(db_todo)

    return serialize_todo(db_todo)


@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int, db: Session = Depends(get_db)):
    db_todo = get_todo_or_404(db, todo_id)

    db.delete(db_todo)
    db.commit()

    return {
        "message": "Todo deleted",
        "todo_id": todo_id,
    }


instrumentator = Instrumentator(
    excluded_handlers=["/metrics"],
)

instrumentator.instrument(app).expose(
    app,
    include_in_schema=False,
    should_gzip=True,
)