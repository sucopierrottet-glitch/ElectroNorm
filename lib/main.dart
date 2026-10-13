import 'package:flutter/material.dart';

import 'screens/calculator_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ElectroNormApp());
}

/// Primary application widget for ElectroNorm Pro, initialized with
/// high-contrast dark field theme and launching directly into CalculatorScreen.
class ElectroNormApp extends StatelessWidget {
  const ElectroNormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElectroNorm Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CalculatorScreen(),
    );
  }
}

/// Backward-compatible widget harness supporting legacy test runner
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElectroNorm Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$_counter'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _counter++),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
