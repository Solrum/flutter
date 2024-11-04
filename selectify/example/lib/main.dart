import 'package:example/constants.dart';
import 'package:flutter/material.dart';
import 'package:selectify/selectify.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Selectify Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Single Wrap'),
            ),
            SingleSelection<SelectionModel<String>>.wrap(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              initialValue: items.last,
              items: items,
              onChanged: (item) {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Single Grid'),
            ),
            SingleSelection<SelectionModel<String>>.grid(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              items: items,
              initialValue: items[1],
              onChanged: (item) {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Multiple Wrap'),
            ),
            MultipleSelection<SelectionModel<String>>.wrap(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              items: items,
              initialValue: items.take(2).toList(),
              onChanged: (items) {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Custom'),
            ),
            MultipleSelection<SelectionModel<String>>.grid(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              items: items,
              initialValue: items.take(2).toList(),
              onChanged: (items) {},
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
                          selected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank_outlined,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('Horizontal Scroll'),
            ),
            MultipleSelection<SelectionModel<String>>.wrap(
              direction: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              items: items,
              initialValue: items.take(2).toList(),
              onChanged: (items) {},
            ),
          ],
        ),
      ),
    );
  }
}
