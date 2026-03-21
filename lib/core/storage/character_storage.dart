import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/app_supabase.dart';

/// Uploads character avatars to Supabase Storage.
/// Path format: `{bucket}/{userId}/{uniqueId}.{ext}` so RLS allows upload.
class CharacterStorage {
  static const String avatarsBucket = 'avatars';

  /// Uploads a file to avatars bucket. Returns public URL or throws.
  static Future<String> uploadAvatar(String userId, File file) async {
    final path = _pathForUser(userId, file.path);
    await AppSupabase.client.storage.from(avatarsBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return AppSupabase.client.storage.from(avatarsBucket).getPublicUrl(path);
  }

  static String _pathForUser(String userId, String filePath) {
    final ext = _extension(filePath);
    final name = '${DateTime.now().millisecondsSinceEpoch}_$ext';
    return '$userId/$name';
  }

  static String _extension(String path) {
    final i = path.lastIndexOf('.');
    if (i == -1) return 'jpg';
    return path.substring(i + 1).toLowerCase();
  }
}
