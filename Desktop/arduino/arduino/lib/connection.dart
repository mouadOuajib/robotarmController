import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:arduino/device.dart';

class SelectBondedDevicePage extends StatefulWidget {
  /// If true, on page start there is performed discovery upon the bonded devices.
  /// Then, if they are not available, they would be disabled from the selection.
  final bool checkAvailability;
  final Function(BluetoothDevice) onChatPage;

  const SelectBondedDevicePage({
    this.checkAvailability = true,
    required this.onChatPage,
  });

  @override
  _SelectBondedDevicePageState createState() => _SelectBondedDevicePageState();
}

enum DeviceAvailability {
  no,
  maybe,
  yes,
}

class DeviceWithAvailability {
  BluetoothDevice device;
  DeviceAvailability availability;
  int? rssi;

  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _SelectBondedDevicePageState extends State<SelectBondedDevicePage> {
  List<DeviceWithAvailability> devices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map(
              (device) => DeviceWithAvailability(
                device,
                widget.checkAvailability
                    ? DeviceAvailability.maybe
                    : DeviceAvailability.yes,
              ),
            )
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  void _startDiscovery() {
    _discoveryStreamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        devices.forEach((_device) {
          if (_device.device == r.device) {
            _device.availability = DeviceAvailability.yes;
            _device.rssi = r.rssi;
          }
        });
      });
    }, onDone: () {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<BluetoothDeviceListEntry> list = devices.map((_device) {
      return BluetoothDeviceListEntry(
        device: _device.device,
        onTap: () {
          widget.onChatPage(_device.device);
        },
      );
    }).toList();
    return ListView(
      children: list,
    );
  }
}
