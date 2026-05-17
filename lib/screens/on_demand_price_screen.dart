import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnDemandPriceScreen extends StatefulWidget {
  const OnDemandPriceScreen({super.key});

  @override
  State<OnDemandPriceScreen> createState() => _OnDemandPriceScreenState();
}

class _OnDemandPriceScreenState extends State<OnDemandPriceScreen> {
  final _goldWeightCtrl = TextEditingController(text: '0');
  final _goldRateCtrl = TextEditingController(text: '0');
  String _goldKarat = '18k';

  final List<Map<String, TextEditingController>> _diamonds = [];
  final List<Map<String, TextEditingController>> _stones = [];

  List<String> _goldKarats = ['14k', '18k', '22k', '24k'];
  List<String> _diamondCategories = [];
  List<String> _stoneTypes = [];

  final _makingCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');

  Map<String, dynamic> _rates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final ratesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('prices')
          .get();
      _rates = ratesSnap.exists ? ratesSnap.data()! : {};

      final gold = _rates['gold'] as Map<String, dynamic>? ?? {};
      if (gold.isNotEmpty) {
        // Use keys from saved rates but ensure 14k is present and 21k removed
        final keys = gold.keys.cast<String>().toSet();
        keys.remove('21k');
        keys.add('14k');
        _goldKarats = keys.toList()..sort();
        if (!_goldKarats.contains(_goldKarat)) _goldKarat = _goldKarats.first;
        _goldRateCtrl.text = (gold[_goldKarat] as num?)?.toString() ?? '0';
      }

      final d = _rates['diamond'] as Map<String, dynamic>? ?? {};
      _diamondCategories = d.keys.cast<String>().toList();

      final s = _rates['stone'] as Map<String, dynamic>? ?? {};
      _stoneTypes = s.keys.cast<String>().toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _addDiamond() {
    setState(() {
      final cat = _diamondCategories.isNotEmpty ? _diamondCategories.first : '';
      final rate = (_rates['diamond'] is Map &&
              (_rates['diamond'] as Map).containsKey(cat))
          ? (_rates['diamond'][cat].toString())
          : '0';
      _diamonds.add({
        'category': TextEditingController(text: cat),
        'carats': TextEditingController(text: '0'),
        'rate': TextEditingController(text: rate),
        'pieces': TextEditingController(text: '1'),
      });
    });
  }

  void _addStone() {
    setState(() {
      final type = _stoneTypes.isNotEmpty ? _stoneTypes.first : 'Other';
      final rate =
          (_rates['stone'] is Map && (_rates['stone'] as Map).containsKey(type))
              ? (_rates['stone'][type].toString())
              : '0';
      _stones.add({
        'type': TextEditingController(text: type),
        'carats': TextEditingController(text: '0'),
        'rate': TextEditingController(text: rate),
        'pieces': TextEditingController(text: '1'),
      });
    });
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0.0;

  // Gold wastage: 25% added to gold weight before pricing
  static const double _wastagePct = 0.25;
  static const double _luxuryTaxRate = 0.02;

  double get _originalGoldPrice =>
      _parse(_goldWeightCtrl) * (double.tryParse(_goldRateCtrl.text) ?? 0);

  double get _wastageWeight => _parse(_goldWeightCtrl) * _wastagePct;
  double get _wastagePrice =>
      _wastageWeight * (double.tryParse(_goldRateCtrl.text) ?? 0);

  double get _goldBaseWithWastage => _originalGoldPrice + _wastagePrice;
  double get _goldLuxury => _goldBaseWithWastage * _luxuryTaxRate;
  double get _goldTotal => _goldBaseWithWastage + _goldLuxury;

  double get _diamondTotal => _diamonds.fold(0.0, (s, d) {
        final carats = _parse(d['carats']!);
        final rate = _parse(d['rate']!);
        return s + carats * rate;
      });

  double get _stoneTotal => _stones.fold(0.0, (s, st) {
        final carats = _parse(st['carats']!);
        final rate = _parse(st['rate']!);
        return s + carats * rate;
      });

  double get _discountPct =>
      (double.tryParse(_discountCtrl.text.trim()) ?? 0).clamp(0, 100);
  double get _discountAmount => _diamondTotal * (_discountPct / 100);

  double get _makingCharge => _parse(_makingCtrl);

  double get _grandTotal =>
      _goldTotal +
      (_diamondTotal - _discountAmount) +
      _stoneTotal +
      _makingCharge;

  String _fmt(double n) {
    final s = n.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }

  void _showCalculationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Calculation summary',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _summaryRow('Gold (base)', _originalGoldPrice),
            _summaryRow('Gold (wastage 25%)', _wastagePrice),
            _summaryRow('Gold (luxury tax 2%)', _goldLuxury),
            _summaryRow('Gold total', _goldTotal),
            _summaryRow('Diamonds (subtotal)', _diamondTotal),
            if (_discountPct > 0)
              _summaryRow('Diamond discount', -_discountAmount),
            _summaryRow('Stones', _stoneTotal),
            if (_makingCharge > 0) _summaryRow('Making', _makingCharge),
            const Divider(),
            _summaryRow('Grand total', _grandTotal, isBold: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ),
          ]),
        );
      },
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500))),
        Text('NPR ${_fmt(amount)}',
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }

  @override
  void dispose() {
    _goldWeightCtrl.dispose();
    _goldRateCtrl.dispose();
    _makingCtrl.dispose();
    _discountCtrl.dispose();
    for (var d in _diamonds) {
      d.values.forEach((c) => c.dispose());
    }
    for (var s in _stones) {
      s.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('On-demand price')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              _section('Gold'),
              Row(children: [
                Expanded(
                    child: _numberField(_goldWeightCtrl, 'Gold weight (g)')),
                const SizedBox(width: 10),
                Expanded(
                    child: _numberField(_goldRateCtrl, 'Rate per g (NPR)')),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _goldKarat,
                decoration: const InputDecoration(labelText: 'Gold purity'),
                items: _goldKarats
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _goldKarat = v;
                    final gold = _rates['gold'] as Map<String, dynamic>? ?? {};
                    final val = (gold[_goldKarat] as num?)?.toString();
                    if (val != null) _goldRateCtrl.text = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              _section('Diamonds'),
              ..._diamonds.map((d) {
                return _smallCard(Column(children: [
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: d['category']!.text.isNotEmpty
                            ? d['category']!.text
                            : null,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: _diamondCategories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            d['category']!.text = v;
                            final r = (_rates['diamond']
                                as Map<String, dynamic>?)?[v];
                            if (r != null) d['rate']!.text = r.toString();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _numberField(d['carats']!, 'Carats')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _numberField(d['rate']!, 'Rate / ct')),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 70, child: _numberField(d['pieces']!, 'Pcs')),
                  ]),
                ]));
              }).toList(),
              TextButton.icon(
                  onPressed: _addDiamond,
                  icon: const Icon(Icons.add),
                  label: const Text('Add diamond')),
              const SizedBox(height: 8),
              _section('Stones'),
              ..._stones.map((s) {
                return _smallCard(Column(children: [
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value:
                            s['type']!.text.isNotEmpty ? s['type']!.text : null,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _stoneTypes
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            s['type']!.text = v;
                            final r =
                                (_rates['stone'] as Map<String, dynamic>?)?[v];
                            if (r != null) s['rate']!.text = r.toString();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _numberField(s['carats']!, 'Carats')),
                    const SizedBox(width: 8),
                    Expanded(child: _numberField(s['rate']!, 'Rate / ct')),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 70, child: _numberField(s['pieces']!, 'Pcs')),
                  ]),
                ]));
              }).toList(),
              TextButton.icon(
                  onPressed: _addStone,
                  icon: const Icon(Icons.add),
                  label: const Text('Add stone')),
              const SizedBox(height: 12),
              _section('Charges & Discount'),
              Row(children: [
                Expanded(child: _numberField(_makingCtrl, 'Making (NPR)')),
                const SizedBox(width: 12),
                Expanded(
                    child: _numberField(_discountCtrl, 'Diamond discount %')),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Expanded(
                      child: Text('Total', style: TextStyle(fontSize: 16))),
                  Text('NPR ${_fmt(_grandTotal)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700))
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _showCalculationSheet(context),
                    child: const Text('Calculate',
                        style: TextStyle(fontWeight: FontWeight.w600))),
              ),
              const SizedBox(height: 30),
            ]),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w600)),
      );

  Widget _numberField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12))),
    );
  }

  Widget _smallCard(Widget child) => Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8)),
      child: child);

  Widget _breakdownTile(String label, double amount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12)),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500))),
          Text('NPR ${_fmt(amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700))
        ]),
      );
}
