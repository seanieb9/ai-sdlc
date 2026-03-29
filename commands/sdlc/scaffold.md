---
name: sdlc:scaffold
description: Scaffold a production-ready service — clean architecture skeleton, multi-stage Dockerfile, docker-compose, Kubernetes manifests (Deployment/Service/ConfigMap/HPA/PDB), Kustomize overlays, GitHub Actions CI/CD. Requires architecture to be designed first.
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
  - Agent
---

<objective>
Config-driven production service scaffolder. Reads tech stack from .claude/ai-sdlc.config.yaml and architecture from the design phase, then generates a complete service skeleton with all infrastructure files.

Generates:
  - Clean architecture skeleton: domain/, application/, infrastructure/, delivery/ layers
  - Multi-stage Dockerfile (non-root user, layer caching, HEALTHCHECK)
  - docker-compose.yml for local dev (app + dependencies)
  - Kubernetes manifests: Deployment, Service, ConfigMap, HPA, PDB
  - Kustomize overlays: base/, staging/, production/
  - GitHub Actions CI/CD pipeline: build, test, lint, docker-build, security-scan
  - Graceful shutdown handler
  - All three health probes: /health/live, /health/ready, /health/startup
</objective>

<context>
Input: $ARGUMENTS — service name

Flags:
  --scaffold-only   Generate code skeleton only (no infra)
  --k8s-only        Generate Kubernetes manifests only
  --ci-only         Generate CI/CD pipeline only
</context>

<execution_context>
@~/.claude/sdlc/workflows/microservices-setup.md
@~/.claude/sdlc/workflows/workspace-resolution.md
@~/.claude/sdlc/references/clean-architecture.md
</execution_context>
