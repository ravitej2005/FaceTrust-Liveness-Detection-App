import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';

void displaySnackBar(
    BuildContext context, String message, IconData icon, Color color,Color backgroundColor) {
  DelightToastBar(
    position: DelightSnackbarPosition.top,
    autoDismiss: true,
    snackbarDuration: Duration(milliseconds: 2500),
    builder: (context) => ToastCard(
      // color: const Color.fromARGB(255, 255, 255, 255),
      color: backgroundColor,
      leading: Icon(
        icon,
        size: 28,
        color: color,
      ),
      title: Text(
        message,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: color,
        ),
      ),
      trailing: GestureDetector(
        onTap: () {
          DelightToastBar.removeAll();
        },
        child: Icon(
          Icons.close,
        ),
      ),
    ),
  ).show(context);
}
