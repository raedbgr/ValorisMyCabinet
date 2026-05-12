import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;

  void navigateTo(int index) {
    currentIndex.value = index;
  }

  void goToDocuments() => navigateTo(1);
  void goToCalendar() => navigateTo(2);
  void goToChat() => navigateTo(3);
  void goToHome() => navigateTo(0);
}
