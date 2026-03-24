import 'package:flutter/services.dart';

class ClipboardUtil {
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
