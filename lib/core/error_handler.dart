import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message,
      {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration ?? const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message,
      {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is String) return error;

    // Handle specific error types
    if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    }

    // Add more specific error handling as needed
    return 'An unexpected error occurred. Please try again.';
  }
}
