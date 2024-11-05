import 'dart:math';

import 'package:flutter/services.dart';

/// An abstract class [PatternFormatter] that extends [TextInputFormatter] to provide a base for
/// custom input formatting. It allows for the creation of specialized formatters that enforce
/// a specific input pattern in a text field.
///
/// This class provides methods for checking input validity, formatting input,
/// and updating the cursor position based on inserted characters.
/// Classes that inherit from [PatternFormatter] should implement the [checkUserInput],
/// [format], and [checkValidValue] methods.
abstract class PatternFormatter extends TextInputFormatter {
  /// Formats the input value based on a specified pattern, enforcing the input
  /// restrictions defined in this formatter.
  ///
  /// - [oldValue]: The previous value of the text field before editing.
  /// - [newValue]: The current value of the text field after editing.
  ///
  /// Returns a [TextEditingValue] that reflects the formatted text and updated cursor position.
  /// This method adjusts the cursor position after format changes to keep it close to the user's input.
  @override
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Validate and clean the input using checkValidValue
    newValue = checkValidValue(oldValue, newValue);
    int selectionIndex = newValue.selection.end;

    // Format the text as per the pattern
    final newText = format(oldValue, newValue);

    // Calculate the new selection index after formatting
    int inputCount = 0;
    int insertCount = 0;

    for (int i = 0; i < newText.length && inputCount < selectionIndex; i++) {
      final character = newText[i];
      if (checkUserInput(character)) {
        inputCount++;
      } else {
        insertCount++;
      }
    }

    // Update selection index by insertCount while limiting it to newText length
    selectionIndex = min(selectionIndex + insertCount, newText.length);

    // Return the formatted text and updated cursor position
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
      composing: TextRange.empty,
    );
  }

  /// Validates if the character [char] is allowed according to the pattern.
  ///
  /// Classes that inherit from [PatternFormatter] should implement this method to define
  /// which characters are permitted in the input.
  ///
  /// - [char]: Character to be checked.
  ///
  /// Returns true if the character is valid according to the input pattern.
  bool checkUserInput(String char);

  /// Formats the [newValue] according to the pattern defined in the implementing class.
  ///
  /// - [oldValue]: The previous value before the change.
  /// - [newValue]: The current value after the change.
  ///
  /// Returns the formatted string representation of [newValue] after applying the pattern.
  String format(TextEditingValue oldValue, TextEditingValue newValue);

  /// Checks if the [newValue] is valid according to the pattern and returns
  /// an updated [TextEditingValue] with valid input only.
  ///
  /// - [oldValue]: The previous text value.
  /// - [newValue]: The new text value to validate.
  ///
  /// Returns a [TextEditingValue] where any invalid characters have been removed or adjusted.
  TextEditingValue checkValidValue(
      TextEditingValue oldValue, TextEditingValue newValue);

  /// Returns the original unformatted string representation of the [value].
  ///
  /// - [value]: Formatted text.
  ///
  /// Returns a string in its original, unformatted form if possible.
  String? original(String value);
}
