# Project Context — Flikkit Backend

> **Last updated:** 2025-01  
> **Maintainer:** deepak93997  
> **Status:** Active development (MVP)

---

## 1. Overview

| Key | Value |
|-----|-------|
| **Project name** | Flikkit Backend |
| **Domain** | Home services marketplace (booking, payments, professionals) |
| **Architecture style** | Modular monolith — multi-module Maven project |
| **Language** | Java 21 (LTS) — records, sealed classes, pattern matching |
| **Framework** | Spring Boot 3.3.5 + Spring Cloud 2023.0.3 (gateway only) |
| **Build tool** | Apache Maven with wrapper (`mvnw`), multi-module |
| **Source control** | Git (GitHub) — `https://github.com/deepak93997/flikkit` |
| **Mono-repo** | Yes — all modules under `flikkit-backend/` |
| **Containerisation** | Docker + Docker Compose for local dev; multi-stage builds |
| **CI/CD** | GitHub Actions (`.github/workflows/ci.yml`) |
| **Database** | PostgreSQL 16 + PostGIS |
| **Database migrations** | Flyway |
| **Auth** | JWT (RS256) — access + refresh tokens |
| **Messaging** | Spring Kafka (optional, toggle via `flikkit.messaging.mode`) |
| **Caching** | Redis 7 via Spring Cache |
| **Base package** | `com.flikkit` |

---

## 2. Maven Modules

### Parent POM (`pom.xml`)
- `spring-boot-starter-parent:3.3.5`
- Packaging: `pom`
- Modules: `flikkit-commons`, `flikkit-app`, `flikkit-gateway`, `flikkit-admin-server`

### 2.1 flikkit-commons
- **Type:** Shared library JAR (no Spring Boot executable)
- **Package:** `com.flikkit.commons`
- **Contains:** DTOs, exceptions, events, security utils, validation, MoneyUtils
- **Key classes:** `ApiResponse`, `GlobalExceptionHandler`, `JwtTokenProvider`, `SecurityConstants`, `FlikkitEvent`

### 2.2 flikkit-app `:8080`
- **Type:** Main Spring Boot application
- **Package:** `com.flikkit`
- **Depends on:** `flikkit-commons`
- **Business modules (12):** auth, user, professional, catalog, booking, payment, review, admin, executive, notification, location, reporting
- **Key dependencies:** Spring Data JPA, Redis, Kafka, Flyway, Razorpay, Firebase Admin, AWS S3, Google Maps, springdoc-openapi

### 2.3 flikkit-gateway `:8080` (external port)
- **Type:** Spring Cloud Gateway (reactive)
- **Package:** `com.flikkit.gateway`
- **Depends on:** `flikkit-commons`
- **Purpose:** API routing, JWT validation, rate limiting, request logging, CORS

### 2.4 flikkit-admin-server `:9090`
- **Type:** Spring Boot Admin Server
- **Package:** `com.flikkit.admin`
- **Purpose:** Service monitoring dashboard

---

## 3. Build & Run

```bash
# Build all modules (skip tests)
./mvnw clean package -DskipTests

# Build specific module
./mvnw clean package -pl flikkit-app -am -DskipTests

# Run tests
./mvnw test

# Docker Compose (full stack)
docker-compose up -d

# Docker Compose with Kafka
docker-compose --profile kafka up -d
```

---

## 4. Infrastructure Services

| Service | Image | Port |
|---------|-------|------|
| PostgreSQL + PostGIS | `postgis/postgis:16-3.4-alpine` | 5432 |
| Redis | `redis:7-alpine` | 6379 |
| Kafka | `confluentinc/cp-kafka:7.5.0` | 9092 (optional profile) |
| Prometheus | `prom/prometheus` | 9091 |
| Grafana | `grafana/grafana` | 3000 |
| Nginx | `nginx:1.25-alpine` | 80, 443 |

---

## 5. Key Version Properties

| Dependency | Version |
|-----------|---------|
| Spring Boot | 3.3.5 |
| Spring Cloud | 2023.0.3 |
| Spring Boot Admin | 3.3.4 |
| JJWT | 0.12.6 |
| springdoc-openapi | 2.6.0 |
| AWS S3 SDK | 2.28.6 |
| Firebase Admin | 9.3.0 |
| Razorpay | 1.4.6 |
| Google Maps Services | 2.2.0 |
| Testcontainers | 1.20.1 |
| Lombok | 1.18.38 |

---

## 6. Source Code Structure

```
flikkit-backend/
├── pom.xml                    # Parent POM
├── mvnw / mvnw.cmd            # Maven wrapper
├── docker-compose.yml
├── .github/
│   ├── copilot-instructions.md
│   ├── prompts/project-context.md
│   └── workflows/ci.yml
├── flikkit-commons/            # Shared library
│   ├── pom.xml
│   └── src/main/java/com/flikkit/commons/
│       ├── event/              # FlikkitEvent, PaymentSuccessEvent, RefundEvent, etc.
│       ├── exception/          # GlobalExceptionHandler, ResourceNotFoundException, etc.
│       ├── response/           # ApiResponse
│       ├── security/           # JwtTokenProvider, SecurityConstants
│       ├── utils/              # MoneyUtils
│       └── validation/         # Custom validators
├── flikkit-app/                # Main application
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/main/java/com/flikkit/
│       ├── FlikkitApplication.java
│       ├── config/             # SecurityConfig, EventPublisher, Redis, Kafka, etc.
│       ├── auth/               # OTP, JWT, login/register
│       ├── user/               # User profiles, addresses
│       ├── professional/       # Professional profiles, availability
│       ├── catalog/            # Services, categories
│       ├── booking/            # Booking lifecycle
│       ├── payment/            # Razorpay integration, payouts
│       ├── review/             # Ratings & reviews
│       ├── admin/              # Admin panel, coupons, audit
│       ├── executive/          # Field executives
│       ├── notification/       # Email, push (Firebase), in-app
│       ├── location/           # Google Maps, geospatial
│       └── reporting/          # Analytics, dashboards
├── flikkit-gateway/            # API Gateway
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/main/java/com/flikkit/gateway/
├── flikkit-admin-server/       # Admin monitoring
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/main/java/com/flikkit/admin/
```

---

## 7. Known Issues & Tech Debt

| # | Severity | Issue |
|---|----------|-------|
| 1 | **Medium** | JUnit tests need Testcontainers (PostgreSQL, Kafka) running |
| 2 | **Medium** | SMS integration is stub-only (`flikkit.sms.enabled=false` by default) |
| 3 | **Low** | Firebase push notifications require `firebase.json` config file |
| 4 | **Low** | Production JWT keys need rotation setup |

---

## 8. Change Log

| Date | Author | Change |
|------|--------|--------|
| 2025-01 | deepak93997 | Initial project — full modular monolith backend with 12 business modules |
| 2025-01 | deepak93997 | Migrated build system from Gradle to Apache Maven |
