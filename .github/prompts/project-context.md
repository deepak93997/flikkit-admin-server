# Project Context - Domzo Admin Server

> Last updated: 2026-03-27
> Repo: domzo-admin-server
> Status: Active

## 1. Overview

| Key | Value |
|-----|-------|
| Project name | Domzo Admin Server |
| Purpose | Spring Boot Admin dashboard for monitoring Domzo services |
| Architecture | Single-module Spring Boot app |
| Language | Java 25 |
| Framework | Spring Boot 3.5.0 + Spring Boot Admin 3.5.0 |
| Build tool | Maven Wrapper (`mvnw`) |
| Default port | 9090 |
| Base package | `com.domzo` |
| Source control | GitHub (`flikkit-admin-server`) |

## 2. Repository Layout

```
domzo-admin-server/
	pom.xml
	Dockerfile
	src/main/java/com/domzo/
		AdminServerApplication.java
		config/SecurityConfig.java
	src/main/resources/
		application.yml
```

## 3. Runtime and Config Notes

- App name: `domzo-admin-server`
- Port is configurable via env `PORT`, default `9090`
- Spring profiles can be set through `SPRING_PROFILES_ACTIVE`
- Exposes actuator endpoints for health and metrics
- Uses basic auth credentials from env for admin UI access

## 4. Build and Run

```bash
./mvnw clean package -DskipTests
java -jar target/domzo-admin-server.jar
```

## 5. Docker

- Multi-stage build with Eclipse Temurin Java 25
- Container exposes port `9090`
- Health checks target actuator endpoint

## 6. Boundaries

- This repository is only the monitoring/admin server
- No business domain APIs should be implemented here
- No booking/payment/user domain logic belongs in this service
