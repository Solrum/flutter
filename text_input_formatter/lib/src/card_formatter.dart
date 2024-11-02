import 'dart:math';
import 'package:flutter/services.dart';
import 'package:text_input_formatter/text_input_formatter.dart';

/// A custom formatter for credit card numbers that formats the input into
/// groups of 4 digits separated by a specified separator (default is a space).
///
/// Example:
/// - Input: "1234567890123456"
/// - Output: "1234 5678 9012 3456"
class CreditCardFormatter extends PatternFormatter {
  // Regular expression to allow only numeric input (0-9).
  static final RegExp _regExp = RegExp(r'[0-9]');

  // An instance of FilteringTextInputFormatter to allow only numeric input
  // based on _regExp.
  final TextInputFormatter _filteringTextInputFormatter =
      FilteringTextInputFormatter.allow(_regExp);

  // Separator used between each group of 4 digits. Default is a single space.
  final String separator;

  /// The formatter will truncate any input beyond the specified maxLength
  /// (default 16).
  final int maxLength;

  /// Creates a [CreditCardFormatter] with an optional [separator]
  /// for formatting.
  CreditCardFormatter({
    this.separator = ' ',
    this.maxLength = 16,
  });

  /// Checks if a single character [char] matches the numeric pattern (0-9).
  /// Returns `true` if the character is numeric, otherwise `false`.
  @override
  bool checkUserInput(String char) => _regExp.firstMatch(char) != null;

  /// Ensures that only numeric values are allowed in the
  /// new [TextEditingValue].
  /// Applies [_filteringTextInputFormatter] to filter out any
  /// non-numeric input.
  ///
  /// Parameters:
  /// - [oldValue]: The previous value before the current edit.
  /// - [newValue]: The new value to be validated.
  ///
  /// Returns a `TextEditingValue` that only contains numeric characters.
  @override
  TextEditingValue checkValidValue(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      _filteringTextInputFormatter.formatEditUpdate(oldValue, newValue);

  /// Formats the credit card number by inserting [separator] every 4 digits.
  ///
  /// Parameters:
  /// - [oldValue]: The previous value before the current edit.
  /// - [newValue]: The new value to be formatted.
  ///
  /// Returns a `String` containing the credit card number formatted with the
  /// specified separator.
  @override
  String format(TextEditingValue oldValue, TextEditingValue newValue) {
    // Extracts only the numeric characters from newValue.
    final value =
        newValue.text.substring(0, min(newValue.text.length, maxLength));
    final buffer = StringBuffer();

    int offset = 0;
    int count = min(4, value.length);
    final length = value.length;

    // Groups digits by 4 and inserts the separator between groups.
    for (; count <= length; count += min(4, max(1, length - count))) {
      buffer.write(value.substring(offset, count));
      if (count < length) {
        buffer.write(separator);
      }
      offset = count;
    }
    return buffer.toString();
  }

  /// Retrieves the original numeric string by removing all
  /// separator characters.
  ///
  /// Parameters:
  /// - [value]: The formatted credit card number string.
  ///
  /// Returns the numeric credit card number as a `String` without separators.
  @override
  String? original(String value) => value.replaceAll(separator, '');
}
