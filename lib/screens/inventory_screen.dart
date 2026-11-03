import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/stock_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const List<String> _categoryOptions = [
    'All',
    'Electronics',
    'Stationery',
    'Hardware',
    'Grocery',
  ];

  static const List<String> _sortOptions = [
    'Default (newest first)',
    'Quantity: Low to High',
    'Quantity: High to Low',
  ];

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  bool _lowStockOnly = false;
  String _selectedSort = _sortOptions.first;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _lowStockOnly = false;
      _selectedSort = _sortOptions.first;
    });
  }

  List<StockItem> _applyFilters(List<StockItem> items) {
    final keyword = _searchController.text.trim().toLowerCase();

    final filtered = items.where((item) {
      final matchesKeyword =
          keyword.isEmpty ||
          item.itemName.toLowerCase().contains(keyword) ||
          item.sku.toLowerCase().contains(keyword);
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesLowStock = !_lowStockOnly || item.isLowStock;
      return matchesKeyword && matchesCategory && matchesLowStock;
    }).toList();

    if (_selectedSort == 'Quantity: Low to High') {
      filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else if (_selectedSort == 'Quantity: High to Low') {
      filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
    } else {
      filtered.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    }

    return filtered;
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory != 'All' ||
      _lowStockOnly ||
      _selectedSort != _sortOptions.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterPanel(context),
        const Divider(height: 1),
        Expanded(child: _buildInventoryList()),
      ],
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by SKU or Item Name',
              hintText: 'e.g. mouse or STK-102',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(_searchController.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _categoryOptions
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value ?? 'All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSort,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _sortOptions
                      .map(
                        (sort) => DropdownMenuItem<String>(
                          value: sort,
                          child: Text(
                            sort,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _selectedSort = value ?? _sortOptions.first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _lowStockOnly,
                  onChanged: (value) =>
                      setState(() => _lowStockOnly = value ?? false),
                  title: const Text('Low Stock Only'),
                  subtitle: const Text('Quantity <= reorder level'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              TextButton.icon(
                onPressed: _hasActiveFilters ? _clearFilters : null,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('stockItems').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline,
            color: Colors.red,
            title: 'Failed to load inventory',
            subtitle: '${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final items = docs.map(StockItem.fromDoc).toList();

        if (items.isEmpty) {
          return const _MessageState(
            icon: Icons.inventory_2_outlined,
            color: Colors.grey,
            title: 'No inventory items yet',
            subtitle:
                'Add your first item from the Stock Entry tab. It will be saved to Firestore.',
          );
        }

        final filtered = _applyFilters(items);

        if (filtered.isEmpty) {
          return const _MessageState(
            icon: Icons.search_off,
            color: Colors.grey,
            title: 'No stock items match your search or filters.',
            subtitle: 'Try a different keyword or clear the filters.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ItemCard(item: filtered[index]),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.isLowStock;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: lowStock ? Colors.red.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (lowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOW STOCK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(icon: Icons.qr_code_2, label: item.sku),
                _Chip(icon: Icons.category_outlined, label: item.category),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(
                  label: 'Quantity',
                  value: '${item.quantity}',
                  highlight: lowStock,
                ),
                _Metric(
                  label: 'Unit Price',
                  value: 'RM ${item.unitPrice.toStringAsFixed(2)}',
                ),
                _Metric(
                  label: 'Reorder Level',
                  value: '${item.reorderLevel}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.red.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
