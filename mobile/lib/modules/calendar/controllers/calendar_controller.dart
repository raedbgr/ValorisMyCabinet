import 'package:get/get.dart';
import '../../../data/models/deadline_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/services/api_client.dart';
import '../../auth/controllers/auth_controller.dart';

class CalendarController extends GetxController {
  final _repo = CalendarRepository();

  final deadlines = <DeadlineModel>[].obs;
  final selectedDeadline = Rxn<DeadlineModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final urgent = <DeadlineModel>[].obs;
  final upcoming = <DeadlineModel>[].obs;
  final late = <DeadlineModel>[].obs;
  final complete = <DeadlineModel>[].obs;

  String get _clientId {
    if (Get.isRegistered<AuthController>()) {
      final u = Get.find<AuthController>().currentUser.value;
      if (u != null) return u.id;
    }
    return _repo.defaultClientId;
  }

  @override
  void onInit() {
    super.onInit();
    refreshDeadlines();
  }

  Future<void> refreshDeadlines() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repo.fetchAll(_clientId);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Erreur inattendue';
    } finally {
      _refreshLocal();
      isLoading.value = false;
    }
  }

  Future<void> seedSampleDeadlines() async {
    try {
      await _repo.seedDeadlines(_clientId);
      await refreshDeadlines();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    }
  }

  void _refreshLocal() {
    deadlines.value = _repo.getAll();
    urgent.value = _repo.getByStatus(DeadlineStatus.urgent);
    upcoming.value = _repo.getByStatus(DeadlineStatus.upcoming);
    late.value = _repo.getByStatus(DeadlineStatus.late);
    complete.value = _repo.getByStatus(DeadlineStatus.complete);
  }

  void selectDeadline(DeadlineModel d) => selectedDeadline.value = d;

  @override
  void refresh() {
    refreshDeadlines();
  }
}
