import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:totals/local_server/server_service.dart';
import 'package:totals/local_server/network_utils.dart';
import 'package:totals/utils/gradients.dart';

class WebPage extends StatefulWidget {
  const WebPage({super.key});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> with SingleTickerProviderStateMixin {
  final ServerService _serverService = ServerService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _networkIp;
  List<NetworkInterfaceInfo> _interfaces = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _loadNetworkInfo() async {
    final ip = await NetworkUtils.getLocalIpAddress();
    final interfaces = await NetworkUtils.getAllInterfaces();
    if (mounted) {
      setState(() {
        _networkIp = ip;
        _interfaces = interfaces;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _serverService.stopServer();
    _serverService.dispose();
    super.dispose();
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_serverService.isRunning) {
        await _serverService.stopServer();
      } else {
        await _serverService.startServer();
      }
      await _loadNetworkInfo();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _displayUrl {
    if (_serverService.isRunning) {
      return _serverService.serverUrl ??
          'http://$_networkIp:${_serverService.port}';
    }
    return 'Not running';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Web Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              'Share your financial data on local network',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Server Status Card
            _buildServerStatusCard(colorScheme, isDark),

            const SizedBox(height: 16),

            // URL Card (only when running)
            if (_serverService.isRunning) ...[
              _buildUrlCard(colorScheme, isDark),
              const SizedBox(height: 16),
            ],

            // Network Info Card
            _buildNetworkInfoCard(colorScheme, isDark),

            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null) _buildErrorCard(colorScheme),

            const SizedBox(height: 16),

            // Instructions Card
            _buildInstructionsCard(colorScheme, isDark),

            const SizedBox(height: 16),

            // API Endpoints Card
            _buildApiEndpointsCard(colorScheme, isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatusCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: GradientUtils.getGradient(99),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Glossy overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Status Icon with animation
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_serverService.isRunning
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.2))
                              .withOpacity(_serverService.isRunning
                                  ? 0.2 + (_pulseController.value * 0.1)
                                  : 0.2),
                        ),
                        child: Icon(
                          _serverService.isRunning
                              ? Icons.wifi_tethering
                              : Icons.wifi_tethering_off,
                          size: 40,
                          color: _serverService.isRunning
                              ? Colors.greenAccent
                              : Colors.white70,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status Text
                  Text(
                    _serverService.isRunning
                        ? 'Server Running'
                        : 'Server Stopped',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _serverService.isRunning
                        ? 'Accepting connections on port ${_serverService.port}'
                        : 'Start the server to share data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _toggleServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _serverService.isRunning
                            ? Colors.red.shade400
                            : Colors.greenAccent.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _serverService.isRunning
                                      ? Icons.stop_circle_outlined
                                      : Icons.play_circle_outline,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _serverService.isRunning
                                      ? 'Stop Server'
                                      : 'Start Server',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Network URL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: SelectableText(
                _displayUrl,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(_displayUrl),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy URL'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfoCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.wifi,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Network Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadNetworkInfo,
                  icon: Icon(
                    Icons.refresh,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Your IP Address',
              _networkIp ?? 'Detecting...',
              colorScheme,
              isHighlighted: true,
            ),
            if (_interfaces.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Available Interfaces',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...(_interfaces.map((iface) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iface.isWifi ? Colors.blue : Colors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          iface.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            iface.address,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (iface.isWifi)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Wi-Fi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Use',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
                1,
                'Make sure your phone is connected to Wi-Fi',
                Colors.amber.shade800),
            _buildInstructionStep(2, 'Start the server using the button above',
                Colors.amber.shade800),
            _buildInstructionStep(
                3, 'Copy the Network URL', Colors.amber.shade800),
            _buildInstructionStep(
                4,
                'Open a browser on another device (same Wi-Fi)',
                Colors.amber.shade800),
            _buildInstructionStep(5, 'Paste the URL to access your dashboard',
                Colors.amber.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int step, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiEndpointsCard(ColorScheme colorScheme, bool isDark) {
    final endpoints = [
      {'method': 'GET', 'path': '/api/accounts', 'desc': 'List all accounts'},
      {
        'method': 'GET',
        'path': '/api/transactions',
        'desc': 'List transactions'
      },
      {'method': 'GET', 'path': '/api/summary', 'desc': 'Overall summary'},
      {'method': 'GET', 'path': '/api/banks', 'desc': 'Supported banks'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.api,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'API Endpoints',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...endpoints.map((endpoint) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          endpoint['method']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              endpoint['path']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              endpoint['desc']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_serverService.isRunning)
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            '$_displayUrl${endpoint['path']}',
                          ),
                          icon: Icon(
                            Icons.copy,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Copy URL',
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
