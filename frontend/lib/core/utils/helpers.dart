import 'package:intl/intl.dart';

class Helpers {
  // Date formatting
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }
  
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }
  
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  // Password validation
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  // Color to hex string
  static String colorToHex(int color) {
    return '#${color.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  // Hex string to color
  static int hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    return int.parse('FF$hexColor', radix: 16);
  }
  
  // Debounce function
  static Function debounce(Function func, Duration wait) {
    int timeoutId = 0;
    return () {
      timeoutId++;
      final currentTimeoutId = timeoutId;
      Future.delayed(wait, () {
        if (currentTimeoutId == timeoutId) {
          func();
        }
      });
    };
  }
  
  // Throttle function
  static Function throttle(Function func, Duration wait) {
    int lastCall = 0;
    return () {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCall >= wait.inMilliseconds) {
        lastCall = now;
        func();
      }
    };
  }
  
  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  // Extract ID from various formats (string, object with _id, object with id)
  static String extractId(dynamic value) {
    if (value == null) return '';
    
    if (value is String) {
      return value;
    }
    
    if (value is Map<String, dynamic>) {
      return value['_id']?.toString() ?? 
             value['id']?.toString() ?? 
             '';
    }
    
    return value.toString();
  }
  
  // Safe date parsing with fallback
  static DateTime parseDate(dynamic value, {DateTime? fallback}) {
    if (value == null) {
      return fallback ?? DateTime.now();
    }
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return fallback ?? DateTime.now();
      }
    }
    
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return fallback ?? DateTime.now();
      }
    }
    
    return fallback ?? DateTime.now();
  }
  
  // Extract string value with fallback
  static String extractString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }
  
  // Extract int value with fallback
  static int extractInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
  
  // Extract double value with fallback
  static double extractDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }
  
  // Extract bool value with fallback
  static bool extractBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return fallback;
  }
}

