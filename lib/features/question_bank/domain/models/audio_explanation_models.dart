import 'package:equatable/equatable.dart';

class AudioExplanation extends Equatable {
  final String id;
  final String questionId;
  final String language; // 'en' | 'am'
  final int durationSeconds;
  final String audioUrl;
  final int fileSizeBytes;
  final String narratorName;
  final String transcription;

  const AudioExplanation({
    required this.id,
    required this.questionId,
    required this.language,
    required this.durationSeconds,
    required this.audioUrl,
    required this.fileSizeBytes,
    required this.narratorName,
    required this.transcription,
  });

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  List<Object?> get props => [
        id,
        questionId,
        language,
        durationSeconds,
        audioUrl,
        fileSizeBytes,
        narratorName,
        transcription,
      ];
}
