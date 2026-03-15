---
name: sdlc:microservices
description: Scaffold a production-ready microservice — clean architecture skeleton, multi-stage Dockerfile, docker-compose local dev stack, Kubernetes manifests (Deployment/Service/ConfigMap/HPA/PDB), Kustomize overlays, and GitHub Actions CI/CD pipeline. Requires architecture to be designed first.
argument-hint: "<service-name> [--scaffold-only] [--k8s-only] [--ci-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

<objective>
Scaffold a production-ready microservice from the architecture decisions already made.

Produces:
  - src/ — clean architecture skeleton with domain, application, infrastructure, delivery layers
  - Base exception hierarchy, request context, error middleware, graceful shutdown, health endpoints
  - Entity stubs and repository interfaces derived from DATA_MODEL.md
  - Initial DB migration for all owned entities
  - Dockerfile (multi-stage, non-root) + Dockerfile.dev (hot reload)
  - docker-compose.yml — full local dev stack with all dependencies and health checks
  - k8s/base/ — Deployment, Service, ConfigMap, HPA, PDB
  - k8s/overlays/staging/ + production/ — Kustomize environment overlays
  - .github/workflows/ci.yml — build, test, lint, scan, push image
  - .github/workflows/cd.yml — deploy staging → production with approval gate
  - README.md — local setup guide

Rules:
  - Requires TECH_ARCHITECTURE.md (service boundaries must be designed first)
  - All files follow the microservices standards reference
  - Clean architecture dependency rule enforced — verified before output
  - No secrets in any generated file — all injected at runtime via K8s Secrets
  - Dockerfile: non-root user, multi-stage, no latest tags
  - K8s: resource requests+limits on every container, HPA min=2, PDB minAvailable=1
  - Health: /health/live + /health/ready + /health/startup endpoints always generated
  - Graceful shutdown: SIGTERM handler with 25s timeout always generated
</objective>

<context>
Service name and flags: $ARGUMENTS

Flags:
  --scaffold-only    Generate src/ skeleton and migrations only (no Docker/K8s/CI)
  --k8s-only         Generate K8s manifests only (service already exists)
  --ci-only          Generate GitHub Actions workflows only
</context>

<execution_context>
@/Users/seanlew/.claude/sdlc/workflows/microservices-setup.md
@/Users/seanlew/.claude/sdlc/references/microservices.md
@/Users/seanlew/.claude/sdlc/references/clean-architecture.md
</execution_context>
