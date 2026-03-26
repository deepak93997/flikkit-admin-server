---
agent: "ask"
description: "Implementation blueprint — data models and component plan"
---
# Blueprint prompt

You are a senior Java 25 + Spring Boot 3.x engineer turning an architecture decision into a **complete, unambiguous implementation plan**.
All decisions must align with the standards in `copilot-instructions.md`.
Every section below must be fully populated — no placeholders, no "TBD".

---

## Phase 1 — Domain model

### 1.1 JPA Entities (`domain/model/`)
For each entity specify:
- Class name, table name, schema
- All fields: Java type, column name, nullability, default, constraints
- Primary key strategy (`@GeneratedValue(strategy = IDENTITY)` or `UUID`)
- Audit fields: `createdAt`, `updatedAt` via `@EntityListeners(AuditingEntityListener.class)`
- Soft-delete field: `deletedAt TIMESTAMPTZ` + `@SQLRestriction("deleted_at IS NULL")`
- All `@OneToMany` / `@ManyToOne` / `@ManyToMany` relationships with `FetchType.LAZY` — no `EAGER`
- `@Index` annotations for every FK column and every filterable column
- `@NaturalId` on business key if the entity has one
- `@Version` field for optimistic locking on any entity with concurrent mutations

### 1.2 Domain value objects and events (`domain/model/`)
- Use Java `record` for all immutable value objects (e.g. `Money`, `EmailAddress`, `PhoneNumber`)
- Use `sealed interface` + `record` variants for discriminated types (e.g. `PaymentMethod`)
- Use Java `record` for all domain events; include `occurredAt Instant` field
- Enums: list all variants; specify the DB column type (`@Enumerated(EnumType.STRING)`)

### 1.3 Request / Response DTOs (`api/dto/`)
For each API endpoint specify:
- Request record: all fields with types, Bean Validation annotations (`@NotNull`, `@NotBlank`, `@Size`, `@Pattern`, `@Email`, `@Min`, `@Max`, `@Valid` for nested objects)
- Response record: all fields with types; no JPA entity exposure
- Page response wrapper: `PageResponse<T>` with `content`, `page`, `size`, `totalElements`, `totalPages`

---

## Phase 2 — Database schema

### 2.1 Flyway migration scripts
For every DDL change provide:
- File name: `V{version}__{description}.sql` (e.g. `V1__create_user_table.sql`)
- Full `CREATE TABLE` DDL with column types, NOT NULL constraints, defaults, and CHECK constraints
- All `CREATE INDEX` / `CREATE UNIQUE INDEX` statements
- FK constraints with `ON DELETE` / `ON UPDATE` behaviour
- Any seed data `INSERT` statements required for the feature

### 2.2 HikariCP configuration
- `maximumPoolSize`, `minimumIdle`, `connectionTimeout`, `idleTimeout`, `maxLifetime` — specify values
- Validation query or `keepaliveTime`

---

## Phase 3 — Service contracts

### 3.1 Domain service interfaces (`domain/service/`)
For every use case define the interface method signature:
```java
// Example — NOT a stub, fill in real types
public interface OrderService {
    OrderId placeOrder(PlaceOrderCommand command);         // throws InsufficientStockException
    Order   findById(OrderId id);                          // throws OrderNotFoundException
    Page<Order> findByCustomer(CustomerId id, Pageable p);
    void    cancelOrder(OrderId id, CancelReason reason);  // throws OrderNotCancellableException
}
```
- Annotate with expected exceptions for each method
- Use domain types as parameters and return values — never DTOs or JPA entities in the domain layer

### 3.2 REST API contract (`api/controller/`)
For every endpoint specify:
| Method | Path | Auth | Request body | Response body | Status codes |
|--------|------|------|-------------|---------------|--------------|
| POST | `/api/v1/orders` | `@PreAuthorize("hasRole('USER')")` | `PlaceOrderRequest` | `OrderResponse` | 201, 400, 401, 409, 422 |

- Include `X-Request-ID` header on all responses
- Include `Idempotency-Key` header support for all mutating endpoints
- Pagination parameters: `page`, `size`, `sort` via Spring `Pageable`

### 3.3 Exception hierarchy (`domain/exception/`)
For each error state define:
```
AppException (base, unchecked)
  └── NotFoundException          → 404  (e.g. OrderNotFoundException, UserNotFoundException)
  └── ConflictException          → 409  (e.g. DuplicateEmailException)
  └── ValidationException        → 422  (e.g. InsufficientStockException)
  └── ForbiddenException         → 403
  └── ExternalServiceException   → 502  (wraps third-party failures)
```
- Each subclass must carry: `errorCode` (SCREAMING_SNAKE_CASE string), `httpStatus`, optional `Map<String, Object> details`
- Global handler returns `ProblemDetail` (RFC 9457) — include `type`, `title`, `status`, `detail`, `instance`, `errorCode`

---

## Phase 4 — Infrastructure contracts

### 4.1 Persistence layer (`infrastructure/persistence/`)
For each repository:
- Interface extending `JpaRepository<Entity, ID>` or `PagingAndSortingRepository`
- All custom query methods: JPQL / `@Query` annotations — no native SQL string concat
- `@EntityGraph` definitions to prevent N+1 on complex reads
- MapStruct mapper interface: method signatures for `toEntity`, `toDomain`, `toDto`, `toResponse`

### 4.2 Cache layer (`infrastructure/cache/`)
For each cached operation:
- Cache name (constant in `CacheNames` class)
- Key expression (SpEL)
- TTL value
- `@CacheEvict` trigger points (on create / update / delete)
- Fallback behaviour on `RedisConnectionFailureException`

### 4.3 Messaging (`infrastructure/messaging/`)
For each Kafka / RabbitMQ interaction:
- Topic / queue / exchange name (constant)
- Message payload: Java record with all fields and types
- Producer: method signature, serialisation format (JSON / Avro)
- Consumer: `@KafkaListener` / `@RabbitListener` method signature, consumer group, idempotency key field
- Dead-letter topic / queue name
- Retry policy: max attempts, back-off multiplier, jitter

### 4.4 External HTTP clients (`infrastructure/client/`)
For each Feign / RestClient:
- Interface name, base URL config property
- Each method: HTTP method, path, request type, response type, timeout
- Resilience4j decorators: `@CircuitBreaker(name=..., fallbackMethod=...)`, `@Retry`, `@TimeLimiter`
- Fallback method signature and return value

---

## Phase 5 — Security plan

- List every endpoint with its required role/scope
- List fields that must be redacted from logs (passwords, tokens, card numbers, PII)
- List fields that must be encrypted at rest (specify algorithm: AES-256-GCM)
- CORS allowed origins list
- Rate limit rules: requests per window per IP / per user per endpoint group

---

## Phase 6 — Testing plan

For every class to be implemented specify:

| Class | Unit test file | Integration test file | Key scenarios |
|-------|---------------|----------------------|---------------|
| `OrderServiceImpl` | `OrderServiceImplTest` | `OrderServiceImplIntegrationTest` | happy path, duplicate idempotency key, insufficient stock, order not found |

- Unit tests: pure Java, Mockito mocks, AssertJ assertions — no Spring context
- Integration tests: `@DataJpaTest` (persistence slice) or `@WebMvcTest` (controller slice) with Testcontainers PostgreSQL
- E2E tests: REST Assured against running environment, cover main user journeys
- WireMock stubs required for each external HTTP client
- Awaitility for all async / messaging assertions

---

## Phase 7 — Observability plan

- List all MDC keys to propagate: `traceId`, `spanId`, `userId`, `requestId`, `tenantId`
- List all custom Micrometer metrics to emit (name, type, tags)
- List all log statements that must be present (method entry/exit for use cases, all exception catches)
- OpenTelemetry span names for each service boundary crossing

---

## Phase 8 — Task breakdown

Break the feature into tasks, each ≤ 4 hours:

| # | Task | Layer | Files to create/modify | Acceptance criteria | Depends on |
|---|------|-------|----------------------|---------------------|------------|
| 1 | Create Flyway migration | DB | `V1__...sql` | Schema applies cleanly on fresh DB | — |
| 2 | Implement domain entity | domain/model | `Order.java` | Fields, indexes, audit, soft-delete present | 1 |
| ... | | | | | |

No full implementations yet — contracts, signatures, and plans only.
