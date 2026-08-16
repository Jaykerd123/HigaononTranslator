import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryService {
  static String? _discoveredBaseUrl;
  static bool _isScanning = false;
  static String? _lastKnownLocalIp;

  static String? get discoveredBaseUrl => _discoveredBaseUrl;

  /// Clears the cached server URL (useful when switching networks)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('discovered_server_url');
    _discoveredBaseUrl = null;
    _lastKnownLocalIp = null;
    print('[DiscoveryService] Cache cleared.');
  }

  /// Tries to find the Python server on the local network.
  /// Scans common ports 8000 and 8080 on the current subnet.
  static Future<String?> discoverServer({bool forceRescan = false}) async {
    if (_isScanning) return null;
    _isScanning = true;

    try {
      // 0. Detect if we've switched networks
      final currentIp = await _getCurrentLocalIp();
      if (_lastKnownLocalIp != null && _lastKnownLocalIp != currentIp) {
        print('[DiscoveryService] Network change detected! Invalidating cache.');
        await clearCache();
      }
      _lastKnownLocalIp = currentIp;

      // 1. Try to load from cache first (unless force rescan)
      if (!forceRescan) {
        final prefs = await SharedPreferences.getInstance();
        final cachedUrl = prefs.getString('discovered_server_url');
        if (cachedUrl != null) {
          print('[DiscoveryService] Verifying cached URL: $cachedUrl');
          if (await _verifyServer(cachedUrl)) {
            _discoveredBaseUrl = cachedUrl;
            _isScanning = false;
            return cachedUrl;
          } else {
            print('[DiscoveryService] Cached URL is stale. Clearing and rescanning...');
            await clearCache();
          }
        }
      }

      // 2. Identify local IP and Subnet
      String? localIp = currentIp;
      
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
        final prefs = await SharedPreferences.getInstance();
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

  /// Get current local IP address
  static Future<String?> _getCurrentLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('[DiscoveryService] Error getting local IP: $e');
    }
    return null;
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
      // Use the new /health endpoint for fast verification
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(milliseconds: 300));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
