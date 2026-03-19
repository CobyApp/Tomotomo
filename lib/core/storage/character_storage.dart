import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/app_supabase.dart';

/// Uploads character avatar/background images to Supabase Storage.
/// Path format: {bucket}/{userId}/{uniqueId}.{ext} so RLS allows upload.
class CharacterStorage {
  static const String avatarsBucket = 'avatars';
  static const String backgroundsBucket = 'backgrounds';

  /// Uploads a file to avatars bucket. Returns public URL or throws.
  static Future<String> uploadAvatar(String userId, File file) async {
    final path = _pathForUser(userId, file.path, avatarsBucket);
    await AppSupabase.client.storage.from(avatarsBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return AppSupabase.client.storage.from(avatarsBucket).getPublicUrl(path);
  }

  /// Uploads a file to backgrounds bucket. Returns public URL or throws.
  static Future<String> uploadBackground(String userId, File file) async {
    final path = _pathForUser(userId, file.path, backgroundsBucket);
    await AppSupabase.client.storage.from(backgroundsBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return AppSupabase.client.storage.from(backgroundsBucket).getPublicUrl(path);
  }

  static String _pathForUser(String userId, String filePath, String bucket) {
    final ext = _extension(filePath);
    final name = '${DateTime.now().millisecondsSinceEpoch}_${bucket}_$ext';
    return '$userId/$name';
  }

  static String _extension(String path) {
    final i = path.lastIndexOf('.');
    if (i == -1) return 'jpg';
    return path.substring(i + 1).toLowerCase();
  }
}
