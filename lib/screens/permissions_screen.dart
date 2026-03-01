import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = true;

  final List<PermissionItem> _permissionItems = [
    PermissionItem(
      permission: Permission.calendarFullAccess,
      title: 'Calendar',
      description: 'Required to sync and manage your device calendars.',
      icon: Icons.calendar_month,
    ),
    PermissionItem(
      permission: Permission.contacts,
      title: 'Contacts',
      description: 'Used to invite guests to events and sync birthdays.',
      icon: Icons.contacts,
    ),
    PermissionItem(
      permission: Permission.locationWhenInUse,
      title: 'Location',
      description: 'Used to pick locations for your events on the map.',
      icon: Icons.location_on,
    ),
    PermissionItem(
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Used to send reminders and alerts for your events.',
      icon: Icons.notifications,
    ),
    PermissionItem(
      permission: Permission.camera,
      title: 'Camera',
      description: 'Used to take photos for event attachments.',
      icon: Icons.camera_alt,
    ),
    PermissionItem(
      permission: Permission.photos,
      title: 'Photos/Gallery',
      description: 'Used to select images from your gallery for events.',
      icon: Icons.photo_library,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    Map<Permission, PermissionStatus> newStatuses = {};
    for (var item in _permissionItems) {
      newStatuses[item.permission] = await item.permission.status;
    }
    setState(() {
      _statuses = newStatuses;
      _loading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('This permission is permanently denied. Please enable it in app settings.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('Settings'),
              ),
            ],
          ),
        );
      }
    }
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('App Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _permissionItems.length,
            itemBuilder: (context, index) {
              final item = _permissionItems[index];
              final status = _statuses[item.permission] ?? PermissionStatus.denied;
              
              return _buildPermissionCard(context, item, status, isDark);
            },
          ),
    );
  }

  Widget _buildPermissionCard(BuildContext context, PermissionItem item, PermissionStatus status, bool isDark) {
    final bool isGranted = status.isGranted;
    final Color statusColor = isGranted ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDisplayText(status),
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isGranted)
                  ElevatedButton(
                    onPressed: () => _requestPermission(item.permission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Allow'),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayText(PermissionStatus status) {
    if (status.isGranted) return 'Allowed';
    if (status.isDenied) return 'Not Allowed';
    if (status.isPermanentlyDenied) return 'Permanently Denied';
    if (status.isRestricted) return 'Restricted';
    if (status.isLimited) return 'Limited Access';
    return 'Unknown';
  }
}

class PermissionItem {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;

  PermissionItem({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
  });
}
