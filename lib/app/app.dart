import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/connectivity_provider.dart';
import '../presentation/pages/error/no_internet_page.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isOnline = ref.watch(connectivityProvider);

    return MaterialApp.router(
      title: 'DineX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (!isOnline)
              const Positioned.fill(
                child: NoInternetPage(),
              ),
          ],
        );
      },
    );
  }
}
