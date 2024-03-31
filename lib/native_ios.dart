import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeIos extends StatefulWidget {
  const NativeIos({super.key});

  @override
  State<NativeIos> createState() => _NativeIosState();
}

class _NativeIosState extends State<NativeIos> {
  static const platformIos = const MethodChannel('method_channel_ios');

  // Method to show toast
  Future<void> showToastIos() async {
    try {
      await platformIos.invokeMethod('showToast', {'message': 'Hello from native iOS!'});
    } on PlatformException catch (e) {
      print("Failed to show toast: '${e.message}'.");
    }
  }

  // Method to show notification
  Future<void> showNotification() async {
    try {
      await platformIos.invokeMethod('showNotification', {'message': 'Hello from native iOS!'});
    } on PlatformException catch (e) {
      print("Failed to show notification: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("data")),
      body:  Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                showToastIos();
              },
              child: Text('Showing native toast'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: showNotification,
              child: Text('Show Notification'),
            ),
          ),
        ],
      ),
    );
  }
}
