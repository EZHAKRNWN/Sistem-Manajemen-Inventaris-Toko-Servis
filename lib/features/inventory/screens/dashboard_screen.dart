import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Screens',
    'Batteries',
    'Cameras',
    'Motherboards',
    'Charging Ports',
  ];

  // Mock repair shop inventory items
  final List<Map<String, dynamic>> _inventoryData = [
    {
      'sku': 'SCR-IP13-OLED',
      'name': 'iPhone 13 OLED Display Assembly',
      'brand': 'Apple',
      'category': 'Screens',
      'stock': 14,
      'minStock': 5,
      'price': 1450000,
    },
    {
      'sku': 'BAT-SAM-S22',
      'name': 'Samsung Galaxy S22 Ultra Battery (5000mAh)',
      'brand': 'Samsung',
      'category': 'Batteries',
      'stock': 3,
      'minStock': 5,
      'price': 420000,
    },
    {
      'sku': 'CAM-IP14P-MAIN',
      'name': 'iPhone 14 Pro 48MP Main Camera Module',
      'brand': 'Apple',
      'category': 'Cameras',
      'stock': 6,
      'minStock': 2,
      'price': 1200000,
    },
    {
      'sku': 'CHG-XIAO-13P',
      'name': 'Xiaomi 13 Pro 120W USB-C Flex Cable',
      'brand': 'Xiaomi',
      'category': 'Charging Ports',
      'stock': 22,
      'minStock': 10,
      'price': 180000,
    },
    {
      'sku': 'MOB-PIX-7P',
      'name': 'Google Pixel 7 Pro Motherboard (128GB Unlocked)',
      'brand': 'Google',
      'category': 'Motherboards',
      'stock': 1,
      'minStock': 2,
      'price': 2850000,
    },
    {
      'sku': 'BAT-IP12-OEM',
      'name': 'iPhone 12 / 12 Pro Battery OEM',
      'brand': 'Apple',
      'category': 'Batteries',
      'stock': 0,
      'minStock': 5,
      'price': 350000,
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _inventoryData.where((item) {
      final matchesSearch = item['name'].toString().toLowerCase().contains(query) ||
          item['sku'].toString().toLowerCase().contains(query) ||
          item['brand'].toString().toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventory Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new stock alert notifications.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search spare parts, SKU, or brand...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Inventory KPI Summary Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildKpiCard(
                  context,
                  title: 'Total Parts',
                  value: '${_inventoryData.length}',
                  color: Colors.blue,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  context,
                  title: 'Low Stock',
                  value: '${_inventoryData.where((e) => (e['stock'] as int) < (e['minStock'] as int)).length}',
                  color: Colors.orange,
                  icon: Icons.warning_amber_rounded,
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  context,
                  title: 'Out of Stock',
                  value: '${_inventoryData.where((e) => (e['stock'] as int) == 0).length}',
                  color: Colors.redAccent,
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Inventory List View
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        Text(
                          'No spare parts found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final stock = item['stock'] as int;
                      final minStock = item['minStock'] as int;

                      Color statusColor = Colors.green;
                      String statusText = 'In Stock ($stock)';
                      if (stock == 0) {
                        statusColor = Colors.red;
                        statusText = 'Out of Stock';
                      } else if (stock < minStock) {
                        statusColor = Colors.orange;
                        statusText = 'Low ($stock)';
                      }

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item['category']),
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SKU: ${item['sku']} • ${item['brand']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${(item['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Screens':
        return Icons.smartphone;
      case 'Batteries':
        return Icons.battery_charging_full;
      case 'Cameras':
        return Icons.camera_alt_outlined;
      case 'Motherboards':
        return Icons.memory;
      case 'Charging Ports':
        return Icons.cable;
      default:
        return Icons.handyman;
    }
  }
}
