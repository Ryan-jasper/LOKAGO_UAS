import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true; 

  Future<void> _play(String fileName) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('SoundService error: $e');
    }
  }

  Future<void> uiTap() => _play('ui_button.mp3');
  Future<void> uiButton() => _play('ui_button.mp3');
  Future<void> uiSelectPositive() => _play('ui_button.mp3');
  Future<void> answerCorrect() => _play('answer_correct.mp3');
  Future<void> answerWrong() => _play('answer_wrong.wav');
  Future<void> levelComplete() => _play('level_complete.mp3');
  Future<void> badgeUnlock() => _play('badge_unlock.wav');
  Future<void> streakCombo() => _play('streak_combo.wav');
  Future<void> heartLost() => _play('heart_lost.wav');
  Future<void> eggHatch() => _play('mascot.wav');
  Future<void> mapUnlock() => _play('map_unlock.wav');
  Future<void> notificationPopup() => _play('notification.mp3');
  Future<void> quizStart() => _play('start.wav');
}