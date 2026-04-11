import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PriceCalculatorScreen extends StatefulWidget {
  const PriceCalculatorScreen({super.key});

  @override
  State<PriceCalculatorScreen> createState() => _PriceCalculatorScreenState();
}

class _PriceCalculatorScreenState extends State<PriceCalculatorScreen> {
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _rates = {};
  bool _loading = true;

  Map<String, dynamic>? _selectedItem;
  String? _selectedCategory;

  final _makingCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');

  static const double _luxuryTaxRate = 0.02; // 2%

  @override
  void initState() {
    super.initState();
    _loadData();
    _makingCtrl.addListener(() => setState(() {}));
    _discountCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final itemsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .get();
      final ratesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('prices')
          .get();
      _items = itemsSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _rates = ratesSnap.exists ? ratesSnap.data()! : {};

      // Extract unique categories
      final categories = _items
          .map((item) => item['itemCategory'] as String?)
          .where((cat) => cat != null && cat.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  // ── Calculations ──────────────────────────────────────────

  double get _goldBase {
    if (_selectedItem == null) return 0;
    final karat = _selectedItem!['goldKarat'] ?? '18k';
    final weight = (_selectedItem!['goldWeightGrams'] as num?)?.toDouble() ?? 0;
    final gold = _rates['gold'] as Map<String, dynamic>? ?? {};
    final rate = (gold[karat] as num?)?.toDouble() ?? 0;
    return weight * rate;
  }

  double get _goldLuxuryTax => _goldBase * _luxuryTaxRate;
  double get _goldTotal => _goldBase + _goldLuxuryTax;

  List<Map<String, dynamic>> get _diamondBreakdown {
    if (_selectedItem == null) return [];
    final diamonds = _selectedItem!['diamonds'] as List<dynamic>? ?? [];
    final dRates = _rates['diamond'] as Map<String, dynamic>? ?? {};
    return diamonds.map((d) {
      final cat = d['category'] ?? '';
      final carats = (d['totalCarats'] as num?)?.toDouble() ?? 0;
      // Map old cent-based categories to new carat-based categories for backward compatibility
      final mappedCat = _mapOldCategoryToNew(cat);
      final rate = (dRates[mappedCat] as num?)?.toDouble() ?? 0;
      final price = carats * rate;
      return {
        'label': mappedCat,
        'carats': carats,
        'rate': rate,
        'price': price,
        'pieces': d['pieces'] ?? 0,
      };
    }).toList();
  }

  // Map old cent-based categories to new carat-based categories
  String _mapOldCategoryToNew(String oldCategory) {
    const mapping = {
      '0–6 cent': '0–0.06 carat',
      '7–13 cent': '0.07–0.13 carat',
      '14–18 cent': '0.14–0.18 carat',
      '19–22 cent': '0.19–0.22 carat',
      '23–27 cent': '0.23–0.27 carat',
      '28–36 cent': '0.28–0.36 carat',
      '37–43 cent': '0.37–0.43 carat',
      '44–65 cent': '0.44–0.65 carat',
      '66–80 cent': '0.66–0.80 carat',
      '81–99 cent': '0.81–0.99 carat',
    };
    return mapping[oldCategory] ??
        oldCategory; // Return original if no mapping found
  }

  double get _diamondSubtotal =>
      _diamondBreakdown.fold(0.0, (s, d) => s + (d['price'] as double));

  double get _discountPct =>
      (double.tryParse(_discountCtrl.text.trim()) ?? 0).clamp(0, 100);

  double get _diamondDiscount => _diamondSubtotal * (_discountPct / 100);

  double get _diamondTotal => _diamondSubtotal - _diamondDiscount;

  List<Map<String, dynamic>> get _stoneBreakdown {
    if (_selectedItem == null) return [];
    final stones = _selectedItem!['stones'] as List<dynamic>? ?? [];
    final sRates = _rates['stone'] as Map<String, dynamic>? ?? {};
    return stones.map((s) {
      final type = s['type'] ?? '';
      final carats = (s['carats'] as num?)?.toDouble() ?? 0;
      final rate = (sRates[type] as num?)?.toDouble() ??
          (sRates['Other'] as num?)?.toDouble() ??
          0;
      final price = carats * rate;
      return {
        'label': type,
        'carats': carats,
        'rate': rate,
        'price': price,
        'pieces': s['pieces'] ?? 0,
      };
    }).toList();
  }

  double get _stoneTotal =>
      _stoneBreakdown.fold(0.0, (s, d) => s + (d['price'] as double));

  double get _makingCharge => double.tryParse(_makingCtrl.text.trim()) ?? 0;

  double get _grandTotal =>
      _goldTotal + _diamondTotal + _stoneTotal + _makingCharge;

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == null) return [];
    return _items
        .where((item) => item['itemCategory'] == _selectedCategory)
        .toList();
  }

  List<String> get _categories {
    return _items
        .map((item) => item['itemCategory'] as String?)
        .where((cat) => cat != null && cat.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Price calculator',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Category selector ──────────────────────
                _sectionLabel('Select category'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      hint: const Text('Choose a category...',
                          style:
                              TextStyle(color: Colors.black38, fontSize: 14)),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        _selectedItem = null; // Reset selected item
                      }),
                    ),
                  ),
                ),

                // ── Item selector ─────────────────────────
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 12),
                  _sectionLabel('Select item'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12, width: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedItem,
                        isExpanded: true,
                        hint: const Text('Choose an item...',
                            style:
                                TextStyle(color: Colors.black38, fontSize: 14)),
                        items: _filteredItems.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(
                              '${item['serialNumber'] ?? ''} · ${item['name'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedItem = v),
                      ),
                    ),
                  ),
                ],

                // ── Selected item summary ─────────────────
                if (_selectedItem != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Text('💎', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedItem!['name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                                '${_selectedItem!['itemCategory'] ?? ''} · ${_selectedItem!['goldKarat'] ?? ''} · ${_selectedItem!['goldWeightGrams'] ?? 0}g',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Making charge + diamond discount ──────
                const SizedBox(height: 20),
                _sectionLabel('Charges & discount'),
                Row(children: [
                  Expanded(
                    child: _inputField(_makingCtrl, 'Making charge', 'NPR'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(_discountCtrl, 'Diamond discount', '%',
                        hint: '0–100'),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'Discount applies to diamonds only. Gold includes 2% luxury tax.',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),

                // ── Breakdown ─────────────────────────────
                if (_selectedItem != null) ...[
                  const SizedBox(height: 24),
                  _sectionLabel('Price breakdown'),

                  // Gold
                  _breakdownCard(
                    title: 'Gold',
                    color: const Color(0xFFFAEEDA),
                    textColor: const Color(0xFF854F0B),
                    total: _goldTotal,
                    rows: [
                      _Row(
                        label:
                            '${_selectedItem!['goldKarat']} × ${_selectedItem!['goldWeightGrams']}g',
                        detail:
                            'Rate: NPR ${(_rates['gold'] as Map?)?[_selectedItem!['goldKarat']] ?? 0}/g',
                        amount: _goldBase,
                      ),
                      _Row(
                        label: 'Luxury tax (2%)',
                        detail: 'NPR ${_fmt(_goldBase)} × 2%',
                        amount: _goldLuxuryTax,
                        isAccent: true,
                        accentColor: const Color(0xFF993C1D),
                      ),
                    ],
                  ),

                  // Diamonds
                  if (_diamondBreakdown.isNotEmpty)
                    _breakdownCard(
                      title: 'Diamonds',
                      color: const Color(0xFFE6F1FB),
                      textColor: const Color(0xFF185FA5),
                      total: _diamondTotal,
                      rows: [
                        ..._diamondBreakdown.map((d) => _Row(
                              label: '${d['label']} · ${d['pieces']} pcs',
                              detail: '${d['carats']}ct × NPR ${d['rate']}/ct',
                              amount: d['price'] as double,
                            )),
                        if (_discountPct > 0)
                          _Row(
                            label:
                                'Discount (${_discountPct.toStringAsFixed(1)}%)',
                            detail:
                                'NPR ${_fmt(_diamondSubtotal)} × ${_discountPct.toStringAsFixed(1)}%',
                            amount: -_diamondDiscount,
                            isAccent: true,
                            accentColor: const Color(0xFF27500A),
                          ),
                      ],
                    ),

                  // Stones
                  if (_stoneBreakdown.isNotEmpty)
                    _breakdownCard(
                      title: 'Precious stones',
                      color: const Color(0xFFFBEAF0),
                      textColor: const Color(0xFF993556),
                      total: _stoneTotal,
                      rows: _stoneBreakdown
                          .map((s) => _Row(
                                label: '${s['label']} · ${s['pieces']} pcs',
                                detail:
                                    '${s['carats']}ct × NPR ${s['rate']}/ct',
                                amount: s['price'] as double,
                              ))
                          .toList(),
                    ),

                  // Making charge
                  if (_makingCharge > 0)
                    _breakdownCard(
                      title: 'Making charge',
                      color: const Color(0xFFEEEDFE),
                      textColor: const Color(0xFF534AB7),
                      total: _makingCharge,
                      rows: [
                        _Row(
                            label: 'Labour & making',
                            detail: '',
                            amount: _makingCharge),
                      ],
                    ),

                  // Grand total
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      // Summary rows
                      _totalRow('Gold (incl. 2% tax)', _goldTotal),
                      if (_diamondBreakdown.isNotEmpty)
                        _totalRow(
                            'Diamonds${_discountPct > 0 ? ' (after ${_discountPct.toStringAsFixed(0)}% disc.)' : ''}',
                            _diamondTotal),
                      if (_stoneBreakdown.isNotEmpty)
                        _totalRow('Precious stones', _stoneTotal),
                      if (_makingCharge > 0)
                        _totalRow('Making charge', _makingCharge),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total price',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70)),
                              Text('All charges included',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white30)),
                            ],
                          ),
                        ),
                        Text(
                          'NPR ${_fmt(_grandTotal)}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ]),
                    ]),
                  ),
                ],

                // ── Empty state ───────────────────────────
                if (_selectedItem == null) ...[
                  const SizedBox(height: 60),
                  const Center(
                    child: Column(children: [
                      Text('🧮', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Select a category and item to calculate',
                          style:
                              TextStyle(fontSize: 15, color: Colors.black45)),
                      SizedBox(height: 6),
                      Text(
                        'Make sure you have set rates\nin Price Settings first',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black38),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ── Card widgets ──────────────────────────────────────────

  Widget _breakdownCard({
    required String title,
    required Color color,
    required Color textColor,
    required double total,
    required List<_Row> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const Spacer(),
            Text('NPR ${_fmt(total)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ]),
        ),
        // Rows
        ...rows.map((row) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: row.isAccent
                  ? BoxDecoration(
                      color: row.accentColor!.withOpacity(0.05),
                      borderRadius: rows.last == row
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(12))
                          : BorderRadius.zero,
                    )
                  : null,
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: row.isAccent
                                  ? row.accentColor
                                  : Colors.black87)),
                      if (row.detail.isNotEmpty)
                        Text(row.detail,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black38)),
                    ],
                  ),
                ),
                Text(
                  '${row.amount < 0 ? '−' : ''}NPR ${_fmt(row.amount.abs())}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: row.isAccent ? row.accentColor : Colors.black87),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _totalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.white54))),
        Text('NPR ${_fmt(amount)}',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
                letterSpacing: 0.6)),
      );

  Widget _inputField(TextEditingController ctrl, String label, String suffix,
      {String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12, width: 0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  String _fmt(double n) {
    final s = n.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }

  @override
  void dispose() {
    _makingCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }
}

class _Row {
  final String label;
  final String detail;
  final double amount;
  final bool isAccent;
  final Color? accentColor;
  const _Row({
    required this.label,
    required this.detail,
    required this.amount,
    this.isAccent = false,
    this.accentColor,
  });
}
