import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_method_channel/native_events.dart';
import 'package:flutter_method_channel/native_ios.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: const MyHomePage(title: 'Native To Flutter'),
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
  String _batteryLevel = 'Unknown battery level.';
  int dateTime = 0;

  static const platformIos = const MethodChannel('method_channel_ios');

  // Method to show toast
  Future<void> showToastIos() async {
    try {
      await platformIos.invokeMethod('showToast', {'message': 'Hello from native iOS!'});
    } on PlatformException catch (e) {
      print("Failed to show toast: '${e.message}'.");
    }
  }

  Future<void> _showIncomingCallBanner(BuildContext context) async {
    try {
      await NativeEvent.methodChannel.invokeMethod('showIncomingCallBanner');
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  Future<void> displayNotification({String? title, String? text}) async {
    try {
      await NativeEvent.methodChannel.invokeMethod('displayNotification', {"title": title, "text": text});
    } on PlatformException catch (e) {
      print("Failed to display notification: '${e.message}'.");
    }
  }

  showToast(String msg) {
    NativeEvent.methodChannel.invokeMethod('ShowToast', msg);
  }

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await NativeEvent.methodChannel.invokeMethod<int>('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
      print("battery:  $batteryLevel");
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  _getDateTime() {
    NativeEvent.methodChannel.invokeMethod('getDateTime');
  }

  Stream<String> streamTimeFromNative() {
    const eventChannel = EventChannel('timeHandlerEvent');
    return eventChannel.receiveBroadcastStream().map((event) => event.toString());
  }

  _launchURL() async {
    final Uri url = Uri.parse('https://github.com/khokanuzzman/flutter_native_communication');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    NativeEvent.initializeChannel();
    NativeEvent.onNativeEvent.listen((data) {
      print("working");
      setState(() {
        dateTime = data;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _getBatteryLevel,
            child: const Text('Get Battery Level'),
          ),
          Center(
            child: Text(_batteryLevel),
          ),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: _getDateTime,
            child: const Text('Start timer'),
          ),
          Text(dateTime.toString()),
          SizedBox(height: 20,),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                var status = await Permission.notification.request();
                if (status.isGranted) {
                  displayNotification(title: "Custom title", text: "Custom description");
                } else if (status.isDenied) {
                  // Permission denied
                  print('Notification permission denied');
                } else if (status.isPermanentlyDenied) {
                  // Permission permanently denied, navigate to app settings
                  print('Notification permission permanently denied');
                  openAppSettings();
                }
              },
              child: Text('Display Notification'),
            ),
          ),
          SizedBox(height: 20,),
          Center(
            child: ElevatedButton(
              onPressed: () {
                _showIncomingCallBanner(context);
              },
              child: Text('Show Incoming Call Banner'),
            ),
          ),
          Text("This timer is from native to flutter"),
          StreamBuilder<String>(
            stream: streamTimeFromNative(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  '${snapshot.data}',
                  style: Theme.of(context).textTheme.headline4,
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                _launchURL();
              },
              child: Text('Get the github link'),
            ),
          ),Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NativeIos()),
                );
              },
              child: Text('From iOs'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showToast('Hi Team'),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
