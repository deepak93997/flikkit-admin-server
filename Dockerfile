# ── Stage 1: Build ────────────────────────────────────────────
FROM eclipse-temurin:25-jdk-alpine AS build

WORKDIR /workspace

# Copy Maven wrapper & POM first (layer caching)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Download dependencies (cached unless pom.xml changes)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -q

# Copy source code
COPY src/ src/

# Build
RUN ./mvnw clean package -DskipTests -q

# ── Stage 2: Runtime ──────────────────────────────────────────
FROM eclipse-temurin:25-jre-alpine
LABEL maintainer="flikkit"

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=build /workspace/target/flikkit-admin-server.jar app.jar

RUN chown -R app:app /app
USER app

EXPOSE ${PORT:-9090}

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=60s \
    CMD wget -qO- http://localhost:${PORT:-9090}/actuator/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseZGC", \
    "-XX:+ZGenerational", \
    "-XX:MaxRAMPercentage=75.0", \
    "-jar", "app.jar"]
