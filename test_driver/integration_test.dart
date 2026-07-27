import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// 截图驱动：跑在宿主机上，负责把设备端捕获的画面落盘并做合规校验。
///
/// 注意 onScreenshot 的调用时机——integration_test 会把测试过程中的截图
/// 攒到运行结束后统一回调，**不是**实时的。所以这里只能用它带回的字节，
/// 不能在回调里临时去抓屏（那样会抓到最后一屏，五张全一样）。
Future<void> main() async {
  const outDir = 'build/screenshots';
  await Directory(outDir).create(recursive: true);

  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final path = '$outDir/$name.png';
          await File(path).writeAsBytes(bytes);
          final result = await Process.run('bash', [
            'tool/screenshots/normalize.sh',
            path,
          ]);
          stdout.write(result.stdout);
          if (result.exitCode != 0) {
            stderr.write(result.stderr);
            return false;
          }
          return true;
        },
  );
}
