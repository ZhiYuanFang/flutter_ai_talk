# App 签名信息

> 敏感信息文档：包含签名文件路径、密码、公钥和指纹，请谨慎保管，避免外发或提交到公共仓库。

## 项目标识

- Android `applicationId` / `namespace`：`com.fzy.pangbao`
- iOS Bundle ID：当前证书对应 Apple Development 身份，后续仍需以实际 Apple 后台配置的 Bundle ID 为准

## Android 签名信息

### 签名文件

- Keystore 路径：`app/android/pangbao-upload.jks`
- Gradle 配置文件：`app/android/app/build.gradle.kts`
- Alias：`pangbao-upload`
- Store Password：`123456`
- Key Password：`123456`

### 证书指纹

- MD5（带冒号）：`7B:F7:D1:7F:FC:99:E8:59:42:83:FC:DA:31:2C:B4:C8`
- MD5（不带冒号）：`7BF7D17FFC99E8594283FCDA312CB4C8`
- SHA-1（带冒号）：`1E:D5:A0:0E:59:F6:14:00:8C:FB:99:DB:3F:39:EF:5D:7A:E3:41:77`
- SHA-1（不带冒号）：`1ED5A00E59F614008CFB99DB3F39EF5D7AE34177`
- SHA-256（带冒号）：`34:B9:2B:AD:A2:02:06:36:4C:17:A4:B3:08:E7:71:90:DD:C8:86:26:FF:F5:A7:59:F6:80:4F:50:0F:EB:2D:AC`
- SHA-256（不带冒号）：`34B92BADA20206364C17A4B308E77190DDC88626FFF5A759F6804F500FEB2DAC`

### 公钥

- 公钥（Base64）：

```text
MIIBCgKCAQEAvywmEZO2dpTJBYUpu2LsOIcXK4hwrVI/15o6eOCyJfmm2O9cFaHm/agCPIoUiG2MwbF3j/fL7LcKSBD3f9GZDQG3NkLdz7Ggx5NUdgtMln9TswNoPyLh1fB35vsLJdJV8BQuasgfUAVfYgWIa5FTGEERrRMIsSsZeHPRnD3JN5MvwQQRD8/BrV5K7P9FzS7d6VrACIQCAcupER4K6AsC++RqyPU4bLKqoDJTBbcpaPwBnc8DZJs2fXOKe+HWiaTW0xKWCO7LSlsD2BrnMnUk8/3UHCDCKl+arNG2MJ8+MoT4fA/aWEEJvMVe/ukt+AGPl/3cG41i1Zv3WtJtW61INQIDAQAB
```

### 有效期

- 有效至：`2053-10-13`

## iOS 签名信息

### 签名文件

- P12 路径：`app/ios/证书.p12`
- P12 Password：`a521521521`

### 证书主题

- Subject：`C=US, O=志远 方, OU=395D9NUCNF, CN=Apple Development: z343315792@icloud.com (K2NJVJM456), OID.0.9.2342.19200300.100.1.1=5PME59355H`

### 证书指纹

- SHA-1（带冒号）：`50:36:DB:86:CE:37:A8:5B:7D:45:AA:FD:72:F5:13:85:79:24:D2:55`
- SHA-1（不带冒号）：`5036DB86CE37A85B7D45AAFD72F513857924D255`

### 公钥

- 公钥（Base64）：

```text
MIIBCgKCAQEAkoTy2Y4gr/0hAQuOO1Bd/NMv8o9ZoPsstpQ6dNEGE8kLc+rd7LjCmD3EOVc9AhTh7OQuQQZcEqVTK0x/lk17KWmQ/khKZcSa2q3ZPkwmD4nMzqcqx6YrNfFbm1d2Jz1mA/IJI7yeq/ZQIazz3D3WFuo0A7CZVZZoCrk8PzxSCfQ8l7MaPcpU+zesLqHdcxlyzUYApcMAmCBD1HTKOQlNbpQdoZqOF3nch62ARvT5GCCvF7WwEy4VyNa2/aD0BiIuBgBaaUk2/xsag82fHx8tRSlH07th28TQG6+uQV6XBs9AO1KhqBfqyE0hJe2sBOysrA3x/Ti6x5MGKFwXOnVtgQIDAQAB
```

### 有效期

- 有效至：`2027-05-27 11:12:45`

## 备注

- Android 指纹来自 `gradlew signingReport` 的 `release` 配置。
- iOS 公钥与 SHA-1 来自 `app/ios/证书.p12` 解出的叶子证书。
- 若后续重新生成 Android keystore 或更换 iOS 证书，本文件中的指纹、公钥、密码都需要同步更新。
