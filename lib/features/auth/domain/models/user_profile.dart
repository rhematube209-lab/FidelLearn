import 'package:equatable/equatable.dart';

enum UserRole {
  student,
  teacher,
  schoolAdmin,
  platformAdmin;

  static UserRole fromString(String val) {
    switch (val.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'school_admin':
      case 'schooladmin':
        return UserRole.schoolAdmin;
      case 'platform_admin':
      case 'platformadmin':
      case 'admin':
        return UserRole.platformAdmin;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.teacher:
        return 'teacher';
      case UserRole.schoolAdmin:
        return 'school_admin';
      case UserRole.platformAdmin:
        return 'platform_admin';
      case UserRole.student:
        return 'student';
    }
  }
}

class UserProfile extends Equatable {
  final String id;
  final String phoneNumber;
  final String displayName;
  final int grade;
  final String stream; // 'natural' | 'social' | 'common'
  final String preferredLanguage; // 'en' | 'am'
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.displayName,
    required this.grade,
    required this.stream,
    required this.preferredLanguage,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? phoneNumber,
    String? displayName,
    int? grade,
    String? stream,
    String? preferredLanguage,
    UserRole? role,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      grade: grade ?? this.grade,
      stream: stream ?? this.stream,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'display_name': displayName,
      'grade': grade,
      'stream': stream,
      'preferred_language': preferredLanguage,
      'role': role.toDbString(),
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Student',
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'natural',
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      role: UserRole.fromString(json['role'] as String? ?? 'student'),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        displayName,
        grade,
        stream,
        preferredLanguage,
        role,
        avatarUrl,
        createdAt,
      ];
}
