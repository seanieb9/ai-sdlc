# Clean Architecture Reference

## The Dependency Rule

**Dependencies point inward only.** Outer layers know about inner layers. Inner layers know NOTHING about outer layers.

```
┌─────────────────────────────────────────────────────┐
│  Delivery (HTTP, CLI, Events, Scheduled Jobs)        │  → depends on Application
├─────────────────────────────────────────────────────┤
│  Infrastructure (DB, HTTP clients, Queue, Email)     │  → depends on Domain + Application
├─────────────────────────────────────────────────────┤
│  Application (Use Cases, Commands, Queries, Ports)   │  → depends on Domain only
├─────────────────────────────────────────────────────┤
│  Domain (Entities, Value Objects, Domain Services)   │  → depends on NOTHING
└─────────────────────────────────────────────────────┘
```

**Violation check:** If a domain file imports from infrastructure, application imports from delivery, or any inner layer knows about an outer layer → STOP, fix it.

---

## Domain Layer

**What lives here:** Pure business logic. No framework. No database. No HTTP. Just business rules.

**Entities:**
- Have identity (UUID or natural key)
- Enforce invariants in the constructor — never allow invalid state to be created
- Expose behavior, not just data (rich domain model, not anemic)
- All mutation through methods that enforce business rules

```python
# Good — rich entity, enforces invariants
class Order:
    def __init__(self, customer_id: UUID, items: list[OrderItem]):
        if not items:
            raise DomainException("Order must have at least one item")
        self._id = uuid4()
        self._customer_id = customer_id
        self._items = items
        self._status = OrderStatus.PENDING
        self._events = [OrderCreated(self._id, customer_id)]

    def add_item(self, item: OrderItem) -> None:
        if self._status != OrderStatus.PENDING:
            raise DomainException("Cannot modify a submitted order")
        self._items.append(item)

# Bad — anemic model, no behavior
class Order:
    def __init__(self):
        self.id = None
        self.status = None
        self.items = []
```

**Value Objects:**
- No identity — equality is defined by attribute values
- Immutable once created
- Self-validating constructor

```python
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str  # ISO 4217

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")
        if len(self.currency) != 3:
            raise ValueError("Currency must be ISO 4217 (3 chars)")

    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(self.amount + other.amount, self.currency)
```

**Domain Services:**
- Business logic that doesn't belong on a single entity
- Stateless
- Depends only on domain entities and value objects

**Repository Interfaces (Ports):**
- Defined in domain layer as abstract interfaces
- Describe WHAT can be done, not HOW
- Implementations live in infrastructure

```python
from abc import ABC, abstractmethod

class OrderRepository(ABC):
    @abstractmethod
    def find_by_id(self, id: UUID) -> Optional[Order]: ...
    @abstractmethod
    def find_by_customer(self, customer_id: UUID, page: int, page_size: int) -> Page[Order]: ...
    @abstractmethod
    def save(self, order: Order) -> None: ...
    @abstractmethod
    def delete(self, id: UUID) -> None: ...
```

---

## Application Layer

**What lives here:** Orchestration. Use cases. Transaction boundaries. Port interfaces for external services.

**Use Cases (Command Handlers):**
- One class per use case
- Single `execute()` method
- Takes a typed command/request object
- Returns a typed result object
- Orchestrates domain entities, calls repository interfaces
- Emits domain events
- Manages transaction boundaries

```python
@dataclass
class CreateOrderCommand:
    customer_id: UUID
    items: list[OrderItemRequest]
    correlation_id: str

@dataclass
class CreateOrderResult:
    order_id: UUID
    status: str

class CreateOrderUseCase:
    def __init__(self, order_repo: OrderRepository, event_bus: EventBus):
        self._order_repo = order_repo
        self._event_bus = event_bus

    def execute(self, command: CreateOrderCommand) -> CreateOrderResult:
        # Validate inputs
        if not command.items:
            raise ValidationException("Order must have items")

        # Create domain entity (invariants checked here)
        items = [OrderItem(UUID(r.product_id), r.quantity, r.unit_price) for r in command.items]
        order = Order(command.customer_id, items)

        # Persist
        self._order_repo.save(order)

        # Publish events
        for event in order.collect_events():
            self._event_bus.publish(event)

        return CreateOrderResult(order_id=order.id, status=order.status.value)
```

**Port Interfaces for external services:**
```python
class EmailPort(ABC):
    @abstractmethod
    def send_order_confirmation(self, order_id: UUID, customer_email: str) -> None: ...

class PaymentPort(ABC):
    @abstractmethod
    def charge(self, amount: Money, payment_method_id: str) -> PaymentResult: ...
```

---

## Infrastructure Layer

**What lives here:** All I/O. Database. HTTP clients. Queue producers/consumers. File storage. Caching.

**Repository Implementations:**
- Implement the domain interface exactly
- Handle ORM mapping (entity → row, row → entity)
- No business logic here

**Adapter Implementations:**
- Implement application port interfaces
- Wrap external SDKs/clients
- Handle errors and translate to domain exceptions

---

## Delivery Layer

**What lives here:** Thin. Framework-specific. Delegates immediately to use cases.

**HTTP Controllers:**
```python
# THIN controller — validate, call use case, serialize
class OrderController:
    def __init__(self, create_order: CreateOrderUseCase):
        self._create_order = create_order

    def post_order(self, request: HttpRequest) -> HttpResponse:
        # Validate (input validation, not business validation)
        body = CreateOrderRequest.from_json(request.body)
        body.validate()  # raises 400 if invalid

        # Call use case
        command = CreateOrderCommand(
            customer_id=request.user.id,
            items=body.items,
            correlation_id=request.correlation_id
        )
        result = self._create_order.execute(command)

        # Serialize
        return HttpResponse(status=201, body={"order_id": str(result.order_id)})
```

Controllers must NOT: contain business logic, query databases directly, instantiate domain objects.

---

## Composition Root

**One place** where all dependencies are wired together. Typically the application startup file.

```python
# composition_root.py
def build_container():
    db = PostgresDatabase(config.DATABASE_URL)
    event_bus = RabbitMQEventBus(config.RABBITMQ_URL)

    order_repo = PostgresOrderRepository(db)
    email_adapter = SendGridEmailAdapter(config.SENDGRID_API_KEY)

    create_order_uc = CreateOrderUseCase(order_repo, event_bus)

    order_controller = OrderController(create_order_uc)
    return order_controller
```

**Dependency Injection rules:**
- Dependencies are injected through constructors (not setters, not service locator)
- Never call `new` on infrastructure objects inside use cases or domain
- Test doubles injected in tests via same constructor

---

## Design Patterns — When to Use

| Pattern | Use When | Don't Use When |
|---------|----------|----------------|
| Repository | Always — for data access | Never access DB directly from use cases |
| Factory | Object creation is complex (multiple steps, conditions) | Simple `new` works fine |
| CQRS | Read and write models differ significantly | Read and write are the same shape |
| Event Sourcing | Audit trail critical, need temporal queries | You just want a simple audit log |
| Saga | Distributed transaction across 2+ services | Single-service transaction |
| Outbox Pattern | Need at-least-once event delivery with ACID | In-memory event bus is fine |
| Circuit Breaker | External service can fail transiently | Calling your own services |
| Decorator | Cross-cutting concerns (logging, caching, retry) | Core business logic |

**Rule: Never use a pattern without being able to state the problem it solves.**

---

## Code Smells to Eliminate

| Smell | Symptom | Fix |
|-------|---------|-----|
| God Class | Class > 200 lines or > 10 methods | Split by responsibility |
| Long Method | Method > 20 lines | Extract sub-methods |
| Feature Envy | Method uses another class's data more than its own | Move method |
| Anemic Domain | Entities are just bags of data with no behavior | Add methods to entity |
| Service Locator | `container.resolve('OrderService')` inside use cases | Constructor injection |
| Magic Number | `if status == 3` | Named constants/enums |
| Primitive Obsession | `string email` instead of `Email` value object | Extract value object |
| Shotgun Surgery | One change requires editing 10 files | Consolidate responsibility |
