import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/navigation/main_navigation_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/documents/controllers/documents_controller.dart';
import '../../modules/calendar/controllers/calendar_controller.dart';
import '../../modules/chat/controllers/chat_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
    Get.lazyPut<MainNavigationController>(
      () => MainNavigationController(),
      fenix: true,
    );
    Get.lazyPut<HomeController>(
      () => HomeController(),
      fenix: true,
    );
    Get.lazyPut<DocumentsController>(
      () => DocumentsController(),
      fenix: true,
    );
    Get.lazyPut<CalendarController>(
      () => CalendarController(),
      fenix: true,
    );
    Get.lazyPut<ChatController>(
      () => ChatController(),
      fenix: true,
    );
  }
}
