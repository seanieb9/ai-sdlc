# Codebase Map Workflow

Analyse the codebase and produce a persistent, structured index that lets Claude (and humans) understand the project instantly in any future session. Replaces the need for code indexing tools or semantic search — the map IS the index.

The map lives at `.sdlc/CODEBASE_MAP.md`. It is committed with the code, survives `/clear`, and is read at the start of every session on a brownfield project.

Run once on first encounter with a brownfield codebase. Re-run with `--refresh` when significant changes have been made. Run with `--module <path>` to re-map a specific area.

---

## Step 1: Scope the Analysis

Read arguments:
- No args → map the entire project from the root
- `--module <path>` → map a specific directory or module only (update that section of CODEBASE_MAP.md)
- `--refresh` → re-run full analysis and overwrite CODEBASE_MAP.md
- `--depth <n>` → control directory depth (default: 3)

Read any existing `.sdlc/CODEBASE_MAP.md` first — if it exists and `--refresh` is not set, do an incremental update (add new files/modules, flag changed patterns).

---

## Step 2: Project Structure Analysis

Run in parallel:

**Directory tree (annotated):**
```bash
find . -type d \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
  ! -path "*/.next/*" ! -path "*/build/*" ! -path "*/__pycache__/*" \
  ! -path "*/.venv/*" ! -path "*/vendor/*" \
  | sort | head -80
```

**File count by type:**
```bash
find . -type f ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20
```

**Largest files (complexity hotspots):**
```bash
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rb" \) \
  ! -path "*/node_modules/*" ! -path "*/dist/*" ! -path "*/.venv/*" \
  -exec wc -l {} + 2>/dev/null | sort -rn | head -25
```

**TODO/FIXME/HACK concentration:**
```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|DEBT" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
  --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.git \
  . 2>/dev/null | wc -l
```

---

## Step 3: Tech Stack Identification

Read whichever of these exists (parallel reads):
- `package.json` — Node.js/JS/TS stack, dependencies, scripts
- `requirements.txt` or `pyproject.toml` or `setup.py` — Python stack
- `go.mod` — Go stack
- `Cargo.toml` — Rust stack
- `pom.xml` or `build.gradle` — Java/Kotlin stack
- `Gemfile` — Ruby stack
- `composer.json` — PHP stack
- `*.csproj` or `*.sln` — .NET stack
- `Dockerfile` and `docker-compose.yml` — runtime environment
- `.github/workflows/*.yml` or `Jenkinsfile` or `.gitlab-ci.yml` — CI/CD
- `tsconfig.json` — TypeScript config
- `.eslintrc*` or `pyproject.toml [tool.ruff]` — linting standards

Identify:
- Primary language and runtime version
- Web framework (Express, FastAPI, Django, Spring, Rails, etc.)
- ORM / database client (TypeORM, Prisma, SQLAlchemy, GORM, etc.)
- Test framework (Jest, pytest, JUnit, go test, RSpec, etc.)
- Build tool and scripts
- Key third-party dependencies (auth, messaging, storage, etc.)

---

## Step 4: Architecture Pattern Recognition

Read the top-level source directory structure and 2–3 key files to identify the architecture pattern:

**Signals to look for:**

| Pattern | Directory signals | Code signals |
|---------|------------------|--------------|
| Clean Architecture | `domain/`, `application/`, `infrastructure/`, `delivery/` | Port interfaces, use cases |
| MVC | `models/`, `views/`, `controllers/` | Framework decorators |
| Layered (N-tier) | `services/`, `repositories/`, `entities/` | Service classes calling repos |
| Hexagonal | `adapters/`, `ports/`, `core/` | Inbound/outbound adapter split |
| Feature-based | `features/`, `modules/` each with own layers | Self-contained module dirs |
| Microservices (mono-repo) | Multiple service dirs at root | Each has own package.json / go.mod |
| Flat / no pattern | Files mixed at root | No clear separation |

Read entry points (main.ts, app.py, index.js, cmd/main.go, etc.) to understand startup sequence and wiring.

---

## Step 5: Domain Concept Extraction

Find where business entities are defined:

```bash
# TypeScript/JavaScript entities
grep -rn "class.*Entity\|interface.*Model\|type.*Schema\|@Entity\|extends BaseEntity" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=dist . 2>/dev/null | head -40

# Python models
grep -rn "class.*Model\|class.*Schema\|class.*Entity" \
  --include="*.py" --exclude-dir=.venv . 2>/dev/null | head -40

# Go structs (domain types)
grep -rn "^type.*struct" --include="*.go" . 2>/dev/null | head -40
```

List all domain entities / models found with their file locations.

Find all service/use-case files:
```bash
find . -name "*Service*" -o -name "*UseCase*" -o -name "*Handler*" -o -name "*Manager*" \
  | grep -v node_modules | grep -v dist | grep -v ".git" | head -40
```

Find repository/DAO/data-access files:
```bash
find . -name "*Repository*" -o -name "*Repo*" -o -name "*DAO*" -o -name "*Store*" \
  | grep -v node_modules | grep -v dist | grep -v ".git" | head -30
```

---

## Step 6: API / Interface Extraction

Find route definitions and endpoint patterns:

```bash
# Express/Fastify/Koa
grep -rn "router\.\(get\|post\|put\|patch\|delete\)\|app\.\(get\|post\|put\|patch\|delete\)" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=dist . 2>/dev/null | head -50

# FastAPI/Flask/Django
grep -rn "@app\.\(get\|post\|put\|patch\|delete\)\|@router\.\|path(\|url(" \
  --include="*.py" --exclude-dir=.venv . 2>/dev/null | head -50

# Go (net/http or gin/echo)
grep -rn "HandleFunc\|\.GET\|\.POST\|\.PUT\|\.DELETE\|\.PATCH" \
  --include="*.go" . 2>/dev/null | head -50
```

Produce a route inventory: method + path + handler file location.

---

## Step 7: Data Access Patterns

Find database connection and query patterns:

```bash
# Connection/client initialization
grep -rn "createConnection\|new Pool\|mongoose.connect\|DataSource\|db.connect\|sql.Open\|engine = create_engine" \
  --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
  --exclude-dir=node_modules . 2>/dev/null | head -20

# Query patterns
grep -rn "\.query(\|\.findOne(\|\.findMany(\|\.save(\|\.execute(\|\.raw(" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules . 2>/dev/null | head -20
```

Find migration files:
```bash
find . -path "*/migrations/*" -o -path "*/migrate/*" \
  | grep -v node_modules | head -20
```

---

## Step 8: Cross-Cutting Concerns

Find authentication / authorization patterns:
```bash
grep -rn "middleware\|auth\|jwt\|token\|session\|requireAuth\|isAuthenticated\|@Guard\|@Auth" \
  --include="*.ts" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules . 2>/dev/null | grep -i "auth\|guard\|jwt\|session" | head -20
```

Find error handling patterns:
```bash
grep -rn "catch\|errorHandler\|Exception\|Error class\|class.*extends.*Error" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules . 2>/dev/null | head -20
```

Find logging patterns:
```bash
grep -rn "logger\.\|log\.\|console\.\|winston\|pino\|bunyan\|structlog\|logging\." \
  --include="*.ts" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules . 2>/dev/null | head -15
```

Find config/environment patterns:
```bash
grep -rn "process\.env\|os\.environ\|config\.\|getenv(" \
  --include="*.ts" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules . 2>/dev/null | head -15
```

---

## Step 9: Dependency Analysis

Find the most-imported internal files (high fan-in = critical/shared code):
```bash
# TypeScript/JavaScript
grep -rh "^import.*from\|require(" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=dist . 2>/dev/null \
  | grep -o "from '[^']*'" | sed "s/from '//;s/'//" \
  | grep "^\." | sort | uniq -c | sort -rn | head -20
```

Find files that import the most things (high fan-out = complex/coupling risk):
```bash
# Count imports per file
grep -rln "^import\|require(" \
  --include="*.ts" --include="*.js" \
  --exclude-dir=node_modules . 2>/dev/null \
  | xargs -I{} sh -c 'echo "$(grep -c "^import\|require(" {} 2>/dev/null) {}"' \
  | sort -rn | head -15
```

---

## Step 10: Test Structure Analysis

Find test files and understand the test layout:
```bash
find . \( -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" \
  -o -name "test_*.py" -o -name "*_test.go" \) \
  ! -path "*/node_modules/*" | head -30
```

Count tests by type (unit vs integration vs e2e):
```bash
find . \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" \
  | grep -E "unit|integration|e2e|contract" | head -20
```

Find test utilities, factories, fixtures:
```bash
find . \( -name "*factory*" -o -name "*fixture*" -o -name "*helper*" -o -name "*mock*" \) \
  ! -path "*/node_modules/*" | grep -i test | head -20
```

---

## Step 11: Generate Project-Specific Search Recipes

Based on the patterns found in Steps 5–10, generate grep commands tailored to THIS codebase.

For example, if the project uses Express with TypeScript and TypeORM:
```
# This project's search recipes (generated from actual patterns found)

Find API endpoints:      grep -rn "router\.(get|post|put|delete|patch)" src/
Find entities:           grep -rn "@Entity" src/domain/
Find repositories:       find src/ -name "*Repository.ts"
Find use cases:          find src/application/ -name "*.ts"
Find DB queries:         grep -rn "\.findOne\|\.save\|\.query" src/infrastructure/
Find auth checks:        grep -rn "authMiddleware\|@Auth" src/delivery/
Find error types:        grep -rn "class.*Exception\|class.*Error" src/domain/
Find config usage:       grep -rn "config\." src/ | grep -v ".test."
Find event publishers:   grep -rn "eventBus\|publish\|emit" src/application/
Find all TODOs:          grep -rn "TODO\|FIXME\|HACK" src/
```

Adjust patterns based on actual framework, language, and conventions found.

---

## Step 12: Write `.sdlc/CODEBASE_MAP.md`

```markdown
# Codebase Map
*Generated: [date] | Refreshed: [date]*
*Regenerate: /sdlc:map --refresh | Module update: /sdlc:map --module <path>*

---

## Tech Stack
| Concern | Technology | Version |
|---------|-----------|---------|
| Language | [e.g. TypeScript] | [e.g. 5.x] |
| Runtime | [e.g. Node.js] | [e.g. 20.x] |
| Framework | [e.g. Express] | [e.g. 4.x] |
| ORM / DB Client | [e.g. TypeORM] | [e.g. 0.3.x] |
| Test framework | [e.g. Jest] | [e.g. 29.x] |
| Build | [e.g. tsc + esbuild] | - |
| CI/CD | [e.g. GitHub Actions] | - |

**Key dependencies:** [list notable ones with purpose]

---

## Architecture Pattern
**Pattern:** [Clean Architecture | MVC | Layered | Hexagonal | Feature-based | Mixed | Unclear]

[1-2 sentences describing how the code is organised and why]

**Layer mapping:**
```
[directory] → [layer/purpose]
[directory] → [layer/purpose]
```

**Dependency rule:** [describe the intended flow, e.g. "controllers → services → repositories"]

---

## Project Structure
```
[annotated directory tree — 2-3 levels deep with a description of each directory]
src/
  domain/          ← Business entities and rules (no external dependencies)
  application/     ← Use cases and orchestration
  infrastructure/  ← Database, HTTP clients, external services
  delivery/        ← HTTP controllers, middleware, serialization
  ...
```

---

## Entry Points
| Purpose | File | Notes |
|---------|------|-------|
| Application start | [file:line] | [startup sequence brief] |
| HTTP server | [file:line] | [port, middleware chain] |
| Worker / queue consumer | [file:line] | [if applicable] |
| CLI | [file:line] | [if applicable] |

---

## Domain Concepts
| Entity / Concept | File(s) | Description |
|-----------------|---------|-------------|
| [EntityName] | [path] | [what it represents] |
| [EntityName] | [path] | [what it represents] |

---

## Services and Use Cases
| Name | File | Responsibility |
|------|------|---------------|
| [ServiceName] | [path] | [what it does] |

---

## API Routes
| Method | Path | Handler | Auth required |
|--------|------|---------|---------------|
| [GET] | [/api/v1/resource] | [file:line] | [yes/no] |

---

## Data Access
| Concern | Pattern | Location |
|---------|---------|---------|
| Database client | [e.g. TypeORM DataSource] | [file] |
| Connection config | [e.g. env vars] | [file] |
| Migrations | [e.g. TypeORM migrations] | [directory] |
| Repositories | [naming convention] | [directory] |

---

## Cross-Cutting Concerns
| Concern | Pattern | Location |
|---------|---------|---------|
| Authentication | [e.g. JWT middleware] | [file] |
| Authorization | [e.g. role guard] | [file] |
| Error handling | [e.g. global error middleware] | [file] |
| Logging | [e.g. pino structured logger] | [file] |
| Config | [e.g. env vars via dotenv] | [file] |
| Validation | [e.g. zod schemas] | [file] |

---

## Dependency Hotspots
**Most imported (shared/critical — change carefully):**
| File | Import count | Why it matters |
|------|-------------|----------------|
| [file] | [N] | [e.g. base entity class, everyone extends it] |

**Most complex (high fan-out — likely doing too much):**
| File | Lines | Imports | Notes |
|------|-------|---------|-------|
| [file] | [N] | [N] | [e.g. monolithic service, refactor candidate] |

---

## Test Structure
| Type | Location | Count | Notes |
|------|---------|-------|-------|
| Unit | [path] | [N] | [e.g. domain + application layers] |
| Integration | [path] | [N] | [e.g. uses test containers] |
| E2E | [path] | [N] | [e.g. Playwright against local stack] |

**How to run:**
```bash
[test command]       # all tests
[test command unit]  # unit only
[test command integ] # integration only
```

---

## Conventions
| Area | Convention |
|------|-----------|
| File naming | [e.g. PascalCase for classes, kebab-case for files] |
| Class naming | [e.g. OrderService, not ServiceOrder] |
| Error types | [e.g. domain errors extend DomainException] |
| DTO naming | [e.g. CreateOrderRequest, CreateOrderResponse] |
| Test naming | [e.g. describe('OrderService') > it('should...)')] |
| Import order | [e.g. stdlib → third-party → internal] |

---

## Technical Debt / Watch Out For
| Location | Issue | Severity |
|----------|-------|---------|
| [file or area] | [what the issue is] | [HIGH / MEDIUM / LOW] |

---

## Search Recipes
*Project-specific grep commands — copy and run directly.*

```bash
# [Category]
[grep command]    # [what it finds]

# [Category]
[grep command]    # [what it finds]
```
```

---

## Step 13: Update `.sdlc/STATE.md`

Add to Document Index:
```
- [x] .sdlc/CODEBASE_MAP.md  (generated [date])
```

Add to Context:
```
[date] CODEBASE_MAP generated — [N] entities, [N] services, [N] API routes mapped. Architecture: [pattern].
```

---

## Step 14: Output

```
✅ Codebase Map Complete

Language/Framework: [stack]
Architecture pattern: [pattern]
Source files: [N] ([N] lines total)
Entities mapped: [N]
API routes mapped: [N]
Test files: [N]
Hotspot files: [N] (>300 lines)
Tech debt items: [N]
Search recipes: [N]

File: .sdlc/CODEBASE_MAP.md

To query the map: /sdlc:explore "<question>"
To re-map a module: /sdlc:map --module <path>
```
