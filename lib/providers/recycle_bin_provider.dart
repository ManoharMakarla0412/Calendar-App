import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class RecycleBinNotifier extends Notifier<List<Event>> {
  @override
  List<Event> build() {
    _loadFromCache();
    return [];
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('recycle_bin_cache');
    if (cachedData != null) {
      final List<dynamic> jsonList = jsonDecode(cachedData);
      state = jsonList.map((j) => Event.fromJson(j)).toList();
      _purgeOldEvents();
    }
  }

  void _purgeOldEvents() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final originalCount = state.length;
    
    state = state.where((e) {
      if (e.deletedAt == null) return false;
      return e.deletedAt!.isAfter(cutoff);
    }).toList();
    
    if (state.length != originalCount) {
      _saveToCache();
    }
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('recycle_bin_cache', jsonData);
  }

  void moveToBin(Event event) {
    state = [...state, event.copyWith(isDeleted: true, deletedAt: DateTime.now())];
    _saveToCache();
  }

  void restoreFromBin(Event event) {
    state = state.where((e) => e.id != event.id).toList();
    _saveToCache();
  }

  void permanentlyDelete(Event event) {
    state = state.where((e) => e.id != event.id).toList();
    _saveToCache();
  }

  void emptyBin() {
    state = [];
    _saveToCache();
  }
}

final recycleBinProvider = NotifierProvider<RecycleBinNotifier, List<Event>>(() {
  return RecycleBinNotifier();
});
