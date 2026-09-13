import '../models/edit_request.dart';
class ModelManager { const ModelManager(); Future<bool> isReady(String model) async => false; }
class AiService { const AiService(); Future<String> apply(String imagePath, EditOp op) async => imagePath; }
