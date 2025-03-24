import 'package:intl/intl.dart';

class DateFormatter {
  static String getMessageTime(DateTime dateTime, String languageCode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // 오늘이면 시간만
      return DateFormat('a h:mm', languageCode).format(dateTime);
    } else if (messageDate == yesterday) {
      // 어제면 '어제'로 표시
      switch (languageCode) {
        case 'ja':
          return '昨日';
        case 'en':
          return 'Yesterday';
        default:
          return '어제';
      }
    } else if (now.difference(dateTime).inDays < 7) {
      // 일주일 이내면 요일
      switch (languageCode) {
        case 'ja':
          return DateFormat('E曜日', languageCode).format(dateTime);
        case 'en':
          return DateFormat('EEEE', languageCode).format(dateTime);
        default:
          return DateFormat('EEEE', languageCode).format(dateTime);
      }
    } else {
      // 그 외에는 날짜
      return DateFormat('M/d', languageCode).format(dateTime);
    }
  }

  static String getLastChatTime(DateTime? dateTime, String languageCode) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      switch (languageCode) {
        case 'ja':
          return '今';
        case 'en':
          return 'now';
        default:
          return '방금';
      }
    } else if (difference.inHours < 1) {
      switch (languageCode) {
        case 'ja':
          return '${difference.inMinutes}分前';
        case 'en':
          return '${difference.inMinutes}m';
        default:
          return '${difference.inMinutes}분 전';
      }
    } else if (difference.inHours < 24) {
      switch (languageCode) {
        case 'ja':
          return '${difference.inHours}時間前';
        case 'en':
          return '${difference.inHours}h';
        default:
          return '${difference.inHours}시간 전';
      }
    } else {
      return getMessageTime(dateTime, languageCode);
    }
  }
} 