---
name: sdlc:infra-design
description: Infrastructure scaffold — generates Dockerfiles, compose, K8s manifests, CI pipeline [auto-chain after design]
argument-hint: "[--auto-chain]"
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
Generate infrastructure configuration files based on the project's container runtime, orchestrator, and CI platform settings. Produces multi-stage Dockerfiles, docker-compose.yml, Kubernetes manifests, and CI pipeline definitions derived from the technical architecture.

Auto-chain: runs automatically after design phase.
Condition: containerRuntime or orchestrator set in .claude/ai-sdlc.config.yaml.
</objective>

<context>
Input: $ARGUMENTS
Flags:
  --auto-chain    Suppress interactive prompts, use defaults, return compact one-line summary
</context>

<execution_context>
@/Users/seanlew/sdlc/workflows/infra-design.md
</execution_context>
