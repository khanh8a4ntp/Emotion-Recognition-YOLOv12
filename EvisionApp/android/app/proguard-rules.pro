# Giữ tất cả các class và thành phần của TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Giữ các class liên quan đến TFLite GPU Delegate
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# Ngăn R8 cảnh báo về các class không tìm thấy
-dontwarn org.tensorflow.lite.**