import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable app bar widget for the tailoring business management app.
/// Implements the "Contemporary Nigerian Business" design style with clean, purposeful design.
///
/// This widget provides consistent top navigation across the application with
/// support for various configurations including title, actions, and back navigation.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display in the app bar
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Whether to show the back button (defaults to automatic detection)
  final bool? showBackButton;

  /// Optional leading widget (overrides back button if provided)
  final Widget? leading;

  /// Optional list of action widgets
  final List<Widget>? actions;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional foreground color override
  final Color? foregroundColor;

  /// Optional elevation override
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Optional custom title widget (overrides title string)
  final Widget? titleWidget;

  /// Optional bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
    this.titleWidget,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canPop = ModalRoute.of(context)?.canPop ?? false;
    final bool shouldShowBack = showBackButton ?? canPop;

    return AppBar(
      title: titleWidget ?? _buildTitle(theme),
      leading:
          leading ?? (shouldShowBack ? _buildBackButton(context, theme) : null),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      automaticallyImplyLeading: shouldShowBack && leading == null,
    );
  }

  /// Builds the title widget with optional subtitle
  Widget _buildTitle(ThemeData theme) {
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.appBarTheme.titleTextStyle),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return Text(title, style: theme.appBarTheme.titleTextStyle);
  }

  /// Builds the back button with proper styling
  Widget _buildBackButton(BuildContext context, ThemeData theme) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Back',
      color: theme.appBarTheme.foregroundColor,
    );
  }

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

/// A specialized app bar variant for customer profile screens with tabs
class CustomAppBarWithTabs extends StatelessWidget
    implements PreferredSizeWidget {
  /// The title to display in the app bar
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// The tab controller for the tab bar
  final TabController tabController;

  /// The list of tabs to display
  final List<String> tabs;

  /// Optional list of action widgets
  final List<Widget>? actions;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional foreground color override
  final Color? foregroundColor;

  const CustomAppBarWithTabs({
    super.key,
    required this.title,
    this.subtitle,
    required this.tabController,
    required this.tabs,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      bottom: TabBar(
        controller: tabController,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        labelColor: theme.tabBarTheme.labelColor,
        unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor,
        indicatorColor: theme.tabBarTheme.indicatorColor,
        labelStyle: theme.tabBarTheme.labelStyle,
        unselectedLabelStyle: theme.tabBarTheme.unselectedLabelStyle,
        indicatorSize:
            theme.tabBarTheme.indicatorSize ?? TabBarIndicatorSize.tab,
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}

/// A specialized app bar variant for search functionality
class CustomSearchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The search query controller
  final TextEditingController searchController;

  /// Callback when search query changes
  final ValueChanged<String>? onSearchChanged;

  /// Callback when search is submitted
  final ValueChanged<String>? onSearchSubmitted;

  /// Placeholder text for the search field
  final String hintText;

  /// Optional list of action widgets
  final List<Widget>? actions;

  /// Optional background color override
  final Color? backgroundColor;

  const CustomSearchAppBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.hintText = 'Search customers...',
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      title: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        onSubmitted: onSearchSubmitted,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: theme.appBarTheme.foregroundColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.6),
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.appBarTheme.foregroundColor?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  onPressed: () {
                    searchController.clear();
                    if (onSearchChanged != null) {
                      onSearchChanged!('');
                    }
                  },
                )
              : null,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
