import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PartyTransactionsScreen extends StatefulWidget {
  final String partyId;
  final String partyName;
  final bool isClient;

  const PartyTransactionsScreen({
    super.key,
    required this.partyId,
    required this.partyName,
    required this.isClient,
  });

  @override
  State<PartyTransactionsScreen> createState() =>
      _PartyTransactionsScreenState();
}

class _PartyTransactionsScreenState extends State<PartyTransactionsScreen> {
  final List<String> _types = [
    'Payment',
    'Purchase',
    'Credit',
    'Debit',
    'Refund',
  ];

  String _selectedType = 'Payment';

  CollectionReference get _transactionCollection {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final parent = widget.isClient ? 'clients' : 'suppliers';
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(parent)
        .doc(widget.partyId)
        .collection('transactions');
  }

  void _showAddTransactionSheet() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String type = _selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
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
                    Text('Add transaction',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.black12, width: 0.5)),
                  ),
                  items: _types
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g. 12500',
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.black12, width: 0.5)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    hintText: 'Optional transaction details',
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.black12, width: 0.5)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? 0;
                      await _transactionCollection.add({
                        'type': type,
                        'amount': amount,
                        'note': noteCtrl.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save transaction'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('${widget.partyName} Transactions',
            style: const TextStyle(color: Colors.white, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddTransactionSheet,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _transactionCollection
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long, size: 56, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('No transactions yet',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Text('Tap + to add a transaction.',
                      style: TextStyle(color: Colors.black45)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? 'Transaction';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              final note = data['note'] ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              final time =
                  createdAt != null ? createdAt.toDate() : DateTime.now();
              final dateText =
                  '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(type,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(dateText,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Amount: ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(note,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black45)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
