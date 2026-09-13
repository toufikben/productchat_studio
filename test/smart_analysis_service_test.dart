import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/smart_analysis_service.dart';
void main() { test('invalid path returns a safe failure result', () async { final result = await SmartAnalysisService().analyze('/does/not/exist.png'); expect(result.ok, isFalse); expect(result.suggestions, isEmpty); }); }
