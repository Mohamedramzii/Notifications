import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fcm/new_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  TextEditingController username_controller = TextEditingController();

  TextEditingController title_controller = TextEditingController();

  TextEditingController body_controller = TextEditingController();

  String? name = '';
  String? title = '';
  String? body = '';

  var usertoken = '';

  @override
  void initState() {
    super.initState();
    requestPermission();
    // getToken();
    initInfo();
  }

  void requestPermission() async {
    FirebaseMessaging message = FirebaseMessaging.instance;

    NotificationSettings settings = await message.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('user Granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('user Granted provisional permission');
    } else {
      debugPrint('user declined or has not accepted permission');
    }
  }

  void getToken(String name) async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        usertoken = token!;
        debugPrint(
            '------------------******Token is $usertoken *******------------');
      });
      saveToken(name);
    });
  }

  void saveToken(String name) async {
    await FirebaseFirestore.instance
        .collection('tokens')
        .doc(name)
        .set({'token': usertoken});
  }

  initInfo() {
    var androidInitialize = const AndroidInitializationSettings('@mipmap/chat');
    var iosInitialize = const DarwinInitializationSettings();
    var initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);

    FlutterLocalNotificationsPlugin().initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        switch (details.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            try {
              if (details.payload != null && details.payload!.isNotEmpty) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      NewPage(info: details.payload.toString()),
                ));
              } else {}
            } catch (e) {}
            break;
          default:
        }
      },
    );

    FirebaseMessaging.onMessage.listen(
      (message) async {
        debugPrint('--------------On Message -----------------');
        debugPrint(
            'onMessage: \n Title:${message.notification?.title} / Body: ${message.notification?.body}');
        BigTextStyleInformation bigTextStyleInformation =
            BigTextStyleInformation(message.notification!.body.toString(),
                htmlFormatBigText: true,
                contentTitle: message.notification!.title.toString(),
                htmlFormatContentTitle: true);
        AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails('dbfood', 'dbfood',
                importance: Importance.high,
                styleInformation: bigTextStyleInformation,
                priority: Priority.high,
                playSound: true,
                //here we should add mp3 sound and pass it
                // sound: RawResourceAndroidNotificationSound('_sound')
                 );
        NotificationDetails platformChannelSpecifics = NotificationDetails(
            android: androidNotificationDetails,
            iOS: const DarwinNotificationDetails());
        await FlutterLocalNotificationsPlugin().show(
            0,
            message.notification?.title,
            message.notification?.body,
            platformChannelSpecifics,
            payload: message.data['body']);
      },
    );
  }

  sendPushMessage(String title, String body, String token) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAML6S-Vc:APA91bEsFLyq4I2acubVgIwtceS4vQmb-EHZtIwlACIkEwxC_vJkymC543trBLwhHfkmfvtfpNBjvc0n9MpjJyMcM-yeQsvntKQg2qRpahHSnTxp-XMsDL5K-3jQGimEjxJ3Wo3IG4_a',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_actions': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
              'android_channel_id': 'dbfood',
            },
            'to': token
          },
        ),
      );
      print('SEEEEEEEEEEEEEEEEEEEEEEEEEEENT');
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: username_controller,
            ),
            TextFormField(
              controller: title_controller,
            ),
            TextFormField(
              controller: body_controller,
            ),
            const SizedBox(
              height: 100,
            ),
            ElevatedButton.icon(
                onPressed: () async {
                  name = username_controller.text.trim();
                  if (name!.isEmpty) {
                    'a7a';
                  } else {
                    getToken(name!);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Token')),
            ElevatedButton.icon(
                onPressed: () async {
                  name = username_controller.text.trim();
                  title = title_controller.text;
                  body = body_controller.text;
                  var targetToken = '';

                  FirebaseFirestore.instance
                      .collection('tokens')
                      .doc(name)
                      .get()
                      .then((value) {
                    targetToken = value.data()!['token'];
                    return sendPushMessage(title!, body!, targetToken);
                  });
                },
                icon: const Icon(Icons.send),
                label: const Text('Send FCM')),
          ],
        ),
      ),
    );
  }
}
