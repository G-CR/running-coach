def test_update_current_goal_creates_history_record(client, auth_headers):
    payload = {
        "primary_goal_type": "ten_k_improvement",
        "target_time_sec": 3000,
        "target_date": "2026-06-01",
        "weekly_run_days": 4,
    }
    response = client.post("/v1/goals/current", json=payload, headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["history_recorded"] is True
