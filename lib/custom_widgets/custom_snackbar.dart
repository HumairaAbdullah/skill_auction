import 'package:flutter/material.dart';

class CustomSnackbar {
  static SnackBar show ({required Widget content}) {
    return SnackBar(
      content: content,
      backgroundColor:Color(0xFF8a2be1),
      padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),

    );
  }
}