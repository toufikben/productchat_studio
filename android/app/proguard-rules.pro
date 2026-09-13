# ONNX Runtime native bindings
-keep class ai.onnxruntime.** { *; }
-keep class com.microsoft.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
-dontwarn com.microsoft.onnxruntime.**

# Flutter plugin and bridge classes
-keep class io.flutter.** { *; }
-keep class com.productchat.studio.** { *; }
