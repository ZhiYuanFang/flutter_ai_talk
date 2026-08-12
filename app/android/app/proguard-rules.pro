# sherpa-onnx / ONNX Runtime（横屏 KWS）
-keep class com.k2fsa.sherpa.onnx.** { *; }
-dontwarn com.k2fsa.sherpa.onnx.**
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { public *; }


-keep class com.fzy.pangbao.UcgHmsMessageService { *; }
-keep class com.fzy.pangbao.UcgMiPushReceiver { *; }
-keep class com.fzy.pangbao.PangbaoWidgetSmallProvider { *; }
-keep class com.fzy.pangbao.PangbaoWidgetMediumProvider { *; }
-keep class com.fzy.pangbao.PangbaoWidgetLargeProvider { *; }
-keep class com.fzy.pangbao.PangbaoWidgetRenderer { *; }
-keep class com.fzy.pangbao.PangbaoWidgetBitmaps { *; }
# home_widget 交互跳过：BackgroundReceiver / JobIntentService
-keep class es.antonborri.home_widget.HomeWidgetBackgroundReceiver { *; }
-keep class es.antonborri.home_widget.HomeWidgetBackgroundService { *; }
-keep class com.huawei.hms.** { *; }
-keep class com.xiaomi.mipush.sdk.** { *; }

# HMS references EMUI-only APIs (e.g. BuildEx) absent on non-Huawei ROMs.
# AGP 8+ R8 full mode treats these optional refs as errors; safe to suppress.
-dontwarn com.huawei.android.os.**
-dontwarn com.huawei.libcore.io.**

# HiAnalytics optional HMS deps (referenced by hms framework; not bundled with push SDK).
-dontwarn com.huawei.hianalytics.process.HiAnalyticsConfig$Builder
-dontwarn com.huawei.hianalytics.process.HiAnalyticsConfig
-dontwarn com.huawei.hianalytics.process.HiAnalyticsInstance$Builder
-dontwarn com.huawei.hianalytics.process.HiAnalyticsInstance
-dontwarn com.huawei.hianalytics.process.HiAnalyticsManager
-dontwarn com.huawei.hianalytics.util.HiAnalyticTools

# 支付宝 SDK（tobias / Alipay SDK）
-keep class com.alipay.** { *; }
-keep class com.alipay.sdk.** { *; }
-dontwarn com.alipay.**
