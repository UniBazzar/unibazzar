module github.com/unibazzar/auth-service

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/google/uuid v1.4.0
    github.com/lib/pq v1.10.9
    github.com/golang-jwt/jwt/v5 v5.2.0
    github.com/streadway/amqp v1.1.0
    golang.org/x/crypto v0.17.0
    go.opentelemetry.io/otel v1.21.0
    go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.21.0
    go.opentelemetry.io/otel/sdk v1.21.0
    go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin v0.46.1
    github.com/prometheus/client_golang v1.17.0
    github.com/go-playground/validator/v10 v10.16.0
    github.com/joho/godotenv v1.4.0
)
