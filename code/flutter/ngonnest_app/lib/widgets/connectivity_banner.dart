import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Widget bannière de connectivité dynamique
/// Utilise uniquement les couleurs du thème pour compatibilité light/dark
/// Respecte les guidelines de l'app pour padding, borderRadius et typographie
class ConnectivityBanner extends StatelessWidget {
  // Paramètres optionnels pour les tests (override le service si fournis)
  final bool? isConnected;
  final bool? isReconnected;
  final VoidCallback? onDismiss;

  const ConnectivityBanner({
    super.key,
    this.isConnected,
    this.isReconnected,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Si des paramètres explicites sont fournis, les utiliser (mode test)
    if (isConnected != null) {
      return _buildStaticBanner(context, theme, colorScheme);
    }

    // Sinon, utiliser le ConnectivityService (mode normal)
    final connectivity = context.watch<ConnectivityService>();

    // Ne pas afficher si la bannière n'est pas active
    if (!connectivity.showBanner) {
      return const SizedBox.shrink();
    }

    // Déterminer les couleurs selon l'état de connectivité
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (!connectivity.isOnline) {
      // État offline - utiliser colorScheme.error
      backgroundColor = colorScheme.error;
      textColor = colorScheme.onError;
      icon = Icons.wifi_off;
      message = 'Vous êtes hors ligne';
    } else {
      // État reconnecté - utiliser colorScheme.secondary
      backgroundColor = colorScheme.secondary;
      textColor = colorScheme.onSecondary;
      icon = Icons.wifi;
      message = 'De retour en ligne';
    }

    return AnimatedOpacity(
      opacity: connectivity.showBanner ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _buildBannerContainer(
        theme: theme,
        backgroundColor: backgroundColor,
        textColor: textColor,
        icon: icon,
        message: message,
        onDismiss: connectivity.hideConnectivityBanner,
      ),
    );
  }

  Widget _buildStaticBanner(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    // Mode test avec paramètres explicites
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (isConnected == false) {
      // État offline - utiliser colorScheme.error
      backgroundColor = colorScheme.error;
      textColor = colorScheme.onError;
      icon = Icons.wifi_off;
      message = 'Pas de connexion';
    } else if (isConnected == true && isReconnected == true) {
      // État reconnecté - utiliser colorScheme.secondary
      backgroundColor = colorScheme.secondary;
      textColor = colorScheme.onSecondary;
      icon = Icons.wifi;
      message = 'Connexion rétablie';
    } else {
      // État connecté normal - ne pas afficher la bannière
      return const SizedBox.shrink();
    }

    return _buildBannerContainer(
      theme: theme,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      message: message,
      onDismiss: onDismiss,
    );
  }

  Widget _buildBannerContainer({
    required ThemeData theme,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16), // Utilise le borderRadius du thème
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 18,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
