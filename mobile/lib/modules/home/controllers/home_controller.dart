import 'package:get/get.dart';
import '../../../data/models/document_model.dart';
import '../../../data/models/deadline_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/calendar_repository.dart';

class HomeController extends GetxController {
  final _docRepo = DocumentRepository();
  final _calRepo = CalendarRepository();

  final recentDocs = <DocumentModel>[].obs;
  final nextDeadline = Rxn<DeadlineModel>();
  final totalDocsThisMonth = 0.obs;
  final upcomingDeadlinesCount = 0.obs;
  final completionRate = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    recentDocs.value = _docRepo.getRecent();
    nextDeadline.value = _calRepo.getNext();
    totalDocsThisMonth.value = _docRepo.totalCount;
    upcomingDeadlinesCount.value =
        _calRepo.getByStatus(DeadlineStatus.upcoming).length +
            _calRepo.getByStatus(DeadlineStatus.urgent).length;
    completionRate.value = 78;
  }

  @override
  void refresh() => _load();
}
