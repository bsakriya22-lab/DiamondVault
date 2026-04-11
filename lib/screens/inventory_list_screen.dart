import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _search = '';
  String _selectedCategory = 'All';

  static const List<String> _filterCategories = [
    'All',
    'Ring',
    'Necklace',
    'Bracelet',
    'Earring',
    'Pendant',
    'Bangle',
    'Brooch',
    'Chain',
    'Custom',
  ];

  static const Map<String, String> _categoryIcons = {
    'All': '🔷',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Inventory',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadCsv,
            tooltip: 'Upload CSV',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddItemScreen())),
      ),
      body: Column(
        children: [
          // ── Search + category filters ─────────────────────────
          Container(
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search name, SN, category...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                // Category filter tabs
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    itemCount: _filterCategories.length,
                    itemBuilder: (context, i) {
                      final cat = _filterCategories[i];
                      final sel = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_categoryIcons[cat] ?? '🔷',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Text(cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? const Color(0xFF1A1A2E)
                                        : Colors.white70,
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('inventory')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState(context);
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final matchCat = _selectedCategory == 'All' ||
                      (d['itemCategory'] ?? '') == _selectedCategory;
                  final matchSearch = _search.isEmpty ||
                      (d['name'] ?? '').toLowerCase().contains(_search) ||
                      (d['serialNumber'] ?? '')
                          .toLowerCase()
                          .contains(_search) ||
                      (d['itemCategory'] ?? '').toLowerCase().contains(_search);
                  return matchCat && matchSearch;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          _search.isNotEmpty
                              ? 'No results for "$_search"'
                              : 'No items in $_selectedCategory',
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _itemCard(context, data, docs[i].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCsv() async {
    try {
      String csvString;
      if (kIsWeb) {
        // Web-specific file picking
        final html.FileUploadInputElement uploadInput =
            html.FileUploadInputElement();
        uploadInput.accept = '.csv';
        uploadInput.click();

        await uploadInput.onChange.first;
        if (uploadInput.files!.isEmpty) return;

        final file = uploadInput.files![0];
        final reader = html.FileReader();
        reader.readAsText(file);
        await reader.onLoad.first;
        csvString = reader.result as String;
      } else {
        // Mobile/desktop
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
        );

        if (result == null || result.files.isEmpty) return;

        final file = result.files.first;
        if (!file.name!.toLowerCase().endsWith('.csv')) {
          _showSnackBar('Please select a CSV file');
          return;
        }
        csvString = String.fromCharCodes(file.bytes!);
      }
      final csvTable = const CsvToListConverter().convert(csvString);

      if (csvTable.isEmpty) {
        _showSnackBar('CSV file is empty');
        return;
      }

      final headers = csvTable[0].map((e) => e.toString().trim()).toList();
      final requiredHeaders = ['serialNumber', 'diamondCarats', 'diamondPieces'];

      for (final req in requiredHeaders) {
        if (!headers.contains(req)) {
          _showSnackBar('CSV must contain columns: serialNumber, diamondCarats, diamondPieces');
          return;
        }
      }

      final userId = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();
      int updated = 0;

      // Group by serialNumber
      final updates = <String, List<Map<String, dynamic>>>{};

      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.length != headers.length) continue;

        final serialNumber = row[headers.indexOf('serialNumber')].toString().trim();
        final carats = double.tryParse(row[headers.indexOf('diamondCarats')].toString()) ?? 0;
        final pieces = int.tryParse(row[headers.indexOf('diamondPieces')].toString()) ?? 0;

        if (serialNumber.isEmpty || carats <= 0 || pieces <= 0) continue;

        final category = _getDiamondCategory(carats);
        final diamond = {
          'category': category,
          'totalCarats': carats,
          'pieces': pieces,
        };

        updates.putIfAbsent(serialNumber, () => []).add(diamond);
      }

      // Update each item
      for (final entry in updates.entries) {
        final serialNumber = entry.key;
        final diamonds = entry.value;

        // Find the doc by serialNumber
        final query = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('inventory')
            .where('serialNumber', isEqualTo: serialNumber)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final docRef = query.docs.first.reference;
          batch.update(docRef, {'diamonds': diamonds});
          updated++;
        }
      }

      await batch.commit();
      _showSnackBar('Updated $updated items with diamond data');
    } catch (e) {
      _showSnackBar('Error uploading CSV: $e');
    }
  }

  String _getDiamondCategory(double carats) {
    if (carats <= 0.06) return '0–0.06 carat';
    if (carats <= 0.13) return '0.07–0.13 carat';
    if (carats <= 0.18) return '0.14–0.18 carat';
    if (carats <= 0.22) return '0.19–0.22 carat';
    if (carats <= 0.27) return '0.23–0.27 carat';
    if (carats <= 0.36) return '0.28–0.36 carat';
    if (carats <= 0.43) return '0.37–0.43 carat';
    if (carats <= 0.65) return '0.44–0.65 carat';
    if (carats <= 0.80) return '0.66–0.80 carat';
    if (carats <= 0.99) return '0.81–0.99 carat';
    return '1 carat & above';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _itemCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final stock = data['stockCount'] ?? 0;
    final isLow = stock <= 1 && stock > 0;
    final isOut = stock == 0;
    final photoUrl = data['photoUrl'] as String?;
    final sn = data['serialNumber'] ?? '';
    final cat = data['itemCategory'] ?? '';
    final catIcon = _categoryIcons[cat] ?? '💎';
    final name = data['name'] ?? 'Unnamed';
    final goldKarat = data['goldKarat'] ?? '18k';
    final goldWeight = data['goldWeightGrams'] ?? 0;

    // Calculate total diamond weight
    double totalDiamondWeight = 0;
    final diamonds = data['diamonds'] as List<dynamic>? ?? [];
    for (final diamond in diamonds) {
      if (diamond is Map<String, dynamic>) {
        final carats = diamond['totalCarats'] as num? ?? 0;
        totalDiamondWeight += carats.toDouble();
      }
    }
    final diamondWeightLabel = totalDiamondWeight > 0
        ? ' · ${totalDiamondWeight.toStringAsFixed(2)}ct'
        : '';
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ItemDetailScreen(itemId: docId, itemData: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        child: Row(
          children: [
            // ── Image on left ────────────────────────────────────
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(14)),
              ),
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14)),
                      child: Image.network(photoUrl,
                          fit: BoxFit.cover, width: double.infinity))
                  : Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5ECD7),
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(14)),
                      ),
                      child: Center(
                          child: Text(catIcon,
                              style: const TextStyle(fontSize: 48))),
                    ),
            ),

            // ── Details on right ─────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and category
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),

                    // Serial number
                    Text(sn,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),

                    // Category and karat
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1A1A2E).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('$cat',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A2E))),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAEEDA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                              '$goldKarat · ${goldWeight}g$diamondWeightLabel',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF854F0B))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Stock badge
                    _stockBadge(stock, isLow, isOut),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💎', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('No items yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Add your first jewellery piece',
              style: TextStyle(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add first piece'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddItemScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
