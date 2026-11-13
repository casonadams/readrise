import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Existing violations and why each is allowed; plan steps refer to
/// docs/architecture-plan.md. New violations fail; fixed ones must be
/// deleted from here.
const _allowed = {
  'packages/phonics_alphabet/lib/src/feed_monster_activity.dart: _MonsterView is a StatefulWidget':
      'one-off reading activity',
  'packages/phonics_alphabet/lib/src/feed_monster_activity.dart: _MonsterPainter draws with CustomPainter':
      'reading has one course; moves to a reading kit with the second',
  'packages/phonics_alphabet/lib/src/letter_intro_activity.dart: _IntroView is a StatefulWidget':
      'one-off reading activity',
  'packages/phonics_alphabet/lib/src/letter_quiz_activity.dart: _QuizView is a StatefulWidget':
      'one-off reading activity',
  'packages/phonics_alphabet/lib/src/letter_quiz_activity.dart: _QuizViewState runs a Ticker':
      'reading has one course; moves to a reading kit with the second',
  'packages/phonics_alphabet/lib/src/letter_quiz_activity.dart: _BalloonPainter draws with CustomPainter':
      'reading has one course; moves to a reading kit with the second',
  'packages/phonics_alphabet/lib/src/letter_trace_activity.dart: _TraceView is a StatefulWidget':
      'one-off reading activity',
  'packages/phonics_alphabet/lib/src/letter_trace_activity.dart: _TracePainter draws with CustomPainter':
      'reading has one course; moves to a reading kit with the second',
  'packages/science_matter/lib/src/experiments/balloon.dart: _BalancePainter draws with CustomPainter':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/heat_lab_activity.dart: _HeatLabView is a StatefulWidget':
      'one-off science activity',
  'packages/science_matter/lib/src/heat_scenes.dart: _ThermometerPainter draws with CustomPainter':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/particle_sim.dart: unseeded Random()':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/particle_view.dart: _ParticlePainter draws with CustomPainter':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/particle_view.dart: _ParticleViewState runs a Ticker':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/particle_view.dart: ParticleView is a StatefulWidget':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/water_molecule_scene.dart: _BondPainter draws with CustomPainter':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/water_molecule_scene.dart: _MoleculeScene is a StatefulWidget':
      'step 9: moves to science_kit',
  'packages/science_matter/lib/src/water_molecule_scene.dart: _MoleculeSceneState runs a Ticker':
      'step 9: moves to science_kit',
};

enum _Layer { api, activityKit, subjectKit, course, app, testing }

_Layer _layerOf(String package) => switch (package) {
  'readrise' => _Layer.app,
  'readrise_plugin_api' => _Layer.api,
  'activity_kit' => _Layer.activityKit,
  'readrise_testing' => _Layer.testing,
  _ when package.endsWith('_kit') => _Layer.subjectKit,
  _ => _Layer.course,
};

/// No layer lists [_Layer.testing]: shipped code never imports test helpers.
const _mayImport = {
  _Layer.api: <_Layer>{},
  _Layer.activityKit: {_Layer.api},
  _Layer.subjectKit: {_Layer.api, _Layer.activityKit},
  _Layer.course: {_Layer.api, _Layer.activityKit, _Layer.subjectKit},
  _Layer.app: {_Layer.api},
  _Layer.testing: {_Layer.api, _Layer.activityKit, _Layer.subjectKit},
};

class _Source {
  _Source(this.package, this.path)
    : unit = parseFile(
        path: File(path).absolute.path,
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;

  final String package;
  final String path;
  final CompilationUnit unit;
}

List<_Source> _sources() => [
  for (final (package, dir) in [
    ('readrise', 'lib'),
    for (final d in Directory('packages').listSync().whereType<Directory>())
      (d.uri.pathSegments.where((s) => s.isNotEmpty).last, '${d.path}/lib'),
  ])
    for (final f in Directory(dir).listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart')) _Source(package, f.path),
];

/// Violations found in [source], as "path: what" lines.
List<String> _violations(_Source source, Set<String> ours) {
  final found = <String>[];
  final layer = _layerOf(source.package);
  for (final directive
      in source.unit.directives.whereType<UriBasedDirective>()) {
    final uri = directive.uri.stringValue ?? '';
    if (!uri.startsWith('package:')) continue;
    final target = uri.substring('package:'.length).split('/').first;
    if (!ours.contains(target) || target == source.package) continue;
    final targetLayer = _layerOf(target);
    final coursesListed =
        layer == _Layer.app &&
        targetLayer == _Layer.course &&
        source.path == 'lib/plugins.dart';
    if (!coursesListed && !_mayImport[layer]!.contains(targetLayer)) {
      found.add('${source.path}: imports $target');
    }
    if (uri.startsWith('package:$target/src/')) {
      found.add('${source.path}: imports internals of $target');
    }
  }
  final visitor = _CodeVisitor(source.path, course: layer == _Layer.course);
  source.unit.accept(visitor);
  return found..addAll(visitor.found);
}

class _CodeVisitor extends RecursiveAstVisitor<void> {
  _CodeVisitor(this.path, {required this.course});

  final String path;
  final bool course;
  final List<String> found = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (course) {
      final name = node.namePart.typeName.lexeme;
      final superclass = node.extendsClause?.superclass.name.lexeme;
      final mixins = [
        for (final t in node.withClause?.mixinTypes ?? <NamedType>[])
          t.name.lexeme,
      ];
      if (superclass == 'StatefulWidget') {
        found.add('$path: $name is a StatefulWidget');
      }
      if (superclass == 'CustomPainter') {
        found.add('$path: $name draws with CustomPainter');
      }
      if (mixins.any((m) => m.contains('TickerProviderStateMixin'))) {
        found.add('$path: $name runs a Ticker');
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null &&
        node.methodName.name == 'Random' &&
        node.argumentList.arguments.isEmpty) {
      found.add('$path: unseeded Random()');
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'Random' &&
        node.argumentList.arguments.isEmpty) {
      found.add('$path: unseeded Random()');
    }
    super.visitInstanceCreationExpression(node);
  }
}

void main() {
  final sources = _sources();
  final ours = {for (final s in sources) s.package};
  final found = {for (final s in sources) ..._violations(s, ours)};

  test('no new architecture violations', () {
    expect(
      found.difference(_allowed.keys.toSet()),
      isEmpty,
      reason:
          'physics and drawing belong in kits, packages import only lower '
          'layers, and randomness comes from a seeded Random',
    );
  });

  test('the allowlist holds only violations that still exist', () {
    expect(
      _allowed.keys.toSet().difference(found),
      isEmpty,
      reason: 'these were fixed: delete them from _allowed',
    );
  });
}
