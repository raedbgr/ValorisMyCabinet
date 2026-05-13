import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;

  void navigateTo(int index) {
    currentIndex.value = index;
  }

  void goToDocuments() => navigateTo(0);
  void goToCalendar() => navigateTo(1);
  void goToChat() => navigateTo(2);
}
