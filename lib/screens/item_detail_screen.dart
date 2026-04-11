import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const ItemDetailScreen(
      {super.key, required this.itemId, required this.itemData});

  @override
  Widget build(BuildContext context) {
    final stock = itemData['stockCount'] ?? 0;
    final isLow = stock <= 1 && stock > 0;
    final isOut = stock == 0;
    final photoUrl = itemData['photoUrl'] as String?;
    final sn = itemData['serialNumber'] ?? '';
    final cat = itemData['itemCategory'] ?? '';
    final catIcon = _categoryIcons[cat] ?? '💎';
    final name = itemData['name'] ?? 'Unnamed';
    final goldKarat = itemData['goldKarat'] ?? '18k';
    final goldWeight = itemData['goldWeightGrams'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Item Details', style: TextStyle(fontSize: 17)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
            label: const Text('Edit', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddItemScreen(
                        existingId: itemId, existingData: itemData))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Photo section ─────────────────────────────────────
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
            child: photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(photoUrl,
                        fit: BoxFit.cover, width: double.infinity))
                : Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5ECD7),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Center(
                        child: Text(catIcon,
                            style: const TextStyle(fontSize: 80))),
                  ),
          ),

          const SizedBox(height: 20),

          // ── Item header ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(sn,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5F5E5A),
                              letterSpacing: 0.4)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$catIcon $cat',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A2E))),
                    ),
                    const Spacer(),
                    _stockBadge(stock, isLow, isOut),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Gold section ──────────────────────────────────────
          _sectionCard(
            title: 'Gold',
            icon: '🌟',
            color: const Color(0xFFFAEEDA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Karat', goldKarat),
                const SizedBox(height: 10),
                _detailRow('Weight', '${goldWeight}g'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Diamonds section ──────────────────────────────────
          if ((itemData['diamonds'] as List<dynamic>?)?.isNotEmpty ??
              false) ...[
            _sectionCard(
              title: 'Diamonds',
              icon: '💎',
              color: const Color(0xFFE6F1FB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (itemData['diamonds'] as List<dynamic>)
                    .asMap()
                    .entries
                    .map((e) {
                  final d = e.value;
                  final idx = e.key;
                  final dcat = d['category'] ?? '';
                  final carats = d['totalCarats'] ?? 0;
                  final pieces = d['pieces'] ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (idx > 0) const SizedBox(height: 12),
                      Text('Group ${idx + 1}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _detailRow('Total Carats', '$carats'),
                      _detailRow('Pieces', '$pieces'),
                      _detailRow('Category', dcat),
                      _detailRow('Per Stone',
                          '${(carats / pieces).toStringAsFixed(2)} carat'),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Stones section ────────────────────────────────────
          if ((itemData['stones'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
            _sectionCard(
              title: 'Precious Stones',
              icon: '🔮',
              color: const Color(0xFFFBEAF0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (itemData['stones'] as List<dynamic>)
                    .asMap()
                    .entries
                    .map((e) {
                  final s = e.value;
                  final idx = e.key;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (idx > 0) const SizedBox(height: 12),
                      _detailRow('Type', s['type'] ?? 'Unknown'),
                      _detailRow('Carats', '${s['carats'] ?? 0}'),
                      _detailRow('Pieces', '${s['pieces'] ?? 0}'),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Delete button ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent, width: 1),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                label: const Text('Delete Item',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w500)),
                onPressed: () => _confirmDelete(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _stockBadge(int stock, bool isLow, bool isOut) {
    Color bg, fg;
    String label;
    if (isOut) {
      bg = const Color(0xFFFCEBEB);
      fg = const Color(0xFFA32D2D);
      label = 'Out of stock';
    } else if (isLow) {
      bg = const Color(0xFFFAEEDA);
      fg = const Color(0xFF854F0B);
      label = 'Low · $stock';
    } else {
      bg = const Color(0xFFEAF3DE);
      fg = const Color(0xFF27500A);
      label = 'In stock · $stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text(
            'This will permanently remove this item from your inventory.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser!.uid;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('inventory')
                  .doc(itemId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  static const Map<String, String> _categoryIcons = {
    'Ring': '💍',
    'Necklace': '📿',
    'Bracelet': '✨',
    'Earring': '💎',
    'Pendant': '🔮',
    'Bangle': '⭕',
    'Brooch': '🌸',
    'Chain': '🔗',
    'Custom': '🎨',
  };
}
