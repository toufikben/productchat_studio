# ONNX Runtime bindings. Keep these rules ready for the production runtime.
-keep class ai.onnxruntime.** { *; }
-keep class com.microsoft.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
-dontwarn com.microsoft.onnxruntime.**

# Flutter plugin registration and native bridge.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.productchat.studio.native.** { *; }
