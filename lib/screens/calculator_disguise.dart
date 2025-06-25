import 'package:flutter/material.dart';

class CalculatorDisguise extends StatelessWidget {
  const CalculatorDisguise({super.key});

  @override
  Widget build(BuildContext context) {
    final List<List<String>> buttons = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['C', '0', '.', '+'],
      ['='],
    ];

    String display = '';

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Calculator"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text(
              display,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          ...buttons.map((row) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((label) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Do nothing, it's just a mock interface.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.all(20),
                    shape: const CircleBorder(),
                    elevation: 3,
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          )),
        ],
      ),
    );
  }
}
