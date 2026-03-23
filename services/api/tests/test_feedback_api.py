def test_submit_feedback_creates_new_analysis_job(client, auth_headers, imported_workout):
    payload = {
        "rpe": 7,
        "fatigue": 4,
        "soreness": 2,
        "breathing_load": 3,
        "confidence": 4,
        "selected_tags": ["偏吃力", "腿沉"],
        "free_text": "前半程轻松，后半程腿有点重。",
    }
    response = client.post(
        f"/v1/workouts/{imported_workout.id}/feedback",
        json=payload,
        headers=auth_headers,
    )
    assert response.status_code == 202
    assert response.json()["analysis_requeued"] is True
