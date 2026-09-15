import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local-only crash reporting. Reports remain on-device for developer review.
class CrashReportingService {
  static const _boxName = 'crash_reports';
  static const _maxReports = 50;
  static Box? _box;
  static RawReceivePort? _errorPort;

  static Future<void> init() async {
    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(_record(
        type: 'flutter',
        error: details.exceptionAsString(),
        stack: details.stack?.toString() ?? '',
        context: details.context?.toString() ?? '',
      ));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(_record(
        type: 'platform',
        error: error.toString(),
        stack: stack.toString(),
      ));
      return true;
    };

    _errorPort?.close();
    _errorPort = RawReceivePort((dynamic pair) {
      final list = pair is List ? pair : <dynamic>[pair, null];
      unawaited(_record(
        type: 'isolate',
        error: list.isNotEmpty ? list.first.toString() : 'Unknown isolate error',
        stack: list.length > 1 ? list[1]?.toString() ?? '' : '',
      ));
    });
    Isolate.current.addErrorListener(_errorPort!.sendPort);
  }

  static Future<void> _record({
    required String type,
    required String error,
    required String stack,
    String context = '',
  }) async {
    try {
      final box = _box;
      if (box == null) return;
      await box.add({
        'type': type,
        'error': error,
        'stack': stack,
        'context': context,
        'ts': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'platform': Platform.operatingSystem,
      });
      while (box.length > _maxReports) {
        await box.deleteAt(0);
      }
    } catch (_) {
      // The crash reporter must never become a source of crashes.
    }
  }

  static Future<void> recordError(Object error, StackTrace? stack,
          {String context = ''}) =>
      _record(
        type: 'manual',
        error: error.toString(),
        stack: stack?.toString() ?? '',
        context: context,
      );

  static List<Map<String, dynamic>> getAll() {
    final box = _box;
    if (box == null) return [];
    return box.values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList()
        .reversed
        .toList();
  }

  static int getCount() => _box?.length ?? 0;

  static String exportAsJson() => const JsonEncoder.withIndent('  ').convert(getAll());

  static Future<void> clear() async => _box?.clear();
}
