-keep class ai.onnxruntime.** { *; }
-keep class com.microsoft.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
-dontwarn com.microsoft.onnxruntime.**

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ProductChat Native
-keep class com.productchat.studio.native.** { *; }
