import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/event.dart';
import 'map_picker_screen.dart';
import '../features/events/presentation/events_view_model.dart';
import 'recurrence_screen.dart';
import '../theme/app_theme.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  final Event? event;
  final DateTime? initialDate;
  const AddEventScreen({super.key, this.event, this.initialDate});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  // 1. Basic Info
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String? _titleError;
  String? _timeError;
  String _selectedCategory = 'Personal';
  final List<String> _categories = [
    'Work',
    'Personal',
    'Meeting',
    'Health',
    'Study',
    'Custom',
  ];

  // Mapping categories to specific colors for visual identity
  final Map<String, Color> _categoryColors = {
    'Work': const Color(0xFF039BE5), // Light Blue
    'Personal': const Color(0xFF8E24AA), // Purple
    'Meeting': const Color(0xFFF4511E), // Orange
    'Health': const Color(0xFF0B8043), // Green
    'Study': const Color(0xFF3F51B5), // Indigo
    'Custom': const Color(0xFF616161), // Grey
  };

  // 2. Date & Time
  bool _isAllDay = false;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  // 3. Recurrence
  RecurrenceRule _recurrenceRule = const RecurrenceRule(
    type: RecurrenceType.none,
  );

  // 4. Reminders
  List<Duration> _reminders = [const Duration(minutes: 10)];
  final List<Duration> _predefinedReminders = [
    const Duration(minutes: 0),
    const Duration(minutes: 10),
    const Duration(hours: 1),
    const Duration(days: 1),
  ];

  // 5. Location & Online
  final _locationController = TextEditingController();
  final _urlController = TextEditingController();
  LatLng? _selectedLocationCoords;
  bool _showMapPreview = false;

  // 6. Advanced Settings
  EventColor _selectedColor = EventColor.health;
  Color _customColor = const Color(0xFF1976D2); // Material Blue
  EventAvailability _availability = EventAvailability.busy;
  EventVisibility _visibility = EventVisibility.private;
  String? _attachmentPath;

  // Other State (Required internally)
  String? _selectedCalendarId;
  String _selectedTimeZone = 'UTC';
  List<String> _attendees = [];
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _initTimeZone();

    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _locationController.text = widget.event!.location ?? '';
      _notesController.text = widget.event!.notes ?? '';
      _urlController.text = widget.event!.url ?? '';
      _startDate = widget.event!.startTime;
      _endDate = widget.event!.endTime;
      _startTime = TimeOfDay.fromDateTime(_startDate);
      _endTime = TimeOfDay.fromDateTime(_endDate);
      _isAllDay = widget.event!.isAllDay;
      _selectedColor = widget.event!.color;
      if (widget.event!.customColor != null) {
        _customColor = widget.event!.customColor!;
      }
      _recurrenceRule = widget.event!.recurrence;
      _reminders = List.from(widget.event!.reminders);
      _selectedCalendarId = widget.event!.calendarId;
      if (widget.event!.attendees != null) {
        _attendees = List.from(widget.event!.attendees!);
      }
      _availability = widget.event!.availability;
      _visibility = widget.event!.visibility;
      _attachmentPath = widget.event!.photoPath;
      if (widget.event!.timeZone != null) {
        _selectedTimeZone = widget.event!.timeZone!;
      }
    } else {
      final now = DateTime.now();
      final baseDate = widget.initialDate ?? now;
      _startDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
      _startTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      _endDate = _startDate;
      _endTime = TimeOfDay(hour: (now.hour + 2) % 24, minute: 0);
    }
  }

  void _initTimeZone() {
    try {
      final location = tz.getLocation('Asia/Kolkata');
      _selectedTimeZone = location.name;
    } catch (e) {
      _selectedTimeZone = 'UTC';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // --- Date/Time Pickers ---
  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _customColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _customColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_startDate.isAtSameMomentAs(_endDate)) {
            final startMin = _startTime.hour * 60 + _startTime.minute;
            final endMin = _endTime.hour * 60 + _endTime.minute;
            if (endMin <= startMin) {
              _endTime = TimeOfDay(
                hour: _startTime.hour + 1,
                minute: _startTime.minute,
              );
            }
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // --- Reminders ---
  void _showReminderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        // use stateful builder since the UI needs to react
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Add Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ..._predefinedReminders.map((d) {
                String label;
                if (d.inMinutes == 0) {
                  label = 'At time of event';
                } else if (d.inMinutes < 60) {
                  label = '${d.inMinutes} minutes before';
                } else if (d.inHours < 24) {
                  label = '${d.inHours} hour(s) before';
                } else {
                  label = '${d.inDays} day(s) before';
                }

                final isSelected = _reminders.any(
                  (r) => r.inMinutes == d.inMinutes,
                );
                return ListTile(
                  title: Text(label),
                  trailing: isSelected
                      ? Icon(Icons.check, color: _customColor)
                      : null,
                  onTap: () {
                    setModalState(() {
                      if (isSelected) {
                        _reminders.removeWhere(
                          (r) => r.inMinutes == d.inMinutes,
                        );
                      } else {
                        _reminders.add(d);
                      }
                      _reminders.sort((a, b) => a.compareTo(b));
                    });
                    setState(() {});
                  },
                );
              }),
              ListTile(
                title: const Text('Custom...'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(
                height: 57,
              ), // 16px default + 41px requested padding
            ],
          );
        },
      ),
    );
  }

  String _formatReminder(Duration d) {
    if (d.inMinutes == 0) return 'At time of event';
    if (d.inMinutes < 60) return '${d.inMinutes} mins before';
    if (d.inHours < 24) return '${d.inHours} hr before';
    return '${d.inDays} day before';
  }

  // --- Map Picker ---
  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation:
              _selectedLocationCoords ?? const LatLng(17.3850, 78.4867),
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLocationCoords = result['location'];
        _locationController.text = result['address'];
        _showMapPreview = true;
      });
    }
  }

  Widget _buildMapPreview(bool isDark) {
    return Container(
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLocationCoords!,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.calender_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocationCoords!,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: _customColor,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _showMapPreview = false),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Attachments & Colors ---
  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final xHeader = await picker.pickImage(source: ImageSource.gallery);
    if (xHeader != null) {
      setState(() => _attachmentPath = xHeader.path);
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Event Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildColorCircle(const Color(0xFF039BE5)),
                  _buildColorCircle(const Color(0xFFD81B60)),
                  _buildColorCircle(const Color(0xFF8E24AA)),
                  _buildColorCircle(const Color(0xFF3F51B5)),
                  _buildColorCircle(const Color(0xFF0B8043)),
                  _buildColorCircle(const Color(0xFFF4511E)),
                  _buildColorCircle(const Color(0xFFF6BF26)),
                  _buildColorCircle(const Color(0xFF616161)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    bool isSelected = _customColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () {
        setState(() => _customColor = color);
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  // --- Save / Delete logic ---
  void _saveEvent() {
    setState(() {
      _titleError = null;
      _timeError = null;
    });

    if (_titleController.text.isEmpty) {
      setState(() => _titleError = 'Please enter an event title');
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    // For all-day events, the end time should be 23:59 of the end date
    final endDateTime = _isAllDay
        ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)
        : DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );

    if (endDateTime.isBefore(startDateTime)) {
      setState(() => _timeError = 'End time cannot be before start time');
      return;
    }
    final newEvent = Event(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      isAllDay: _isAllDay,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      url: _urlController.text.isNotEmpty ? _urlController.text : null,
      color: _selectedColor,
      customColor: _customColor,
      recurrence: _recurrenceRule,
      reminders: _reminders,
      calendarId: _selectedCalendarId,
      attendees: _attendees,
      photoPath: _attachmentPath,
      availability: _availability,
      visibility: _visibility,
      timeZone: _selectedTimeZone,
      emoji: _selectedEmoji ?? _selectedCategory,
    );

    if (widget.event != null) {
      ref.read(eventsProvider.notifier).deleteEvent(widget.event!);
      ref.read(eventsProvider.notifier).addEvent(newEvent);
    } else {
      ref.read(eventsProvider.notifier).addEvent(newEvent);
    }
    Navigator.pop(context);
  }

  void _duplicateEvent() {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final duplicate = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${_titleController.text} (Copy)',
      startTime: startDateTime,
      endTime: endDateTime,
      isAllDay: _isAllDay,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      url: _urlController.text.isNotEmpty ? _urlController.text : null,
      color: _selectedColor,
      customColor: _customColor,
      recurrence: _recurrenceRule,
      reminders: _reminders,
      calendarId: _selectedCalendarId,
      attendees: _attendees,
      photoPath: _attachmentPath,
      availability: _availability,
      visibility: _visibility,
      timeZone: _selectedTimeZone,
      emoji: _selectedEmoji ?? _selectedCategory,
    );
    ref.read(eventsProvider.notifier).addEvent(duplicate);
    Navigator.pop(context);
  }

  // --- UI Render ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFF2F2F7); // iOS grouped bg
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 17),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          widget.event == null ? 'New Event' : 'Edit Event',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Basic Info Section
              _buildSectionHeader('BASIC INFORMATION'),
              _buildGroupedCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildTextInputRow(
                    controller: _titleController,
                    hint: 'Enter event title *',
                    maxLength: 100,
                    isDark: isDark,
                    errorText: _titleError,
                    onChanged: (val) {
                      if (_titleError != null) {
                        setState(() => _titleError = null);
                      }
                    },
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildTextInputRow(
                    controller: _notesController,
                    hint: 'Description (Optional)',
                    maxLength: 1000,
                    maxLines: 5,
                    minLines: 3,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories
                              .map((c) => _buildCategoryChip(c, isDark))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Date & Time Section
              _buildSectionHeader('DATE & TIME'),
              _buildGroupedCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildRowItem(
                    title: 'All-Day',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _isAllDay,
                      onChanged: (v) => setState(() => _isAllDay = v),
                      activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                      activeThumbColor: theme.colorScheme.primary,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildDateTimeRow(
                    title: 'Starts',
                    date: _startDate,
                    time: _startTime,
                    isStart: true,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDateTimeRow(
                    title: 'Ends',
                    date: _endDate,
                    time: _endTime,
                    isStart: false,
                    isDark: isDark,
                  ),
                  if (_timeError != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: Text(
                        _timeError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Recurrence Section
              _buildSectionHeader('RECURRENCE'),
              _buildGroupedCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildRowItem(
                    title: 'Repeat',
                    valueText: _recurrenceRule.type == RecurrenceType.none
                        ? 'Does not repeat'
                        : _recurrenceRule.type.name.toUpperCase(),
                    isDark: isDark,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecurrenceScreen(
                            initialRule: _recurrenceRule,
                            startDate: _startDate,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() => _recurrenceRule = result);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Reminder & Notification
              _buildSectionHeader('REMINDERS & NOTIFICATIONS'),
              _buildGroupedCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  ..._reminders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reminder = entry.value;
                    return Column(
                      children: [
                        _buildRowItem(
                          title: 'Alert',
                          valueText: _formatReminder(reminder),
                          isDark: isDark,
                          onTap: _showReminderPicker,
                          leading: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                setState(() => _reminders.removeAt(index)),
                          ),
                        ),
                        if (index < _reminders.length - 1)
                          _buildDivider(isDark),
                      ],
                    );
                  }),
                  if (_reminders.isNotEmpty) _buildDivider(isDark),
                  _buildRowItem(
                    title: 'Add Alert',
                    titleColor: theme.colorScheme.primary,
                    isDark: isDark,
                    onTap: _showReminderPicker,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Location & Online
              _buildSectionHeader('LOCATION & ONLINE'),
              _buildGroupedCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildTextInputRow(
                    controller: _locationController,
                    hint: 'Location',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    trailing: IconButton(
                      icon: Icon(Icons.map, color: theme.colorScheme.primary),
                      onPressed: _openMapPicker,
                    ),
                  ),
                  if (_selectedLocationCoords != null && _showMapPreview)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildMapPreview(isDark),
                    ),
                  _buildDivider(isDark),
                  _buildTextInputRow(
                    controller: _urlController,
                    hint: 'Add Google Meet / Zoom link',
                    icon: Icons.link,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6. Advanced Settings
              _buildSectionHeader('ADVANCED SETTINGS'),
              _buildGroupedCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildRowItem(
                    title: 'Event Color',
                    isDark: isDark,
                    onTap: _showColorPicker,
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _customColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildRowItem(
                    title: 'Attachments',
                    valueText: _attachmentPath != null ? '1 File' : 'None',
                    isDark: isDark,
                    onTap: _pickAttachment,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 7. Action Buttons
              if (widget.event != null) ...[
                _buildActionButton(
                  'Duplicate Event',
                  theme.colorScheme.primary,
                  _duplicateEvent,
                  cardColor,
                ),
                const SizedBox(height: 12),
                _buildActionButton('Delete Event', Colors.red, () {
                  ref.read(eventsProvider.notifier).deleteEvent(widget.event!);
                  Navigator.pop(context);
                }, cardColor),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard({
    required Color cardColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildTextInputRow({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int? maxLength,
    int maxLines = 1,
    int minLines = 1,
    required bool isDark,
    TextStyle? textStyle,
    Widget? trailing,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0, right: 12),
              child: Icon(
                icon,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 22,
              ),
            ),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              minLines: minLines,
              onChanged: onChanged,
              style:
                  textStyle ??
                  TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
              decoration: InputDecoration(
                hintText: hint,
                errorText: errorText,
                errorStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
                border: InputBorder.none,
                counterText: '', // Hide default counter to keep layout clean
                isDense: true,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required String title,
    String? valueText,
    Color? titleColor,
    required bool isDark,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) leading,
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            if (valueText != null)
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            if (onTap != null && trailing == null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required bool isStart,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _pickDate(isStart: isStart),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              if (!_isAllDay) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _pickTime(isStart: isStart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time.format(context),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isDark) {
    final isSelected = _selectedCategory == label;
    final catColor = _categoryColors[label] ?? _customColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
          // Auto-update event color when category changes (unless Custom)
          if (label != 'Custom' && _categoryColors.containsKey(label)) {
            _customColor = _categoryColors[label]!;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? catColor.withValues(alpha: isDark ? 0.3 : 0.1)
              : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? catColor.withValues(alpha: 0.5)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? catColor : catColor.withValues(alpha: 1.0))
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    Color color,
    VoidCallback onTap,
    Color cardColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
