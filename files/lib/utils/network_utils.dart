import 'dart:io';
import 'package:flutter/material.dart';

class NetworkUtils {
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    if (error.toString().contains('Connection reset by peer') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('No Internet connection')) {
      return true;
    }
    return false;
  }

  static String getErrorMessage(dynamic error) {
    if (isNetworkError(error)) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Failed to load image. Please try again.';
  }

  static Widget buildErrorWidget(BuildContext context, dynamic error, {double? size}) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.grey[600],
            size: size ?? 40,
          ),
          const SizedBox(height: 8),
          Text(
            'No Internet',
            style: TextStyle(
              color: Colors.grey[600],

            ),
          ),
        ],
      ),
    );
  }
}

