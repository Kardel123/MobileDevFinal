# flutter_local_notifications persists scheduled notifications with Gson.
# R8 full mode strips generic signatures → RuntimeException: Missing type parameter.
# See: https://github.com/MaikuB/flutter_local_notifications/issues/2223

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

-keep class com.dexterous.flutterlocalnotifications.** { *; }
