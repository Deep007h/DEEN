# Flutter Engine rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Shared Preferences Pigeon and Registrar rules
-dontwarn io.flutter.plugins.sharedpreferences.**
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class * extends io.flutter.plugins.sharedpreferences.SharedPreferencesApi { *; }
-keep class * extends io.flutter.plugins.sharedpreferences.SharedPreferencesApiRegistrar { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class * implements io.flutter.plugins.sharedpreferences.** { *; }

# MediaKit Video & Audio Engine
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }
-keep class com.alexmercerind.media_kit_libs_video.** { *; }
-dontwarn com.alexmercerind.media_kit.**

# Keep all native JNI method bindings
-keepclasseswithmembers class * {
    native <methods>;
}

# Wakelock
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# Kotlin reflection, coroutines, and Pigeon attributes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.coroutines.**
-dontwarn kotlinx.coroutines.**
