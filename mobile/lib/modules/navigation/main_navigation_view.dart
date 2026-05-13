import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main_navigation_controller.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../documents/views/documents_view.dart';
import '../calendar/views/calendar_view.dart';
import '../chat/views/chat_view.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  static const _screens = [
    DocumentsView(),
    CalendarView(),
    ChatView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: _screens,
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: controller.currentIndex.value,
          onTap: controller.navigateTo,
        ),
      ),
    );
  }
}
