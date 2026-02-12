import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ggd_punctuation/main.dart';

void main() {
  testWidgets('应用启动测试', (WidgetTester tester) async {
    // 构建应用并触发一帧
    await tester.pumpWidget(const MyApp());

    // 验证应用能够正常启动
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
