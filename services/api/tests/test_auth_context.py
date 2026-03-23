def test_auth_dependency_extracts_user_id(client, signed_token):
    response = client.get("/v1/goals/current", headers={"Authorization": f"Bearer {signed_token}"})
    assert response.status_code != 401
