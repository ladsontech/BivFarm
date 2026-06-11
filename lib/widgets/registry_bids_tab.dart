import 'package:flutter/material.dart';
import '../models/bid_model.dart';
import '../models/bulk_order_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

enum DateFilterType { all, today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth, custom, customRange }
enum SortType { dateNewest, dateOldest, priceHigh, priceLow }

bool matchesDateFilter(DateTime date, DateFilterType filter, DateTime? customDate, DateTime? customEndDate) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  
  switch (filter) {
    case DateFilterType.all:
      return true;
    case DateFilterType.today:
      final todayEnd = todayStart.add(const Duration(days: 1));
      return date.isAfter(todayStart) && date.isBefore(todayEnd);
    case DateFilterType.yesterday:
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      return date.isAfter(yesterdayStart) && date.isBefore(todayStart);
    case DateFilterType.thisWeek:
      final daysToSubtract = now.weekday - 1;
      final weekStart = todayStart.subtract(Duration(days: daysToSubtract));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return date.isAfter(weekStart) && date.isBefore(weekEnd);
    case DateFilterType.lastWeek:
      final daysToSubtract = now.weekday - 1;
      final thisWeekStart = todayStart.subtract(Duration(days: daysToSubtract));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      return date.isAfter(lastWeekStart) && date.isBefore(thisWeekStart);
    case DateFilterType.thisMonth:
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      return date.isAfter(monthStart) && date.isBefore(monthEnd);
    case DateFilterType.lastMonth:
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      return date.isAfter(lastMonthStart) && date.isBefore(thisMonthStart);
    case DateFilterType.custom:
      if (customDate == null) return true;
      final customStart = DateTime(customDate.year, customDate.month, customDate.day);
      final customEnd = customStart.add(const Duration(days: 1));
      return date.isAfter(customStart) && date.isBefore(customEnd);
    case DateFilterType.customRange:
      if (customDate == null || customEndDate == null) return true;
      final rangeStart = DateTime(customDate.year, customDate.month, customDate.day);
      final rangeEnd = DateTime(customEndDate.year, customEndDate.month, customEndDate.day + 1);
      return date.isAfter(rangeStart) && date.isBefore(rangeEnd);
  }
}

List<T> sortBids<T>(List<T> items, SortType sortType) {
  final sorted = List<T>.from(items);
  
  switch (sortType) {
    case SortType.dateNewest:
      sorted.sort((a, b) {
        DateTime dateA = (a is BidModel) ? a.createdAt : (a as BulkOrderModel).createdAt;
        DateTime dateB = (b is BidModel) ? b.createdAt : (b as BulkOrderModel).createdAt;
        return dateB.compareTo(dateA);
      });
      break;
    case SortType.dateOldest:
      sorted.sort((a, b) {
        DateTime dateA = (a is BidModel) ? a.createdAt : (a as BulkOrderModel).createdAt;
        DateTime dateB = (b is BidModel) ? b.createdAt : (b as BulkOrderModel).createdAt;
        return dateA.compareTo(dateB);
      });
      break;
    case SortType.priceHigh:
      sorted.sort((a, b) {
        double priceA = (a is BidModel) ? a.offeredPrice : 0;
        double priceB = (b is BidModel) ? b.offeredPrice : 0;
        return priceB.compareTo(priceA);
      });
      break;
    case SortType.priceLow:
      sorted.sort((a, b) {
        double priceA = (a is BidModel) ? a.offeredPrice : 0;
        double priceB = (b is BidModel) ? b.offeredPrice : 0;
        return priceA.compareTo(priceB);
      });
      break;
  }
  
  return sorted;
}

Widget _buildTableHeader(List<String> titles, List<int> flexes) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceLight,
      border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
    ),
    child: Row(
      children: List.generate(titles.length, (index) {
        return Expanded(
          flex: flexes[index],
          child: Text(
            titles[index],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        );
      }),
    ),
  );
}

class RegistryBidsTab extends StatefulWidget {
  final DatabaseService db;
  const RegistryBidsTab({super.key, required this.db});

  @override
  State<RegistryBidsTab> createState() => _RegistryBidsTabState();
}

class _RegistryBidsTabState extends State<RegistryBidsTab> with SingleTickerProviderStateMixin {
  late TabController _typeCtrl;
  DateFilterType _selectedFilter = DateFilterType.all;
  DateTime? _selectedCustomDate;
  DateTime? _selectedCustomEndDate;
  SortType _selectedSort = SortType.dateNewest;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangeDialog(context);
    if (picked != null) {
      setState(() {
        _selectedFilter = DateFilterType.customRange;
        _selectedCustomDate = picked.start;
        _selectedCustomEndDate = picked.end;
      });
    }
  }

  Widget _buildEnhancedFilterBar() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Column(
      children: [
        // Date filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _FilterChip(
                label: 'All Time',
                isSelected: _selectedFilter == DateFilterType.all,
                onTap: () => setState(() => _selectedFilter = DateFilterType.all),
              ),
              _FilterChip(
                label: 'Today',
                isSelected: _selectedFilter == DateFilterType.today,
                onTap: () => setState(() => _selectedFilter = DateFilterType.today),
              ),
              _FilterChip(
                label: 'Yesterday',
                isSelected: _selectedFilter == DateFilterType.yesterday,
                onTap: () => setState(() => _selectedFilter = DateFilterType.yesterday),
              ),
              _FilterChip(
                label: 'This Week',
                isSelected: _selectedFilter == DateFilterType.thisWeek,
                onTap: () => setState(() => _selectedFilter = DateFilterType.thisWeek),
              ),
              _FilterChip(
                label: 'Last Week',
                isSelected: _selectedFilter == DateFilterType.lastWeek,
                onTap: () => setState(() => _selectedFilter = DateFilterType.lastWeek),
              ),
              _FilterChip(
                label: 'This Month',
                isSelected: _selectedFilter == DateFilterType.thisMonth,
                onTap: () => setState(() => _selectedFilter = DateFilterType.thisMonth),
              ),
              _FilterChip(
                label: 'Last Month',
                isSelected: _selectedFilter == DateFilterType.lastMonth,
                onTap: () => setState(() => _selectedFilter = DateFilterType.lastMonth),
              ),
              _FilterChip(
                label: 'Pick Date',
                isSelected: _selectedFilter == DateFilterType.custom,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedCustomDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedFilter = DateFilterType.custom;
                      _selectedCustomDate = picked;
                    });
                  }
                },
              ),
              _FilterChip(
                label: 'Date Range',
                isSelected: _selectedFilter == DateFilterType.customRange,
                onTap: _showDateRangePicker,
              ),
            ],
          ),
        ),
        // Sort and controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortDropdown(
                        selectedSort: _selectedSort,
                        onSortChanged: (sort) => setState(() => _selectedSort = sort),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedFilter == DateFilterType.custom && _selectedCustomDate != null)
                        Chip(
                          label: Text(
                            'Date: ${DateFormat('MMM dd, yyyy').format(_selectedCustomDate!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () => setState(() => _selectedFilter = DateFilterType.all),
                          backgroundColor: AppTheme.green.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppTheme.green),
                        ),
                      if (_selectedFilter == DateFilterType.customRange && _selectedCustomDate != null && _selectedCustomEndDate != null)
                        Chip(
                          label: Text(
                            '${DateFormat('MMM dd').format(_selectedCustomDate!)} - ${DateFormat('MMM dd, yyyy').format(_selectedCustomEndDate!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () => setState(() => _selectedFilter = DateFilterType.all),
                          backgroundColor: AppTheme.green.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppTheme.green),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _typeCtrl,
            labelColor: AppTheme.green,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.green,
            tabs: const [
              Tab(text: 'Bulk Requests'),
              Tab(text: 'Individual Bids'),
            ],
          ),
        ),
        _buildEnhancedFilterBar(),
        Expanded(
          child: TabBarView(
            controller: _typeCtrl,
            children: [
              _BulkRequestsList(
                db: widget.db,
                selectedFilter: _selectedFilter,
                selectedCustomDate: _selectedCustomDate,
                selectedCustomEndDate: _selectedCustomEndDate,
                selectedSort: _selectedSort,
              ),
              _IndividualBidsList(
                db: widget.db,
                selectedFilter: _selectedFilter,
                selectedCustomDate: _selectedCustomDate,
                selectedCustomEndDate: _selectedCustomEndDate,
                selectedSort: _selectedSort,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.green,
        backgroundColor: AppTheme.surfaceLight,
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppTheme.border,
            width: 0.5,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final SortType selectedSort;
  final Function(SortType) onSortChanged;

  const _SortDropdown({
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
        color: AppTheme.card,
      ),
      child: DropdownButton<SortType>(
        value: selectedSort,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: const [
          DropdownMenuItem(
            value: SortType.dateNewest,
            child: Text('Newest First', style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: SortType.dateOldest,
            child: Text('Oldest First', style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: SortType.priceHigh,
            child: Text('Price High', style: TextStyle(fontSize: 12)),
          ),
          DropdownMenuItem(
            value: SortType.priceLow,
            child: Text('Price Low', style: TextStyle(fontSize: 12)),
          ),
        ],
        onChanged: (sort) {
          if (sort != null) onSortChanged(sort);
        },
      ),
    );
  }
}

Future<DateTimeRange?> showDateRangeDialog(BuildContext context) async {
  final result = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  return result;
}

class _BulkRequestsList extends StatelessWidget {
  final DatabaseService db;
  final DateFilterType selectedFilter;
  final DateTime? selectedCustomDate;
  final DateTime? selectedCustomEndDate;
  final SortType selectedSort;

  const _BulkRequestsList({
    required this.db,
    required this.selectedFilter,
    required this.selectedCustomDate,
    required this.selectedCustomEndDate,
    required this.selectedSort,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    
    return StreamBuilder<List<BulkOrderModel>>(
      stream: db.streamBulkOrders(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var orders = snap.data!;
        
        // Date filtering
        orders = orders.where((o) => matchesDateFilter(o.createdAt, selectedFilter, selectedCustomDate, selectedCustomEndDate)).toList();
        
        // Sorting
        orders = sortBids(orders, selectedSort) as List<BulkOrderModel>;
        
        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No bulk requests matching your filters',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return isWide
            ? _buildWideLayout(orders)
            : _buildMobileLayout(orders);
      },
    );
  }

  Widget _buildWideLayout(List<BulkOrderModel> orders) {
    return Column(
      children: [
        _buildTableHeader(['Date', 'Item & Category', 'Qty', 'Buyer', 'Status', ''], [2, 3, 2, 2, 2, 1]),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            separatorBuilder: (ctx, i) => Divider(height: 0, color: AppTheme.border, thickness: 0.5),
            itemBuilder: (ctx, i) {
              return _BulkOrderRow(order: orders[i], db: db);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<BulkOrderModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        return _BulkOrderMobileCard(order: orders[i], db: db);
      },
    );
  }
}

class _IndividualBidsList extends StatelessWidget {
  final DatabaseService db;
  final DateFilterType selectedFilter;
  final DateTime? selectedCustomDate;
  final DateTime? selectedCustomEndDate;
  final SortType selectedSort;

  const _IndividualBidsList({
    required this.db,
    required this.selectedFilter,
    required this.selectedCustomDate,
    required this.selectedCustomEndDate,
    required this.selectedSort,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    
    return StreamBuilder<List<BidModel>>(
      stream: db.streamAllBids(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var bids = snap.data!;
        
        // Date filtering
        bids = bids.where((b) => matchesDateFilter(b.createdAt, selectedFilter, selectedCustomDate, selectedCustomEndDate)).toList();
        
        // Sorting
        bids = sortBids(bids, selectedSort) as List<BidModel>;
        
        if (bids.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No individual bids matching your filters',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return isWide
            ? _buildWideLayout(bids)
            : _buildMobileLayout(bids);
      },
    );
  }

  Widget _buildWideLayout(List<BidModel> bids) {
    return Column(
      children: [
        _buildTableHeader(['Date', 'Product', 'Buyer', 'Price (UGX)', 'Status', ''], [2, 3, 2, 2, 2, 1]),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bids.length,
            separatorBuilder: (ctx, i) => Divider(height: 0, color: AppTheme.border, thickness: 0.5),
            itemBuilder: (ctx, i) {
              return _BidRow(bid: bids[i], db: db);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<BidModel> bids) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: bids.length,
      itemBuilder: (ctx, i) {
        return _BidMobileCard(bid: bids[i], db: db);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════════
// Mobile Card Widgets
// ═══════════════════════════════════════════════════════════════════════════════════

class _BulkOrderMobileCard extends StatefulWidget {
  final BulkOrderModel order;
  final DatabaseService db;
  const _BulkOrderMobileCard({required this.order, required this.db});

  @override
  State<_BulkOrderMobileCard> createState() => _BulkOrderMobileCardState();
}

class _BulkOrderMobileCardState extends State<_BulkOrderMobileCard> {
  bool _expanded = false;
  bool _updating = false;

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Processing', 'Distributor Assigned', 'Completed']
              .map((status) => ListTile(
                    title: Text(status),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _updating = true);
                      try {
                        await widget.db.updateBulkOrderStatus(widget.order.id, status);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating status: $e')),
                        );
                      }
                      if (mounted) setState(() => _updating = false);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final formattedDate = DateFormat('MMM dd, yyyy').format(o.createdAt);
    
    Color statusColor = AppTheme.warning;
    if (o.status == 'Completed') {
      statusColor = AppTheme.green;
    } else if (o.status == 'Processing' || o.status == 'Distributor Assigned') {
      statusColor = AppTheme.info;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppTheme.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.itemName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          o.status,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _mobileDetailItem('Qty', '${o.quantity} ${o.quantityUnit}'),
                      _mobileDetailItem('Buyer', o.buyerName),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 12),
                    _mobileDetailItem('Order ID', o.id),
                    const SizedBox(height: 8),
                    _mobileDetailItem('Phone', o.buyerPhone),
                    const SizedBox(height: 8),
                    _mobileDetailItem('Category', o.category),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showStatusDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Update Status', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileDetailItem(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BidMobileCard extends StatefulWidget {
  final BidModel bid;
  final DatabaseService db;
  const _BidMobileCard({required this.bid, required this.db});

  @override
  State<_BidMobileCard> createState() => _BidMobileCardState();
}

class _BidMobileCardState extends State<_BidMobileCard> {
  bool _expanded = false;
  bool _updating = false;

  void _verifyBid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Bid'),
        content: Text('Verify bid for ${widget.bid.productName} (UGX ${widget.bid.offeredPrice.toInt()})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _updating = true);
      try {
        await widget.db.updateBid(widget.bid.id, {'isRegistryVerified': true, 'status': 'Under Review'});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Bid Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Under Review', 'Accepted', 'Rejected', 'Completed']
              .map((status) => ListTile(
                    title: Text(status),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _updating = true);
                      try {
                        await widget.db.updateBidStatus(widget.bid.id, status);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating status: $e')),
                        );
                      }
                      if (mounted) setState(() => _updating = false);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bid;
    final formattedDate = DateFormat('MMM dd, yyyy').format(b.createdAt);
    
    Color statusColor = AppTheme.info;
    if (b.status == 'Accepted' || b.status == 'Completed' || b.isRegistryVerified) {
      statusColor = AppTheme.green;
    } else if (b.status == 'Rejected') {
      statusColor = AppTheme.error;
    } else if (b.status == 'Pending') {
      statusColor = AppTheme.warning;
    }

    final displayStatus = b.isRegistryVerified ? 'Registry Verified' : b.status;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppTheme.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.productName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _mobileDetailItem('Price', 'UGX ${b.offeredPrice.toInt()}'),
                      _mobileDetailItem('Buyer', b.buyerName),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 12),
                    _mobileDetailItem('Bid ID', b.id),
                    const SizedBox(height: 8),
                    _mobileDetailItem('Qty', '${b.quantity}'),
                    const SizedBox(height: 8),
                    _mobileDetailItem('Seller', b.sellerName),
                    const SizedBox(height: 8),
                    _mobileDetailItem('Registry', b.isRegistryVerified ? 'Verified' : 'Not Verified'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          if (!b.isRegistryVerified)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _verifyBid,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.green,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text('Verify', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          if (!b.isRegistryVerified) const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showStatusDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.info,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Status', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileDetailItem(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════════
// Desktop/Web Row Widgets
// ═══════════════════════════════════════════════════════════════════════════════════

class _BulkOrderRow extends StatefulWidget {
  final BulkOrderModel order;
  final DatabaseService db;
  const _BulkOrderRow({required this.order, required this.db});

  @override
  State<_BulkOrderRow> createState() => _BulkOrderRowState();
}

class _BulkOrderRowState extends State<_BulkOrderRow> {
  bool _expanded = false;
  bool _updating = false;

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Processing', 'Distributor Assigned', 'Completed']
              .map((status) => ListTile(
                    title: Text(status),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _updating = true);
                      try {
                        await widget.db.updateBulkOrderStatus(widget.order.id, status);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating status: $e')),
                        );
                      }
                      if (mounted) setState(() => _updating = false);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showNotesDialog() {
    final ctrl = TextEditingController(text: widget.order.adminNotes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Admin Notes'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter notes here...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _updating = true);
              try {
                await widget.db.updateBulkOrderAdminNotes(widget.order.id, ctrl.text.trim());
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating notes: $e')),
                );
              }
              if (mounted) setState(() => _updating = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final formattedDate = DateFormat('MMM dd, yyyy').format(o.createdAt);
    final formattedTime = DateFormat('HH:mm').format(o.createdAt);
    
    Color statusColor = AppTheme.warning;
    if (o.status == 'Completed') {
      statusColor = AppTheme.green;
    } else if (o.status == 'Processing' || o.status == 'Distributor Assigned') {
      statusColor = AppTheme.info;
    }

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          hoverColor: AppTheme.cardHover.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.itemName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        o.category,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${o.quantity} ${o.quantityUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    o.buyerName,
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _updating
                      ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              o.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  flex: 1,
                  child: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _detailItem('Order ID', o.id),
                    _detailItem('Buyer Phone', o.buyerPhone),
                    _detailItem('Order Type', o.orderType),
                    _detailItem('Created At', DateFormat('yyyy-MM-dd HH:mm:ss').format(o.createdAt)),
                  ],
                ),
                if (o.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailItem('Buyer Notes', o.notes),
                ],
                const SizedBox(height: 12),
                _detailItem('Admin/Registry Notes', o.adminNotes.isEmpty ? 'No notes added' : o.adminNotes),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showStatusDialog,
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showNotesDialog,
                      icon: const Icon(Icons.note_alt_outlined, size: 14),
                      label: const Text('Admin Notes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _BidRow extends StatefulWidget {
  final BidModel bid;
  final DatabaseService db;
  const _BidRow({required this.bid, required this.db});

  @override
  State<_BidRow> createState() => _BidRowState();
}

class _BidRowState extends State<_BidRow> {
  bool _expanded = false;
  bool _updating = false;

  void _verifyBid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Bid'),
        content: Text('Are you sure you want to mark the bid for ${widget.bid.productName} (UGX ${widget.bid.offeredPrice.toInt()}) as verified by Registry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify Bid')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _updating = true);
      try {
        await widget.db.updateBid(widget.bid.id, {'isRegistryVerified': true, 'status': 'Under Review'});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Bid Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Under Review', 'Accepted', 'Rejected', 'Completed']
              .map((status) => ListTile(
                    title: Text(status),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _updating = true);
                      try {
                        await widget.db.updateBidStatus(widget.bid.id, status);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating status: $e')),
                        );
                      }
                      if (mounted) setState(() => _updating = false);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showNotesDialog() {
    final ctrl = TextEditingController(text: widget.bid.adminNotes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Admin Notes'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter admin notes here...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _updating = true);
              try {
                await widget.db.updateBid(widget.bid.id, {'adminNotes': ctrl.text.trim()});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating notes: $e')),
                );
              }
              if (mounted) setState(() => _updating = false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bid;
    final formattedDate = DateFormat('MMM dd, yyyy').format(b.createdAt);
    final formattedTime = DateFormat('HH:mm').format(b.createdAt);
    
    Color statusColor = AppTheme.info;
    if (b.status == 'Accepted' || b.status == 'Completed' || b.isRegistryVerified) {
      statusColor = AppTheme.green;
    } else if (b.status == 'Rejected') {
      statusColor = AppTheme.error;
    } else if (b.status == 'Pending') {
      statusColor = AppTheme.warning;
    }

    final displayStatus = b.isRegistryVerified ? 'Registry Verified' : b.status;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          hoverColor: AppTheme.cardHover.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    b.productName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    b.buyerName,
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'UGX ${b.offeredPrice.toInt()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.green,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _updating
                      ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  flex: 1,
                  child: Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bid Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _detailItem('Bid ID', b.id),
                    _detailItem('Product ID', b.productId),
                    _detailItem('Buyer Phone', b.buyerPhone),
                    _detailItem('Seller Name', b.sellerName),
                    _detailItem('Seller Phone', b.sellerPhone),
                    _detailItem('Quantity', '${b.quantity}'),
                    _detailItem('Offered Price', 'UGX ${b.offeredPrice.toInt()}'),
                    _detailItem('Registry Verified', b.isRegistryVerified ? '✓ Yes' : 'No'),
                  ],
                ),
                if (b.notes != null && b.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailItem('Buyer Notes', b.notes!),
                ],
                const SizedBox(height: 12),
                _detailItem('Admin Notes', (b.adminNotes == null || b.adminNotes!.isEmpty) ? 'No notes' : b.adminNotes!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!b.isRegistryVerified) ...[
                      ElevatedButton.icon(
                        onPressed: _verifyBid,
                        icon: const Icon(Icons.verified_outlined, size: 14),
                        label: const Text('Verify Bid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: _showStatusDialog,
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.info,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showNotesDialog,
                      icon: const Icon(Icons.note_alt_outlined, size: 14),
                      label: const Text('Admin Notes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ],
    );
  }
}
