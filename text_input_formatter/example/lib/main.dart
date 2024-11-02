import 'package:flutter/material.dart';
import 'package:text_input_formatter/text_input_formatter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Input Formatter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Input Formatter Page'),
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // numerical
              TextField(
                decoration: InputDecoration(
                  label: Text('Numeric'),
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  NumericFormatter(
                    allowFraction: true,
                    fractionDigits: 5,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// date format
              TextField(
                decoration: InputDecoration(
                  label: Text(DatePattern.dd_MM_yyyy.value),
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  DateFormatter(
                    separator: DateSeparator.slash,
                    pattern: DatePattern.dd_MM_yyyy,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              //credit card
              TextField(
                decoration: InputDecoration(
                  label: Text('Credit Card'),
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  CreditCardFormatter(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
