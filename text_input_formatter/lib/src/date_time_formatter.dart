import 'package:flutter/services.dart';
import 'package:text_input_formatter/src/pattern_formatter.dart';

enum DatePattern {
  dd_MM_yyyy('dd/MM/yyyy'),
  MM_dd_yyyy('MM/dd/yyyy'),
  yyyy_MM_dd('yyyy/MM/dd'),
  yyyy_dd_mm('yyyy/dd/MM'),
  dd_MM('dd/MM'),
  MM_dd('MM/dd'),
  yyyy_MM('yyyy/MM'),
  MM_yyyy('MM/yyyy');

  final String value;

  const DatePattern(this.value);
}

enum DateSeparator {
  slash('/'),
  dot('.'),
  dash('-');

  final String value;

  const DateSeparator(this.value);
}

const _DATE_SEP = '/';
const INDEX_NOT_FOUND = -1;

/// An abstract class [DateFormatter] that extends [PatternFormatter] to provide
/// a specialized formatter for handling date inputs in various formats. It allows
/// users to input dates in a specific pattern while automatically inserting
/// separators at appropriate positions.
///
/// This class provides methods for formatting date inputs, checking valid user input,
/// and retrieving the original unformatted string representation of the date.
///
/// Classes that inherit from [DateFormatter] should implement the [checkUserInput],
/// [format], and [checkValidValue] methods.
class DateFormatter extends PatternFormatter {
  final FilteringTextInputFormatter
      filteringTextInputFormatter; // Formatter to restrict input characters
  final DateSeparator separator; // Separator to be used in the date format
  final DatePattern pattern; // Selected date format pattern
  final bool patternAsPlaceholder; // Flag to show the pattern as a placeholder

  /// Initializes the [DateFormatter] with a specified [pattern], [separator],
  /// and a flag [patternAsPlaceholder] to guide user input visually.
  ///
  /// - [pattern]: The date pattern to enforce (default is dd/MM/yyyy).
  /// - [separator]: The separator character to use in the formatted output
  /// - [patternAsPlaceholder]: Whether to show the pattern in the input field
  DateFormatter({
    this.pattern = DatePattern.dd_MM_yyyy,
    this.separator = DateSeparator.slash,
    this.patternAsPlaceholder = true,
  }) : filteringTextInputFormatter = FilteringTextInputFormatter.allow(
          RegExp('[0-9]+([${separator.value}])?'),
        );

  /// Provides the date pattern as a string, with the separator applied.
  ///
  /// Returns the date pattern string where the default separator / is replaced
  /// by the user-defined [separator].
  String get _strPattern =>
      pattern.value.replaceAll(_DATE_SEP, separator.value);

  /// Returns a list of indices where separators should appear in the formatted input.
  ///
  /// The method scans the formatted pattern to identify the positions of
  /// the specified [separator] for formatting.
  List<int> get _sepIndices => _sepIndexes();

  /// Computes the positions of separators based on the chosen pattern.
  ///
  /// Scans through the formatted pattern and collects the indices of
  /// the separator characters. This helps in formatting the user input
  /// correctly.
  List<int> _sepIndexes() {
    List<int> indices = [];
    for (int i = 0; i < _strPattern.length; i++) {
      if (_strPattern[i] == separator.value) {
        indices.add(i); // Collects the index of each separator
      }
    }
    return indices;
  }

  /// Formats the [newValue] to match the date pattern with appropriate separators.
  ///
  /// - [oldValue]: The previous value of the text field before editing.
  /// - [newValue]: The current value of the text field after editing.
  ///
  /// Returns a [String] that reflects the formatted date text. It manages
  /// the insertion of separators and ensures the text does not exceed the
  /// defined pattern.
  @override
  String format(TextEditingValue oldValue, TextEditingValue newValue) {
    final deleted = oldValue.text.length >
        newValue.text.length; // Checks if characters were deleted
    final input = newValue.text;
    final indices = _sepIndices
        .where((index) => index >= 0 && index <= input.length)
        .toList();

    if (indices.isEmpty) {
      // Return input if no separators are needed
      return input;
    }

    List<String> chars = [];

    // Loop through the input characters and insert separators in correct positions.
    for (int i = 0, j = 0; i < input.length; i++) {
      if (input[i] == separator.value &&
          (j >= indices.length || i != indices[j])) {
        continue; // Skip redundant separators
      }
      chars.add(input[i]);
      if (j < indices.length && i == indices[j]) {
        j++;
      }
    }

    // Insert separators into their respective positions if not already present.
    for (int i = indices.length - 1; i >= 0; i--) {
      int index = indices[i];
      if (index < chars.length && chars[index] != separator.value) {
        chars.insert(index, separator.value);
      }
    }

    String result = chars.join('');

    // Trim any excess characters beyond the pattern length.
    if (result.length > _strPattern.length) {
      result = result.substring(0, _strPattern.length);
    }

    // Remove trailing separator if deleted.
    if (deleted && result.endsWith(separator.value)) {
      result = result.substring(0, result.length - 1);
    }

    return result; // Return the formatted result
  }

  /// Checks if the [newValue] is valid according to the pattern
  /// and returns an updated [TextEditingValue] with valid input only.
  ///
  /// - [oldValue]: The previous text value.
  /// - [newValue]: The new text value to validate.
  ///
  /// Returns a [TextEditingValue] where any invalid characters have been removed or adjusted.
  @override
  TextEditingValue checkValidValue(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      filteringTextInputFormatter.formatEditUpdate(oldValue, newValue);

  /// Returns the original unformatted string representation of the [value].
  ///
  /// - [value]: Formatted text.
  ///
  /// Returns a string in its original, unformatted form if possible by removing
  /// the separator characters.
  @override
  String? original(String value) =>
      value.replaceAll(separator.value, ''); // Removes separators

  /// Validates if the character [char] is allowed according to the pattern.
  ///
  /// Classes that inherit from [DateFormatter] should implement this method to define
  /// which characters are permitted in the input.
  ///
  /// - [char]: Character to be checked.
  ///
  /// Returns true if the character is valid according to the input pattern.
  @override
  bool checkUserInput(String char) =>
      char != separator.value; // Excludes separator from valid input
}
