import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:slidable_button_package/slidable_button_package.dart';

void main() {
  test(
    'adds one to input values',
    () {
      AnimatedSlidableButton(
        // This is required property

        onChanged: (ButtonPosition value) {
          log("Button Position : $value");
        },

        //  Use other properties for customizing your button.

        padding: const EdgeInsets.all(8),
        height: 50,
        width: 200,
        buttonHeight: 45,
        buttonWidth: 45,
        borderRadius: BorderRadius.circular(60),
        buttonBorderRadius: BorderRadius.circular(60),
        color: Colors.black,
        buttonColor: Colors.white,
        dismissible: true,
        child: const Center(
          child: Text(
            "Slide >>>",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  );
}
