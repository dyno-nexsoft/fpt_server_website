import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot notification consumed by the single top-level listener in
/// `app.dart` — mirrors the "no try/catch + ScaffoldMessenger in individual
/// widgets" convention: business logic sets this, the app root displays it.
class ToastMessage {
  const ToastMessage(this.text, {this.isError = false});

  final String text;
  final bool isError;
}

class AppToastNotifier extends Notifier<ToastMessage?> {
  @override
  ToastMessage? build() => null;

  void show(String text, {bool isError = false}) {
    state = ToastMessage(text, isError: isError);
  }

  void clear() => state = null;
}

final appToastProvider = NotifierProvider<AppToastNotifier, ToastMessage?>(
  AppToastNotifier.new,
);
