import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({super.key, required this.server});

  @override
  State<ChatPage> createState() => _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static const clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = [];
  String _messageBuffer = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((c) {
      log('Connected to the device');
      connection = c;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection?.input?.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          log('Disconnecting locally!');
        } else {
          log('Disconnected remotely!');
        }
        if (mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      log('Cannot connect, exception occured');
      log(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  double _value = 90.0;
  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((m) {
      return Row(
        mainAxisAlignment: m.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
              color: m.whom == clientID ? Colors.blueAccent : Colors.grey,
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Text(
              (text) {
                return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
              }(m.text.trim()),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ${widget.server.name}...')
              : isConnected
                  ? Text('Live chat with ${widget.server.name}')
                  : Text('Chat log with ${widget.server.name}'))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 50),
              padding: const EdgeInsets.all(5),
              width: double.infinity,
              child: SfSlider(
                min: 0.0,
                max: 180.0,
                value: _value,
                interval: 30,
                stepSize: 30.0,
                showTicks: true,
                showLabels: true,
                minorTicksPerInterval: 1,
                onChanged: (dynamic value) {
                  if (isConnected) {
                    setState(() {
                      _value = value;
                    });
                    _sendMessage((_value / 30).toString());
                    if (_value == 0) {
                      _sendMessage('motor1 0');
                    } else if (_value == 30) {
                      _sendMessage('1');
                    } else if (_value == 60) {
                      _sendMessage('2');
                    } else if (_value == 90) {
                      _sendMessage('3');
                    } else if (_value == 120) {
                      _sendMessage('4');
                    } else if (_value == 150) {
                      _sendMessage('5');
                    } else if (_value == 180) {
                      _sendMessage('6');
                    }
                  }
                },
              ),
            ),
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                                ? 'Type your message...'
                                : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isConnected
                          ? () => _sendMessage(textEditingController.text)
                          : null),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    for (int byte in data) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    }
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.isNotEmpty) {
      try {
        connection?.output.add(Uint8List.fromList(('$text\r\n').codeUnits));
        await connection?.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(const Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
