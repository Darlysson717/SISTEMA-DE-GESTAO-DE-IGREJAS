import 'package:flutter/material.dart';

/// Constantes de breakpoints para layout responsivo.
class Breakpoints {
  /// Mobile pequeno: até 599px
  static const double mobile = 600;

  /// Tablet: de 600px a 1199px
  static const double tablet = 1200;

  /// Desktop: 1200px ou mais
  static const double desktop = 1200;

  /// Largura máxima para conteúdo em telas grandes
  static const double maxContentWidth = 1200;
}

/// Extensão para facilitar verificações de breakpoint.
extension ResponsiveExtension on BuildContext {
  /// Retorna true se a tela for considerada pequena (mobile).
  bool get isSmallScreen => MediaQuery.sizeOf(this).width < Breakpoints.mobile;

  /// Retorna true se a tela for considerada média (tablet).
  bool get isMediumScreen {
    final width = MediaQuery.sizeOf(this).width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Retorna true se a tela for considerada grande (desktop).
  bool get isLargeScreen => MediaQuery.sizeOf(this).width >= Breakpoints.desktop;

  /// Retorna true se a tela for desktop ou tablet (não mobile).
  bool get isNotMobile => MediaQuery.sizeOf(this).width >= Breakpoints.mobile;
}

/// Widget que aplica constraints de largura máxima e centraliza o conteúdo
/// em telas grandes, mantendo layout mobile em telas pequenas.
///
/// Uso:
/// ```dart
/// ResponsiveLayout(
///   child: Scaffold(
///     body: SingleChildScrollView(
///       child: Column(
///         children: [
///           // conteúdo aqui
///         ],
///       ),
///     ),
///   ),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool centerOnDesktop;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.centerOnDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = context.isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 32);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
        child: Padding(
          padding: padding ?? defaultPadding,
          child: child,
        ),
      ),
    );
  }
}

/// Wrapper para Scaffold que aplica layout responsivo automaticamente.
///
/// Em telas desktop/tablet, o conteúdo é centralizado com largura máxima.
/// Em telas mobile, ocupa a largura total.
class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final bool showNavigationChips;
  final VoidCallback? onNavigateToInicio;
  final VoidCallback? onNavigateToAgendamentos;
  final VoidCallback? onNavigateToPerfil;
  final int currentIndex;

  const ResponsiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.centerTitle = false,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.showNavigationChips = false,
    this.onNavigateToInicio,
    this.onNavigateToAgendamentos,
    this.onNavigateToPerfil,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              centerTitle: centerTitle,
              actions: actions,
              backgroundColor: backgroundColor,
            )
          : null,
      body: ResponsiveLayout(
        padding: EdgeInsets.zero,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}