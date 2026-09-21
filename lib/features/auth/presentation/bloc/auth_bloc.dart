import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/auth/session_coordinator.dart';
import '../../domain/auth_models.dart';

sealed class AuthEvent {
  @override
  String toString() => 'AuthEvent(redacted)';
}

final class AuthRequested extends AuthEvent {
  AuthRequested(this.action, this.input);
  final AuthAction action;
  final AuthInput input;
}

final class AuthLogoutRequested extends AuthEvent {}

final class AuthLockRequested extends AuthEvent {}

final class _SessionChanged extends AuthEvent {
  _SessionChanged(this.snapshot);
  final AuthViewState snapshot;
}

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthViewState> {
  AuthBloc(this.coordinator) : super(coordinator.state) {
    on<AuthRequested>((event, emit) async {
      await coordinator.run(event.action, event.input);
    });
    on<AuthLogoutRequested>((event, emit) async => coordinator.logout());
    on<AuthLockRequested>((event, emit) => coordinator.lock());
    on<_SessionChanged>((event, emit) => emit(event.snapshot));
    _subscription = coordinator.changes.listen((state) {
      if (!isClosed) add(_SessionChanged(state));
    });
  }
  final SessionCoordinator coordinator;
  late final StreamSubscription<AuthViewState> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    // Cancel session listening before closing the event queue.
    await super.close();
  }
}
