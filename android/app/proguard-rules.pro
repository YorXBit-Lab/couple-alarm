# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class **.R$raw { *; }
-keepclassmembers class **.R$raw {
    public static final int mozart;
}

# Alarm Manager Plus - QUAN TRỌNG
-keep class dev.fluttercommunity.plus.** { *; }
-keep class io.flutter.plugins.androidalarmmanager.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Callback functions
-keepattributes *Annotation*
-keepclassmembers class ** {
    @org.greenrobot.eventbus.Subscribe <methods>;
}

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

-dontwarn com.google.**
-dontwarn io.flutter.plugins.**