## ProGuard rules for Culinara
## Keep essential Flutter/Firebase classes and silence optional Play Core warnings.

## Flutter (keep entry points)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

## Firebase & Google Play services (used via reflection)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

## Application classes
-keep class com.example.culinara.** { *; }

## Google Play Core split install APIs are referenced by some libraries but
## are optional at runtime. Suppress missing-class warnings for them.
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.assetpacks.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
