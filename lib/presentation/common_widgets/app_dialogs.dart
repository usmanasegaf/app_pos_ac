// lib/presentation/common_widgets/app_dialogs.dart

import 'package:flutter/material.dart';

/// Shows a custom confirmation dialog.
Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmButtonText = 'Yes',
    String cancelButtonText = 'No',
    Color? confirmButtonColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              // Mengatur warna teks tombol 'No' menjadi hitam
              // Mengatur warna latar belakang tombol 'No' menjadi abu-abu terang
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Warna teks
                backgroundColor: Colors.grey[200], // Warna latar belakang tombol "No"
                side: const BorderSide(color: Colors.grey, width: 1.0), // Border tipis abu-abu
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Memastikan border juga punya radius
              ),
              child: Text(cancelButtonText),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Mengubah warna latar belakang tombol 'Yes' menjadi warna yang diinginkan
                // Defaultnya ke biru jika confirmButtonColor tidak disediakan
                backgroundColor: confirmButtonColor ?? Colors.blueAccent, // Warna latar belakang tombol "Yes"
                foregroundColor: Colors.white, // Warna teks agar kontras
                side: const BorderSide(color: Colors.blueAccent, width: 1.0), // Border mengikuti warna background
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Memastikan border juga punya radius
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              // Mengatur warna teks tombol 'Yes' menjadi putih (agar kontras dengan latar belakang)
              child: Text(confirmButtonText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

/// Shows a simple informational message dialog (replaces alert()).
/// This function is typically used to display general messages or errors to the user.
Future<void> showAppMessageDialog(BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'OK',
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(buttonText),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
