# flutter_local_notifications persists scheduled notifications with Gson.
# Without these rules R8 strips the generic signatures, and every
# cancel/zonedSchedule call fails in release with "Missing type parameter".
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
