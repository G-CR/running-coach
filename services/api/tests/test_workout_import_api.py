def test_workout_import_is_idempotent(client, auth_headers, healthkit_payload):
    first = client.post("/v1/workouts/import", json=healthkit_payload, headers=auth_headers)
    second = client.post("/v1/workouts/import", json=healthkit_payload, headers=auth_headers)

    assert first.status_code == 202
    assert second.status_code == 200
    assert second.json()["deduplicated"] is True
