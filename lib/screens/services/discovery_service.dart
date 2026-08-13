import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryService {
  static String? _discoveredBaseUrl;
  static bool _isScanning = false;

  static String? get discoveredBaseUrl => _discoveredBaseUrl;

  /// Tries to find the Python server on the local network.
  /// Scans common ports 8000 and 8080 on the current subnet.
  static Future<String?> discoverServer() async {
    if (_isScanning) return null;
    _isScanning = true;

    try {
      // 1. Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('discovered_server_url');
      if (cachedUrl != null) {
        if (await _verifyServer(cachedUrl)) {
          _discoveredBaseUrl = cachedUrl;
          _isScanning = false;
          return cachedUrl;
        }
      }

      // 2. Identify local IP and Subnet
      String? localIp;
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }

      if (localIp == null) {
        _isScanning = false;
        return null;
      }

      final String subnet = localIp.substring(0, localIp.lastIndexOf('.'));
      print('[DiscoveryService] Scanning subnet $subnet.x for server...');

      // 3. Scan subnet in parallel
      final ports = [8000, 8080];
      final List<Future<String?>> scanTasks = [];

      for (int i = 1; i < 255; i++) {
        final host = '$subnet.$i';
        // Skip self
        if (host == localIp) continue;

        for (int port in ports) {
          scanTasks.add(_checkAddress(host, port));
        }
      }

      // Wait for the first successful match or all to fail
      final results = await Future.wait(scanTasks);
      final foundUrl = results.firstWhere((url) => url != null, orElse: () => null);

      if (foundUrl != null) {
        print('[DiscoveryService] Successfully discovered server at $foundUrl');
        _discoveredBaseUrl = foundUrl;
        await prefs.setString('discovered_server_url', foundUrl);
      } else {
        print('[DiscoveryService] No server found on subnet.');
      }

      _isScanning = false;
      return foundUrl;
    } catch (e) {
      print('[DiscoveryService] Error during discovery: $e');
      _isScanning = false;
      return null;
    }
  }

  static Future<String?> _checkAddress(String host, int port) async {
    final url = 'http://$host:$port';
    if (await _verifyServer(url)) {
      return url;
    }
    return null;
  }

  static Future<bool> _verifyServer(String baseUrl) async {
    try {
      // We try a simple GET or check the /tts endpoint with a HEAD request if possible, 
      // but since it's a POST only, we might just try to see if the port is open or use a timeout.
      // A better way is to add a /health endpoint to server.py, but for now we try the root or docs.
      final response = await http.get(Uri.parse('$baseUrl/docs')).timeout(const Duration(milliseconds: 500));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
