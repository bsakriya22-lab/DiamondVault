import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<Map<String, dynamic>> _fetchCounts() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final inventory = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .get();
    final lowStock =
        inventory.docs.where((d) => (d['stockCount'] ?? 0) <= 1).length;
    final totalReceivable = await _fetchPartyBalance(userId, 'clients');
    final totalPayable = await _fetchPartyBalance(userId, 'suppliers');

    return {
      'inventory': inventory.docs.length,
      'totalReceivable': totalReceivable,
      'totalPayable': totalPayable,
      'lowStock': lowStock,
    };
  }

  Future<double> _fetchPartyBalance(
      String userId, String partyCollection) async {
    final partyDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(partyCollection)
        .get();
    double total = 0;

    for (final party in partyDocs.docs) {
      final transactions =
          await party.reference.collection('transactions').get();
      for (final tx in transactions.docs) {
        final data = tx.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = (data['type'] ?? '').toString().toLowerCase();
        total += amount * _transactionSign(type);
      }
    }

    return total;
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Container(
              width: double.infinity,
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💎 DiamondVault',
                      style: TextStyle(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                      style: TextStyle(
                          color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
                          fontSize: 12)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _fetchCounts(),
                  builder: (context, snapshot) {
                    final counts = snapshot.data ?? {};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        const Text('OVERVIEW',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black45,
                                letterSpacing: 0.6)),
                        const SizedBox(height: 10),

                        // Stat cards grid
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.6,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _statCard(
                                'Total pieces',
                                '${counts['inventory'] ?? '-'}',
                                Colors.black87,
                                Colors.black12),
                            _statCard(
                                'Total receivables',
                                '₹${(counts['totalReceivable'] as double? ?? 0).toStringAsFixed(2)}',
                                const Color(0xFF185FA5),
                                const Color(0xFFE6F1FB)),
                            _statCard(
                                'Low stock',
                                '${counts['lowStock'] ?? '-'}',
                                const Color(0xFF854F0B),
                                const Color(0xFFFAEEDA)),
                            _statCard(
                                'Total payable',
                                '₹${(counts['totalPayable'] as double? ?? 0).toStringAsFixed(2)}',
                                const Color(0xFFA32D2D),
                                const Color(0xFFFFEBEB)),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Text(
                            'Use the bottom navigation to access Inventory, Price Calculator, or Menu',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 24),
                        const Text('RECENT INVENTORY',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black45,
                                letterSpacing: 0.6)),
                        const SizedBox(height: 10),

                        // Recent items from Firestore
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('inventory')
                              .orderBy('createdAt', descending: true)
                              .limit(3)
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final docs = snap.data!.docs;
                            if (docs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.black12, width: 0.5),
                                ),
                                child: const Center(
                                  child: Text(
                                      'No inventory yet. Add your first piece!',
                                      style: TextStyle(
                                          color: Colors.black45, fontSize: 13)),
                                ),
                              );
                            }
                            return Column(
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final stock = data['stockCount'] ?? 0;
                                return _recentItem(
                                  name: data['name'] ?? 'Unnamed',
                                  meta:
                                      '${data['goldKarat'] ?? ''} · ${data['goldWeightGrams'] ?? 0}g gold',
                                  stock: stock,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _recentItem(
      {required String name, required String meta, required int stock}) {
    final isLow = stock <= 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text(meta,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLow ? const Color(0xFFFAEEDA) : const Color(0xFFEAF3DE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLow ? 'Low' : 'In stock',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color:
                    isLow ? const Color(0xFF854F0B) : const Color(0xFF27500A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
