PYTHON := ./.venv/bin/python

.PHONY: test-api test-domain ios-generate

test-api:
	$(PYTHON) -m pytest services/api/tests -q

test-domain:
	$(PYTHON) -m pytest packages/domain/tests -q

ios-generate:
	xcodegen generate --spec apps/ios/project.yml
