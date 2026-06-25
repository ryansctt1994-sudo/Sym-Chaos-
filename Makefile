SHELL := /usr/bin/env bash

PROJECT_ID ?=
REGION ?= us-central1
REPOSITORY ?= symchaos-repo
API_IMAGE ?= $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/api:latest
DASHBOARD_IMAGE ?= $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY)/dashboard:latest
TF_DIR ?= infra/gcp

.PHONY: help install dev dev-api dev-dashboard test lint fmt terraform-fmt terraform-init terraform-validate terraform-plan terraform-registry docker-auth docker-build-api docker-build-dashboard docker-push-api docker-push-dashboard docker-push deploy-gcp-coldstart

help:
	@echo "SymChaos developer commands"
	@echo ""
	@echo "Development:"
	@echo "  make install            Install JS and Python dependencies when project manifests exist"
	@echo "  make dev                Run API and dashboard concurrently"
	@echo "  make dev-api            Run FastAPI development server"
	@echo "  make dev-dashboard      Run Next.js development server"
	@echo "  make test               Run available test suites"
	@echo "  make lint               Run available linters"
	@echo "  make fmt                Format Terraform and common source files"
	@echo ""
	@echo "Terraform:"
	@echo "  make terraform-fmt      Format Terraform files"
	@echo "  make terraform-init     Initialize Terraform"
	@echo "  make terraform-validate Validate Terraform configuration"
	@echo "  make terraform-plan     Plan Terraform deployment"
	@echo "  make terraform-registry Create Artifact Registry only"
	@echo ""
	@echo "GCP images:"
	@echo "  make docker-auth        Configure Docker for Artifact Registry"
	@echo "  make docker-push        Build and push API and dashboard images"
	@echo "  make deploy-gcp-coldstart PROJECT_ID=... [REGION=us-central1]"

install:
	@if [ -f package.json ]; then npm install; fi
	@if [ -f apps/dashboard/package.json ]; then cd apps/dashboard && npm install; fi
	@if [ -f packages/symchaos-core/pyproject.toml ]; then cd packages/symchaos-core && python -m pip install -e .; fi
	@if [ -f packages/zorel-emulator/pyproject.toml ]; then cd packages/zorel-emulator && python -m pip install -e .; fi
	@if [ -f apps/api/requirements.txt ]; then python -m pip install -r apps/api/requirements.txt; fi
	@if [ -f apps/api/pyproject.toml ]; then cd apps/api && python -m pip install -e .; fi

dev:
	./scripts/dev.sh

dev-api:
	@if [ -f apps/api/main.py ]; then uvicorn apps.api.main:app --reload --host 0.0.0.0 --port 8080; \
	elif [ -f apps/api/app/main.py ]; then uvicorn apps.api.app.main:app --reload --host 0.0.0.0 --port 8080; \
	else echo "Could not find FastAPI entrypoint under apps/api." && exit 1; fi

dev-dashboard:
	@if [ -f apps/dashboard/package.json ]; then cd apps/dashboard && npm run dev; \
	else echo "Could not find apps/dashboard/package.json." && exit 1; fi

test:
	@if [ -f package.json ]; then npm test --if-present; fi
	@if [ -f apps/dashboard/package.json ]; then cd apps/dashboard && npm test --if-present; fi
	@if find . -path './.git' -prune -o -name 'test_*.py' -print -quit | grep -q .; then pytest; fi

lint:
	@if [ -f package.json ]; then npm run lint --if-present; fi
	@if [ -f apps/dashboard/package.json ]; then cd apps/dashboard && npm run lint --if-present; fi
	@if command -v ruff >/dev/null 2>&1; then ruff check .; else echo "ruff not found; skipping Python lint."; fi

fmt: terraform-fmt
	@if command -v ruff >/dev/null 2>&1; then ruff format .; else echo "ruff not found; skipping Python format."; fi
	@if [ -f package.json ]; then npm run format --if-present; fi
	@if [ -f apps/dashboard/package.json ]; then cd apps/dashboard && npm run format --if-present; fi

terraform-fmt:
	cd $(TF_DIR) && terraform fmt -recursive

terraform-init:
	cd $(TF_DIR) && terraform init

terraform-validate:
	cd $(TF_DIR) && terraform validate

terraform-plan:
	cd $(TF_DIR) && terraform plan

terraform-registry:
	cd $(TF_DIR) && terraform apply -target=google_artifact_registry_repository.symchaos_repo

docker-auth:
	gcloud auth configure-docker $(REGION)-docker.pkg.dev

docker-build-api:
	@test -n "$(PROJECT_ID)" || (echo "PROJECT_ID is required" && exit 1)
	docker build -t $(API_IMAGE) -f apps/api/Dockerfile .

docker-build-dashboard:
	@test -n "$(PROJECT_ID)" || (echo "PROJECT_ID is required" && exit 1)
	docker build -t $(DASHBOARD_IMAGE) -f apps/dashboard/Dockerfile .

docker-push-api: docker-build-api
	docker push $(API_IMAGE)

docker-push-dashboard: docker-build-dashboard
	docker push $(DASHBOARD_IMAGE)

docker-push: docker-push-api docker-push-dashboard

deploy-gcp-coldstart:
	@test -n "$(PROJECT_ID)" || (echo "PROJECT_ID is required" && exit 1)
	./scripts/deploy-gcp-coldstart.sh "$(PROJECT_ID)" "$(REGION)"
