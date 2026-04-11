def test_get_todo_by_id(client):
    # 1. Сначала создаем Todo, чтобы было что получать по id
    create_response = client.post(
        "/todos",
        json={"title": "Read by id test", "done": False}
    )
    assert create_response.status_code == 201

    created_todo = create_response.json()
    todo_id = created_todo["id"]

    # 2. Запрашиваем эту Todo по id
    response = client.get(f"/todos/{todo_id}")
    assert response.status_code == 200

    data = response.json()
    assert data["id"] == todo_id
    assert data["title"] == "Read by id test"
    assert data["done"] is False


def test_get_todo_by_id_not_found(client):
    response = client.get("/todos/999999")
    assert response.status_code == 404
    assert response.json() == {"detail": "Todo not found"}


def test_update_todo(client):
    # 1. Создаем исходную запись
    create_response = client.post(
        "/todos",
        json={"title": "Old title", "done": False}
    )
    assert create_response.status_code == 201

    created_todo = create_response.json()
    todo_id = created_todo["id"]

    # 2. Обновляем запись
    update_response = client.put(
        f"/todos/{todo_id}",
        json={"title": "New title", "done": True}
    )
    assert update_response.status_code == 200

    updated = update_response.json()
    assert updated["id"] == todo_id
    assert updated["title"] == "New title"
    assert updated["done"] is True

    # 3. Дополнительно проверяем повторным GET, что обновление реально сохранилось
    get_response = client.get(f"/todos/{todo_id}")
    assert get_response.status_code == 200

    stored = get_response.json()
    assert stored["id"] == todo_id
    assert stored["title"] == "New title"
    assert stored["done"] is True


def test_update_todo_not_found(client):
    response = client.put(
        "/todos/999999",
        json={"title": "Missing todo", "done": True}
    )
    assert response.status_code == 404
    assert response.json() == {"detail": "Todo not found"}


def test_delete_todo(client):
    # 1. Создаем запись
    create_response = client.post(
        "/todos",
        json={"title": "To be deleted", "done": False}
    )
    assert create_response.status_code == 201

    created_todo = create_response.json()
    todo_id = created_todo["id"]

    # 2. Удаляем
    delete_response = client.delete(f"/todos/{todo_id}")
    assert delete_response.status_code == 200

    deleted_payload = delete_response.json()
    assert deleted_payload["message"] == "Todo deleted"

    # 3. Проверяем, что записи больше нет
    get_response = client.get(f"/todos/{todo_id}")
    assert get_response.status_code == 404
    assert get_response.json() == {"detail": "Todo not found"}


def test_delete_todo_not_found(client):
    response = client.delete("/todos/999999")
    assert response.status_code == 404
    assert response.json() == {"detail": "Todo not found"}