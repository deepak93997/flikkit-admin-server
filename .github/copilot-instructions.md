---
applyTo: "**"
---

> Always read .github/prompts/project-context.md before editing code in this repository.

# Copilot Instructions - Domzo Admin Server

## Scope
- This repository is only for the monitoring service (Spring Boot Admin Server).
- Do not add business APIs or domain modules (booking, payment, user, catalog) here.
- Keep changes focused on admin dashboard, security for dashboard access, and observability.

## Stack and Runtime
- Java 25, Spring Boot 3.5.0, Spring Boot Admin 3.5.0
- Maven Wrapper only (`./mvnw` or `mvnw.cmd`)
- Default server port: `9090` (env `PORT` may override)

## Architecture Rules
- Keep package layout under `com.domzo` clear and minimal.
- Centralize security settings in config classes.
- Prefer actuator-driven health and metrics exposure.
- Avoid introducing database, Kafka, or Redis dependencies unless truly required for monitoring features.

## Coding Rules
- Follow standard Java naming and immutability best practices.
- Keep methods short and side effects explicit.
- Do not hardcode credentials; use environment variables.
- Keep exception handling explicit and avoid empty catch blocks.

## Testing and Validation
- For functional changes, add or update tests in `src/test`.
- At minimum run:
  - `./mvnw test`
  - `./mvnw clean package -DskipTests`

## Deployment Notes
- Docker image should continue exposing `9090`.
- Preserve actuator health endpoints used by health checks.

## Documentation
- Every public class and public method must have a Javadoc comment
- Maintain an up-to-date `README.md` per service: purpose, setup, env vars, how to run locally, endpoints
- Keep `CHANGELOG.md` updated using Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.)
- Document all significant design decisions as ADRs (Architecture Decision Records) in `docs/adr/`
- API documentation auto-generated from springdoc-openapi annotations — no hand-written API docs
- Keep `application-example.yml` in sync with all actual config keys whenever properties change
