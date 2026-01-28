# =====================================
# ✅ Reglas para Google ML Kit
# =====================================
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# =====================================
# ✅ Reglas básicas para Flutter y Firebase
# =====================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
# =====================================
# ✅ Reglas para Flutter Play Core (SplitInstall)
# =====================================
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

