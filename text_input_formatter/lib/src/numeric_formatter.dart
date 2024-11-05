import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'pattern_formatter.dart';

/// Maximum number of digits allowed in the formatted numeric input.
const _MAX_DIGITS = 18;

/// Default decimal separator (dot).
const _DOT = '.';

/// Default comma separator.
const _COMMA = ',';

/// [NumericFormatter] formats and validates user input to ensure it adheres to numeric patterns.
///
/// - Supports optional localization via the [locale] parameter.
/// - Handles optional fractional input, configured with [allowFraction] and [fractionDigits].
/// - Formats according to the specified [NumberFormat] and applies custom filtering on input characters.
class NumericFormatter extends PatternFormatter {
  /// Separator for the decimal symbol in the formatted number (locale-specific).
  late final String separator;

  /// Optional locale for the formatter, affects decimal separator and number grouping.
  final String? locale;

  /// Regular expression for permitted characters in the input, based on [allowFraction].
  late final RegExp regex;

  /// Maximum number of fraction digits to allow in the input.
  final int? fractionDigits;

  /// Separator for the decimal group
  late final String thousandSeparator;

  /// Allows fractional input if true.
  final bool allowFraction;

  /// Text input formatter that filters out characters based on [regex].
  late final FilteringTextInputFormatter filteringInputFormatter;

  /// Formatter instance for formatting the number according to locale and digit restrictions.
  late NumberFormat formatter;

  /// Creates an instance of [NumericFormatter] with customizable formatting parameters.
  ///
  /// - [numberFormat]: Optional [NumberFormat] for customization of decimal patterns.
  /// - [locale]: Optional locale code, affects decimal symbol and formatting.
  /// - [allowFraction]: If true, allows fractional input. Default is false.
  /// - [fractionDigits]: Limits the number of fraction digits if provided.
  ///
  /// Throws an [AssertionError] if [fractionDigits] exceeds [_MAX_DIGITS].
  NumericFormatter({
    NumberFormat? numberFormat,
    this.locale,
    this.allowFraction = false,
    this.fractionDigits,
    String? thousandSeparator,
    String? separator,
  }) : assert(fractionDigits == null || fractionDigits <= _MAX_DIGITS) {
    formatter = numberFormat ??
        NumberFormat.decimalPatternDigits(
          decimalDigits: fractionDigits,
          locale: locale,
        );
    this.separator = separator ?? formatter.symbols.DECIMAL_SEP;
    this.thousandSeparator = thousandSeparator ?? formatter.symbols.GROUP_SEP;
    regex = RegExp(allowFraction ? '[0-9]+([${this.separator}])?' : r'\d+');
    filteringInputFormatter = FilteringTextInputFormatter.allow(regex);

    assert(this.thousandSeparator != this.separator,
        '"separator cannot be the same as thousandSeparator"');
  }

  /// Formats the given [newValue] based on the pattern.
  ///
  /// Converts the value into [Decimal], ensuring only valid characters are retained.
  ///
  /// - [oldValue]: Previous value before the change.
  /// - [newValue]: Current value after the change.
  ///
  /// Returns a formatted string, ensuring it adheres to locale-specific decimal rules.
  @override
  String format(TextEditingValue oldValue, TextEditingValue newValue) {
    final value = newValue.text;
    if (value.isEmpty) return '';

    /// Need convert to valid Decimal value
    String decimals = value.replaceAll(_COMMA, _DOT);

    final inputDecimals = decimals.split(_DOT);

    /// number in fraction need to convert base on the input length
    /// With fractionDigits = 3, Input = 100.3
    ///
    /// Bad result = 100.300
    int digits = allowFraction && inputDecimals.length > 1
        ? min(inputDecimals[1].length, fractionDigits ?? _MAX_DIGITS)
        : 0;

    if (digits > 0) {
      decimals =
          '${inputDecimals[0]}${_getDecimalSep()}${inputDecimals[1].substring(0, digits)}';
    }

    final number = Decimal.tryParse(decimals) ?? Decimal.zero;

    formatter = NumberFormat.decimalPatternDigits(
      decimalDigits: digits,
      locale: locale,
    );

    var result = DecimalFormatter(formatter).format(number);

    if (thousandSeparator != formatter.symbols.GROUP_SEP) {
      result = result.replaceAll(
        formatter.symbols.GROUP_SEP,
        thousandSeparator,
      );
    }
    return allowFraction && value.endsWith(separator)
        ? '$result$separator'
        : result;
  }

  /// Validates and cleans the input by ensuring no duplicate decimal separators.
  ///
  /// - [oldValue]: Previous value before the change.
  /// - [newValue]: New value after the change.
  ///
  /// Returns a modified [TextEditingValue] where the text has only one decimal separator.
  @override
  TextEditingValue checkValidValue(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newEditingValue =
        filteringInputFormatter.formatEditUpdate(oldValue, newValue);

    /// Remove the seconds fraction separator
    RegExp regExp = _getDecimalReg();
    final dotLength = regExp.allMatches(newEditingValue.text).length;
    if (dotLength <= 1) {
      return newEditingValue;
    } else {
      return newEditingValue.copyWith(
          text: newEditingValue.text
              .substring(0, newEditingValue.text.length - 1));
    }
  }

  /// Checks if the user input character is allowed in the current numeric format.
  ///
  /// - [char]: Character entered by the user.
  ///
  /// Returns true if the character is allowed based on [regex].
  @override
  bool checkUserInput(String char) =>
      char == separator || regex.firstMatch(char) != null;

  /// Parses the formatted [value] back to its original decimal representation.
  ///
  /// - [value]: Formatted numeric string.
  ///
  /// Returns the original [Decimal] value or `null` if parsing fails.
  @override
  String? original(String value) => DecimalFormatter(formatter)
      .tryParse(
        value.replaceAll(thousandSeparator, formatter.symbols.GROUP_SEP),
      )
      ?.toString();

  /// Returns the correct decimal separator based on the current [separator] setting.
  ///
  /// Ensures consistency in decimal representation.
  String _getDecimalSep() {
    if (separator != _DOT) {
      return _DOT;
    }
    return separator;
  }

  /// Retrieves the regular expression for decimal separator based on the current locale setting.
  ///
  /// Used to validate that only one decimal separator is present in the input.
  RegExp _getDecimalReg() {
    if (separator != _DOT) {
      return RegExp(r'\\,');
    }
    return RegExp(r'\.');
  }
}
