part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  const AuthState._(this.status, {this.user, this.message});

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.authenticated(User user)
      : this._(AuthStatus.authenticated, user: user);
  const AuthState.error(String message)
      : this._(AuthStatus.error, message: message);

  final AuthStatus status;
  final User? user;
  final String? message;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [status, user?.id, message];
}
