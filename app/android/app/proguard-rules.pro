-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }

-keep class com.fzy.pangbao.UcgHmsMessageService { *; }
-keep class com.fzy.pangbao.UcgMiPushReceiver { *; }
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
