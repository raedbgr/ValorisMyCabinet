class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? companyName;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.companyName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();
}
