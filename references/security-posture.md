# Security Posture Reference

Prescribes security practices for agentic SDLC workflows. Loaded by `commands/sdlc/00-start.md` and `commands/sdlc/08-code.md`. These are operational rules, not theory — follow them during every session.

---

## 1. Credential Isolation

**Rule: Agents never touch real credentials directly.**

- All secrets are accessed via environment variables, never hardcoded in source files.
- Use non-production accounts and sandboxed services during design, test, and build phases. Switch to production credentials only at the explicit deploy step.
- Rotate tokens after every major session or after any suspected exposure.
- Use scoped tokens — read-only where the task only requires reading (research, exploration, code review). Never use a production write credential when a read credential suffices.

**Pattern:**
```bash
# Correct — secret from environment
export DB_URL="$DATABASE_URL"

# Wrong — never do this
export DB_URL="postgres://user:password@prod-host:5432/db"
```

**Required .env discipline:**
- Every project must have `.env.example` committed to source control (with placeholder values).
- The real `.env` must be in `.gitignore` before the first commit.
- CI/CD reads secrets from vault or environment variable injection — never from committed files.

---

## 2. Sandbox Configuration

**Recommended `settings.json` for Claude Code during the build phase:**

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(npm run *)",
      "Bash(npx *)",
      "Bash(go build *)",
      "Bash(go test *)",
      "Bash(docker compose up *)",
      "Bash(docker compose down *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git add *)",
      "Bash(git commit *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force*)",
      "Bash(git push -f *)",
      "Bash(DROP TABLE*)",
      "Bash(DROP DATABASE*)",
      "Bash(truncate *)",
      "Bash(kubectl delete *)",
      "Bash(terraform destroy*)"
    ]
  }
}
```

**Phase-specific permission adjustments:**

- **Research phase** — set `defaultMode: "default"` (requires confirmation for all writes); add WebFetch and WebSearch to allow.
- **Design / artifact phase** — allow Write/Edit to `$ARTIFACTS/**` only; deny writes outside the artifacts directory.
- **Build phase** — use the config above (`defaultMode: "acceptEdits"`); write access to project source only.
- **Deploy phase** — revert to `defaultMode: "default"`; require explicit confirmation for every Bash command that touches infrastructure.

**Minimum recommended deny list (always active regardless of phase):**

```json
"deny": [
  "Bash(rm -rf /)",
  "Bash(rm -rf ~*)",
  "Bash(git push --force*)",
  "Bash(git push -f *)",
  "Bash(DROP TABLE*)",
  "Bash(DROP DATABASE*)",
  "Bash(kubectl delete namespace*)",
  "Bash(terraform destroy*)",
  "Bash(aws s3 rb *)",
  "Bash(gcloud projects delete *)"
]
```

---

## 3. MCP Tool Safety Classification

Tools are classified into three tiers. Higher tiers require more justification before use.

### Tier 1 — Read Tools (safe, auto-allow)
These tools read without side effects. No confirmation required.
- `Read` — file reads
- `Glob` — file pattern matching
- `Grep` — content search
- `Bash` read-only commands: `git status`, `git log`, `git diff`, `ls`, `cat`, `find` (read-only), `ps`, `env`

### Tier 2 — Write Tools (require confirmation)
These tools modify local state. Use `defaultMode: "acceptEdits"` during build; require explicit confirmation in research/design phases.
- `Write` — create or overwrite files
- `Edit` — modify existing files
- `Bash` write commands: `git add`, `git commit`, `npm install`, `docker build`, file creation commands

### Tier 3 — Network Tools (require justification)
These tools make outbound network requests. Every use should have a stated reason.
- `WebFetch` — fetches a specific URL
- `WebSearch` — queries a search engine
- `Bash` network commands: `curl`, `wget`, `npm publish`, `docker push`, `git push`, `kubectl apply`

**PreToolUse hook for network tools during sensitive phases (design, threat model, deploy):**

Add to `settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "WebFetch|WebSearch",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "A network request is about to be made. Confirm the URL and reason before proceeding."
          }
        ]
      }
    ]
  }
}
```

---

## 4. Secrets in Code — Detection and Prevention

**Never commit:**
- API keys (any string matching `[A-Za-z0-9]{20,}` in an assignment)
- Passwords or connection strings with embedded credentials
- Private keys (PEM blocks, `-----BEGIN * PRIVATE KEY-----`)
- OAuth client secrets
- Database URLs with username:password embedded

**Patterns to detect and block (use in pre-commit hooks and deploy gate):**

```bash
# Patterns that indicate a secret may be committed
grep -rE "(password|passwd|secret|api_key|apikey|token|private_key)\s*=\s*['\"][^'\"]{8,}" .
grep -rE "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----" .
grep -rE "(postgres|mysql|mongodb|redis):\/\/[^:]+:[^@]+@" .
grep -rE "(AKIA|AIza|sk-|xox[baprs]-)[A-Za-z0-9]+" .
```

**Required .gitignore entries for every project:**
```gitignore
.env
.env.local
.env.*.local
*.pem
*.key
*.p12
*.pfx
secrets/
credentials/
```

**If a secret is accidentally committed:**
1. Immediately rotate the credential — treat it as compromised.
2. Use `git filter-branch` or `git filter-repo` to rewrite history.
3. Force-push only after rotating (the old credential is already exposed in git history — rotating first limits the damage window).
4. Notify the relevant service provider if the key grants production access.

---

## 5. Agent Permission Scope by Phase

Each SDLC phase operates with a different permission level. Agents should not hold broader permissions than the phase requires.

| Phase | Read | Write Artifacts | Write Source | Network | Infrastructure |
|-------|------|----------------|-------------|---------|---------------|
| 00-start / research | Yes | No | No | Yes (web search) | No |
| 01-research through 05-data-model | Yes | Yes (`$ARTIFACTS/**`) | No | Yes (limited) | No |
| 06-tech-arch / design | Yes | Yes (`$ARTIFACTS/**`) | No | Read-only | No |
| 07-plan | Yes | Yes (`$ARTIFACTS/**`) | No | No | No |
| 08-code / build | Yes | Yes | Yes (project source) | Package install only | No |
| 09–13 / QA | Yes | Yes | Yes (test files) | No | No |
| deploy | Yes | No | No | Yes (explicit) | Yes (with approval) |

**Enforcement pattern — set permissions at phase start:**

In `00-start.md` and `08-code.md`, read this file and apply the corresponding permission profile. Log the active profile to `$STATE` so downstream phases inherit the right context.

**Escalation rule:** If an agent needs permissions beyond its phase profile, it must pause and ask for explicit human confirmation — not silently self-escalate. This applies to any Bash command that would write outside the allowed scope, make a network request in a read-only phase, or touch infrastructure.

---

## Checklist — Before Every Session

- [ ] `.env` is in `.gitignore` and not committed
- [ ] `settings.json` deny list includes destructive commands
- [ ] Active credentials are non-production unless explicitly in deploy phase
- [ ] Network tools have a stated reason before use
- [ ] No API keys or passwords appear in any file being edited
- [ ] Phase permission profile matches the current SDLC phase
