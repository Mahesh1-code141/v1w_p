# ─────────────────────────────────────────────────────────────
#  Multi-stage Dockerfile — Java 17 / Spring Boot
# ─────────────────────────────────────────────────────────────

# ── Stage 1: Build ────────────────────────────────────────────
FROM maven:3.8.4-amazoncorretto-17 AS builder

WORKDIR /app

# Cache dependencies (only re-downloads when pom.xml changes)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build JAR
COPY src ./src
RUN mvn clean package -DskipTests -B

# ── Stage 2: Runtime ──────────────────────────────────────────
FROM amazoncorretto:17-alpine

WORKDIR /app

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/target/*.jar app.jar
RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]

