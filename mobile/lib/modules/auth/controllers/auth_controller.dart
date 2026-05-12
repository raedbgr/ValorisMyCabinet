import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final _repo = AuthRepository();

  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final obscurePassword = true.obs;

  bool get isAuthenticated => currentUser.value != null;

  void toggleObscurePassword() =>
      obscurePassword.value = !obscurePassword.value;

  void clearError() => errorMessage.value = null;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      currentUser.value = await _repo.signIn(
        email: email,
        password: password,
      );
      Get.offAllNamed(AppRoutes.main);
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Une erreur est survenue. Réessayez.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.auth);
  }
}
