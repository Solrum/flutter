import 'package:flutter/material.dart';

class SelectionModel<T> {
  final T code;
  final String? valueShow;
  final bool enable;

  const SelectionModel({
    required this.code,
    this.valueShow,
    this.enable = true,
  });

  SelectionModel copyWith({T? code, String? valueShow, bool? enable}) {
    return SelectionModel(
      code: null == code ? this.code : code as T,
      valueShow: valueShow ?? this.valueShow,
      enable: enable ?? this.enable,
    );
  }

  @override
  int get hashCode => Object.hash(code, valueShow, enable);

  @override
  bool operator ==(Object other) {
    return other is SelectionModel &&
        other.code == code &&
        other.valueShow == valueShow &&
        other.enable == enable;
  }

  @override
  String toString() {
    return "SelectionModel(code: $code, valueShow: $valueShow, enable: $enable)";
  }
}

class SelectionConfig {
  final double radius;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double? itemHeight;
  final TextStyle textStyle;

  const SelectionConfig({
    this.radius = 8,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.itemHeight,
    this.textStyle = const TextStyle(fontSize: 15, height: 1),
  });

  SelectionConfig copyWith({
    double? radius,
    int? crossAxisCount,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    double? itemHeight,
    TextStyle? textStyle,
  }) {
    return SelectionConfig(
      radius: radius ?? this.radius,
      crossAxisCount: crossAxisCount ?? this.crossAxisCount,
      mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
      textStyle: textStyle ?? this.textStyle,
      itemHeight: itemHeight ?? this.itemHeight,
    );
  }
}
