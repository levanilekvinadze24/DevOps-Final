.PHONY: setup validate deploy rollback test security lint

setup:
	./scripts/setup.sh

validate:
	./scripts/validate-environment.sh

deploy:
	./scripts/deploy.sh

rollback:
	./scripts/rollback.sh

test:
	cd app && python -m pytest tests/ -v

security:
	docker compose config --quiet
	pip-audit -r app/requirements.txt

lint:
	docker run --rm -i hadolint/hadolint hadolint - < app/Dockerfile
