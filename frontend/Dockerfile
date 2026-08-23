# Multi-stage build for Flutter Web on ARM64 / AMD64
FROM ghcr.io/cirruslabs/flutter:3.19.6 AS build-env

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --pwa-strategy=none

# Stage 2: Nginx Static Server with Reverse Proxy
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
