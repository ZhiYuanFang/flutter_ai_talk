# 在云服务器上构建 Flutter Web，并用 Nginx 提供静态资源（PathUrlStrategy 需 SPA 回退）。
# 构建上下文须为 app/：cd app && docker build -t pangbao-web .
#
# 构建阶段使用官方 Debian slim + 自装 Flutter，避免部分云主机在 cirruslabs/flutter 等镜像上触发
# runc: unable to find user root: invalid argument。
FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils zip \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# 固定 channel；需要可锁版本时改为例如 3.27.0（须为仓库存在的 tag）
ARG FLUTTER_BRANCH=stable
RUN git clone --depth 1 --branch "${FLUTTER_BRANCH}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && flutter config --no-analytics \
    && flutter precache --web

WORKDIR /app

ARG API_BASE_URL=
ARG WS_HISTORY_URL=
ARG BASE_HREF=/

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release \
  ${API_BASE_URL:+--dart-define=API_BASE_URL=${API_BASE_URL}} \
  ${WS_HISTORY_URL:+--dart-define=WS_HISTORY_URL=${WS_HISTORY_URL}} \
  --base-href="${BASE_HREF}"

FROM nginx:alpine
COPY docker/nginx-flutter.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
