import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  static final _mockUser = UserModel(
    id: 'usr_001',
    email: 'marie.dupont@valoris.fr',
    firstName: 'Marie',
    lastName: 'Dupont',
    companyName: 'Dupont Conseil SARL',
  );

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email et mot de passe requis.');
    }
    if (!email.contains('@')) {
      throw const AuthException('Adresse email invalide.');
    }
    if (password.length < 4) {
      throw const AuthException('Mot de passe trop court.');
    }
    return _mockUser;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
