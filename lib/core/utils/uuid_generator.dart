import 'package:uuid/uuid.dart';

class UuidGenerator {
  static String generate() {
    return const Uuid().v4();
  }
}
