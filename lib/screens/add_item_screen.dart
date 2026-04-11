import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Diamond helpers ───────────────────────────────────────────────────────────

String getDiamondCategory(double weightPerStoneCents) {
  if (weightPerStoneCents < 7) return '0–6 cent';
  if (weightPerStoneCents < 14) return '7–13 cent';
  if (weightPerStoneCents < 19) return '14–18 cent';
  if (weightPerStoneCents < 23) return '19–22 cent';
  if (weightPerStoneCents < 28) return '23–27 cent';
  if (weightPerStoneCents < 37) return '28–36 cent';
  if (weightPerStoneCents < 44) return '37–43 cent';
  if (weightPerStoneCents < 66) return '44–65 cent';
  if (weightPerStoneCents < 81) return '66–80 cent';
  if (weightPerStoneCents < 100) return '81–99 cent';
  return '1 carat & above';
}

Color getCategoryColor(String category) {
  const m = {
    '0–6 cent': Color(0xFF185FA5),
    '7–13 cent': Color(0xFF0F6E56),
    '14–18 cent': Color(0xFF3B6D11),
    '19–22 cent': Color(0xFF854F0B),
    '23–27 cent': Color(0xFF854F0B),
    '28–36 cent': Color(0xFF993556),
    '37–43 cent': Color(0xFF534AB7),
    '44–65 cent': Color(0xFF993C1D),
    '66–80 cent': Color(0xFFA32D2D),
    '81–99 cent': Color(0xFF791F1F),
    '1 carat & above': Color(0xFF26215C),
  };
  return m[category] ?? const Color(0xFF444441);
}

Color getCategoryBg(String category) {
  const m = {
    '0–6 cent': Color(0xFFE6F1FB),
    '7–13 cent': Color(0xFFE1F5EE),
    '14–18 cent': Color(0xFFEAF3DE),
    '19–22 cent': Color(0xFFFAEEDA),
    '23–27 cent': Color(0xFFFAEEDA),
    '28–36 cent': Color(0xFFFBEAF0),
    '37–43 cent': Color(0xFFEEEDFE),
    '44–65 cent': Color(0xFFFAECE7),
    '66–80 cent': Color(0xFFFCEBEB),
    '81–99 cent': Color(0xFFF7C1C1),
    '1 carat & above': Color(0xFFCECBF6),
  };
  return m[category] ?? const Color(0xFFF1EFE8);
}

// ── Jewellery categories ──────────────────────────────────────────────────────

const List<Map<String, String>> kJewelleryCategories = [
  {'name': 'Ring', 'prefix': 'RNG', 'icon': '💍'},
  {'name': 'Necklace', 'prefix': 'NCK', 'icon': '📿'},
  {'name': 'Bracelet', 'prefix': 'BRC', 'icon': '✨'},
  {'name': 'Earring', 'prefix': 'ERG', 'icon': '💎'},
  {'name': 'Pendant', 'prefix': 'PND', 'icon': '🔮'},
  {'name': 'Bangle', 'prefix': 'BNG', 'icon': '⭕'},
  {'name': 'Brooch', 'prefix': 'BRH', 'icon': '🌸'},
  {'name': 'Chain', 'prefix': 'CHN', 'icon': '🔗'},
  {'name': 'Custom', 'prefix': 'CST', 'icon': '🎨'},
];

String _prefixForCategory(String categoryName) {
  return kJewelleryCategories.firstWhere((c) => c['name'] == categoryName,
      orElse: () => {'prefix': 'ITM'})['prefix']!;
}

// ── Data models ───────────────────────────────────────────────────────────────

class DiamondGroup {
  TextEditingController caratsCtrl = TextEditingController();
  TextEditingController piecesCtrl = TextEditingController();
  double? weightPerStoneCents;
  String? category;

  DiamondGroup();
  DiamondGroup.fromMap(Map<String, dynamic> m) {
    caratsCtrl.text = '${m['totalCarats'] ?? ''}';
    piecesCtrl.text = '${m['pieces'] ?? ''}';
    weightPerStoneCents = (m['weightPerStoneCents'] as num?)?.toDouble();
    category = m['category'];
  }

  Map<String, dynamic> toMap() => {
        'totalCarats': double.tryParse(caratsCtrl.text) ?? 0,
        'pieces': int.tryParse(piecesCtrl.text) ?? 0,
        'weightPerStoneCents': weightPerStoneCents ?? 0,
        'category': category ?? '',
      };

  void recalc() {
    final carats = double.tryParse(caratsCtrl.text.trim());
    final pieces = double.tryParse(piecesCtrl.text.trim());
    if (carats != null && pieces != null && pieces > 0) {
      weightPerStoneCents = (carats / pieces) * 100;
      category = getDiamondCategory(weightPerStoneCents!);
    } else {
      weightPerStoneCents = null;
      category = null;
    }
  }

  void dispose() {
    caratsCtrl.dispose();
    piecesCtrl.dispose();
  }
}

class StoneGroup {
  TextEditingController typeCtrl = TextEditingController();
  TextEditingController caratsCtrl = TextEditingController();
  TextEditingController piecesCtrl = TextEditingController();

  StoneGroup();
  StoneGroup.fromMap(Map<String, dynamic> m) {
    typeCtrl.text = m['type'] ?? '';
    caratsCtrl.text = '${m['carats'] ?? ''}';
    piecesCtrl.text = '${m['pieces'] ?? ''}';
  }

  Map<String, dynamic> toMap() => {
        'type': typeCtrl.text.trim(),
        'carats': double.tryParse(caratsCtrl.text) ?? 0,
        'pieces': int.tryParse(piecesCtrl.text) ?? 0,
      };

  void dispose() {
    typeCtrl.dispose();
    caratsCtrl.dispose();
    piecesCtrl.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AddItemScreen extends StatefulWidget {
  final String? existingId;
  final Map<String, dynamic>? existingData;
  const AddItemScreen({super.key, this.existingId, this.existingData});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _goldWtCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _snCtrl = TextEditingController();

  String _selectedKarat = '18k';
  String _selectedCategory = 'Ring';
  File? _imageFile;
  String? _existingPhotoUrl;
  bool _isSaving = false;
  bool _snEdited = false; // true when user manually typed SN
  String? _snError;

  List<DiamondGroup> _diamonds = [];
  List<StoneGroup> _stones = [];

  bool get _isEditing => widget.existingId != null;
  final List<String> _karatOptions = ['14k', '18k', '22k', '24k'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final d = widget.existingData!;
      _nameCtrl.text = d['name'] ?? '';
      _goldWtCtrl.text = '${d['goldWeightGrams'] ?? ''}';
      _stockCtrl.text = '${d['stockCount'] ?? ''}';
      _snCtrl.text = d['serialNumber'] ?? '';
      _selectedKarat = d['goldKarat'] ?? '18k';
      _selectedCategory = d['itemCategory'] ?? 'Ring';
      _existingPhotoUrl = d['photoUrl'];
      _snEdited = true;

      final dList = d['diamonds'] as List<dynamic>? ?? [];
      _diamonds = dList
          .map((e) => DiamondGroup.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      final sList = d['stones'] as List<dynamic>? ?? [];
      _stones = sList
          .map((e) => StoneGroup.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (_diamonds.isEmpty) _addDiamond();
    if (_stones.isEmpty) _addStone();
    if (!_isEditing) _generateSN();
  }

  // ── SN generation ────────────────────────────────────────────────────────

  Future<void> _generateSN() async {
    final prefix = _prefixForCategory(_selectedCategory);
    final year = DateTime.now().year;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Count existing items in this category to get next number
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .where('itemCategory', isEqualTo: _selectedCategory)
        .get();

    final next = (snap.docs.length + 1).toString().padLeft(4, '0');
    final sn = '$prefix-$year-$next';

    if (!_snEdited) setState(() => _snCtrl.text = sn);
  }

  Future<bool> _isSnDuplicate(String sn) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .where('serialNumber', isEqualTo: sn)
        .get();

    // If editing, exclude the current doc
    if (_isEditing) {
      return snap.docs.any((d) => d.id != widget.existingId);
    }
    return snap.docs.isNotEmpty;
  }

  // ── Diamond / stone helpers ───────────────────────────────────────────────

  void _addDiamond() {
    final g = DiamondGroup();
    g.caratsCtrl.addListener(() => setState(() => g.recalc()));
    g.piecesCtrl.addListener(() => setState(() => g.recalc()));
    setState(() => _diamonds.add(g));
  }

  void _removeDiamond(int i) {
    _diamonds[i].dispose();
    setState(() => _diamonds.removeAt(i));
  }

  void _addStone() => setState(() => _stones.add(StoneGroup()));

  void _removeStone(int i) {
    _stones[i].dispose();
    setState(() => _stones.removeAt(i));
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadPhoto(String itemId) async {
    if (_imageFile == null) return _existingPhotoUrl;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref =
        FirebaseStorage.instance.ref('users/$userId/inventory/$itemId.jpg');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final sn = _snCtrl.text.trim();

    // Check duplicate SN
    setState(() => _snError = null);
    final isDup = await _isSnDuplicate(sn);
    if (isDup) {
      setState(() => _snError = 'This serial number already exists.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('inventory');
      final docRef = _isEditing ? col.doc(widget.existingId) : col.doc();
      final photoUrl = await _uploadPhoto(docRef.id);

      final diamondData = _diamonds
          .where((g) =>
              g.caratsCtrl.text.isNotEmpty && g.piecesCtrl.text.isNotEmpty)
          .map((g) => g.toMap())
          .toList();

      final stoneData = _stones
          .where((g) => g.typeCtrl.text.isNotEmpty)
          .map((g) => g.toMap())
          .toList();

      final data = <String, dynamic>{
        'id': docRef.id,
        'serialNumber': sn,
        'itemCategory': _selectedCategory,
        'name': _nameCtrl.text.trim(),
        'goldKarat': _selectedKarat,
        'goldWeightGrams': double.tryParse(_goldWtCtrl.text) ?? 0,
        'diamonds': diamondData,
        'stones': stoneData,
        'stockCount': int.tryParse(_stockCtrl.text) ?? 1,
        'photoUrl': photoUrl,
      };

      if (_isEditing) {
        await docRef.update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(_isEditing ? 'Item updated' : 'Item added to inventory')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit item' : 'Add new piece',
            style: const TextStyle(fontSize: 17)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveItem,
            child: _isSaving
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Photo ────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!,
                            fit: BoxFit.cover, width: double.infinity))
                    : _existingPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_existingPhotoUrl!,
                                fit: BoxFit.cover, width: double.infinity))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: Colors.black38),
                              SizedBox(height: 8),
                              Text('Tap to add photo',
                                  style: TextStyle(
                                      color: Colors.black38, fontSize: 13)),
                            ],
                          ),
              ),
            ),

            // ── Category ─────────────────────────────────────────
            const SizedBox(height: 20),
            _sectionLabel('Category'),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kJewelleryCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = kJewelleryCategories[i];
                  final name = cat['name']!;
                  final icon = cat['icon']!;
                  final sel = _selectedCategory == name;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = name;
                        _snEdited = false;
                      });
                      _generateSN();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 72,
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? const Color(0xFF1A1A2E) : Colors.black12,
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: sel ? Colors.white : Colors.black54,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Serial number ─────────────────────────────────────
            const SizedBox(height: 20),
            _sectionLabel('Serial number'),
            TextFormField(
              controller: _snCtrl,
              onChanged: (v) => setState(() {
                _snEdited = v.isNotEmpty;
                _snError = null;
              }),
              decoration: _inputDecoration('Serial number').copyWith(
                hintText: 'Auto-generated',
                suffixIcon: _snEdited
                    ? IconButton(
                        icon: const Icon(Icons.refresh,
                            size: 18, color: Colors.black38),
                        tooltip: 'Regenerate',
                        onPressed: () {
                          setState(() => _snEdited = false);
                          _generateSN();
                        },
                      )
                    : null,
                errorText: _snError,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 6),
            const Text(
              'Auto-generated from category. You can edit it manually. Duplicates are not allowed.',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),

            // ── Item details ──────────────────────────────────────
            const SizedBox(height: 20),
            _sectionLabel('Item details'),
            _field(_nameCtrl, 'Item name',
                hint: 'e.g. Solitaire ring', required: true),
            const SizedBox(height: 12),
            _field(_stockCtrl, 'Stock count',
                hint: '1', keyboardType: TextInputType.number, required: true),

            // ── Gold ──────────────────────────────────────────────
            const SizedBox(height: 20),
            _sectionLabel('Gold'),
            Row(children: [
              Expanded(
                  child: _field(_goldWtCtrl, 'Weight (grams)',
                      hint: '4.2',
                      keyboardType: TextInputType.number,
                      required: true)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedKarat,
                  decoration: _inputDecoration('Karat'),
                  items: _karatOptions
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedKarat = v!),
                ),
              ),
            ]),

            // ── Diamonds ──────────────────────────────────────────
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabelWidget('Diamonds'),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add size'),
                  onPressed: _addDiamond,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF185FA5)),
                ),
              ],
            ),
            ..._diamonds
                .asMap()
                .entries
                .map((e) => _diamondGroupCard(e.key, e.value)),

            // ── Stones ────────────────────────────────────────────
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabelWidget('Precious stones'),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add stone'),
                  onPressed: _addStone,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF993556)),
                ),
              ],
            ),
            ..._stones
                .asMap()
                .entries
                .map((e) => _stoneGroupCard(e.key, e.value)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Card widgets ──────────────────────────────────────────────────────────

  Widget _diamondGroupCard(int i, DiamondGroup g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Diamond group ${i + 1}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54)),
              if (_diamonds.length > 1)
                GestureDetector(
                  onTap: () => _removeDiamond(i),
                  child:
                      const Icon(Icons.close, size: 18, color: Colors.black38),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextFormField(
              controller: g.caratsCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration('Total carats').copyWith(hintText: '0.50'),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: TextFormField(
              controller: g.piecesCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration('No. of diamonds').copyWith(hintText: '10'),
            )),
          ]),
          if (g.category != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: getCategoryBg(g.category!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.diamond_outlined,
                    size: 14, color: getCategoryColor(g.category!)),
                const SizedBox(width: 8),
                Text(g.category!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: getCategoryColor(g.category!))),
                const Spacer(),
                Text('${g.weightPerStoneCents!.toStringAsFixed(2)} cent/stone',
                    style: TextStyle(
                        fontSize: 12,
                        color: getCategoryColor(g.category!).withOpacity(0.8))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stoneGroupCard(int i, StoneGroup g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stone ${i + 1}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54)),
              if (_stones.length > 1)
                GestureDetector(
                  onTap: () => _removeStone(i),
                  child:
                      const Icon(Icons.close, size: 18, color: Colors.black38),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: g.typeCtrl,
            decoration: _inputDecoration('Stone type')
                .copyWith(hintText: 'e.g. Ruby, Emerald, Sapphire'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextFormField(
              controller: g.caratsCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration('Total carats').copyWith(hintText: '1.20'),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: TextFormField(
              controller: g.piecesCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration('No. of stones').copyWith(hintText: '3'),
            )),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
                letterSpacing: 0.6)),
      );

  Widget _sectionLabelWidget(String text) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.black45,
          letterSpacing: 0.6));

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12, width: 0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget _field(TextEditingController ctrl, String label,
      {String? hint, TextInputType? keyboardType, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goldWtCtrl.dispose();
    _stockCtrl.dispose();
    _snCtrl.dispose();
    for (final g in _diamonds) g.dispose();
    for (final g in _stones) g.dispose();
    super.dispose();
  }
}
