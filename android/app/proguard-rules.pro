# ONNX Runtime native bindings
-keep class ai.onnxruntime.** { *; }
-keep class com.microsoft.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
-dontwarn com.microsoft.onnxruntime.**

# Flutter plugin and bridge classes
-keep class io.flutter.** { *; }
-keep class com.productchat.aiphotostudio.** { *; }

# Flutter's optional Play Store deferred-components integration is not used by
# this app. Do not add the legacy monolithic Play Core dependency just to
# satisfy these optional references.
-dontwarn com.google.android.play.core.**
