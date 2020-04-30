import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as statusCodes;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const URL = 'ws://localhost:3000';


void main() =>
    runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FauxLoginPage(),
    );
  }
}

class FauxLoginPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();




  void goToMainPage(String nickname, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AnnouncementPage(nickname)
        )
    );
  }



  @override
  Widget build(BuildContext context) =>
      Scaffold(
          appBar: AppBar(title: Text("Login Page")),
          body: Center(
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      labelText: "Nickname"
                  ),
                  onSubmitted: (nickname) => goToMainPage(nickname, context),
                ),
                FlatButton(
                    onPressed: () => goToMainPage(controller.text, context),
                    child: Text("Log In")
                )
              ],
            ),
          )
      );
}

class AnnouncementPage extends StatefulWidget {
  AnnouncementPage(this.nickname);

  final String nickname;

  @override
  AnnouncementPageState createState() => AnnouncementPageState();
}

class AnnouncementPageState extends State<AnnouncementPage> {
  WebSocketChannel channel = WebSocketChannel.connect(Uri.parse(URL));
  TextEditingController controller = TextEditingController();
  var sub;
  String text;

  @override
   void initState() {
    super.initState();

    //createLocalNotification();

    FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    var androidInit = AndroidInitializationSettings('app_icon');
    var iOSInit = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var init = InitializationSettings(androidInit, iOSInit);


    notifications.initialize(init).then((done) {
      sub = channel.stream.listen((newData) {
        setState(() {
          text = newData;
        });

        notifications.show(
            0,
            "New announcement",
            newData,
            NotificationDetails(
                AndroidNotificationDetails(
                    "announcement_app_0",
                    "Announcement App",
                    ""
                ),
                IOSNotificationDetails()
            )
        );
      });
    });
  }

  /// For manual displaying local notification
  Future createLocalNotification() async{

    FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    var androidInit = AndroidInitializationSettings('app_icon');
    var iOSInit = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var init = InitializationSettings(androidInit, iOSInit);



    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await notifications.show(
        0, 'Test title', 'Test body', platformChannelSpecifics,
        payload: 'item x');


  }



  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
            },
          )
        ],
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
    channel.sink.close(statusCodes.goingAway);
    sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Announcement Page"),
      ),
      body: Center(
          child: Column(
            children: <Widget>[
              text != null ?
              Text(text, style: Theme.of(context).textTheme.display1)
                  :
              CircularProgressIndicator(),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                    labelText: "Enter your message here"
                ),
              )
            ],
          )
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.send),
          onPressed: () {
            channel.sink.add("${widget.nickname}: ${controller.text}");
          }
      ),
    );
  }
}

