import 'package:equatable/equatable.dart';

enum SavedAccountProvider {
  password,
  google,
}

class SavedAccount extends Equatable {
  const SavedAccount({
    required this.email,
    required this.displayName,
    required this.provider,
    this.password,
    this.token,
  });

  final String email;
  final String displayName;
  final SavedAccountProvider provider;
  final String? password;
  final String? token;

  bool get isGoogle => provider == SavedAccountProvider.google;

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      provider: (json['provider'] as String?) == 'google'
          ? SavedAccountProvider.google
          : SavedAccountProvider.password,
      password: json['password'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'provider': provider == SavedAccountProvider.google
            ? 'google'
            : 'password',
        if (password != null) 'password': password,
        if (token != null) 'token': token,
      };

  @override
  List<Object?> get props => [email, displayName, provider, password, token];
}
