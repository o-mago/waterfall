import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class WaterfallPage extends StatefulWidget {

  final BluetoothDevice device;
  final BluetoothConnection connection;

  const WaterfallPage({this.device, this.connection});

  @override
  _WaterfallPage createState() => new _WaterfallPage();
}

class _WaterfallPage extends State<WaterfallPage> {
  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>();

  static final clientID = 0;
  static final maxMessageLength = 4096 - 3;

  double _speed = 0.0;

  String _messageBuffer = '0';

  bool isOn = true;
  bool isConnecting = true;
  BluetoothConnection _connection;
  BluetoothDevice _device;
  
  bool get isConnected => _connection != null && _connection.isConnected;

  bool isDisconnecting = false;

  _WaterfallPage();

  @override
  void initState() {
    super.initState();

    setState(() {
     _device = widget.device;
     _connection = widget.connection;
    });

    _connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        }
        else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
    });
  }

  @override
  void dispose() {
    // if (isConnected) {
    //   isDisconnecting = true;
    //   _connection.dispose();
    //   _connection = null;
    // }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            // AppBar(
            //   title: isDiscovering ? Text('Discovering devices') : Text('Discovered devices'),
            //   actions: <Widget>[
            //     (
            //       isDiscovering ?
            //         FittedBox(child: Container(
            //           margin: new EdgeInsets.all(16.0),
            //           child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            //         ))
            //       :
            //         IconButton(
            //           icon: Icon(Icons.replay),
            //           onPressed: _restartDiscovery
            //         )
            //     )
            //   ],
            // ),
          PreferredSize(
          preferredSize: Size(null, 100),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
                top: 20,
                right: 10,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                      child: Material(
                          color: Colors.white,
                          elevation: 2,
                          child: InkWell(
                            splashColor: Colors.black38,
                            child: isOn
                                ? SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Center(
                                      child: Text(
                                        "ON",
                                        style: TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.w300),
                                        textAlign: TextAlign.center
                                      ),
                                    )
                                  )
                                : SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Center(
                                      child: Text(
                                      "OFF",
                                      style: TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.w300),
                                      textAlign: TextAlign.center),
                                    )
                                  ),
                            onTap: () {
                              isOn ? _sendMessage('b') : _sendMessage('a');
                              setState(() {
                                isOn = !isOn;
                              });
                            },
                          ))),
                  Text(
                    "Waterfall",
                    style: TextStyle(fontSize: 30, color: Colors.white),
                  ),
                  ClipOval(
                      child: Material(
                          color: Colors.white,
                          elevation: 2,
                          child: InkWell(
                            splashColor: Colors.black38,
                            child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Icon(Icons.bluetooth_disabled),
                                  ),
                            onTap: () {
                              _connection.dispose();
                              _connection = null;
                              Navigator.of(context).pop();
                            },
                          ))),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: Center(
          child: Padding (
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                Container(
                  margin: const EdgeInsets.only(top: 60, bottom: 80),
                  child: Column (children: <Widget>[
                    Text(
                      "high",
                      style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 5, bottom: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 5),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: (_messageBuffer == '1') ? 
                        Image.asset('assets/images/waves.png') :
                        Image.asset('assets/images/waves_low.png'),
                    ),
                    Text(
                      "low",
                      style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center
                    )],
                  )
                ),
                // Row (
                    // mainAxisSize: MainAxisSize.max,
                    // children: <Widget>[
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // valueIndicatorColor: Colors.black,
                    // thumbColor: Colors.black,
                    valueIndicatorTextStyle: TextStyle(
                        color: Colors.black, letterSpacing: 2.0)
                  ),
                  child: Slider(
                    min: 0,
                    max: 5,
                    divisions: 5, 
                    value: _speed.toDouble(),
                    activeColor: Colors.white,
                    inactiveColor: Colors.white38,
                    label: _speed.round().toString()+'x',
                    onChanged: (double newSpeed) {
                      _sendMessage(newSpeed.toInt().toString());
                      setState(() {
                        _speed = newSpeed;
                      });
                    }
                  )
                ),
                Column(
                  children: <Widget>[
                    Image.asset('assets/images/speed.png'),
                    Text(
                      "speed",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center
                    )
                  ],
                )
              ]
            )
                // ]
              // )
            )
          )
        );
        // Padding(
        //     padding: const EdgeInsets.only(
        //       left: 10,
        //       top: 20,
        //       right: 10,
        //       bottom: 0,
        //     ),
        //     child: 
        //     );
  }
    void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      }
      else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        }
        else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) { // \r\n
      setState(() {
        _messageBuffer = dataString.substring(index);
      });
    }
    else {
      _messageBuffer = (
        backspacesCounter > 0 
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter) 
          : _messageBuffer
        + dataString
      );
    }
    print(_messageBuffer);
  }

  void _sendMessage(String text) async {
    text = text.trim();
    // textEditingController.clear();

    if (text.length > 0)  {
      try {
        _connection.output.add(utf8.encode(text + "\r\n"));
        await _connection.output.allSent;

        // Future.delayed(Duration(milliseconds: 333)).then((_) {
        //   listScrollController.animateTo(listScrollController.position.maxScrollExtent, duration: Duration(milliseconds: 333), curve: Curves.easeOut);
        // });
      }
      catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
