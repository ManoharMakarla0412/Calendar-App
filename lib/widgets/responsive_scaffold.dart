import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.title,
    this.titleWidget,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: titleWidget ?? Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            actions: actions,
          ),
          drawer: drawer,
          drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
          drawerEnableOpenDragGesture: true,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
