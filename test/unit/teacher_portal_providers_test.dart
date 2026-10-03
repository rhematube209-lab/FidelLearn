import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_learn/features/teacher/presentation/providers/teacher_portal_providers.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';

class FakeActiveSchoolContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  FakeActiveSchoolContextNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('P7 Teacher Portal Providers Test', () {
    test('teacherAssignedClassesProvider returns empty when not a teacher',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              const ActiveSchoolContext.independent(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final classes =
          await container.read(teacherAssignedClassesProvider.future);
      expect(classes, isEmpty);
    });

    test(
        'ClassRosterNotifier loads initial page, filters by search, and loads more',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const params = (classroomId: 'cls_12A', subjectId: 'physics_g12');
      final sub = container.listen(classRosterProvider(params), (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(classRosterProvider(params).notifier);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final initial = container.read(classRosterProvider(params)).value;
      expect(initial, isNotNull);
      expect(initial!.students.length, 25);
      expect(initial.hasMore, isTrue);

      // Test loadNext
      await notifier.loadNext();
      final afterNext = container.read(classRosterProvider(params)).value;
      expect(afterNext!.students.length, 44);
      expect(afterNext.hasMore, isFalse);

      // Test search filter
      await notifier.load(search: 'Almaz');
      final afterSearch = container.read(classRosterProvider(params)).value;
      expect(afterSearch!.students, isNotEmpty);
      expect(afterSearch.students.any((s) => s.displayName.contains('Almaz')),
          isTrue);
    });

    test('AttentionStudentsNotifier loads and handles pagination', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const params = (classroomId: 'cls_12A', subjectId: 'physics_g12');
      final sub =
          container.listen(attentionStudentsProvider(params), (_, __) {});
      addTearDown(sub.close);

      final notifier =
          container.read(attentionStudentsProvider(params).notifier);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final page = container.read(attentionStudentsProvider(params)).value;
      expect(page, isNotNull);
      expect(page!.items, isNotEmpty);
      expect(page.items.first.reasonCodes, isNotEmpty);

      await notifier.loadNext();
      final pageAfter = container.read(attentionStudentsProvider(params)).value;
      expect(pageAfter, isNotNull);
    });

    test('studentAcademicSummaryProvider returns parsed student summary',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const params = (
        studentId: 'student_3',
        classroomId: 'cls_12A',
        subjectId: 'physics_g12',
        subjectName: 'Physics',
      );

      final summary =
          await container.read(studentAcademicSummaryProvider(params).future);
      expect(summary, isNotNull);
      expect(summary!.studentId, 'student_3');
      expect(summary.recentExams, isNotEmpty);
      expect(summary.weakTopics, isNotEmpty);
    });
  });
}
