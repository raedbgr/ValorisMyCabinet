import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../bindings/initial_binding.dart';
import '../../modules/navigation/main_navigation_view.dart';
import '../../modules/auth/views/auth_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainNavigationView(),
      binding: InitialBinding(),
    ),
  ];
}
