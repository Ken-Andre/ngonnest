import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/error_logger_service.dart';
import '../models/alert.dart';

class DeveloperConsoleScreen extends StatefulWidget {
  const DeveloperConsoleScreen({super.key});

  @override
  State<DeveloperConsoleScreen> createState() => _DeveloperConsoleScreenState();
}

class _DeveloperConsoleScreenState extends State<DeveloperConsoleScreen> {
  List<ErrorLogEntry> _logs = [];
  bool _isLoading = true;
  bool _autoRefresh = false;
  ErrorSeverity? _filterSeverity;

  @override
  void initState() {
    super.initState();
    _loadLogs();

    if (_autoRefresh) {
      // Rafraîchissement automatique toutes les 5 secondes
      // (Seulement en mode développement)
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final allLogs = await ErrorLoggerService.getAllLogs();

      // Appliquer le filtre de sévérité
      final filteredLogs = _filterSeverity != null
          ? allLogs.where((log) => log.severity == _filterSeverity).toList()
          : allLogs;

      // Trier par date décroissante (plus récent en premier)
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _logs = filteredLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement logs: $e')),
        );
      }
    }
  }

  Future<void> _clearOldLogs() async {
    await ErrorLoggerService.cleanOldLogs(daysToKeep: 7);
    await _loadLogs();
  }

  Future<void> _clearAllLogs() async {
    // Pour une vraie implémentation, il faudrait ajouter cette méthode au service
    // Pour l'instant, on recharge juste
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark theme like dev consoles
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          '🛠️ Developer Console',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
          ),
        ),
        actions: [
          // Filtres de sévérité
          PopupMenuButton<ErrorSeverity>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (severity) {
              setState(() => _filterSeverity = severity);
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tous les logs'),
              ),
              const PopupMenuItem(
                value: ErrorSeverity.critical,
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Critiques'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ErrorSeverity.high,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Hauts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ErrorSeverity.medium,
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.yellow),
                    SizedBox(width: 8),
                    Text('Moyens'),
                  ],
                ),
              ),
            ],
          ),

          // Bouton refresh
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadLogs,
            child: const Icon(
              CupertinoIcons.refresh,
              color: Colors.white,
            ),
          ),

          // Menu actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'clear_old':
                  _clearOldLogs();
                  break;
                case 'clear_all':
                  _clearAllLogs();
                  break;
                case 'toggle_auto_refresh':
                  setState(() => _autoRefresh = !_autoRefresh);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_old',
                child: Text('Nettoyer anciens (>7 jours)'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Tout effacer'),
              ),
              PopupMenuItem(
                value: 'toggle_auto_refresh',
                child: Row(
                  children: [
                    Icon(_autoRefresh ? Icons.check_box : Icons.check_box_outline_blank),
                    const SizedBox(width: 8),
                    const Text('Auto-refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            )
          : _buildLogsList(),
    );
  }

  Widget _buildLogsList() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.tray,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun log disponible',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (_filterSeverity != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() => _filterSeverity = null);
                  _loadLogs();
                },
                child: const Text(
                  'Retirer le filtre',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(ErrorLogEntry log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getSeverityColor(log.severity),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            // Icon de sévérité
            Icon(
              _getSeverityIcon(log.severity),
              color: _getSeverityColor(log.severity),
              size: 20,
            ),
            const SizedBox(width: 8),
            // Code d'erreur et composant
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${log.errorCode} - ${log.component}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    log.operation,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Timestamp
            Text(
              _formatTimestamp(log.timestamp),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
        subtitle: Text(
          log.userMessage,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          // Détails étendus
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF252525),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message technique
                const Text(
                  'Message technique:',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.technicalMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),

                // Stack trace (tronqué)
                const Text(
                  'Stack trace (aperçu):',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _truncateStackTrace(log.stackTrace),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),

                // Métadonnées si présentes
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Métadonnées:',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.metadata.toString(),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 11,
                    ),
                  ),
                ],

                // Infos device
                const SizedBox(height: 12),
                const Text(
                  'Contexte système:',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.deviceInfo['platform'] ?? 'unknown'} • v${log.appVersion}',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return Colors.red;
      case ErrorSeverity.high:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.yellow;
      case ErrorSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return Icons.error;
      case ErrorSeverity.high:
        return Icons.warning;
      case ErrorSeverity.medium:
        return Icons.info;
      case ErrorSeverity.low:
        return Icons.check_circle;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return '${diff.inSeconds}s';
    }
  }

  String _truncateStackTrace(String stackTrace) {
    final lines = stackTrace.split('\n');
    if (lines.length <= 5) {
      return stackTrace;
    }
    return '${lines.take(5).join('\n')}\n... (${lines.length - 5} lignes supplémentaires)';
  }
}
