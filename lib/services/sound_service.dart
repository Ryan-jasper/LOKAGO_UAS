import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true; // bisa disambungkan ke pengaturan notifikasi/suara user

  Future<void> _play(String fileName) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (_) {
      // Diamkan kalau file gagal diputar (misal device tanpa audio),
      // supaya tidak mengganggu flow utama app.
    }
  }

  Future<void> uiTap() => _play('ui_tap.wav');
  Future<void> uiButton() => _play('ui_button.wav');
  Future<void> uiSelectPositive() => _play('ui_select.wav');
  Future<void> answerCorrect() => _play('answer_correct.wav');
  Future<void> answerWrong() => _play('answer_wrong.wav');
  Future<void> levelComplete() => _play('level_complete.wav');
  Future<void> badgeUnlock() => _play('badge_unlock.wav');
  Future<void> streakCombo() => _play('streak_combo.wav');
  Future<void> heartLost() => _play('heart_lost.wav');
  Future<void> eggHatch() => _play('mascot.wav');
  Future<void> mapUnlock() => _play('map_unlock.wav');
  Future<void> notificationPopup() => _play('notification.wav');
  Future<void> quizStart() => _play('start.wav');
}