import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../data/repositories/auth_repository.dart';

// ---- Events -------------------------------------------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignUpRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

/// Fired after login once the user has answered "Upload your existing data?".
class AuthMigrationDecided extends AuthEvent {
  final bool uploadLocal;
  const AuthMigrationDecided(this.uploadLocal);
  @override
  List<Object?> get props => [uploadLocal];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Permanently delete the signed-in account and all its data.
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}

class AuthContinueAsGuest extends AuthEvent {
  const AuthContinueAsGuest();
}

class _AuthSessionChanged extends AuthEvent {
  final sb.User? user;
  const _AuthSessionChanged(this.user);
  @override
  List<Object?> get props => [user?.id];
}

// ---- States -------------------------------------------------------------

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthGuest extends AuthState {
  const AuthGuest();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Logged in, but we still need to ask whether to upload local guest data.
class AuthNeedsMigration extends AuthState {
  final sb.User user;
  final bool hasLocalData;
  const AuthNeedsMigration(this.user, this.hasLocalData);
  @override
  List<Object?> get props => [user.id, hasLocalData];
}

class AuthAuthenticated extends AuthState {
  final sb.User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user.id];
}

/// Sign-up succeeded but email confirmation is pending.
class AuthConfirmEmail extends AuthState {
  final String email;
  const AuthConfirmEmail(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Account deletion finished; the app is back in (empty) guest mode.
/// Separate from [AuthError] so only the Settings screen reacts to it.
class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted();
}

/// Account deletion failed; the user is still signed in.
class AuthDeleteFailed extends AuthState {
  final String message;
  const AuthDeleteFailed(this.message);
  @override
  List<Object?> get props => [message];
}

// ---- Bloc ---------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  StreamSubscription? _sub;
  bool _migrationHandled = false;

  AuthBloc(this._repo) : super(const AuthGuest()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleRequested>(_onGoogle);
    on<AuthMigrationDecided>(_onMigrationDecided);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
    on<AuthContinueAsGuest>((e, emit) => emit(const AuthGuest()));
    on<_AuthSessionChanged>(_onSessionChanged);
  }

  bool get isAvailable => _repo.isAvailable;

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    if (!_repo.isAvailable) {
      emit(const AuthGuest());
      return;
    }
    final user = _repo.currentUser;
    if (user != null) {
      _migrationHandled = true;
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthGuest());
    }
    _sub ??= _repo.authChanges?.listen((s) {
      add(_AuthSessionChanged(s.session?.user));
    });
  }

  Future<void> _onSessionChanged(
      _AuthSessionChanged e, Emitter<AuthState> emit) async {
    final user = e.user;
    if (user == null) {
      _migrationHandled = false;
      if (state is! AuthGuest) emit(const AuthGuest());
      return;
    }
    // Handles OAuth returns (Google) where the login didn't go through
    // _onSignIn.
    if (state is AuthAuthenticated || state is AuthNeedsMigration) return;
    if (_migrationHandled) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthNeedsMigration(user, _repo.hasLocalData));
    }
  }

  Future<void> _onSignIn(AuthSignInRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signIn(e.email, e.password);
      emit(AuthNeedsMigration(user, _repo.hasLocalData));
    } catch (err) {
      emit(AuthError(AuthRepository.friendlyError(err)));
      emit(const AuthGuest());
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signUp(e.email, e.password);
      final session = _repo.currentUser;
      if (session != null) {
        emit(AuthNeedsMigration(session, _repo.hasLocalData));
      } else if (user != null) {
        emit(AuthConfirmEmail(e.email));
        emit(const AuthGuest());
      } else {
        emit(const AuthError('Sign up failed.'));
        emit(const AuthGuest());
      }
    } catch (err) {
      emit(AuthError(AuthRepository.friendlyError(err)));
      emit(const AuthGuest());
    }
  }

  Future<void> _onGoogle(AuthGoogleRequested e, Emitter<AuthState> emit) async {
    try {
      await _repo.signInWithGoogle();
      // Result arrives through the auth stream → _onSessionChanged.
    } catch (err) {
      emit(AuthError(AuthRepository.friendlyError(err)));
      emit(const AuthGuest());
    }
  }

  Future<void> _onMigrationDecided(
      AuthMigrationDecided e, Emitter<AuthState> emit) async {
    final user = _repo.currentUser;
    if (user == null) {
      emit(const AuthGuest());
      return;
    }
    emit(const AuthLoading());
    try {
      await _repo.onLoggedIn(uploadLocal: e.uploadLocal);
    } catch (_) {
      // Sync failures are non-fatal; SyncService retries when online.
    }
    _migrationHandled = true;
    emit(AuthAuthenticated(user));
  }

  Future<void> _onSignOut(AuthSignOutRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repo.signOut();
    } catch (_) {}
    _migrationHandled = false;
    emit(const AuthGuest());
  }

  Future<void> _onDeleteAccount(
      AuthDeleteAccountRequested e, Emitter<AuthState> emit) async {
    final user = _repo.currentUser;
    emit(const AuthLoading());
    try {
      await _repo.deleteAccount();
      _migrationHandled = false;
      emit(const AuthAccountDeleted());
      emit(const AuthGuest());
    } catch (err) {
      debugPrint('Delete account failed: $err');
      emit(AuthDeleteFailed(err is sb.PostgrestException && err.code == 'PGRST202'
          // Function missing on the server → migration not run yet.
          ? "Account deletion isn't available yet. Please try again later."
          : AuthRepository.friendlyError(err)));
      if (user != null) emit(AuthAuthenticated(user));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
