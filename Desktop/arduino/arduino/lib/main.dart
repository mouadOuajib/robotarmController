import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:arduino/connection.dart';
import 'package:arduino/led.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: FlutterBluetoothSerial.instance.requestEnable(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                height: double.infinity,
                child: Center(
                  child: Icon(
                    Icons.bluetooth_disabled,
                    size: 200.0,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          } else if (snapshot.data == true) {
            return Home();
          } else {
            return Scaffold(
              body: Container(
                height: double.infinity,
                child: Center(
                  child: Text(
                    'Bluetooth is disabled.',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Connection'),
        ),
        body: SelectBondedDevicePage(
          onChatPage: (device) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChatPage(server: device);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
