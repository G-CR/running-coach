def test_get_workout_detail_includes_analysis_feedback_and_features(client, auth_headers, analyzed_workout_with_feedback):
    response = client.get(f"/v1/workouts/{analyzed_workout_with_feedback.id}", headers=auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["analysis"]["mode"] == "protective"
    assert body["analysis"]["decision"]["next_workout"]["type"] == "recovery_run"
    assert body["feedback"]["selected_tags"] == ["偏吃力", "腿沉"]
    assert body["derived_features"]["average_pace_sec_per_km"] == 360.0
