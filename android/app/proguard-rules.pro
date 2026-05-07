# Preserve generic type signatures required by Gson TypeToken.
-keepattributes Signature

# Keep runtime annotation metadata used by serialization libraries.
-keepattributes *Annotation*

# Keep Gson TypeToken and its subclasses.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep flutter_local_notifications model classes used in cached JSON parsing.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
