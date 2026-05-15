# 在云服务器上构建 Flutter Web，并用 Nginx 提供静态资源（PathUrlStrategy 需 SPA 回退）。
# 构建上下文须为 app/：cd app && docker build -t pangbao-web .
#
# 构建阶段：Debian slim + 国内 apt / Flutter 镜像源，避免官方 deb.debian.org、GitHub 过慢。
FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive

# 阿里云 Debian 源：构建初期尚无 ca-certificates，须用 http（勿用 https，否则会证书校验失败）
ARG APT_MIRROR=http://mirrors.aliyun.com/debian
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
      "deb ${APT_MIRROR}/ bookworm main contrib non-free non-free-firmware" \
      "deb ${APT_MIRROR}/ bookworm-updates main contrib non-free non-free-firmware" \
      "deb ${APT_MIRROR}-security bookworm-security main contrib non-free non-free-firmware" \
      > /etc/apt/sources.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils zip; \
    rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Flutter 中国社区镜像（precache / pub / 引擎下载）
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 默认 Gitee 镜像 clone；可 --build-arg FLUTTER_GIT_URL=https://github.com/flutter/flutter.git 回退
ARG FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git
ARG FLUTTER_BRANCH=stable
RUN git clone --depth 1 --branch "${FLUTTER_BRANCH}" "${FLUTTER_GIT_URL}" "${FLUTTER_HOME}" \
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
