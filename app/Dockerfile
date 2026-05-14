# 在云服务器上构建 Flutter Web，并用 Nginx 提供静态资源（PathUrlStrategy 需 SPA 回退）。
# 构建上下文须为 app/：在仓库中执行 cd app && docker build -t pangbao-web .
# https://github.com/cirruslabs/docker-images-flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

ARG API_BASE_URL=
ARG WS_HISTORY_URL=
ARG BASE_HREF=/

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN set -eux; \
  extra=""; \
  if [ -n "$API_BASE_URL" ]; then extra="$extra --dart-define=API_BASE_URL=$API_BASE_URL"; fi; \
  if [ -n "$WS_HISTORY_URL" ]; then extra="$extra --dart-define=WS_HISTORY_URL=$WS_HISTORY_URL"; fi; \
  flutter build web --release $extra --base-href="$BASE_HREF"

FROM nginx:alpine
COPY docker/nginx-flutter.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
