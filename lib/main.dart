import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'dart:io' show Platform;
import 'dart:async';

import 'package:pushy_flutter/pushy_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainPage());
}

// Please place this code in main.dart,
// After the import statements, and outside any Widget class (top-level)

@pragma('vm:entry-point')
void backgroundNotificationListener(Map<String, dynamic> data) {
  // Print notification payload data
  print('Received notification: $data');

  // Notification title
  String notificationTitle = 'PushyWkk';

  // Attempt to extract the "message" property from the payload: {"message":"Hello World!"}
  String notificationText = data['message'] ?? 'Hello World!';

  // Android: Displays a system notification
  // iOS: Displays an alert dialog
  Pushy.notify(notificationTitle, notificationText, data);

  // Clear iOS app badge number
  Pushy.clearBadge();

  playNotiSound();
}

playNotiSound() async {
  final _player = AudioPlayer();

  try {
    await _player
        .setAudioSource(AudioSource.asset("assets/songs/incomeing.mp3"));
    await _player.play();
    Future.delayed(const Duration(seconds: 20));
    _player.stop();
  } catch (e) {
    print("Error loading audio source: $e");
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pushy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.grey[900],
      ),
      home: PushyDemo(),
    );
  }
}

class PushyDemo extends StatefulWidget {
  @override
  _PushyDemoState createState() => _PushyDemoState();
}

class _PushyDemoState extends State<PushyDemo> {
  String _deviceToken = 'Loading...';
  String _instruction = '(please wait)';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    pushySubcribe();
  }

  pushySubcribe() async {
    try {
      if (await Pushy.isRegistered()) {
        await Pushy.subscribe('joy');
        print('Subscribed to topic successfully');
      } else {
        pushyRegister();
      }
    } on PlatformException {
      print('Subscribed fail');
    }
  }

  Future pushyRegister() async {
    try {
      String deviceToken = await Pushy.register();
      print('Device token: $deviceToken');
      //save token
      // helper.writeSecureData(key: TOKEN_KEY, value: deviceToken);
    } on PlatformException catch (error) {
      // Display an alert with the error message
      print('Device token error: ${error.message}');
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method
  Future<void> initPlatformState() async {
    // Start the Pushy service
    Pushy.listen();

    // Set Pushy App ID (required for Web Push)
    Pushy.setAppId('6659a98044f72bc8361c9614');

    // Enable FCM Fallback Delivery
    Pushy.toggleFCM(true);

    // Set custom notification icon (Android)
    Pushy.setNotificationIcon('ic_notify');

    try {
      // Register the device for push notifications
      String deviceToken = await Pushy.register();

      // Print token to console/logcat
      print('Device token: $deviceToken');

      // Send the token to your backend server
      // ...

      // Update UI with token
      setState(() {
        _deviceToken = deviceToken;
        _instruction =
            isAndroid() ? '(copy from logcat)' : '(copy from console)';
      });
    } catch (error) {
      // Print to console/logcat
      print('Error: ${error.toString()}');

      // Show error
      setState(() {
        _deviceToken = 'Registration failed';
        _instruction = '(restart app to try again)';
      });
    }

    // Enable in-app notification banners (iOS 10+)
    Pushy.toggleInAppBanner(true);

    // Listen for push notifications received
    Pushy.setNotificationListener(backgroundNotificationListener);

    // Listen for push notification clicked
    Pushy.setNotificationClickListener((Map<String, dynamic> data) {
      // Print notification payload data
      print('Notification clicked: $data');

      // Extract notification messsage
      String message = data['message'] ?? 'Hello World!';

      // Display an alert with the "message" payload value
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Notification clicked'),
              content: Text(message),
              actions: [
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog'); 
                  },
                )
              ]);
        },
      );

      // Clear iOS app badge number
      Pushy.clearBadge();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Demo app UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pushy Testing'),
      ),
      body: Builder(
        builder: (context) => Center(
            child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Image.asset('assets/ic_logo.png', width: 90),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(_deviceToken,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[700])),
                  ),
                  Text(_instruction,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const Text(
                    '1. Settings >  permission ထဲက Auto-start ဆိုတာကိုရွေးပြီး notification မတက်ဘူးဖြစ်နေတဲ့ applications တွေကို slider လေးဖွင့်ပေးရမှာပါ',
                    style: TextStyle(
                        color: Color.fromARGB(255, 212, 86, 83),
                        fontWeight: FontWeight.w600,
                        fontSize: 18),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const MaterialButton(
                      color: Colors.amber,
                      onPressed: getAutoStartPermission,
                      child: Text(
                        'Open Auto-Start',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 25),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    '2. Setting > Battery and performance > Choose apps > Noti တက်စေချင်တဲ့ app ကိုရွေး > Battery Saver > No restrictions ဆိုတာကိုရွေးပေးရပါမယ်။',
                    style: TextStyle(
                        color: Color.fromARGB(255, 212, 86, 83),
                        fontWeight: FontWeight.w600,
                        fontSize: 18),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
            
                  // const Text(
                  //   '3. Battery>Battery Saver> Adaptive Battery > Expand More > Turn on Use Adaptive Battery if its turned off.',
                  //   style: TextStyle(
                  //       color: Color.fromARGB(255, 212, 86, 83),
                  //       fontWeight: FontWeight.w600,
                  //       fontSize: 25),
                  // ),
                  // const SizedBox(
                  //   height: 20,
                  // ),
                  // const Text(
                  //   '4. Apps >  See all apps> Choose your app. Then, tap Battery>Under "Manage battery usage," tap Optimized.',
                  //   style: TextStyle(
                  //       color: Color.fromARGB(255, 212, 86, 83),
                  //       fontWeight: FontWeight.w600,
                  //       fontSize: 25),
                  // ),
                  // const SizedBox(
                  //   height: 20,
                  // ),
                  MaterialButton(
                      color: Colors.amber,
                      onPressed: () {
                       OptimizeBattery.openBatteryOptimizationSettings();
                      },
                      child: const Text(
                        'Open battery optimization',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 25),
                      )),
                ]),
          ),
        )),
      ),
    );
  }
}

bool isAndroid() {
  try {
    // Return whether the device is running on Android
    return Platform.isAndroid;
  } catch (e) {
    // If it fails, we're on Web
    return false;
  }
}
