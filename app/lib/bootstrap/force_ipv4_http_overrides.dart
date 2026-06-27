import 'dart:async';
import 'dart:io';

/// 安装全局 [HttpOverrides]，使 `dart:io` HTTP/WebSocket 仅解析并连接 IPv4。
void installForceIpv4HttpOverrides() {
  HttpOverrides.global = ForceIpv4HttpOverrides();
}

class ForceIpv4HttpOverrides extends HttpOverrides {
  static const _lookupTimeout = Duration(seconds: 8);
  static const _connectionTimeout = Duration(seconds: 10);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = _connectionTimeout;
    client.connectionFactory = _ipv4ConnectionFactory;
    return client;
  }

  static Future<ConnectionTask<Socket>> _ipv4ConnectionFactory(
    Uri url,
    String? proxyHost,
    int? proxyPort,
  ) async {
    if (proxyHost != null) {
      return Socket.startConnect(proxyHost, proxyPort ?? 8080);
    }

    final host = url.host;
    final port = url.port == 0 ? _defaultPort(url.scheme) : url.port;
    final addresses = await InternetAddress.lookup(
      host,
      type: InternetAddressType.IPv4,
    ).timeout(_lookupTimeout);
    if (addresses.isEmpty) {
      throw SocketException('No IPv4 address for $host');
    }

    if (_isSecureScheme(url.scheme)) {
      return _connectTlsFirst(addresses, port, host: host);
    }
    return _connectPlainFirst(addresses, port, host: host);
  }

  static ConnectionTask<Socket> _connectPlainFirst(
    List<InternetAddress> addresses,
    int port, {
    required String host,
  }) {
    var cancelled = false;
    ConnectionTask<Socket>? activeTask;

    Future<Socket> connect() async {
      Object? lastError;
      for (final address in addresses) {
        if (cancelled) {
          throw const SocketException('Connection cancelled');
        }
        try {
          activeTask = await Socket.startConnect(address, port);
          return await activeTask!.socket;
        } catch (e) {
          lastError = e;
        }
      }
      throw SocketException(
        'No IPv4 plain connection for $host',
        osError: lastError is OSError ? lastError : null,
      );
    }

    return ConnectionTask.fromSocket(connect(), () {
      cancelled = true;
      activeTask?.cancel();
    });
  }

  static ConnectionTask<Socket> _connectTlsFirst(
    List<InternetAddress> addresses,
    int port, {
    required String host,
  }) {
    var cancelled = false;
    ConnectionTask<Socket>? activeTask;

    Future<Socket> connect() async {
      Object? lastError;
      for (final address in addresses) {
        if (cancelled) {
          throw const SocketException('Connection cancelled');
        }
        Socket? raw;
        try {
          activeTask = await Socket.startConnect(address, port);
          raw = await activeTask!.socket;
          if (cancelled) {
            raw.destroy();
            throw const SocketException('Connection cancelled');
          }
          final secure = await SecureSocket.secure(
            raw,
            host: host,
          );
          if (cancelled) {
            secure.destroy();
            throw const SocketException('Connection cancelled');
          }
          return secure;
        } catch (e) {
          lastError = e;
          raw?.destroy();
        }
      }
      throw SocketException(
        'No IPv4 TLS connection for $host',
        osError: lastError is OSError ? lastError : null,
      );
    }

    return ConnectionTask.fromSocket(connect(), () {
      cancelled = true;
      activeTask?.cancel();
    });
  }

  static bool _isSecureScheme(String scheme) {
    switch (scheme.toLowerCase()) {
      case 'https':
      case 'wss':
        return true;
      default:
        return false;
    }
  }

  static int _defaultPort(String scheme) {
    switch (scheme.toLowerCase()) {
      case 'https':
      case 'wss':
        return 443;
      default:
        return 80;
    }
  }
}
