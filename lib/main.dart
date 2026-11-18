import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.loadFonts();
  runApp(const MyApp());
}

/// Root app. Grows its router/shell in Iteration 29; for now it proves
/// the Living Sketchbook theme end-to-end on the temporary counter screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCSTGO Showcase Kiosk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MyHomePage(title: 'UCSTGO Showcase Kiosk'),
    );
  }
}

/// Temporary counter screen (default scaffold) — replaced by the real
/// feedback flow in Phase 3. Kept so `test/widget_test.dart` can prove the
/// app tree still builds and interacts while the foundation is laid.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
