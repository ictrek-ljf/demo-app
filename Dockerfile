# ===== 阶段 1：编译 =====
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY main.go .

# CGO_ENABLED=0：静态编译，不依赖 glibc
# -ldflags="-s -w"：去掉调试符号，镜像瘦身 30%
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -o demo-app main.go

# ===== 阶段 2：运行 =====
FROM alpine:3.19
WORKDIR /app

# 非 root 用户（安全合规）
RUN adduser -D -u 1000 appuser
COPY --from=builder /app/demo-app .

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

EXPOSE 8080
USER appuser
ENTRYPOINT ["./demo-app"]
