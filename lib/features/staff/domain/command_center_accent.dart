import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'admin_panel_access.dart';

/// Command Center chrome accent: medical = red, master = brand blue.
class CommandCenterAccent {
  const CommandCenterAccent({required this.primary});

  final Color primary;

  static CommandCenterAccent forRole(AdminConsoleRole role) {
    switch (role) {
      case AdminConsoleRole.medical:
        return const CommandCenterAccent(primary: Color(0xFFE53935));
      case AdminConsoleRole.master:
        return CommandCenterAccent(primary: AppColors.accentBlue);
    }
  }
}
