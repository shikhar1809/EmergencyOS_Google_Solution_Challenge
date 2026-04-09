import 'package:flutter/material.dart';

/// Shared so code outside [GoRouter] (e.g. drill cleanup) can reach a [BuildContext] under [ProviderScope].
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>();
