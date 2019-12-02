import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import './BackgroundCollectingTask.dart';
import './BackgroundCollectedPage.dart';
import './WaterfallPage.dart';

//import './LineChart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  static const BackgroundColor = const Color(0xFF303f9f);

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask _collectingTask;

  bool _autoAcceptPairingRequests = false;

  BluetoothDevice _device;
  BluetoothConnection _connection;

  @override
  void initState() {
    super.initState();

    if(_device != null && _device.isConnected) {
        _startWaterfall(context, _device, _connection);
    }

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: 
        Center(
          child: (
            ClipOval(
              child: Material(
                color: Colors.white,
                elevation: 2,
                child: InkWell(
                  splashColor: Colors.black38,
                  child: SizedBox(width: 56, height: 56, child: Icon(Icons.bluetooth_searching)),
                  onTap: () async { // async lambda seems to not working
                      if (_bluetoothState == BluetoothState.STATE_OFF)
                        await FlutterBluetoothSerial.instance.requestEnable();
                        
                      final deviceConnection = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) { return DiscoveryPage(); })
                      );
                      setState(() {
                       _device = deviceConnection['device'] as BluetoothDevice;
                       _connection = deviceConnection['connection'] as BluetoothConnection;
                      });
                      if (deviceConnection != null) {
                        print('Discovery -> selected ' + deviceConnection['device'].address);
                        _startWaterfall(context, _device, _connection);
                      }
                      else {
                        print('Discovery -> no device selected');
                      }
                  },
                )
              )
            )
          )
        )
    );
  }

  void _startWaterfall(BuildContext context, BluetoothDevice device, BluetoothConnection connection) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return WaterfallPage(device: device, connection: connection);
      // return WaterfallPage();
    }));
  }

  Future<void> _startBackgroundTask(
      BuildContext context, BluetoothDevice server) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask.start();
    } catch (ex) {
      if (_collectingTask != null) {
        _collectingTask.cancel();
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
