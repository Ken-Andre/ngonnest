import 'package:flutter/material.dart';

enum ExpiryFilter {
  all,
  expiringSoon, // Within 7 days
  expired,
}

class InventoryFilterState {
  final String? selectedRoom;
  final ExpiryFilter expiryFilter;

  const InventoryFilterState({
    this.selectedRoom,
    this.expiryFilter = ExpiryFilter.all,
  });

  InventoryFilterState copyWith({
    String? selectedRoom,
    ExpiryFilter? expiryFilter,
  }) {
    return InventoryFilterState(
      selectedRoom: selectedRoom ?? this.selectedRoom,
      expiryFilter: expiryFilter ?? this.expiryFilter,
    );
  }

  bool get hasActiveFilters => selectedRoom != null || expiryFilter != ExpiryFilter.all;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryFilterState &&
        other.selectedRoom == selectedRoom &&
        other.expiryFilter == expiryFilter;
  }

  @override
  int get hashCode => selectedRoom.hashCode ^ expiryFilter.hashCode;
}

class InventoryFilterPanel extends StatefulWidget {
  final InventoryFilterState filterState;
  final Function(InventoryFilterState) onFilterChanged;
  final List<String> availableRooms;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const InventoryFilterPanel({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    required this.availableRooms,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  State<InventoryFilterPanel> createState() => _InventoryFilterPanelState();
}

class _InventoryFilterPanelState extends State<InventoryFilterPanel> {
  void _updateRoomFilter(String? room) {
    final newState = widget.filterState.copyWith(selectedRoom: room);
    widget.onFilterChanged(newState);
  }

  void _updateExpiryFilter(ExpiryFilter filter) {
    final newState = widget.filterState.copyWith(expiryFilter: filter);
    widget.onFilterChanged(newState);
  }

  void _clearAllFilters() {
    widget.onFilterChanged(const InventoryFilterState());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Filter header with toggle button
          InkWell(
            onTap: widget.onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: widget.filterState.hasActiveFilters
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtres',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: widget.filterState.hasActiveFilters
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (widget.filterState.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActiveFilterCount().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.filterState.hasActiveFilters)
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Effacer'),
                    ),
                  Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable filter content
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4, // Max 40% of screen height
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Room filter
                          Text(
                            'Pièce',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.start,
                              runAlignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                FilterChip(
                                  label: const Text('Toutes'),
                                  selected: widget.filterState.selectedRoom == null,
                                  onSelected: (_) => _updateRoomFilter(null),
                                ),
                                ...widget.availableRooms.map((room) => FilterChip(
                                  label: Text(
                                    room,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  selected: widget.filterState.selectedRoom == room,
                                  onSelected: (_) => _updateRoomFilter(room),
                                )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Expiry filter (only for consumables)
                          Text(
                            'Date d\'expiration',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.start,
                              runAlignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                FilterChip(
                                  label: const Text('Tous'),
                                  selected: widget.filterState.expiryFilter == ExpiryFilter.all,
                                  onSelected: (_) => _updateExpiryFilter(ExpiryFilter.all),
                                ),
                                FilterChip(
                                  label: const Text('Expire bientôt'),
                                  selected: widget.filterState.expiryFilter == ExpiryFilter.expiringSoon,
                                  onSelected: (_) => _updateExpiryFilter(ExpiryFilter.expiringSoon),
                                ),
                                FilterChip(
                                  label: const Text('Expirés'),
                                  selected: widget.filterState.expiryFilter == ExpiryFilter.expired,
                                  onSelected: (_) => _updateExpiryFilter(ExpiryFilter.expired),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (widget.filterState.selectedRoom != null) count++;
    if (widget.filterState.expiryFilter != ExpiryFilter.all) count++;
    return count;
  }
}
