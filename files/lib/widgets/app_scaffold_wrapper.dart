import 'package:flutter/material.dart';

class AppScaffoldWrapper extends StatefulWidget {
  final Widget child;

  const AppScaffoldWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppScaffoldWrapper> createState() => _AppScaffoldWrapperState();
}

class _AppScaffoldWrapperState extends State<AppScaffoldWrapper>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // no-op
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Global chatbot removed; HomePage has its own draggable icon.
    return widget.child;
  }
}


