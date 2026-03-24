# Keep the Application class and its methods
-keep class com.dime.tomotomo.MainActivity { *; }
-keep class com.dime.tomotomo.NotebookWidgetProvider { *; }
-keep class com.dime.tomotomo.NotebookWidgetActionReceiver { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.** 