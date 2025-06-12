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
              child: Text(cancelButtonText),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor ?? Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              child: Text(confirmButtonText),
            ),
          ],
        );
      },
    );
  }
