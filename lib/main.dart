import 'package:flutter/material.dart';

void main() {
  runApp(const TasbeehApp());
}

class TasbeehApp extends StatelessWidget {
  const TasbeehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تسبيح',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark, // Dark theme for better focus
        scaffoldBackgroundColor: Colors.grey.shade900, // Darker background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey.shade800,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          contentTextStyle: TextStyle(color: Colors.white70),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.green.shade300),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade600),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade300, width: 2),
          ),
        ),
      ),
      home: const TasbeehHomePage(),
    );
  }
}

class TasbeehHomePage extends StatefulWidget {
  const TasbeehHomePage({super.key});

  @override
  State<TasbeehHomePage> createState() => _TasbeehHomePageState();
}

class _TasbeehHomePageState extends State<TasbeehHomePage> {
  int _counter = 0;
  int _target = 33; // Default target

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  void _setTarget(int newTarget) {
    setState(() {
      _target = newTarget;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool targetReached = _target > 0 && _counter >= _target;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسبيح'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'إعادة تعيين العداد',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showTargetDialog(context);
            },
            tooltip: 'تعيين الهدف',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'العدد الحالي:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: targetReached ? Colors.amber.shade300 : Colors.white,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              'الهدف: ${_target == 0 ? 'غير محدد' : _target}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _incrementCounter,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _showTargetDialog(BuildContext context) async {
    TextEditingController targetController = TextEditingController(text: _target.toString());

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تعيين الهدف'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'أدخل الهدف (0 لغير محدد)',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حفظ'),
              onPressed: () {
                int? newTarget = int.tryParse(targetController.text);
                if (newTarget != null && newTarget >= 0) {
                  _setTarget(newTarget);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}