---
applyTo: "**"
---

> **Always read `.github/prompts/project-context.md` before answering any question or making any change.** That file is the single source of truth for the project's service map, ports, databases, Kafka topics, known issues, and tech debt.

# Copilot Global Instructions — Production-Ready Java Application Standards

## Tech stack
- Language: Java 21 (LTS) with records, sealed classes, pattern matching
- Framework: Spring Boot 3.3.5 + Spring Cloud 2023.0.3 (Gateway)
- Build tool: Apache Maven with wrapper (`mvnw`) — never rely on system install
- Testing: JUnit 5 + Mockito + AssertJ; Testcontainers for integration tests; MockMvc for API tests
- Linting / static analysis: Checkstyle + SpotBugs + PMD enforced in CI
- ORM / DB access: Spring Data JPA + Hibernate; use JPQL / Criteria API — never raw SQL string concat
- Migrations: Flyway (preferred) or Liquibase — always version-controlled
- API style: REST (Spring MVC) — be consistent per service; use springdoc-openapi for docs
- Messaging: Spring Kafka / RabbitMQ / SQS — choose one transport per service
- Caching: Spring Cache abstraction backed by Redis (Lettuce client)
- Service discovery & config: Spring Cloud Eureka + Spring Cloud Config Server
- Containerisation: Docker + Docker Compose for local dev; multi-stage builds for production images

---

## Code style
- Follow the Google Java Style Guide as the baseline
- Prefer immutable objects — use `final` fields, Java records for DTOs and value objects
- Favour functional style with Streams and Optional; avoid imperative loops where a pipeline is clearer
- Never return `null` from a public method — use `Optional<T>` or throw a typed exception
- Keep methods under 40 lines; extract private helpers or dedicated classes when exceeded
- No magic numbers or magic strings — define them as `static final` constants or enums
- Avoid deeply nested conditionals — use early returns and guard clauses
- Use `var` (local type inference) only when the type is obvious from the right-hand side
- Prefer `record` over plain POJO for immutable data carriers (DTOs, events, value objects)
- Use `@NonNull` / `@Nullable` annotations (Lombok or JSpecify) on all method parameters and return types

---

## Naming conventions
- `camelCase` for variables and methods
- `PascalCase` for classes, interfaces, enums, and annotations
- `SCREAMING_SNAKE_CASE` for `static final` constants
- Suffix interfaces with their role when it aids clarity (e.g. `UserService`, `OrderRepository`)
- Suffix implementations with `Impl` only as a last resort — prefer descriptive names (e.g. `JpaUserRepository`)
- Suffix enums with their kind (e.g. `UserRole`, `PaymentStatus`, `OrderState`)
- Name booleans with `is`, `has`, `can`, `should` prefixes (e.g. `isActive`, `hasPermission`)
- Name async / reactive methods with their action clearly (e.g. `fetchUserById`, `publishOrderEvent`)
- Test classes: `<ClassUnderTest>Test` (unit), `<ClassUnderTest>IntegrationTest`

---

## General rules
- Always handle exceptions explicitly — never swallow them with an empty `catch` block
- Catch the most specific exception type; avoid catching `Exception` or `Throwable` unless at a boundary
- Use checked exceptions only for recoverable conditions; use unchecked (`RuntimeException`) for programming errors
- Validate all method arguments at the start using `Objects.requireNonNull` or Bean Validation (`@Valid`)
- Never trust client-supplied data — always validate and sanitise server-side before use
- Never hardcode credentials, secrets, or environment-specific values — inject via Spring properties / env vars
- Write a test for every public method (co-located `*Test.java` in `src/test/`)

---

## Project structure (Spring Boot microservice)
```
src/
  main/
    java/com/company/service/
      config/          # Spring @Configuration classes, env validation, constants
      domain/          # Pure business logic — no Spring dependencies
        model/         # Entities, value objects, Java records
        service/       # Use-case / domain service interfaces + implementations
        exception/     # Domain-specific exception hierarchy
        event/         # Domain events (records)
      infrastructure/  # Spring-dependent adapters (DB, cache, messaging, HTTP clients)
        persistence/   # JPA repositories, entity mappers
        cache/         # Redis configuration and cache adapters
        messaging/     # Kafka / RabbitMQ producers and consumers
        client/        # Feign / RestClient HTTP clients for other services
      api/             # Controllers, request/response DTOs, exception handlers
        controller/
        dto/
        mapper/        # MapStruct mappers between domain and DTOs
        handler/       # @RestControllerAdvice global exception handler
      shared/          # Reusable utilities (pagination, date utils, crypto helpers)
      job/             # Scheduled tasks, background workers
    resources/
      application.yml
      application-{profile}.yml
      db/migration/    # Flyway SQL migration scripts
  test/
    java/com/company/service/
      unit/            # Pure unit tests — no Spring context
      integration/     # @SpringBootTest / Testcontainers slices
      e2e/             # Full-stack tests against a running environment
```
- Domain layer must have **zero** Spring / framework imports
- Infrastructure adapters implement domain interfaces (ports-and-adapters / hexagonal)
- One class = one clear responsibility; avoid "util" god-classes

---

## Environment & configuration
- Externalise all config via `application.yml` + Spring profiles (`dev`, `test`, `staging`, `prod`)
- Validate required properties at startup with `@ConfigurationProperties` + `@Validated` (JSR-303)
- Never read `System.getenv()` or `System.getProperty()` directly outside a `@Configuration` class
- Provide an `application-example.yml` / `.env.example` with all required keys and no real values
- Use Spring Cloud Config Server for centralised config in a microservices topology
- All feature flags must be toggleable via environment variables or config server properties
- Secrets (DB passwords, API keys) must come from a secrets manager (Vault, AWS Secrets Manager) — never committed to source control

---

## Error handling
- Define a typed exception hierarchy extending a base `AppException` (unchecked)
- Every exception must carry: `message`, `errorCode` (machine-readable string), `httpStatus`, optional `details` map
- Use `@RestControllerAdvice` + `@ExceptionHandler` as the single global error handler — no scattered `try/catch` in controllers
- Map domain exceptions to HTTP responses in the global handler; never let framework exceptions leak raw to the client
- Never expose stack traces, internal class names, or SQL errors to API consumers in production
- Log the full exception with context server-side (`logger.error("...", ex)`); return a sanitised `ErrorResponse` DTO to the client
- Use `ProblemDetail` (RFC 9457, built into Spring 6) as the standard error response format

---

## Security
- Use Spring Security for all authentication and authorisation configuration
- Validate and sanitise all request inputs with Bean Validation (`@Valid`, `@Validated`) + custom validators
- Use Spring Data JPA / named queries / Criteria API — never concatenate JPQL or SQL strings
- Apply rate limiting on all public endpoints (e.g. Bucket4j + Redis, or API Gateway throttling)
- Set secure HTTP response headers via Spring Security's `HeadersConfigurer` (CSP, HSTS, X-Frame-Options)
- Use `BCryptPasswordEncoder` (strength ≥ 12) for password hashing — never MD5, SHA1, or plain SHA256
- Store secrets in Vault or a cloud secrets manager in production; inject at startup via Spring Cloud Vault
- Enforce HTTPS at the load balancer / gateway level; reject plain HTTP in production
- Apply the principle of least privilege to DB roles and service accounts
- Rotate tokens and secrets on a schedule; support zero-downtime rotation
- CORS: whitelist allowed origins explicitly in `CorsConfigurationSource` — never allow `*` in production

---

## Authentication & authorisation
- Use Spring Security OAuth2 Resource Server for JWT validation
- Issue short-lived access tokens (15 min) and long-lived refresh tokens (7 days) signed with RS256 or ES256
- Validate token signature, expiry (`exp`), issuer (`iss`), and audience (`aud`) on every protected request
- Implement refresh token rotation — invalidate the old token immediately on use
- Store refresh tokens server-side (DB or Redis) to support explicit revocation
- Implement RBAC using Spring Security's `@PreAuthorize` / `@Secured` at the **service layer**, not only at the controller
- Never store passwords, PII, or sensitive state inside JWT payloads — keep claims minimal

---

## Database
- Always use Flyway migrations for schema changes — never modify the schema manually or with `spring.jpa.hibernate.ddl-auto=update` in production
- Keep migrations forward-only; provide compensating migrations instead of rollback scripts
- Use `@Transactional` for any multi-step write that must be atomic; annotate at the service layer, not the repository
- Add JPA indexes (`@Index`) on all foreign key columns and frequently filtered fields
- Use HikariCP connection pool (Spring Boot default); configure `maximumPoolSize`, `minimumIdle`, and `connectionTimeout` explicitly
- Never run the application as a DB superuser in production
- Paginate all list queries using Spring Data's `Pageable` — never return unbounded result sets
- Use soft deletes (`deletedAt` timestamp + `@Where(clause = "deleted_at IS NULL")`) for auditable entities
- Prefer `@NaturalId` or business keys over exposing auto-increment surrogate PKs in API responses

---

## Caching
- Use the Spring Cache abstraction (`@Cacheable`, `@CacheEvict`, `@CachePut`) backed by Redis
- Cache at the right layer: CDN → HTTP cache → application cache (`@Cacheable`) → DB query cache
- Set TTL on every cache entry — never use indefinite caches (configure via `RedisCacheConfiguration`)
- Key cache entries with a version prefix to enable instant invalidation on deploy
- Never cache sensitive personal data without appropriate TTL and access controls
- Handle `RedisConnectionFailureException` gracefully — fall back to DB, do not propagate the error to the client

---

## API design
- Follow RESTful conventions: plural nouns for resources, HTTP verbs for actions
- Version APIs from day one: `/api/v1/...`
- Return consistent response envelopes: `{ "data": ..., "meta": ..., "error": ... }`
- Use standard HTTP status codes correctly (200, 201, 204, 400, 401, 403, 404, 409, 422, 500)
- Paginate list endpoints — accept `page`, `size`, `sort` via Spring's `Pageable`; return `Page<T>` metadata
- Use `java.time.Instant` / `OffsetDateTime` for all timestamps; serialise as ISO 8601 UTC strings
- Document all endpoints with springdoc-openapi (OpenAPI 3.x) — annotations kept in sync with code
- Accept `X-Request-ID` request header and echo it in all responses for distributed tracing
- Use `MapStruct` for all entity ↔ DTO mappings — never expose JPA entities directly from controllers

---

## Testing
- Minimum coverage targets: 80% unit (line), 60% integration; all critical user journeys covered by e2e
- **Unit tests**: test domain services and pure logic in isolation — no Spring context, no DB, no HTTP
  - Use Mockito for mocking collaborators; AssertJ for fluent assertions
- **Integration tests**: use `@SpringBootTest` or test slices (`@WebMvcTest`, `@DataJpaTest`) with Testcontainers for a real DB
- **E2E tests**: run against a deployed environment using REST Assured; cover the main journeys end-to-end
- Use `@BeforeEach` / `@AfterEach` to isolate test state — never share mutable state between test methods
- Mock external HTTP services with WireMock in all non-e2e tests
- Test error paths (invalid input, service failures, unauthorised access) as thoroughly as happy paths
- Use `@Nested` classes to group tests by scenario or method under test
- Never use `Thread.sleep()` in tests — use Awaitility for async assertions
- Annotate integration tests with a custom `@IntegrationTest` meta-annotation to allow selective execution in CI

---

## Logging & observability
- Use SLF4J API with Logback as the implementation; output JSON (`logstash-logback-encoder`) in production
- Log levels: `ERROR` (failures requiring action), `WARN` (degraded / recoverable), `INFO` (lifecycle events), `DEBUG` (dev only — never in production)
- Include in every log entry: `timestamp`, `level`, `service`, `traceId`, `spanId`, `userId` (if available)
- Use MDC (`MDC.put(...)`) to propagate `traceId` and `userId` across the request lifecycle
- Never log passwords, tokens, PII, or full request/response bodies containing sensitive fields
- Expose Spring Boot Actuator metrics; emit custom metrics via Micrometer for: request latency (p50/p95/p99), error rate, queue depth, HikariCP pool usage
- Integrate OpenTelemetry (via Micrometer Tracing + OTLP exporter) — propagate `traceId` across service boundaries via HTTP headers (`traceparent`)
- Set up alerting on error rate spikes, latency regressions (p99 > SLO), and availability drops
- Retain logs for ≥ 30 days; archive cold logs to cheap storage (S3, GCS)

---

## Performance
- Set response time SLOs per endpoint type (e.g. reads ≤ 200 ms p95, writes ≤ 500 ms p95)
- Profile with Java Flight Recorder / async-profiler before optimising — never guess at bottlenecks
- Use `EXPLAIN ANALYZE` on slow JPA queries; enable Hibernate's `generate_statistics` in dev/test to catch N+1 problems
- Use `@EntityGraph` or `JOIN FETCH` to avoid N+1 queries; never use `FetchType.EAGER` on collections
- Offload heavy computation and blocking I/O to `@Async` methods or dedicated thread pools — keep HTTP handler threads free
- Use Spring's `StreamingResponseBody` or reactive streaming for large payload responses
- Enable HTTP response compression (`server.compression.enabled=true`) and HTTP/2 (`server.http2.enabled=true`)
- Use virtual threads (Project Loom, `spring.threads.virtual.enabled=true`) for high-concurrency I/O workloads — default on Java 25

---

## Background jobs & queues
- Use Spring Kafka / RabbitMQ / SQS — never in-process `LinkedBlockingQueue` in production
- Make all `@KafkaListener` / `@RabbitListener` / job handler methods **idempotent** — safe to retry on failure
- Use Spring Batch for multi-step, restartable batch processing with chunk-oriented commits
- Use `@Scheduled` only for lightweight, non-clustered tasks; use Quartz or ShedLock for clustered scheduling
- Set max retry count and exponential back-off with jitter (`RetryTemplate`, `DeadLetterPublishingRecoverer`)
- Monitor queue depth and dead-letter queue size as SLIs; alert when DLQ is non-empty
- Separate job processing workers from the API server process (separate Spring Boot application or profile)

---

## Deployment & CI/CD
- Every merge to `main` must pass: Checkstyle → SpotBugs → unit tests → integration tests → build
- Use multi-stage Docker builds: build stage uses full JDK; runtime stage uses `eclipse-temurin:25-jre-alpine`
- Pin all base image versions (e.g. `eclipse-temurin:25.0.1_9-jre-alpine3.21`) — never use `latest` in production
- Run containers as a non-root user (`USER 1001`)
- Use Spring Boot Actuator's `/actuator/health/liveness` and `/actuator/health/readiness` for orchestrator probes
- Support graceful shutdown: `server.shutdown=graceful` + `spring.lifecycle.timeout-per-shutdown-phase=30s`
- Use rolling deployments or blue/green to achieve zero-downtime releases
- Store all infrastructure as code (IaC — Terraform, Helm); no manual console changes in production
- Tag every production release with a semantic version git tag; record it in `CHANGELOG.md`
- Use `spring-boot-maven-plugin` (or Gradle equivalent) to produce a fat JAR or OCI image (`./mvnw spring-boot:build-image`)

---

## Resilience & reliability
- Use Resilience4j for circuit breakers, retry, rate limiter, and bulkhead — integrated via Spring Boot starter
- Apply timeouts to all outbound HTTP calls (`RestClient` / `WebClient` / Feign) and DB queries — never wait indefinitely
- Configure `CircuitBreaker` on all calls to external services; define `fallbackMethod` for graceful degradation
- Design all state-mutating operations for idempotency (safe to retry) — use idempotency keys where needed
- Use Actuator health indicators to automatically reflect dependency state; integrate with load balancer health checks
- Test failure modes with fault injection (Chaos Monkey for Spring Boot) and verify graceful degradation
- Define and document RTO and RPO per service in the service's `README.md`

---

## Documentation
- Every public class and public method must have a Javadoc comment
- Maintain an up-to-date `README.md` per service: purpose, setup, env vars, how to run locally, endpoints
- Keep `CHANGELOG.md` updated using Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.)
- Document all significant design decisions as ADRs (Architecture Decision Records) in `docs/adr/`
- API documentation auto-generated from springdoc-openapi annotations — no hand-written API docs
- Keep `application-example.yml` in sync with all actual config keys whenever properties change
