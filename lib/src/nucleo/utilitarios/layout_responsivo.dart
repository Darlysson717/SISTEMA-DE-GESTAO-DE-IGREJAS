import 'package:flutter/material.dart';

/// Constantes de breakpoints para layout responsivo.
class Breakpoints {
  /// Mobile pequeno: até 599px
  static const double mobile = 600;

  /// Tablet: de 600px a 899px
  static const double tablet = 900;

  /// Desktop: de 900px a 1400px
  static const double desktop = 900;

  /// Desktop grande: 1400px ou mais
  static const double desktopLarge = 1400;

  /// Largura máxima para conteúdo em telas grandes
  static const double maxContentWidth = 1400;
}

/// Extensão para facilitar verificações de breakpoint.
extension ResponsiveExtension on BuildContext {
  /// Retorna true se a tela for considerada pequena (mobile).
  bool get isSmallScreen => MediaQuery.sizeOf(this).width < Breakpoints.mobile;

  /// Retorna true se a tela for considerada tablet.
  bool get isTablet {
    final width = MediaQuery.sizeOf(this).width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Retorna true se a tela for considerada desktop.
  bool get isDesktop => MediaQuery.sizeOf(this).width >= Breakpoints.desktop;

  /// Retorna true se a tela for desktop grande.
  bool get isDesktopLarge => MediaQuery.sizeOf(this).width >= Breakpoints.desktopLarge;

  /// Retorna o número de colunas para grids baseado no tamanho da tela.
  int get gridColumns {
    if (isSmallScreen) return 1;
    if (isTablet) return 2;
    if (isDesktopLarge) return 4;
    return 3; // desktop padrão
  }
}

/// Widget que aplica constraints de largura máxima e centraliza o conteúdo
/// em telas grandes, mantendo layout mobile em telas pequenas.
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

/// Sidebar de navegação para desktop.
class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SidebarItem> items;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.church,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 32),
          // Items de navegação
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = currentIndex == index;
                return _SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;

  SidebarItem({required this.icon, required this.label});
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra superior para desktop.
class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? notificationBadge;

  const DesktopAppBar({
    super.key,
    required this.title,
    this.actions,
    this.notificationBadge,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (notificationBadge != null) ...[
            notificationBadge!,
            const SizedBox(width: 16),
          ],
          ...?actions,
        ],
      ),
    );
  }
}

/// Card responsivo que se adapta ao tamanho da tela.
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final effectivePadding = padding ??
        EdgeInsets.all(isDesktop ? 16 : 20);

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow: onTap != null && isDesktop
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Grid responsivo que ajusta o número de colunas automaticamente.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.gridColumns;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: columns == 1 ? 2.5 : (columns == 2 ? 2.0 : 1.5),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}