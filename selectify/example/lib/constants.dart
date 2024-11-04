import 'package:selectify/selectify.dart';

List<SelectionModel<String>> items = [
  SelectionModel(code: 'gb', valueShow: 'United Kingdom'),
  SelectionModel(
    code: 'us',
    valueShow: 'United State',
    enable: false,
  ),
  SelectionModel(
    code: 'fr',
    valueShow: 'French',
  ),
  SelectionModel(code: 'sa', valueShow: 'Saudi Arabia'),
  SelectionModel(code: 'ag', valueShow: 'Antigua and Barbuda'),
];
