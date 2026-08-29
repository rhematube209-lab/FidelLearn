import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/audio_explanation_models.dart';

void main() {
  group('AudioExplanation Model Tests', () {
    test('formats duration into mm:ss standard string', () {
      const audio1 = AudioExplanation(
        id: 'aud_1',
        questionId: 'q_math_1',
        language: 'en',
        durationSeconds: 42,
        audioUrl: 'https://cdn.fidellearn.et/audio/q1_en.opus',
        fileSizeBytes: 14500,
        narratorName: 'Dr. Abebe',
        transcription: 'Step by step derivation...',
      );

      const audio2 = AudioExplanation(
        id: 'aud_2',
        questionId: 'q_math_1',
        language: 'am',
        durationSeconds: 125, // 2 mins 5 secs
        audioUrl: 'https://cdn.fidellearn.et/audio/q1_am.opus',
        fileSizeBytes: 32000,
        narratorName: 'ወ/ሮ ትዕግስት',
        transcription: 'የደረጃ በደረጃ ማብራሪያ...',
      );

      expect(audio1.formattedDuration, '00:42');
      expect(audio2.formattedDuration, '02:05');
      expect(audio1.language, 'en');
      expect(audio2.language, 'am');
    });

    test('supports equality comparison for AudioExplanation instances', () {
      const a1 = AudioExplanation(
        id: 'aud_1',
        questionId: 'q_math_1',
        language: 'en',
        durationSeconds: 42,
        audioUrl: 'https://cdn.fidellearn.et/audio/q1_en.opus',
        fileSizeBytes: 14500,
        narratorName: 'Dr. Abebe',
        transcription: 'Transcription',
      );

      const a2 = AudioExplanation(
        id: 'aud_1',
        questionId: 'q_math_1',
        language: 'en',
        durationSeconds: 42,
        audioUrl: 'https://cdn.fidellearn.et/audio/q1_en.opus',
        fileSizeBytes: 14500,
        narratorName: 'Dr. Abebe',
        transcription: 'Transcription',
      );

      expect(a1, equals(a2));
    });
  });
}
