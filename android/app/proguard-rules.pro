# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core — needed by Flutter deferred components (split APK delivery)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
