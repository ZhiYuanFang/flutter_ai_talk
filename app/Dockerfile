# 在云服务器上构建 Flutter Web，并用 Nginx 提供静态资源（PathUrlStrategy 需 SPA 回退）。
# 构建上下文须为 app/：在仓库中执行 cd app && docker build -t pangbao-web .
# https://github.com/cirruslabs/docker-images-flutter
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root

WORKDIR /app

ARG API_BASE_URL=
ARG WS_HISTORY_URL=
ARG BASE_HREF=/

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# 用 Dockerfile 变量替换拼参数，避免未加引号的 $extra 被 shell 拆词；URL 勿含未转义双引号。
RUN flutter build web --release \
  ${API_BASE_URL:+--dart-define=API_BASE_URL=${API_BASE_URL}} \
  ${WS_HISTORY_URL:+--dart-define=WS_HISTORY_URL=${WS_HISTORY_URL}} \
  --base-href="${BASE_HREF}"

FROM nginx:alpine
COPY docker/nginx-flutter.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
