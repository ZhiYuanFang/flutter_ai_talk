import Foundation
import Security

/// Live Activity 免鉴权 register：缓存 wxId/deviceKey/apiBase，并在唤醒窗 URLSession POST。
/// 不存 accessToken；身份仅 body.wxId（对齐 go twin live-activity-register-no-auth-go）。
enum LiveActivityNativeRegister {
  /// App Group：与小组件同源，后台唤醒可读。
  private static let appGroupId = "group.com.fzy.pangbao.widget"
  private static let kWxId = "la.register.wxId"
  private static let kDeviceKey = "la.register.deviceKey"
  private static let kApiBase = "la.register.apiBaseUrl"
  /// Keychain 备份 wxId（AfterFirstUnlock，兼顾锁屏后唤醒）。
  private static let keychainService = "com.fzy.pangbao.live_activity"
  private static let keychainWxAccount = "wxId"

  private static let successLock = NSLock()
  private static var successIdentities = Set<String>()
  private static let maxSuccessIdentities = 64

  /// Dart 登录/刷新后写入上下文；登出清空。
  static func setContext(wxId: Int64, deviceKey: String, apiBaseUrl: String) {
    let dk = deviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let base = apiBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard wxId > 0, !dk.isEmpty, !base.isEmpty else {
      NSLog("[live_activity] setContext skip invalid wxIdOrKeys")
      return
    }
    if let defaults = UserDefaults(suiteName: appGroupId) {
      defaults.set("\(wxId)", forKey: kWxId)
      defaults.set(dk, forKey: kDeviceKey)
      defaults.set(base, forKey: kApiBase)
    }
    keychainWriteWxId("\(wxId)")
    NSLog("[live_activity] setContext wxId=%lld deviceKeyLen=%d baseLen=%d", wxId, dk.count, base.count)
  }

  /// 登出：清 App Group + Keychain，避免旧 wxId 继续上报。
  static func clearContext() {
    if let defaults = UserDefaults(suiteName: appGroupId) {
      defaults.removeObject(forKey: kWxId)
      defaults.removeObject(forKey: kDeviceKey)
      defaults.removeObject(forKey: kApiBase)
    }
    keychainDeleteWxId()
    successLock.lock()
    successIdentities.removeAll()
    successLock.unlock()
    NSLog("[live_activity] clearContext")
  }

  /// token 到手后立即尝试原生 POST；不依赖 Dart / Bearer。
  static func registerIfPossible(_ args: [String: Any]) {
    let kind = ((args["tokenKind"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let attr = ((args["attributesKind"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let token = ((args["token"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    var activityId = ((args["activityId"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard kind == "push_to_start" || kind == "activity" else { return }
    guard attr == "imminent" || attr == "timing" else { return }
    guard !token.isEmpty else { return }
    if kind == "push_to_start" {
      activityId = ""
    } else if activityId.isEmpty {
      NSLog("[live_activity] nativeRegister skip activity without activityId")
      return
    }

    guard let wxId = readWxId(), wxId > 0 else {
      NSLog("[live_activity] nativeRegister skip no_wxId kind=%@", kind)
      return
    }
    guard let deviceKey = readDeviceKey(), !deviceKey.isEmpty else {
      NSLog("[live_activity] nativeRegister skip no_deviceKey")
      return
    }
    guard let apiBase = readApiBase(), !apiBase.isEmpty else {
      NSLog("[live_activity] nativeRegister skip no_apiBase")
      return
    }

    let identity = "\(wxId)|\(deviceKey)|\(kind)|\(attr)|\(activityId)|\(token)"
    successLock.lock()
    let already = successIdentities.contains(identity)
    successLock.unlock()
    if already {
      NSLog("[live_activity] nativeRegister skip cached kind=%@ attr=%@", kind, attr)
      return
    }

    guard let url = URL(string: "\(apiBase)/app/api/push/live-activity/register") else {
      NSLog("[live_activity] nativeRegister bad url")
      return
    }
    var body: [String: Any] = [
      "wxId": wxId,
      "deviceKey": deviceKey,
      "tokenKind": kind,
      "attributesKind": attr,
      "token": token,
    ]
    if kind == "activity" {
      body["activityId"] = activityId
    }
    guard let json = try? JSONSerialization.data(withJSONObject: body) else {
      NSLog("[live_activity] nativeRegister json fail")
      return
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    // 免鉴权：故意不附 Authorization
    req.httpBody = json
    req.timeoutInterval = 15

    URLSession.shared.dataTask(with: req) { _, response, error in
      if let error = error {
        NSLog("[live_activity] nativeRegister err=%@", error.localizedDescription)
        return
      }
      let code = (response as? HTTPURLResponse)?.statusCode ?? 0
      if code >= 200 && code < 300 {
        successLock.lock()
        if successIdentities.count >= maxSuccessIdentities {
          successIdentities.removeAll()
        }
        successIdentities.insert(identity)
        successLock.unlock()
        NSLog(
          "[live_activity] nativeRegister ok kind=%@ attr=%@ activityIdLen=%d http=%d",
          kind,
          attr,
          activityId.count,
          code
        )
      } else {
        NSLog("[live_activity] nativeRegister http=%d kind=%@", code, kind)
      }
    }.resume()
  }

  // MARK: - 读缓存

  private static func readWxId() -> Int64? {
    if let defaults = UserDefaults(suiteName: appGroupId),
       let s = defaults.string(forKey: kWxId)?.trimmingCharacters(in: .whitespacesAndNewlines),
       let v = Int64(s), v > 0 {
      return v
    }
    if let s = keychainReadWxId(), let v = Int64(s), v > 0 {
      return v
    }
    return nil
  }

  private static func readDeviceKey() -> String? {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return nil }
    let s = defaults.string(forKey: kDeviceKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return s.isEmpty ? nil : s
  }

  private static func readApiBase() -> String? {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return nil }
    let s = defaults.string(forKey: kApiBase)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return s.isEmpty ? nil : s
  }

  // MARK: - Keychain wxId

  private static func keychainWriteWxId(_ value: String) {
    keychainDeleteWxId()
    let data = Data(value.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainWxAccount,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess {
      NSLog("[live_activity] keychain write status=%d", status)
    }
  }

  private static func keychainReadWxId() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainWxAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static func keychainDeleteWxId() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainWxAccount,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
