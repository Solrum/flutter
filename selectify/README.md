[![pub package](https://img.shields.io/pub/v/selectify.svg)](https://pub.dev/packages/selectify) [![pub points](https://img.shields.io/pub/points/selectify)](https://pub.dev/packages/selectify/score) [![popularity](https://img.shields.io/pub/popularity/selectify)](https://pub.dev/packages/selectify/score)

# Selectify - Selection Library for Flutter
Selectify is a versatile Flutter library that simplifies the creation of selection components, supporting both single and multiple selections similar to radio buttons and checkboxes. Designed for high customizability, it provides a range of layout options, like grid, list, and wrap views, along with extensive styling and behavior configurations. This makes it ideal for crafting responsive, visually consistent, and intuitive selection UIs across various app themes and user scenarios.

## Features
	-	Single and Multiple Selection Support: Offers flexible configurations for single or multiple selection modes.
	-	Highly Customizable: Control the layout, style, and interaction of each selection item.
	-	Multiple Layouts: Display items in grid or wrap formats with cross-axis count and direction options.
	-	Customizable Selection Model: Use the provided SelectionModel class or define your own for tailored control.
	-	Works with Custom Widgets: Extend functionality using custom item builders to create unique selection experiences.

<p align="center">
    <img width="40%" style="margin-right: 20px;" src="https://github.com/solrum/flutter/blob/main/selectify/screenshots/multiple.png?raw=true"/>
    <img width="40%" src="https://github.com/solrum/flutter/blob/main/selectify/screenshots/single.png?raw=true"/>
</p>

## Getting Started
To get started, add selectify to your project by including it in your pubspec.yaml file:

```yaml
dependencies:
  selectify: ^1.0.0
```

Then, import the library:

```dart
import 'package:selectify/selectify.dart';
```
## Usage

### Single Selection Example
**Wrap items**

Display items in a wrap layout that adjusts based on available screen width.
```dart
SingleSelection<String>.wrap(
    initialValue: items.last,
    items: items,
    onChanged: (item) {},
),
```
**Grid Layout**
Organize items in a grid with a defined number of items per row.
```dart
SingleSelection<String>.grid(
    crossAxisCount: 2, // Number of items per row
    initialValue: items.last,
    items: items,
    onChanged: (item) {},
),
```

### Multiple Selection Example

```dart
MultipleSelection<String>.wrap(
    initialValue: items.last,
    items: items,
    onChanged: (item) {},
    // Enable multiple selection in a single row layout.
    direction: Axis.horizontal,
),
```

### Customization
Grid Layout with Custom SelectionModel (to control each item’s display properties.)
```dart
MultipleSelection<SelectionModel<String>>.grid(
    ...
    // Signature for a function that creates a widget for a given index,
    itemBuilder: (context, item, index, selected) {
        return Opacity(
            opacity: item.enable ? 1.0 : 0.5,
            child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? Colors.blueAccent : Colors.black54,
                ),
                borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Icon(
                      selected ? Icons.check_box : Icons.check_box_outline_blank_outlined,
                      color: selected ? Colors.blueAccent : Colors.black54,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(item.valueShow ?? item.code),
                    ),
                  ],
                ),
            ),
        );
    },
),
```

# Upcoming features
	1.	Customizable Default UI: Allow developers to override the default UI components with their own designs, while still retaining core selection functionality.
	2.	Asynchronous Data Loading: Provide options for handling large or dynamically loaded lists, making it easier to use the library with paginated or streamed data sources.
	3.	Multi-level Selection Support: Introduce nested selections to handle complex structures, like categories with subcategories.
	4.	Selection Animation Options: Add customizable animations, such as fades, scales, and transitions, to enhance selection experience.
	5.	Enhanced Accessibility Features: Include better keyboard navigation, screen reader support, and visual cues for accessibility compliance.
	6.	Theming Options: Offer theme packs for different visual styles, such as material design, dark mode, or custom color schemes.

# License
<p>
Selectify is licensed under the MIT License.
</p>