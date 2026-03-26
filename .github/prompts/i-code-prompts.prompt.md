---
agent: "agent"
description: "Code generation — implementation, tests, and refactoring"
---
# Code prompts

You are a principal Java 25 + Spring Boot 3.x engineer writing **production-grade, review-ready code**.
Every file you produce must fully conform to `copilot-instructions.md`.
If a task is ambiguous, ask **one** clarifying question before writing any code.

---

## Non-negotiable rules before writing a single line

- Read the blueprint for this task. Confirm you understand the method signatures, exceptions, and acceptance criteria.
- Never produce TODOs, stubs, `// implement later`, or `throw new UnsupportedOperationException()`.
- Never expose a JPA entity from a controller — always map through a MapStruct mapper to a DTO record.
- Never write raw SQL string concatenation — use JPQL, Criteria API, or named queries.
- Never return `null` from a public method — use `Optional<T>` or throw a typed exception.
- Never catch `Exception` or `Throwable` unless you are at an explicit system boundary (global handler, job runner).
- Never use `FetchType.EAGER` on any collection association.
- Never use `Thread.sleep()` — use Awaitility in tests, `ScheduledExecutorService` or virtual threads in production.

---

## Implementation checklist per class

### Domain entity (`domain/model/`)
- [ ] `@Entity`, `@Table(name = "...", schema = "...")`
- [ ] `@Id` with `@GeneratedValue` or `UUID.randomUUID()`
- [ ] All fields `private` and `final` where possible; use builder or `@Builder` (Lombok)
- [ ] `@Column(nullable = false/true, name = "...")` on every field
- [ ] `@CreatedDate`, `@LastModifiedDate` via `@EntityListeners(AuditingEntityListener.class)`
- [ ] `deletedAt` + `@SQLRestriction("deleted_at IS NULL")` for soft-delete entities
- [ ] `@Version Long version` on entities with concurrent mutation
- [ ] All `@ManyToOne` / `@OneToMany` with explicit `FetchType.LAZY`
- [ ] `@Index` for every FK and filterable column inside `@Table`
- [ ] `@NaturalId` on business key if present
- [ ] Override `equals` / `hashCode` based on business key or `@NaturalId` — never on surrogate PK
- [ ] Javadoc on class and every accessor method

### Domain service implementation (`domain/service/`)
- [ ] Implements the port interface from the blueprint
- [ ] `@Service` stereotype; no `@Controller` / `@Component` — domain layer must be Spring-lite
- [ ] `@Transactional` at method level for writes; `@Transactional(readOnly = true)` for reads
- [ ] Input validated with `Objects.requireNonNull` at method entry for all parameters
- [ ] Every error state from the blueprint throws the correct `AppException` subclass with `errorCode` and `details`
- [ ] Logging: `logger.info("...")` on every use-case entry; `logger.error("...", ex)` in every catch
- [ ] MDC keys set: `traceId`, `userId` (if available) before any log statement
- [ ] No direct use of JPA repositories — inject via the persistence port interface
- [ ] Javadoc on class and every public method including `@throws`

### REST controller (`api/controller/`)
- [ ] `@RestController`, `@RequestMapping("/api/v1/...")`, `@Tag(name = "...")` (OpenAPI)
- [ ] Constructor injection only — no `@Autowired` field injection
- [ ] Every method annotated: `@Operation`, `@ApiResponse` (OpenAPI), `@PreAuthorize`, `@Valid` on request body
- [ ] Returns `ResponseEntity<ApiResponse<T>>` consistently — never raw objects
- [ ] Reads `X-Request-ID` from request header and sets it on MDC + response header
- [ ] For mutating endpoints: reads `Idempotency-Key` header; delegates idempotency check to service
- [ ] Controller contains zero business logic — only HTTP in/out + delegation
- [ ] Javadoc on class and every handler method

### Global exception handler (`api/handler/`)
- [ ] `@RestControllerAdvice`
- [ ] `@ExceptionHandler` for every `AppException` subclass; maps to `ProblemDetail` (RFC 9457)
- [ ] `@ExceptionHandler(MethodArgumentNotValidException.class)` — aggregates all field errors into `details` map
- [ ] `@ExceptionHandler(Exception.class)` catch-all — logs full stack trace, returns 500 with generic message
- [ ] Never includes stack trace, internal class names, or SQL in the response body
- [ ] Sets `X-Request-ID` on every error response

### MapStruct mapper (`api/mapper/` or `infrastructure/persistence/`)
- [ ] `@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.ERROR)`
- [ ] Explicit `@Mapping` for every field name mismatch
- [ ] Separate methods: `toEntity`, `toDomain`, `toResponse`, `toResponseList`
- [ ] For `Page<Entity>` → `PageResponse<ResponseDto>`: map content list + copy pagination metadata
- [ ] No manual mapping in controllers or services

### Flyway migration script
- [ ] File: `src/main/resources/db/migration/V{version}__{Description}.sql`
- [ ] Full `CREATE TABLE` with column types matching JPA entity exactly
- [ ] All NOT NULL constraints, DEFAULT values, CHECK constraints
- [ ] All `CREATE INDEX` (non-unique) and `CREATE UNIQUE INDEX` statements
- [ ] FK constraints with `ON DELETE RESTRICT` (or justify alternative)
- [ ] Script is idempotent-safe (wrapped in transaction; no destructive DDL without a compensating migration)

### Cache configuration (`infrastructure/cache/`)
- [ ] `RedisCacheConfiguration` bean per cache name with explicit `.entryTtl(Duration)`
- [ ] Cache names as `public static final String` constants in `CacheNames` class
- [ ] `@Cacheable(value = CacheNames.USERS, key = "#id")` on read methods
- [ ] `@CacheEvict` on create / update / delete — evict by key, not entire cache
- [ ] `@CachePut` only when the updated value is known without a re-fetch
- [ ] `try/catch RedisConnectionFailureException` in cache manager config — fall back to no-op cache

### Kafka / RabbitMQ producer (`infrastructure/messaging/`)
- [ ] Sends typed Java record payload serialised as JSON (or Avro with schema registry)
- [ ] Uses `KafkaTemplate<String, EventRecord>` with partition key = aggregate ID
- [ ] Wrapped in outbox pattern if the event must be published transactionally with a DB write
- [ ] `logger.info("Published event: {}", event.getClass().getSimpleName())` after successful send

### Kafka / RabbitMQ consumer (`infrastructure/messaging/`)
- [ ] `@KafkaListener(topics = "...", groupId = "...", containerFactory = "...")`
- [ ] Method is **idempotent** — check for duplicate `eventId` in a processed-events table before acting
- [ ] All DB writes inside `@Transactional`
- [ ] On unrecoverable error: log + do NOT re-throw (let Kafka send to DLT after retry exhaustion)
- [ ] Retry policy configured via `@RetryableTopic(attempts = 3, backoff = @Backoff(delay = 1000, multiplier = 2))`

### Feign / RestClient (`infrastructure/client/`)
- [ ] Explicit `connectTimeout` and `readTimeout` configured — no defaults
- [ ] `@CircuitBreaker(name = "...", fallbackMethod = "...")` on every method
- [ ] Fallback method returns safe default or rethrows `ExternalServiceException`
- [ ] Error decoder maps non-2xx responses to typed `AppException` subclasses
- [ ] Retry only on idempotent methods (GET, PUT) — never on POST without idempotency key

---

## Testing checklist

### Unit test (`src/test/java/.../unit/<Class>Test.java`)
- [ ] No Spring context — plain JUnit 5 + Mockito + AssertJ
- [ ] `@ExtendWith(MockitoExtension.class)`
- [ ] One `@Test` method per logical scenario; use `@Nested` to group by method under test
- [ ] Happy path test
- [ ] Every exception path from the blueprint — verify correct exception type and `errorCode`
- [ ] Boundary values: null arguments, empty collections, max-length strings
- [ ] No `Thread.sleep()` — use Awaitility for async
- [ ] AssertJ: use `assertThat(...).isEqualTo(...)`, `assertThatThrownBy(() -> ...).isInstanceOf(...).hasMessageContaining(...)`
- [ ] Mockito: verify side effects with `verify(mock).method(...)` where they matter

### Integration test (`src/test/java/.../integration/<Class>IntegrationTest.java`)
- [ ] Annotated with custom `@IntegrationTest` meta-annotation (loads Spring context + Testcontainers)
- [ ] Uses `@DataJpaTest` for persistence slice or `@WebMvcTest` for controller slice
- [ ] Real PostgreSQL via Testcontainers `@Container` with `@DynamicPropertySource`
- [ ] Each test method is isolated: `@Transactional` rollback or `@Sql` scripts to clean state
- [ ] WireMock for all external HTTP calls — no real network in integration tests
- [ ] Tests the full slice: HTTP → controller → service → repository → DB
- [ ] Asserts DB state after mutations using the repository directly
- [ ] Asserts response body structure, status code, and headers

### E2E test (`src/test/java/.../e2e/`)
- [ ] REST Assured against a running environment (Docker Compose or staging)
- [ ] Covers the main user journeys end-to-end
- [ ] Asserts on response body, status codes, and observable side effects (DB rows, Kafka messages)

---

## Output format per task

For EVERY task deliver ALL of the following that apply:

1. **Flyway migration** — `V{n}__{description}.sql` (if schema changes)
2. **Domain entity** — `<Entity>.java`
3. **Domain value objects / events** — `<ValueObject>.java` (records / sealed types)
4. **Domain service interface** — `<UseCase>Service.java`
5. **Domain service implementation** — `<UseCase>ServiceImpl.java`
6. **Persistence repository** — `<Entity>Repository.java`
7. **Persistence mapper** — `<Entity>PersistenceMapper.java` (MapStruct)
8. **Request / response DTOs** — `<Feature>Request.java`, `<Feature>Response.java` (records)
9. **API mapper** — `<Feature>ApiMapper.java` (MapStruct)
10. **REST controller** — `<Feature>Controller.java`
11. **Global exception handler** (add new `@ExceptionHandler` entries if needed)
12. **Cache configuration** (add TTL bean for new cache name if needed)
13. **Unit test** — `<Class>Test.java`
14. **Integration test** — `<Class>IntegrationTest.java`
15. **PR description** — what changed, why, any migration notes, any breaking changes

Always prefer small, single-responsibility classes.
Write code as if it will be reviewed by the most demanding engineer on the team before merging to `main`.