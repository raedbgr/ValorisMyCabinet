import 'package:get/get.dart';
import '../../../data/models/deadline_model.dart';
import '../../../data/repositories/calendar_repository.dart';

class CalendarController extends GetxController {
  final _repo = CalendarRepository();

  final deadlines = <DeadlineModel>[].obs;
  final selectedDeadline = Rxn<DeadlineModel>();

  final urgent = <DeadlineModel>[].obs;
  final upcoming = <DeadlineModel>[].obs;
  final late = <DeadlineModel>[].obs;
  final complete = <DeadlineModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    deadlines.value = _repo.getAll();
    urgent.value = _repo.getByStatus(DeadlineStatus.urgent);
    upcoming.value = _repo.getByStatus(DeadlineStatus.upcoming);
    late.value = _repo.getByStatus(DeadlineStatus.late);
    complete.value = _repo.getByStatus(DeadlineStatus.complete);
  }

  void selectDeadline(DeadlineModel d) => selectedDeadline.value = d;

  @override
  void refresh() => _load();
}
