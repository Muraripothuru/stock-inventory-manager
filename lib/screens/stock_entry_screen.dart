import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _reorderLevelController = TextEditingController();

  static const List<String> _categories = [
    'Electronics',
    'Stationery',
    'Hardware',
    'Grocery',
  ];

  String? _selectedCategory;
  int _categoryResetKey = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _skuController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  String? _validateSku(String? value) {
    final sku = (value ?? '').trim();
    if (sku.isEmpty) return 'SKU is required.';
    if (!RegExp(r'^STK-\d{3}$').hasMatch(sku)) {
      return 'SKU must follow STK- followed by exactly three digits (e.g. STK-101).';
    }
    return null;
  }

  String? _validateItemName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Item name is required.';
    if (name.length < 3) return 'Item name must be at least 3 characters.';
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Please select a category.';
    if (!_categories.contains(value)) return 'Please select a valid category.';
    return null;
  }

  String? _validateQuantity(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Quantity is required.';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Quantity must be a whole number.';
    if (parsed < 0) return 'Quantity must be zero or greater.';
    return null;
  }

  String? _validateUnitPrice(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Unit price is required.';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Unit price must be a valid number.';
    if (parsed <= 0) return 'Unit price must be greater than zero.';
    return null;
  }

  String? _validateReorderLevel(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Reorder level is required.';
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Reorder level must be a whole number.';
    if (parsed < 0) return 'Reorder level must be zero or greater.';
    return null;
  }

  Future<void> _saveItem() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final sku = _skuController.text.trim();
    final itemName = _itemNameController.text.trim();
    final quantity = int.parse(_quantityController.text.trim());
    final unitPrice = double.parse(_unitPriceController.text.trim());
    final reorderLevel = int.parse(_reorderLevelController.text.trim());
    final category = _selectedCategory!;

    try {
      await FirebaseFirestore.instance.collection('stockItems').add({
        'sku': sku,
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'reorderLevel': reorderLevel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _skuController.clear();
      _itemNameController.clear();
      _quantityController.clear();
      _unitPriceController.clear();
      _reorderLevelController.clear();
      setState(() {
        _selectedCategory = null;
        _categoryResetKey++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock item saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item. Please try again. ($e)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Add Stock Item',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fill in all fields. Every field is required.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _skuController,
            decoration: _decoration('SKU (e.g. STK-101)', Icons.qr_code_2),
            textCapitalization: TextCapitalization.characters,
            validator: _validateSku,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _itemNameController,
            decoration: _decoration('Item Name', Icons.label_outline),
            validator: _validateItemName,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_categoryResetKey),
            initialValue: _selectedCategory,
            decoration: _decoration('Category', Icons.category_outlined),
            items: _categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: _validateCategory,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantityController,
            decoration: _decoration('Quantity', Icons.numbers),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            validator: _validateQuantity,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _unitPriceController,
            decoration: _decoration(
              'Unit Price (RM)',
              Icons.payments_outlined,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validateUnitPrice,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reorderLevelController,
            decoration: _decoration(
              'Reorder Level',
              Icons.low_priority,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            validator: _validateReorderLevel,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveItem,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Item'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
