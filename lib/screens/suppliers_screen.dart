import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'party_transactions_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _search = '';

  static const List<String> _materialTypes = [
    'Gold',
    'Diamonds',
    'Silver',
    'Precious Stones',
    'Pearls',
    'Platinum',
    'Mixed',
    'Other',
  ];

  static const Map<String, Color> _materialColors = {
    'Gold': Color(0xFF854F0B),
    'Diamonds': Color(0xFF185FA5),
    'Silver': Color(0xFF5F5E5A),
    'Precious Stones': Color(0xFF993556),
    'Pearls': Color(0xFF0F6E56),
    'Platinum': Color(0xFF534AB7),
    'Mixed': Color(0xFF993C1D),
    'Other': Color(0xFF444441),
  };

  static const Map<String, Color> _materialBgColors = {
    'Gold': Color(0xFFFAEEDA),
    'Diamonds': Color(0xFFE6F1FB),
    'Silver': Color(0xFFF1EFE8),
    'Precious Stones': Color(0xFFFBEAF0),
    'Pearls': Color(0xFFE1F5EE),
    'Platinum': Color(0xFFEEEDFE),
    'Mixed': Color(0xFFFAECE7),
    'Other': Color(0xFFF1EFE8),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Suppliers',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.add_business, color: Colors.white),
        onPressed: () => _showSupplierForm(context, null, null),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or material...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('suppliers')
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
                  return _search.isEmpty ||
                      (d['name'] ?? '').toLowerCase().contains(_search) ||
                      (d['materialType'] ?? '')
                          .toLowerCase()
                          .contains(_search) ||
                      (d['location'] ?? '').toLowerCase().contains(_search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No suppliers match your search.',
                          style: TextStyle(color: Colors.black45)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _supplierCard(context, data, docs[i].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplierCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final name = data['name'] ?? 'Unknown';
    final material = data['materialType'] ?? '';
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    final color = _materialColors[material] ?? const Color(0xFF444441);
    final bgColor = _materialBgColors[material] ?? const Color(0xFFF1EFE8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: color)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('suppliers')
                      .doc(docId)
                      .collection('transactions')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(height: 6);
                    }
                    final balance = _calculatePartyBalance(snapshot.data!.docs);
                    return Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Payable: ${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFA32D2D))),
                    );
                  },
                ),
                const SizedBox(height: 4),
                if (material.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(material,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color)),
                  ),
                if ((data['phone'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(data['phone'],
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black45)),
                ],
                if ((data['location'] ?? '').isNotEmpty)
                  Text(data['location'],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black38)),
                if ((data['notes'] ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFE8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data['notes'],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF5F5E5A))),
                  ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long,
                    size: 18, color: Colors.black38),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartyTransactionsScreen(
                      partyId: docId,
                      partyName: name,
                      isClient: false,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Colors.black38),
                onPressed: () => _showSupplierForm(context, docId, data),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, docId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculatePartyBalance(List<QueryDocumentSnapshot> docs) {
    double balance = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final type = (data['type'] ?? '').toString().toLowerCase();
      final sign = _transactionSign(type);
      balance += amount * sign;
    }
    return balance;
  }

  double _transactionSign(String type) {
    switch (type) {
      case 'payment':
      case 'credit':
      case 'refund':
        return -1;
      case 'purchase':
      case 'debit':
      default:
        return 1;
    }
  }

  void _showSupplierForm(
      BuildContext context, String? docId, Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final locationCtrl =
        TextEditingController(text: existing?['location'] ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes'] ?? '');
    String selectedMaterial = existing?['materialType'] ?? 'Gold';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(docId == null ? 'Add supplier' : 'Edit supplier',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetField(nameCtrl, 'Supplier name', required: true),
                const SizedBox(height: 12),

                // Material type dropdown
                DropdownButtonFormField<String>(
                  value: selectedMaterial,
                  decoration: InputDecoration(
                    labelText: 'Material type',
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Colors.black12, width: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Colors.black12, width: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: _materialTypes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedMaterial = v!),
                ),
                const SizedBox(height: 12),
                _sheetField(phoneCtrl, 'Phone number',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _sheetField(locationCtrl, 'Location',
                    hint: 'e.g. Kathmandu, Delhi'),
                const SizedBox(height: 12),
                _sheetField(notesCtrl, 'Notes', maxLines: 2),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            final userId =
                                FirebaseAuth.instance.currentUser!.uid;
                            final col = FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('suppliers');
                            final data = {
                              'name': nameCtrl.text.trim(),
                              'materialType': selectedMaterial,
                              'phone': phoneCtrl.text.trim(),
                              'location': locationCtrl.text.trim(),
                              'notes': notesCtrl.text.trim(),
                            };
                            if (docId == null) {
                              data['createdAt'] =
                                  DateTime.now().toIso8601String();
                              await col.add(data);
                            } else {
                              await col.doc(docId).update(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(docId == null
                            ? 'Save supplier'
                            : 'Update supplier'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label,
      {TextInputType? keyboardType,
      bool required = false,
      int maxLines = 1,
      String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12, width: 0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete supplier?'),
        content: const Text('This will permanently remove this supplier.'),
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
                  .collection('suppliers')
                  .doc(docId)
                  .delete();
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏪', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('No suppliers yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Add your first supplier',
              style: TextStyle(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_business),
            label: const Text('Add supplier'),
            onPressed: () => _showSupplierForm(context, null, null),
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
