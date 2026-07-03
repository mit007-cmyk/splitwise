import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/connectivity_service.dart';
import '../utils/context_extension.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve connectivity stream from DI
    final connectivityService = GetIt.I<ConnectivityService>();

    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: connectivityService.onConnectionChanged,
            initialData: true, // Default to online
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? true;
              if (isOnline) {
                return const SizedBox.shrink();
              }
              
              // Render premium, styled offline warning bar
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: context.colorScheme.errorContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: context.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.translate('network_error_title'),
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
