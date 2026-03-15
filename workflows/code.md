# Code Workflow

Implement planned tasks following clean architecture, clean code, and established patterns. A plan MUST exist. No improvised coding.

## Step 1: Pre-Flight Gate Check

Read in parallel (ALL required):
- `.sdlc/PLAN.md` — REQUIRED. Must exist with tasks defined.
- `.sdlc/TODO.md` — REQUIRED. Identifies tasks to work on.
- `docs/data/DATA_MODEL.md` — entity shapes, invariants, field types
- `docs/architecture/TECH_ARCHITECTURE.md` — component design, layer decisions, patterns chosen
- `docs/architecture/API_SPEC.md` — contracts to implement exactly
- `docs/architecture/SOLUTION_DESIGN.md` — ADRs: auth strategy, DB choice, patterns
- `docs/product/PRODUCT_SPEC.md` — requirements and acceptance criteria to fulfill
- `.sdlc/STATE.md` — project context, tech stack, constraints

If PLAN.md missing: STOP. Run `/sdlc:07-plan` first.
If TODO.md missing or empty: STOP. No tasks to work on.

Identify the task from `$ARGUMENTS` (TASK-ID or description). If none specified, show the next available task from TODO.md and ask for confirmation before proceeding.

---

## Step 2: Task Orientation

For the identified task:
1. Read the task description and done criteria from TODO.md
2. Identify the layer: domain / application / infrastructure / delivery
3. Read ALL existing code in the affected area — understand patterns before writing
4. Identify which requirements (REQ-IDs) this task satisfies — note them
5. Identify which API endpoints (from API_SPEC.md) this task implements — note them
6. Identify which DATA_MODEL.md entities this task touches — note them
7. List the precise files to create or modify before writing a single line

Never start coding without reading the existing code in the affected area. If the pattern is unclear, ask — don't invent.

---

## Step 3: Design the Error Hierarchy (first time only)

If the project does not yet have a defined exception hierarchy, establish it now. This is infrastructure for all subsequent code.

**Exception hierarchy (establish once, reference always):**

```
DomainException               ← invariant violations inside entities/value objects
  └── BusinessRuleException   ← named business rule violated (e.g. InsufficientFundsException)

ApplicationException          ← use case precondition failures
  └── NotFoundException       ← requested resource does not exist
  └── ConflictException       ← state conflict (e.g. already exists, wrong status)
  └── AuthorizationException  ← caller lacks permission for this operation

ValidationException           ← input schema/type failures (delivery layer)
  └── fields: list of {field, message}

InfrastructureException       ← DB/network/external service failures
```

**HTTP mapping (in error-handling middleware, NOT in use cases):**
```
DomainException        → 422 Unprocessable Entity
BusinessRuleException  → 422 Unprocessable Entity
ApplicationException   → 500 (default — be specific below)
NotFoundException      → 404 Not Found
ConflictException      → 409 Conflict
AuthorizationException → 403 Forbidden
ValidationException    → 400 Bad Request
InfrastructureException → 500 Internal Server Error (never leak details)
```

Rules:
- Domain exceptions carry a machine-readable `code` (e.g. `INSUFFICIENT_FUNDS`) and human message
- Infrastructure exceptions are caught at the boundary, logged with full detail, re-thrown as `InfrastructureException` with a safe message (never leak DB errors to callers)
- Never throw HTTP-specific exceptions from domain or application layers — they know nothing about HTTP
- Never swallow exceptions — empty catch blocks are a bug

---

## Step 4: Implement in Layer Order

Always implement in this sequence within a task. Never implement a higher layer before the layer beneath it is done.

### 4a: Domain Layer — implement first

**Entities:**
- Enforce ALL invariants in the constructor — never allow an invalid entity to be created
- All mutation through named methods that enforce business rules (rich domain model, not anemic)
- Collect domain events internally — dispatch happens AFTER the transaction commits (see Step 6)
- Use a version field for optimistic locking on aggregates that can be modified concurrently

```python
class Order:
    def __init__(self, customer_id: UUID, items: list[OrderItem]):
        # Invariant enforcement
        if not items:
            raise DomainException("Order must have at least one item", code="ORDER_EMPTY")
        if any(i.quantity <= 0 for i in items):
            raise DomainException("All items must have positive quantity", code="INVALID_QUANTITY")

        self._id = uuid4()
        self._customer_id = customer_id
        self._items = list(items)
        self._status = OrderStatus.PENDING
        self._version = 0                      # optimistic lock version
        self._events: list[DomainEvent] = [
            OrderCreated(order_id=self._id, customer_id=customer_id)
        ]

    def submit(self) -> None:
        if self._status != OrderStatus.PENDING:
            raise BusinessRuleException(
                f"Cannot submit order in status {self._status}",
                code="ORDER_NOT_SUBMITTABLE"
            )
        self._status = OrderStatus.SUBMITTED
        self._events.append(OrderSubmitted(order_id=self._id))

    def collect_events(self) -> list[DomainEvent]:
        return list(self._events)

    def clear_events(self) -> None:
        self._events.clear()
```

**Value Objects:**
- Immutable — no setters, frozen dataclass or equivalent
- Equality by value, not identity
- Self-validating constructor — raise `DomainException` for invalid values
- Encapsulate domain logic related to the value (e.g. `Money.add()`, `Email.domain()`)

```python
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str  # ISO 4217

    def __post_init__(self):
        if self.amount < 0:
            raise DomainException("Amount cannot be negative", code="NEGATIVE_AMOUNT")
        if len(self.currency) != 3:
            raise DomainException("Currency must be ISO 4217", code="INVALID_CURRENCY")

    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise DomainException("Cannot add different currencies", code="CURRENCY_MISMATCH")
        return Money(self.amount + other.amount, self.currency)
```

**Domain Services:**
- Stateless — no instance state
- Pure domain logic that spans multiple entities and doesn't belong on any single one
- No infrastructure dependencies — if you need to look something up, accept it as a parameter
- Rarely needed — if you find yourself reaching for a domain service often, check if the logic belongs on an entity first

**Aggregate boundaries:**
- An aggregate is a cluster of entities/value objects treated as a unit for data changes
- Only the aggregate root is accessible from outside — never hold references to child entities
- All changes to children go through the root's methods (which enforce cross-entity invariants)
- Keep aggregates small — if loading one aggregate requires many DB joins, the boundary is wrong

**Repository interfaces (ports — defined in domain, implemented in infrastructure):**
```python
class OrderRepository(ABC):
    @abstractmethod
    def find_by_id(self, id: UUID) -> Optional[Order]: ...
    @abstractmethod
    def find_by_customer(self, customer_id: UUID, cursor: str | None, limit: int) -> Page[Order]: ...
    @abstractmethod
    def save(self, order: Order) -> None: ...      # insert or update
    @abstractmethod
    def delete(self, id: UUID) -> None: ...
```

**Import rule: ZERO imports from application, infrastructure, or delivery layers.**

---

### 4b: Application Layer — implement second

**Use cases (one class per use case):**
- Single `execute()` method with a typed command/request object
- Returns a typed result object (never return domain entities directly — use DTOs)
- Owns the transaction boundary: the transaction starts and ends in the use case
- After transaction commits: dispatch domain events (see Step 6)
- Checks authorization before doing any work (see Step 7)
- Checks business preconditions before constructing domain objects

```python
@dataclass
class CreateOrderCommand:
    customer_id: UUID
    items: list[OrderItemRequest]
    idempotency_key: str | None
    request_context: RequestContext    # carries trace_id, user_id, roles

@dataclass
class CreateOrderResult:
    order_id: UUID
    status: str

class CreateOrderUseCase:
    def __init__(
        self,
        order_repo: OrderRepository,
        customer_repo: CustomerRepository,
        event_dispatcher: EventDispatcher,
        idempotency_store: IdempotencyStore,
    ):
        self._order_repo = order_repo
        self._customer_repo = customer_repo
        self._event_dispatcher = event_dispatcher
        self._idempotency_store = idempotency_store

    def execute(self, command: CreateOrderCommand) -> CreateOrderResult:
        # 1. Authorization check (before any work)
        if not command.request_context.has_role('customer'):
            raise AuthorizationException("Must be a customer to place orders")

        # 2. Idempotency check (before any side effects)
        if command.idempotency_key:
            cached = self._idempotency_store.get(command.idempotency_key)
            if cached:
                return cached  # return previous result, no duplicate processing

        # 3. Business preconditions
        customer = self._customer_repo.find_by_id(command.customer_id)
        if not customer:
            raise NotFoundException(f"Customer {command.customer_id} not found")
        if not customer.is_active:
            raise ConflictException("Customer account is not active", code="ACCOUNT_INACTIVE")

        # 4. Build domain objects (invariants enforced inside)
        items = [
            OrderItem(UUID(r.product_id), r.quantity, Money(r.unit_price, r.currency))
            for r in command.items
        ]
        order = Order(command.customer_id, items)  # raises DomainException if invalid

        # 5. Persist (transaction boundary — begins here, commits here)
        self._order_repo.save(order)

        # 6. Dispatch events AFTER commit
        events = order.collect_events()
        order.clear_events()
        self._event_dispatcher.dispatch_all(events)

        # 7. Cache idempotency result
        result = CreateOrderResult(order_id=order.id, status=order.status.value)
        if command.idempotency_key:
            self._idempotency_store.set(command.idempotency_key, result)

        return result
```

**CQRS — Query handlers (if architecture chose CQRS):**
- Separate from command handlers — queries do NOT go through the domain model
- Query handlers return read-optimized DTOs directly from the DB (skip repository interface)
- No domain events, no transaction boundaries, no invariant checking needed
- Can be as simple as a parameterized SQL query returning a DTO

```python
class GetOrderSummaryQuery:
    order_id: UUID
    request_context: RequestContext

class GetOrderSummaryHandler:
    def __init__(self, db: ReadDatabase):
        self._db = db

    def handle(self, query: GetOrderSummaryQuery) -> OrderSummaryDTO:
        row = self._db.query_one(
            "SELECT id, status, total, created_at FROM orders WHERE id = %s",
            [query.order_id]
        )
        if not row:
            raise NotFoundException(f"Order {query.order_id} not found")
        return OrderSummaryDTO(**row)
```

**Port interfaces for external services:**
```python
class PaymentPort(ABC):
    @abstractmethod
    def charge(self, amount: Money, method_id: str, idempotency_key: str) -> PaymentResult: ...

class NotificationPort(ABC):
    @abstractmethod
    def send_order_confirmation(self, order_id: UUID, customer_email: str) -> None: ...
```

**Import rule: NO imports from infrastructure or delivery layers.**

---

### 4c: Infrastructure Layer — implement third

**Repository implementations:**

Map between the ORM/DB model and the domain entity. The domain entity must never be the ORM model — they are separate objects.

```python
class PostgresOrderRepository(OrderRepository):
    def __init__(self, db: Database):
        self._db = db

    def find_by_id(self, id: UUID) -> Optional[Order]:
        row = self._db.query_one(
            "SELECT * FROM orders WHERE id = %s", [id]
        )
        if not row:
            return None
        return self._to_domain(row)   # always map row → domain entity

    def save(self, order: Order) -> None:
        row = self._to_row(order)     # map domain entity → row
        self._db.upsert('orders', row, conflict_column='id', version_column='version')
        # version column handles optimistic locking — raises ConcurrentModificationError on mismatch

    def _to_domain(self, row: dict) -> Order:
        # Reconstruct domain entity from raw data
        # Use a reconstitution factory or private constructor — bypass invariant checks
        # (data was valid when saved; do not re-run creation invariants on load)
        items = self._load_items(row['id'])
        return Order.reconstitute(
            id=UUID(row['id']),
            customer_id=UUID(row['customer_id']),
            status=OrderStatus(row['status']),
            items=items,
            version=row['version']
        )

    def _to_row(self, order: Order) -> dict:
        return {
            'id': str(order.id),
            'customer_id': str(order.customer_id),
            'status': order.status.value,
            'version': order.version,
            'updated_at': utcnow(),
        }
```

**N+1 query prevention:**
- If loading a collection of aggregates with children, use a JOIN or batch-load children
- Never load child records inside a loop
- Document any known eager/lazy loading choices in comments

**External service adapters:**
- Wrap the external SDK entirely — calling code should never import the vendor SDK directly
- Translate external errors into domain/infrastructure exceptions
- Never let vendor exception types leak into the application layer
- Apply retry + backoff here for transient errors, not in the use case

```python
class StripePaymentAdapter(PaymentPort):
    def __init__(self, client: stripe.StripeClient, config: PaymentConfig):
        self._client = client
        self._config = config

    def charge(self, amount: Money, method_id: str, idempotency_key: str) -> PaymentResult:
        try:
            intent = self._client.payment_intents.create(
                amount=int(amount.amount * 100),   # Stripe uses cents
                currency=amount.currency.lower(),
                payment_method=method_id,
                idempotency_key=idempotency_key,
            )
            return PaymentResult(payment_id=intent.id, status=intent.status)
        except stripe.CardError as e:
            raise BusinessRuleException(e.user_message, code="PAYMENT_DECLINED")
        except stripe.StripeError as e:
            raise InfrastructureException(f"Payment provider error: {type(e).__name__}")
            # Do NOT include e.message — may contain sensitive data
```

**Database migrations:**
- One migration file per change — never modify an existing migration
- Naming convention: `YYYYMMDDHHMMSS_description_of_change.sql`
- Every migration must have an `up` and a `down` (rollback)
- Separate schema migrations (DDL: `CREATE TABLE`, `ALTER TABLE`) from data migrations (DML: `INSERT`, `UPDATE`) — run in separate transactions
- For large tables: use `ADD COLUMN ... DEFAULT NULL` (no lock), backfill in batches, then add constraint separately
- Never rename a column in production in a single migration — add new column, dual-write, migrate data, drop old column

**Import rule: CAN import from domain and application layers only.**

---

### 4d: Delivery Layer — implement last

**HTTP controllers — thin, no business logic:**
```python
class OrderController:
    def __init__(
        self,
        create_order: CreateOrderUseCase,
        get_order: GetOrderSummaryHandler,
    ):
        self._create_order = create_order
        self._get_order = get_order

    def post_order(self, request: HttpRequest) -> HttpResponse:
        # 1. Schema validation only (not business rules)
        body = CreateOrderRequestSchema.parse(request.body)   # raises ValidationException if invalid

        # 2. Build command with request context
        command = CreateOrderCommand(
            customer_id=request.auth.user_id,
            items=body.items,
            idempotency_key=request.headers.get('Idempotency-Key'),
            request_context=RequestContext.from_request(request),
        )

        # 3. Execute use case
        result = self._create_order.execute(command)

        # 4. Serialize — never return domain entity directly
        return HttpResponse(
            status=201,
            body={"order_id": str(result.order_id), "status": result.status},
            headers={"Location": f"/api/v1/orders/{result.order_id}"}
        )
```

Controllers must NOT: contain business logic, query databases directly, construct domain objects, handle authorization (authorization belongs in the use case).

**Request/Response DTOs:**
- Request DTOs: validate schema (types, required fields, formats) — not business rules
- Response DTOs: explicit field list — never serialize a domain entity or ORM model directly
- Sensitive fields (passwords, tokens, full card numbers): never include in response DTOs

**Error handling middleware:**
- One central place that catches all exceptions and maps to HTTP responses
- Never let unhandled exceptions surface raw stack traces to callers
- Log full exception detail server-side; return safe error response to client

```python
def error_middleware(handler):
    def wrapped(request):
        try:
            return handler(request)
        except ValidationException as e:
            return HttpResponse(400, {"code": "VALIDATION_ERROR", "message": str(e), "fields": e.fields, "trace_id": request.trace_id})
        except NotFoundException as e:
            return HttpResponse(404, {"code": "NOT_FOUND", "message": str(e), "trace_id": request.trace_id})
        except ConflictException as e:
            return HttpResponse(409, {"code": e.code, "message": str(e), "trace_id": request.trace_id})
        except AuthorizationException as e:
            return HttpResponse(403, {"code": "FORBIDDEN", "message": str(e), "trace_id": request.trace_id})
        except DomainException as e:
            return HttpResponse(422, {"code": e.code, "message": str(e), "trace_id": request.trace_id})
        except InfrastructureException as e:
            logger.error("infrastructure_failure", error=str(e), trace_id=request.trace_id)
            return HttpResponse(500, {"code": "INTERNAL_ERROR", "message": "An unexpected error occurred", "trace_id": request.trace_id})
        except Exception as e:
            logger.critical("unhandled_exception", error=str(e), trace_id=request.trace_id, exc_info=True)
            return HttpResponse(500, {"code": "INTERNAL_ERROR", "message": "An unexpected error occurred", "trace_id": request.trace_id})
    return wrapped
```

**Authentication middleware:**
- Validate token (signature, expiry, issuer)
- Extract identity and attach to request context
- Raise `401 Unauthorized` if token missing or invalid
- NEVER extract identity inside a use case or domain object — it flows in via `RequestContext`

**Dependency injection / composition root:**
- Update the composition root every time a new use case or adapter is added
- Wire: repository implementations → use cases; adapter implementations → use cases; use cases → controllers
- No `new` calls anywhere except the composition root
- In tests: swap implementations via the same constructor injection — no monkey patching

```python
# composition_root.py  (one file, wired at startup)
def build_container(config: Config) -> AppContainer:
    db = PostgresDatabase(config.database_url)
    event_dispatcher = OutboxEventDispatcher(db)
    idempotency_store = RedisIdempotencyStore(config.redis_url)

    order_repo = PostgresOrderRepository(db)
    customer_repo = PostgresCustomerRepository(db)
    payment_adapter = StripePaymentAdapter(stripe.StripeClient(config.stripe_key), config.payment)

    create_order_uc = CreateOrderUseCase(order_repo, customer_repo, event_dispatcher, idempotency_store)
    get_order_handler = GetOrderSummaryHandler(db)

    order_controller = OrderController(create_order_uc, get_order_handler)
    return AppContainer(order_controller=order_controller)
```

---

### 4e: Event-Driven Infrastructure — implement alongside delivery (if applicable)

Skip this step entirely if the architecture does not use messaging/events.

If the TECH_ARCHITECTURE.md event-driven design exists, implement all of the following. Reference the event taxonomy and broker topology defined there.

---

#### Event Envelope

Every message published to the broker uses a standard envelope. Define this once:

```python
@dataclass(frozen=True)
class EventEnvelope:
    event_id: UUID          # unique per event instance — used for deduplication
    event_type: str         # e.g. "order.placed.v1"
    event_version: str      # "v1", "v2" — incremented on breaking schema changes
    occurred_at: datetime   # ISO 8601 UTC — when the domain event happened
    producer: str           # service name — e.g. "order-service"
    trace_id: str           # W3C TraceContext trace ID — for distributed tracing
    correlation_id: str     # business correlation (e.g. order_id)
    payload: dict           # event-specific data (see event schema below)
```

Rules:
- `event_id` is generated when the domain event is created — it is stable across retry/relay
- `event_type` uses dot notation: `{domain}.{event}.{version}` — e.g. `order.placed.v1`
- `occurred_at` is the business timestamp (when it happened), not the publish timestamp
- Never put sensitive PII in the envelope payload — use references (IDs), not values where possible

---

#### Outbox Table Schema

The outbox table is written inside the business transaction (Step 6). Define the migration:

```sql
CREATE TABLE outbox_events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id     UUID NOT NULL UNIQUE,      -- idempotency: don't publish twice
    event_type   VARCHAR(255) NOT NULL,
    topic        VARCHAR(255) NOT NULL,     -- broker topic/exchange to publish to
    payload      JSONB NOT NULL,            -- serialized EventEnvelope
    status       VARCHAR(50) NOT NULL DEFAULT 'PENDING',  -- PENDING | PUBLISHED | FAILED
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ,
    attempts     INT NOT NULL DEFAULT 0,
    last_error   TEXT
);

CREATE INDEX idx_outbox_status_created ON outbox_events (status, created_at)
    WHERE status = 'PENDING';
```

---

#### Outbox Relay Process (infrastructure)

The relay is a background worker — separate from the API process — that polls the outbox and publishes to the broker:

```python
class OutboxRelayWorker:
    """
    Polls outbox_events for PENDING records and publishes to the message broker.
    Runs on a short interval (e.g. every 500ms or triggered by DB NOTIFY).
    """
    BATCH_SIZE = 50
    MAX_ATTEMPTS = 5
    RETRY_BACKOFF = [1, 2, 5, 15, 30]  # seconds between attempts

    def __init__(self, db: Database, broker: MessageBroker, metrics: MetricsClient):
        self._db = db
        self._broker = broker
        self._metrics = metrics

    def run_once(self) -> None:
        rows = self._db.query(
            """
            SELECT * FROM outbox_events
            WHERE status = 'PENDING'
              AND (attempts = 0 OR last_error_at < now() - (RETRY_BACKOFF[attempts] || ' seconds')::interval)
            ORDER BY created_at
            LIMIT %s
            FOR UPDATE SKIP LOCKED
            """,
            [self.BATCH_SIZE]
        )

        for row in rows:
            try:
                self._broker.publish(
                    topic=row['topic'],
                    key=row['event_id'],          # partition key for ordering
                    payload=row['payload'],
                    headers={"event_type": row['event_type']}
                )
                self._db.execute(
                    "UPDATE outbox_events SET status='PUBLISHED', published_at=now() WHERE id=%s",
                    [row['id']]
                )
                self._metrics.increment("outbox.published", tags={"event_type": row['event_type']})

            except Exception as e:
                new_attempts = row['attempts'] + 1
                new_status = 'FAILED' if new_attempts >= self.MAX_ATTEMPTS else 'PENDING'
                self._db.execute(
                    """UPDATE outbox_events
                       SET attempts=%s, status=%s, last_error=%s, last_error_at=now()
                       WHERE id=%s""",
                    [new_attempts, new_status, str(e), row['id']]
                )
                logger.warning("outbox.relay_failed", {
                    "event_id": row['event_id'],
                    "event_type": row['event_type'],
                    "attempt": new_attempts,
                    "error": str(e)
                })
                if new_status == 'FAILED':
                    logger.error("outbox.dead_letter", {
                        "event_id": row['event_id'],
                        "event_type": row['event_type'],
                        "max_attempts_reached": True
                    })
                    self._metrics.increment("outbox.dead_lettered", tags={"event_type": row['event_type']})
```

Rules:
- `FOR UPDATE SKIP LOCKED` prevents multiple relay instances from processing the same row (safe for horizontal scaling)
- Failed rows after MAX_ATTEMPTS are marked `FAILED` and alerted — they require manual intervention or a dead-letter queue consumer
- Relay interval: 500ms for low-latency; 5s is fine for background workflows — document in OBSERVABILITY.md

---

#### Message Broker Publisher Adapter (infrastructure)

```python
class RabbitMQMessageBroker(MessageBroker):
    def __init__(self, connection: pika.BlockingConnection):
        self._channel = connection.channel()

    def publish(self, topic: str, key: str, payload: dict, headers: dict) -> None:
        try:
            self._channel.basic_publish(
                exchange=topic,
                routing_key=key,
                body=json.dumps(payload),
                properties=pika.BasicProperties(
                    content_type='application/json',
                    delivery_mode=2,        # persistent — survives broker restart
                    message_id=key,         # used for broker-level deduplication where supported
                    headers=headers,
                )
            )
        except pika.exceptions.AMQPError as e:
            raise InfrastructureException(f"Message broker publish failed: {type(e).__name__}")
```

---

#### Event Consumer / Handler Pattern

Each event type has a dedicated handler class in the application layer (or a separate consumer service):

```python
# Application layer: define the handler interface and command
@dataclass
class HandleOrderPlacedCommand:
    event_id: UUID
    order_id: UUID
    customer_id: UUID
    occurred_at: datetime
    trace_id: str

class HandleOrderPlacedUseCase:
    """
    Triggered when an OrderPlaced event is received.
    Sends confirmation email and reserves inventory.
    """
    def __init__(
        self,
        notification_port: NotificationPort,
        inventory_port: InventoryPort,
        idempotency_store: IdempotencyStore,
    ):
        self._notification = notification_port
        self._inventory = inventory_port
        self._idempotency_store = idempotency_store

    def execute(self, command: HandleOrderPlacedCommand) -> None:
        # 1. Idempotency check — consumers MUST be idempotent (at-least-once delivery)
        key = f"handle_order_placed:{command.event_id}"
        if self._idempotency_store.get(key):
            logger.info("consumer.duplicate_skipped", {
                "event_id": str(command.event_id),
                "handler": "HandleOrderPlaced"
            })
            return

        # 2. Handle the event
        self._notification.send_order_confirmation(command.order_id, command.customer_id)
        self._inventory.reserve(command.order_id)

        # 3. Mark as processed
        self._idempotency_store.set(key, True, ttl_seconds=86400 * 7)  # 7 days
```

---

#### Consumer Infrastructure (delivery layer for events)

```python
# Infrastructure: message broker consumer — thin, like an HTTP controller
class OrderEventConsumer:
    def __init__(
        self,
        handle_order_placed: HandleOrderPlacedUseCase,
        handle_order_cancelled: HandleOrderCancelledUseCase,
    ):
        self._handlers = {
            "order.placed.v1": self._on_order_placed,
            "order.cancelled.v1": self._on_order_cancelled,
        }

    def on_message(self, message: BrokerMessage) -> ConsumerResult:
        event_type = message.headers.get("event_type")
        handler = self._handlers.get(event_type)

        if not handler:
            logger.warning("consumer.unknown_event_type", {"event_type": event_type})
            return ConsumerResult.ACK    # ack unknown types — don't block the queue

        try:
            envelope = EventEnvelope(**json.loads(message.body))
            handler(envelope)
            return ConsumerResult.ACK

        except ValidationException as e:
            # Malformed message — don't retry, route to DLQ
            logger.error("consumer.malformed_message", {
                "event_type": event_type,
                "error": str(e),
                "message_id": message.id
            })
            return ConsumerResult.DEAD_LETTER

        except InfrastructureException as e:
            # Transient failure — NACK and let the broker retry
            logger.warning("consumer.transient_failure", {
                "event_type": event_type,
                "error": str(e),
                "message_id": message.id
            })
            return ConsumerResult.NACK    # broker will redeliver

        except Exception as e:
            logger.error("consumer.unhandled_error", {
                "event_type": event_type,
                "error": str(e),
                "message_id": message.id
            }, exc_info=True)
            return ConsumerResult.NACK

    def _on_order_placed(self, envelope: EventEnvelope) -> None:
        command = HandleOrderPlacedCommand(
            event_id=UUID(envelope.event_id),
            order_id=UUID(envelope.payload['order_id']),
            customer_id=UUID(envelope.payload['customer_id']),
            occurred_at=envelope.occurred_at,
            trace_id=envelope.trace_id,
        )
        self._handle_order_placed.execute(command)
```

**Consumer result rules:**
- `ACK`: processed successfully, or a non-retryable error (malformed, unknown type) — remove from queue
- `NACK`: transient failure — broker redelivers after backoff (configure max redelivery count on the queue)
- `DEAD_LETTER`: poison message — route to DLQ, alert, do not reprocess automatically

---

#### Dead Letter Queue (DLQ) Handling

Every consumer queue must have a configured DLQ. When a message exhausts retries:
1. Broker routes to DLQ automatically (configure via broker policy, not in code)
2. An alert fires when DLQ depth > 0 (define in OBSERVABILITY.md)
3. DLQ consumer reads messages for manual inspection — logs full envelope for diagnosis
4. Resolution options: fix the bug, replay from DLQ after fix, discard with documented reason

Document in RUNBOOKS.md: how to inspect the DLQ, how to replay a dead-lettered message, when to discard.

---

#### Consumer Idempotency Table (alternative to Redis for high-durability requirements)

For use cases where Redis TTL-based deduplication is insufficient (e.g. financial transactions):

```sql
CREATE TABLE processed_events (
    event_id    UUID PRIMARY KEY,
    handler     VARCHAR(255) NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Partition by month if high volume
-- Retain for 30 days minimum (align with message retention on broker)
```

```python
# In the handler use case, replace idempotency_store with:
def _is_already_processed(self, event_id: UUID, handler: str) -> bool:
    return self._db.query_one(
        "SELECT 1 FROM processed_events WHERE event_id = %s AND handler = %s",
        [event_id, handler]
    ) is not None

def _mark_processed(self, event_id: UUID, handler: str) -> None:
    self._db.execute(
        "INSERT INTO processed_events (event_id, handler) VALUES (%s, %s) ON CONFLICT DO NOTHING",
        [event_id, handler]
    )
```

---

#### Saga Pattern Implementation

Use sagas for distributed transactions that span multiple services.

**Choreography (event-driven, no central coordinator):**
Each service listens for events and publishes compensating events on failure. Best for simple, well-understood flows.

```
OrderService:    OrderPlaced →
InventoryService:              → InventoryReserved | InventoryFailed →
PaymentService:                                                        → PaymentCharged | PaymentFailed →
OrderService:    OrderConfirmed | OrderCancelled (with compensation)
```

Implementation: each step is an event consumer (as above). Compensation events trigger compensating use cases (e.g. `ReleaseInventoryUseCase` on `PaymentFailed`).

**Orchestration (saga orchestrator, explicit state machine):**
A dedicated orchestrator service manages the saga state and issues commands to each participant. Best for complex flows, easier to reason about failure paths.

```python
class OrderSaga:
    """
    Orchestrates the order fulfilment saga.
    State persisted in order_sagas table.
    """
    STEPS = ['reserve_inventory', 'charge_payment', 'confirm_order']

    def __init__(self, saga_id: UUID, order_id: UUID):
        self._saga_id = saga_id
        self._order_id = order_id
        self._state = SagaState.STARTED
        self._completed_steps: list[str] = []
        self._compensation_steps: list[str] = []

    def on_inventory_reserved(self) -> SagaCommand:
        self._completed_steps.append('reserve_inventory')
        return SagaCommand.charge_payment(self._order_id)

    def on_payment_failed(self, reason: str) -> list[SagaCommand]:
        self._state = SagaState.COMPENSATING
        # Issue compensating commands in reverse order
        return [SagaCommand.release_inventory(self._order_id)]

    def on_inventory_released(self) -> SagaCommand:
        self._state = SagaState.FAILED
        return SagaCommand.cancel_order(self._order_id, reason="payment_failed")
```

Saga state is persisted to DB after every step — the orchestrator must be resumable if it crashes mid-saga.

---

#### Event Schema Versioning

Events on a broker are consumed by multiple services that may deploy independently. Handle schema evolution carefully:

**Additive changes (backward compatible — no version bump required):**
- Add new optional fields to payload
- Consumers that don't know the field ignore it (tolerant reader pattern)

**Breaking changes (require version bump):**
- Remove a field
- Rename a field
- Change a field's type

For breaking changes:
1. Publish `order.placed.v2` alongside `order.placed.v1`
2. Consumers migrate to v2 at their own pace
3. Deprecate v1 with a sunset date (log a warning when v1 is published)
4. Remove v1 publisher only after all consumers have migrated

**Tolerant reader rule:** consumers must ignore unknown fields. Never fail on an unrecognised field — use `**kwargs` / `additionalProperties: true` / equivalent for the language/framework.

---

## Step 5: Input Validation Layering

Apply validation at exactly one layer — the right one. Don't duplicate.

```
DELIVERY LAYER  → Schema validation: types, required fields, string formats, enum values
                  "Is this a valid UUID?" "Is amount a number?" "Is status one of [PENDING, ACTIVE]?"
                  Raises: ValidationException (→ 400)

APPLICATION LAYER → Business preconditions: does the referenced resource exist? is the state correct?
                  "Does this customer exist?" "Is the account active?" "Is this order in PENDING status?"
                  Raises: NotFoundException, ConflictException, ApplicationException (→ 404, 409, 422)

DOMAIN LAYER    → Invariant enforcement: can this object exist with these values?
                  "Can an order have zero items?" "Can Money have negative amount?"
                  Raises: DomainException, BusinessRuleException (→ 422)
```

Never put business rules in the delivery layer. Never put schema validation in the domain. Never duplicate the same check at two layers.

---

## Step 6: Transaction Boundaries and Event Dispatch

Transaction management is owned by the application layer. This is the pattern:

```python
# In the use case execute() method:

# Option A: explicit transaction (preferred for clarity)
with self._db.transaction():
    order = Order(command.customer_id, items)
    self._order_repo.save(order)
    self._outbox.write(order.collect_events())  # write outbox records IN SAME TRANSACTION
# Transaction commits here — DB is consistent

# AFTER commit: dispatch events
# (if this fails, the outbox relay process will retry — at-least-once delivery)
events = self._outbox.flush_pending()
self._event_dispatcher.dispatch_all(events)
order.clear_events()
```

Rules:
- Transaction begins at the start of the write path, commits after all writes succeed
- Domain events are collected from the aggregate AFTER `save()`, dispatched AFTER `commit()`
- If using the Outbox pattern: write events to the outbox table inside the same transaction as business data — this guarantees events are never lost even if the process crashes before dispatch
- NEVER dispatch events inside a transaction — if dispatch fails, it causes a rollback of committed business data
- NEVER open a transaction in the domain or delivery layer

**Event dispatch ordering:**
1. Build domain object
2. Call repository `save()` (writes entity + outbox records atomically)
3. Transaction commits
4. Collect events from aggregate
5. Clear events from aggregate
6. Dispatch events (async relay picks up from outbox if synchronous dispatch fails)

---

## Step 7: Authorization Implementation

Authorization is enforced in the **application layer** (use cases), not in controllers and not in the domain.

```python
class UpdateOrderUseCase:
    def execute(self, command: UpdateOrderCommand) -> UpdateOrderResult:
        order = self._order_repo.find_by_id(command.order_id)
        if not order:
            raise NotFoundException(f"Order {command.order_id} not found")

        # Authorization: caller must own this order OR be an admin
        is_owner = order.customer_id == command.request_context.user_id
        is_admin = command.request_context.has_role('admin')
        if not is_owner and not is_admin:
            raise AuthorizationException("Cannot modify another customer's order")

        # Proceed with business logic...
```

Rules:
- Authentication (is the token valid?) → middleware, before the request reaches the controller
- Authorization (is the caller allowed to do THIS?) → use case, after loading the resource
- Never authorize based on request parameters alone — always load the resource and check ownership/state
- Role checks (`has_role`) are fine for coarse-grained access; attribute checks (ownership, status) are required for fine-grained access
- Domain objects must never contain authorization logic — they don't know who the caller is

---

## Step 8: Idempotency Implementation

For any use case that performs a mutation, implement idempotency if the API spec specifies `Idempotency-Key`.

```python
class IdempotencyStore(ABC):
    @abstractmethod
    def get(self, key: str) -> Optional[Any]: ...
    @abstractmethod
    def set(self, key: str, result: Any, ttl_seconds: int = 86400) -> None: ...

# In the use case (see Step 4b for full example):
if command.idempotency_key:
    cached = self._idempotency_store.get(command.idempotency_key)
    if cached:
        return cached    # exact same response, no side effects replayed
```

Rules:
- Check BEFORE any side effects
- Store result AFTER transaction commits and events dispatched
- TTL: 24 hours is standard for most operations (align with API_SPEC.md)
- Idempotency key is provided by the caller — use it as-is as the cache key (scoped to operation type to prevent cross-operation collisions: `create_order:{key}`)
- If the operation is still in progress (concurrent duplicate request): return 409 Conflict with a "processing" code, not a cached result

---

## Step 9: Add Observability at Implementation Time

Do NOT skip — observability is part of coding, not an afterthought.

**At every use case entry:**
```python
logger.info("use_case.started", {
    "trace_id": context.trace_id,
    "correlation_id": context.correlation_id,
    "user_id": str(context.user_id),
    "action": "create_order",
    "input_summary": {"item_count": len(command.items)}
})
span = tracer.start_span("order_service.create_order.execute")
timer = Timer.start()
```

**At every use case exit (success):**
```python
logger.info("use_case.completed", {
    "trace_id": context.trace_id,
    "action": "create_order",
    "outcome": "success",
    "duration_ms": timer.elapsed(),
    "entity_id": str(result.order_id)
})
span.set_status(SpanStatus.OK)
span.end()
```

**At every error:**
```python
logger.error("use_case.failed", {
    "trace_id": context.trace_id,
    "action": "create_order",
    "outcome": "failure",
    "error_type": type(error).__name__,
    "error_code": getattr(error, 'code', None),
    "duration_ms": timer.elapsed()
    # Do NOT log: passwords, tokens, card numbers, PII beyond user_id
})
span.record_exception(error)
span.set_status(SpanStatus.ERROR)
span.end()
```

**At every external service call (infrastructure adapters):**
```python
logger.info("external_call.started", {
    "trace_id": context.trace_id,
    "service": "stripe",
    "operation": "charge",
    "amount_currency": amount.currency   # log currency, not amount (may be sensitive)
})
```

**Structured log rules:**
- Every log entry has `trace_id` — no exceptions
- Log level discipline: DEBUG (local dev only), INFO (business events), WARN (degraded but ok), ERROR (failure, needs attention)
- Never log: passwords, tokens, secrets, full card numbers, raw PII (hash or mask user IDs in shared logs if required by compliance)
- Log message is a `snake_case.event_name`, context is a structured object — not a formatted string

---

## Step 10: Simplicity and Dependency Rule Check

After implementing each component:

**Dependency rule check:**
- Domain files: do any imports come from application, infrastructure, or delivery? → STOP, fix it
- Application files: do any imports come from infrastructure or delivery? → STOP, fix it
- If you need infrastructure behaviour in the application layer: define a port interface in application, implement adapter in infrastructure, inject it

**Simplicity check:**
- Could this be simpler? Fewer classes, fewer methods, less abstraction?
- Is every abstraction necessary? An abstraction with one concrete implementation and no test doubles is probably premature
- Is the code readable to a new engineer on day 1?
- Are there DRY violations? Extract after second occurrence, not first
- Are there any god classes (> 200 lines) or long methods (> 20 lines)? Split them
- Is there any "primitive obsession"? Replace raw strings/numbers with value objects where they carry domain meaning

Run `/simplify` on all changed files before marking the task complete.

---

## Step 11: Verify Against Specifications

Before marking any task done, cross-check implementation against the source documents:

**Against DATA_MODEL.md:**
- [ ] Every field defined in the model is present in the entity and the DB migration
- [ ] Types match the model (ISO 4217 for currency, RFC 4122 for UUIDs, ISO 8601 for timestamps)
- [ ] All constraints (required, unique, nullable) are enforced
- [ ] All defined invariants are enforced in the entity constructor

**Against API_SPEC.md (if this task implements an endpoint):**
- [ ] Path and HTTP method match exactly
- [ ] All required request fields validated
- [ ] Response body matches the spec schema
- [ ] All documented status codes are reachable
- [ ] Error response format matches the standard schema (code, message, trace_id)
- [ ] Idempotency-Key support implemented if spec requires it
- [ ] Pagination matches spec (cursor fields present)

**Against PRODUCT_SPEC.md:**
- [ ] Each REQ-ID this task was planned to satisfy is actually met by the implementation
- [ ] Each BDD scenario for affected requirements passes (mentally trace through the code)
- [ ] Business rules (BR-IDs) are enforced at the correct layer (domain or application)
- [ ] NFRs applicable to this component are addressed (performance-critical paths have caching/indexes noted)

If any cross-check fails: fix before marking done — do not defer.

---

## Step 12: Mark Task Complete

After implementation and verification:
1. Update `.sdlc/TODO.md` — mark task done: `[x] TASK-NNN`
2. Update `.sdlc/STATE.md` — note phase progress
3. Show what was implemented, which specs were satisfied, and what comes next

Output:
```
✅ TASK-[NNN] Complete: [description]

Files changed:
  • [file path] (new | modified)

Specifications satisfied:
  ✅ REQ-[ID]: [requirement description]
  ✅ BR-[ID]: [business rule description]
  ✅ API: [endpoint] matches API_SPEC.md

Done criteria:
  ✅ [criterion 1]
  ✅ [criterion 2]

Next task: TASK-[NNN+1]: [description]
Run: /sdlc:08-code --task TASK-[NNN+1]
```
