import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './BluetoothDeviceListEntry.dart';
import './WaterfallPage.dart';

class DiscoveryPage extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  const DiscoveryPage({this.start = true});

  @override
  _DiscoveryPage createState() => new _DiscoveryPage();
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}

class _DeviceWithAvailability extends BluetoothDevice {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _DiscoveryPage extends State<DiscoveryPage> {
  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>();
  // List<BluetoothDevice> bonded = List<BluetoothDevice>();
  bool isDiscovering;
  bool isConnecting = true;

  _DiscoveryPage();

  @override
  void initState() {
    super.initState();

    isDiscovering = widget.start;
    if (isDiscovering) {
      _startDiscovery();
    }

    // FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> bondedDevices) {
    //   setState(() {
    //     bonded = bondedDevices;
    //   });
    // });
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        results.add(r);
      });
    });

    _streamSubscription.onDone(() {
      setState(() {
        isDiscovering = false;
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();

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
                            child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Icon(Icons.arrow_back)),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ))),
                  Text(
                    "Devices",
                    style: TextStyle(fontSize: 30, color: Colors.white),
                  ),
                  ClipOval(
                      child: Material(
                          color: Colors.white,
                          elevation: 2,
                          child: InkWell(
                            splashColor: Colors.black38,
                            child: isDiscovering
                                ? SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Container(
                                        margin: new EdgeInsets.all(16),
                                        child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.black))))
                                : SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Icon(Icons.replay),
                                  ),
                            onTap: () {
                              if (!isDiscovering) _restartDiscovery();
                            },
                          ))),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: 
        Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 20,
              right: 10,
              bottom: 0,
            ),
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (BuildContext context, index) {
                BluetoothDiscoveryResult result = results[index];
                return BluetoothDeviceListEntry(
                    device: result.device,
                    rssi: result.rssi,
                    onTap: () async {
                      try {
                        // // REMOVE THIS (JUST MOCK BEFORE TESTING WITH THE REAL BLUETOOTH MODULE)
                        // Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                        //   return WaterfallPage();
                        // }));
                        // //======================================================================
                        bool bonded = false;
                        if (!result.device.isBonded) {
                          print('Bonding with ${result.device.address}...');
                          bonded = await FlutterBluetoothSerial.instance
                            .bondDeviceAtAddress(result.device.address);
                          print('Bonding with ${result.device.address} has ${bonded ? 'succed' : 'failed'}.');
                          
                        } else {
                          bonded = true;
                        }
                        if(bonded) {
                          await BluetoothConnection.toAddress(result.device.address).then((_connection) {
                            print('Connected to the device');
                            var map = {'device': result.device, 'connection': _connection};
                            setState(() {
                              isConnecting = false;
                            });
                            Navigator.of(context).pop(map);
                          }).catchError((error) {
                            print('Cannot connect, exception occured');
                            print(error);
                          });
                        }
                      } catch (ex) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error occured while bonding'),
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
                    },
                    onLongPress: () async {
                      try {
                        bool bonded = false;
                        if (result.device.isBonded) {
                          print('Unbonding from ${result.device.address}...');
                          await FlutterBluetoothSerial.instance
                              .removeDeviceBondWithAddress(
                                  result.device.address);
                          print(
                              'Unbonding from ${result.device.address} has succed');
                        } else {
                          print('Bonding with ${result.device.address}...');
                          bonded = await FlutterBluetoothSerial.instance
                              .bondDeviceAtAddress(result.device.address);
                          print(
                              'Bonding with ${result.device.address} has ${bonded ? 'succed' : 'failed'}.');
                        }
                        setState(() {
                          results[results.indexOf(result)] =
                              BluetoothDiscoveryResult(
                                  device: BluetoothDevice(
                                    name: result.device.name ?? '',
                                    address: result.device.address,
                                    type: result.device.type,
                                    bondState: bonded
                                        ? BluetoothBondState.bonded
                                        : BluetoothBondState.none,
                                  ),
                                  rssi: result.rssi);
                        });
                      } catch (ex) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error occured while bonding'),
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
                    });
              },
            )));
  }
}
