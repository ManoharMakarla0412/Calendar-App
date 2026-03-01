import 'package:flutter_riverpod/flutter_riverpod.dart';

class Mood {
  final String emoji;
  final String label;

  const Mood({required this.emoji, required this.label});
}

const List<Mood> availableMoods = [
  Mood(emoji: '🤩', label: 'Excited'),
  Mood(emoji: '😊', label: 'Happy'),
  Mood(emoji: '🥰', label: 'Loved'),
  Mood(emoji: '😎', label: 'Cool'),
  Mood(emoji: '💪', label: 'Productive'),
  Mood(emoji: '🧘', label: 'Calm'),
  Mood(emoji: '✨', label: 'Inspired'),
  Mood(emoji: '🥳', label: 'Party'),
  Mood(emoji: '🤔', label: 'Thinking'),
  Mood(emoji: '😐', label: 'Neutral'),
  Mood(emoji: '😴', label: 'Tired'),
  Mood(emoji: '🥱', label: 'Bored'),
  Mood(emoji: '😔', label: 'Sad'),
  Mood(emoji: '😭', label: 'Crying'),
  Mood(emoji: '🥺', label: 'Lonely'),
  Mood(emoji: '🤯', label: 'Stressed'),
  Mood(emoji: '😠', label: 'Angry'),
  Mood(emoji: '😱', label: 'Scared'),
  Mood(emoji: '🤒', label: 'Sick'),
  Mood(emoji: '🤕', label: 'Hurt'),
];

class MoodNotifier extends Notifier<Map<String, Mood>> {
  @override
  Map<String, Mood> build() {
    return {};
  }

  void setMood(DateTime date, Mood mood) {
    final key = _getDateKey(date);
    state = {
      ...state,
      key: mood,
    };
  }

  Mood? getMood(DateTime date) {
    return state[_getDateKey(date)];
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

final moodProvider = NotifierProvider<MoodNotifier, Map<String, Mood>>(() {
  return MoodNotifier();
});
