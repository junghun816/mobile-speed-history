import 'package:flutter/material.dart';

class AppBody extends StatelessWidget {
  const AppBody({
    super.key,
    required this.child,
    this.dismissKeyboard = true,
  });

  final Widget child;
  final bool dismissKeyboard;

  @override
  Widget build(BuildContext context) {
    if (!dismissKeyboard) return child;
    return Listener(
      onPointerDown: (_) => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
