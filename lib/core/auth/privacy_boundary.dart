import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_coordinator.dart';

class PrivacyBoundary extends StatefulWidget {
  const PrivacyBoundary({
    required this.session,
    required this.child,
    super.key,
  });
  final SessionCoordinator session;
  final Widget child;
  @override
  State<PrivacyBoundary> createState() => _PrivacyBoundaryState();
}

class _PrivacyBoundaryState extends State<PrivacyBoundary>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_key);
  }

  bool _key(KeyEvent event) {
    widget.session.activity();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.session.resume());
    } else {
      widget.session.background();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => widget.session.activity(),
    onPointerSignal: (_) => widget.session.activity(),
    onPointerMove: (_) => widget.session.activity(),
    child: widget.child,
  );
}
