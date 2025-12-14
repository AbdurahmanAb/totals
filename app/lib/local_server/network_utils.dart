import 'dart:io';

class NetworkUtils {
  /// Gets the local IP address of this device on the network
  static Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Skip loopback addresses
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  /// Gets all available network interfaces
  static Future<List<NetworkInterfaceInfo>> getAllInterfaces() async {
    final result = <NetworkInterfaceInfo>[];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            result.add(
              NetworkInterfaceInfo(name: interface.name, address: addr.address),
            );
          }
        }
      }
    } catch (e) {
      print('Error listing interfaces: $e');
    }

    return result;
  }
}

class NetworkInterfaceInfo {
  final String name;
  final String address;

  NetworkInterfaceInfo({required this.name, required this.address});
}
