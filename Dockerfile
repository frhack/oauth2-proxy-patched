# Stage 1: Build oauth2-proxy from source with PR #3333 patch applied
FROM golang:1.25-bookworm AS builder

ARG VERSION=v7.14.2

WORKDIR /go/src/github.com/oauth2-proxy/oauth2-proxy

# Clone the specific release tag
RUN git clone --branch ${VERSION} --depth 1 https://github.com/oauth2-proxy/oauth2-proxy.git .

# Apply PR #3333 patch: invalidate session on fatal OAuth2 refresh errors
COPY pr-3333.patch /tmp/pr-3333.patch
RUN git apply /tmp/pr-3333.patch

# Download dependencies
RUN go mod download

# Build the binary
RUN CGO_ENABLED=0 go build -a -installsuffix cgo \
    -ldflags="-X github.com/oauth2-proxy/oauth2-proxy/v7/pkg/version.VERSION=${VERSION}-patched" \
    -o oauth2-proxy \
    github.com/oauth2-proxy/oauth2-proxy/v7

# Create empty jwt signing key file (needed for GCP App Engine compatibility)
RUN touch jwt_signing_key.pem

# Stage 2: Get curl binary and libraries from Alpine
FROM alpine:3.19 AS curl-provider
RUN apk add --no-cache curl

# Stage 3: Runtime distroless image with patched binary + curl
FROM gcr.io/distroless/static:nonroot

# Copy patched oauth2-proxy binary
COPY --from=builder /go/src/github.com/oauth2-proxy/oauth2-proxy/oauth2-proxy /bin/oauth2-proxy
COPY --from=builder /go/src/github.com/oauth2-proxy/oauth2-proxy/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem

# Copy curl and all required libraries from Alpine
COPY --from=curl-provider /usr/bin/curl /usr/bin/curl
COPY --from=curl-provider /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=curl-provider /usr/lib/libcurl.so.4 /usr/lib/libcurl.so.4
COPY --from=curl-provider /lib/libz.so.1 /lib/libz.so.1
COPY --from=curl-provider /usr/lib/libnghttp2.so.14 /usr/lib/libnghttp2.so.14
COPY --from=curl-provider /usr/lib/libssl.so.3 /usr/lib/libssl.so.3
COPY --from=curl-provider /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3
COPY --from=curl-provider /usr/lib/libcares.so.2 /usr/lib/libcares.so.2
COPY --from=curl-provider /usr/lib/libidn2.so.0 /usr/lib/libidn2.so.0
COPY --from=curl-provider /usr/lib/libpsl.so.5 /usr/lib/libpsl.so.5
COPY --from=curl-provider /usr/lib/libbrotlidec.so.1 /usr/lib/libbrotlidec.so.1
COPY --from=curl-provider /usr/lib/libbrotlicommon.so.1 /usr/lib/libbrotlicommon.so.1
COPY --from=curl-provider /usr/lib/libunistring.so.5 /usr/lib/libunistring.so.5

LABEL org.opencontainers.image.licenses=MIT \
      org.opencontainers.image.description="oauth2-proxy v7.14.2 with PR #3333 patch (fatal refresh error session invalidation) and curl" \
      org.opencontainers.image.source=https://github.com/oauth2-proxy/oauth2-proxy \
      org.opencontainers.image.title=oauth2-proxy-patched

ENTRYPOINT ["/bin/oauth2-proxy"]
