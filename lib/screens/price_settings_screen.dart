import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PriceSettingsScreen extends StatefulWidget {
  const PriceSettingsScreen({super.key});

  @override
  State<PriceSettingsScreen> createState() => _PriceSettingsScreenState();
}

class _PriceSettingsScreenState extends State<PriceSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  // Gold rates per gram
  final Map<String, TextEditingController> _goldRates = {
    '14k': TextEditingController(),
    '18k': TextEditingController(),
    '22k': TextEditingController(),
    '24k': TextEditingController(),
  };

  // Diamond rates per cent
  final Map<String, TextEditingController> _diamondRates = {
    '0–0.06 carat': TextEditingController(),
    '0.07–0.13 carat': TextEditingController(),
    '0.14–0.18 carat': TextEditingController(),
    '0.19–0.22 carat': TextEditingController(),
    '0.23–0.27 carat': TextEditingController(),
    '0.28–0.36 carat': TextEditingController(),
    '0.37–0.43 carat': TextEditingController(),
    '0.44–0.65 carat': TextEditingController(),
    '0.66–0.80 carat': TextEditingController(),
    '0.81–0.99 carat': TextEditingController(),
    '1 carat & above': TextEditingController(),
  };

  // Stone rates per carat
  final Map<String, TextEditingController> _stoneRates = {
    'Ruby': TextEditingController(),
    'Emerald': TextEditingController(),
    'Sapphire': TextEditingController(),
    'Pearl': TextEditingController(),
    'Topaz': TextEditingController(),
    'Opal': TextEditingController(),
    'Other': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('prices')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final gold = data['gold'] as Map<String, dynamic>? ?? {};
        final diamond = data['diamond'] as Map<String, dynamic>? ?? {};
        final stone = data['stone'] as Map<String, dynamic>? ?? {};
        gold.forEach((k, v) {
          if (_goldRates.containsKey(k)) _goldRates[k]!.text = '$v';
        });
        diamond.forEach((k, v) {
          // Handle migration from old cent-based to new carat-based categories
          final migratedKey = _migrateDiamondCategoryKey(k);
          if (_diamondRates.containsKey(migratedKey)) {
            _diamondRates[migratedKey]!.text = '$v';
          }
        });
        stone.forEach((k, v) {
          if (_stoneRates.containsKey(k)) _stoneRates[k]!.text = '$v';
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveRates() async {
    setState(() => _saving = true);
    try {
      final gold = <String, double>{};
      _goldRates.forEach((k, ctrl) {
        gold[k] = double.tryParse(ctrl.text.trim()) ?? 0;
      });

      final diamond = <String, double>{};
      _diamondRates.forEach((k, ctrl) {
        diamond[k] = double.tryParse(ctrl.text.trim()) ?? 0;
      });

      final stone = <String, double>{};
      _stoneRates.forEach((k, ctrl) {
        stone[k] = double.tryParse(ctrl.text.trim()) ?? 0;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('settings')
          .doc('prices')
          .set({
        'gold': gold,
        'diamond': diamond,
        'stone': stone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rates saved successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text('Price settings',
            style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontSize: 17)),
        iconTheme:
            IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveRates,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Gold rates ──────────────────────────────
                _sectionHeader(
                  'Gold rates',
                  'Price per gram (NPR)',
                  const Color(0xFFFAEEDA),
                  const Color(0xFF854F0B),
                  Icons.circle,
                ),
                const SizedBox(height: 10),
                ..._goldRates.entries.map((e) => _rateRow(
                    e.key,
                    e.value,
                    'NPR / gram',
                    const Color(0xFFFAEEDA),
                    const Color(0xFF854F0B))),

                // ── Diamond rates ───────────────────────────
                const SizedBox(height: 24),
                _sectionHeader(
                  'Diamond rates',
                  'Price per carat (NPR)',
                  const Color(0xFFE6F1FB),
                  const Color(0xFF185FA5),
                  Icons.diamond_outlined,
                ),
                const SizedBox(height: 10),
                ..._diamondRates.entries.map((e) => _rateRow(
                    e.key,
                    e.value,
                    'NPR / carat',
                    const Color(0xFFE6F1FB),
                    const Color(0xFF185FA5))),

                // ── Stone rates ─────────────────────────────
                const SizedBox(height: 24),
                _sectionHeader(
                  'Precious stone rates',
                  'Price per carat (NPR)',
                  const Color(0xFFFBEAF0),
                  const Color(0xFF993556),
                  Icons.auto_awesome,
                ),
                const SizedBox(height: 10),
                ..._stoneRates.entries.map((e) => _rateRow(
                    e.key,
                    e.value,
                    'NPR / carat',
                    const Color(0xFFFBEAF0),
                    const Color(0xFF993556))),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveRates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save all rates',
                            style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _sectionHeader(
      String title, String subtitle, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: fg.withOpacity(0.7))),
        ]),
      ]),
    );
  }

  Widget _rateRow(String label, TextEditingController ctrl, String unit,
      Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        SizedBox(
          width: 160,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: '0.00',
              suffixText: unit,
              suffixStyle: TextStyle(fontSize: 11, color: fg.withOpacity(0.7)),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : bg.withOpacity(0.5),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    for (final c in _goldRates.values) c.dispose();
    for (final c in _diamondRates.values) c.dispose();
    for (final c in _stoneRates.values) c.dispose();
    super.dispose();
  }

  // Migrate old cent-based category keys to new carat-based keys
  String _migrateDiamondCategoryKey(String oldKey) {
    const migrationMap = {
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
    return migrationMap[oldKey] ?? oldKey;
  }
}
