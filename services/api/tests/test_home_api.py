def test_home_returns_next_workout_and_todo_flags(client, auth_headers, analyzed_workout):
    response = client.get("/v1/home", headers=auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["next_workout"]["type"] == "recovery_run"
    assert body["latest_workout_summary"]["id"] == analyzed_workout.id
    assert body["plan_change_summary"]["changed_items"] == 3
    assert body["todos"]["needs_feedback"] is True
