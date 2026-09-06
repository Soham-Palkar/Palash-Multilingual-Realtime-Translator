import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/constants/app_colors.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final bool showLabel;
  final bool allowToggle;

  const ConnectionStatusBadge({
    super.key,
    this.showLabel = true,
    this.allowToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, conn, child) {
        final isOnline = conn.isOnline;
        final isSimulated = conn.isSimulatedOffline;

        return Tooltip(
          message: allowToggle
              ? 'टैप करके ऑनलाइन/ऑफ़लाइन मोड बदलें (Tap to toggle offline demo mode)'
              : (isOnline ? 'Online' : 'Offline'),
          child: InkWell(
            onTap: allowToggle
                ? () {
                    conn.toggleSimulation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 2),
                        backgroundColor:
                            conn.isOnline ? AppColors.secondary : AppColors.error,
                        content: Row(
                          children: [
                            Icon(
                              conn.isOnline ? Icons.wifi : Icons.wifi_off,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                conn.isOnline
                                    ? '🟢 ऑनलाइन मोड सक्रिय (Online mode active)'
                                    : '🔴 ऑफ़लाइन परीक्षण मोड सक्रिय (Simulated offline mode - all student features continue working)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.secondaryContainer
                    : AppColors.errorContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnline ? AppColors.secondary : AppColors.error,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.secondary : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Text(
                      isOnline
                          ? 'Online'
                          : (isSimulated ? 'Offline (Demo)' : 'Offline'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOnline
                            ? AppColors.onSecondaryContainer
                            : AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
