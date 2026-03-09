# ─────────────────────────────────────────────────
# Stage 1: Build
# Gradle로 bootJar 빌드 (JDK 필요)
# ─────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# 의존성 레이어 캐싱: 소스보다 먼저 복사
# → 소스만 변경됐을 때 의존성 다운로드 생략 가능
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

RUN chmod +x ./gradlew

# 의존성 미리 다운로드 (캐싱)
RUN ./gradlew dependencies --no-daemon

# 실제 소스 복사 후 빌드
COPY src src
RUN ./gradlew bootJar -x test --no-daemon

# ─────────────────────────────────────────────────
# Stage 2: Run
# JAR만 복사해서 실행 (JRE만 있으면 됨 → 이미지 경량화)
# ─────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

# 8080 포트 명시 (문서 목적, 실제 바인딩은 docker-compose에서)
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
