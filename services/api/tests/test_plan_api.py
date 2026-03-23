def test_plan_returns_seven_days_with_change_flags(client, auth_headers, analyzed_workout):
    response = client.get("/v1/plan?days=7", headers=auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["version"] == 1
    assert len(body["items"]) == 7
    assert body["items"][0]["workout_type"] == "recovery_run"
    assert body["items"][0]["changed"] is True
