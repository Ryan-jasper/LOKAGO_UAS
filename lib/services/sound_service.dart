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

  Future<void> uiTap() => _play('ui_tap_07s_wood_bamboo.wav');
  Future<void> uiButton() => _play('ui_button_07s_bamboo_soft.wav');
  Future<void> uiSelectPositive() => _play('ui_select_positive_07s_bonang.wav');
  Future<void> answerCorrect() => _play('answer_correct_07s_bamboo_bonang.wav');
  Future<void> answerWrong() => _play('answer_wrong_07s_soft_kendang_gong.wav');
  Future<void> levelComplete() => _play('level_complete_07s_gamelan_ui.wav');
  Future<void> badgeUnlock() => _play('badge_unlock_07s_bonang_spark.wav');
  Future<void> streakCombo() => _play('streak_combo_07s_angklung_rise.wav');
  Future<void> heartLost() => _play('heart_lost_07s_soft_wood_gong.wav');
  Future<void> eggHatch() => _play('egg_hatch_07s_bamboo_spark.wav');
  Future<void> mapUnlock() => _play('map_unlock_07s_bonang_open.wav');
  Future<void> notificationPopup() => _play('notification_popup_07s_saron_clean.wav');
  Future<void> quizStart() => _play('quiz_start_07s_kecapi_bamboo.wav');
}