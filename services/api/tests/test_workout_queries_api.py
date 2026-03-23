def test_get_workout_detail_returns_laps_and_distributions(client, auth_headers, imported_workout):
    response = client.get(f"/v1/workouts/{imported_workout.id}", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()["laps"]) == 5
    assert "heart_rate_distribution" in response.json()["distributions"]
