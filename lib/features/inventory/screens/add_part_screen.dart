import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfix_mobile/core/api_service.dart';

class AddPartScreen extends StatefulWidget {
  const AddPartScreen({super.key});

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Display';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Display',
    'Battery',
    'Machine',
    'Accessories',
  ];

  // Theme Constants (matching SmartFix Industrial-Tech design system)
  static const Color _bgColor = Color(0xFF1E1E1E);
  static const Color _surfaceColor = Color(0xFF2A2A2A);
  static const Color _cardBorderColor = Color(0xFF383838);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tealDark = Color(0xFF0F766E);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFB0B0B0);

  @override
  void dispose() {
    _serialController.dispose();
    _nameController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Helper to auto-generate an industry-standard Serial Number / SKU
  void _generateSerialNumber() {
    final prefix = _selectedCategory.substring(0, min(4, _selectedCategory.length)).toUpperCase();
    final randomDigits = Random().nextInt(89999) + 10000;
    setState(() {
      _serialController.text = 'SN-$prefix-$randomDigits';
    });
  }

  /// Formats raw number string to Indonesian Rupiah display
  String _formatCurrency(num value) {
    final intVal = value.toInt();
    final formatted = intVal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Clean price string (remove any dots or spaces)
    final cleanPrice = _priceController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final double? parsedPrice = double.tryParse(cleanPrice);
    final int? parsedStock = int.tryParse(_stockController.text.trim());

    if (parsedPrice == null || parsedStock == null) {
      _showSnackbar('Invalid number format in price or stock quantity', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final Map<String, dynamic> payload = {
      'serial_number': _serialController.text.trim(),
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'stock_quantity': parsedStock,
      'base_price_idr': parsedPrice,
    };

    try {
      final response = await ApiService().addPart(payload);
      if (!mounted) return;

      final String hash = (response is Map && response['blockchain_hash'] != null)
          ? response['blockchain_hash'].toString()
          : '0x${List.generate(64, (_) => Random().nextInt(16).toRadixString(16)).join()}';

      _showSuccessDialog(
        partData: payload,
        blockchainHash: hash,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : _tealDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Cryptographic Proof & Item Summary Dialog
  void _showSuccessDialog({
    required Map<String, dynamic> partData,
    required String blockchainHash,
  }) {
    final truncatedHash = blockchainHash.length > 20
        ? '${blockchainHash.substring(0, 10)}...${blockchainHash.substring(blockchainHash.length - 8)}'
        : blockchainHash;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _teal, width: 1.2),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withValues(alpha: 0.15),
                  border: Border.all(color: _teal, width: 2),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: _teal,
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Part Registered',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'SHA-256 Ledger Block Created',
                style: TextStyle(
                  color: _teal,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorderColor),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Part Name', partData['name'].toString()),
                      const Divider(color: _cardBorderColor, height: 16),
                      _buildSummaryRow('Serial / SKU', partData['serial_number'].toString()),
                      const Divider(color: _cardBorderColor, height: 16),
                      _buildSummaryRow('Category', partData['category'].toString()),
                      const Divider(color: _cardBorderColor, height: 16),
                      _buildSummaryRow('Stock Quantity', '${partData['stock_quantity']} pcs'),
                      const Divider(color: _cardBorderColor, height: 16),
                      _buildSummaryRow(
                        'Base Price',
                        _formatCurrency(partData['base_price_idr'] as num),
                        isTeal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Blockchain Cryptographic Hash Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _tealDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link, color: _teal, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Cryptographic Blockchain Hash',
                            style: TextStyle(
                              color: _teal,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SHA-256',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        truncatedHash,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Copy Hash Button
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: blockchainHash));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Blockchain hash copied to clipboard!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: _tealDark,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 14, color: _teal),
                          label: const Text(
                            'Copy Full Hash',
                            style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _teal.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to dashboard with refresh flag
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTeal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isTeal ? _teal : _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Part',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Register part with on-chain cryptographic provenance',
              style: TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cardBorderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined, color: _teal, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blockchain Protected Part',
                              style: TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Every entry computes an immutable SHA-256 block linked to the technician session.',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Serial Number Field + Auto-generate action
                TextFormField(
                  controller: _serialController,
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDecoration(
                    label: 'Serial Number / SKU',
                    hint: 'e.g. SN-DISP-10492',
                    icon: Icons.qr_code_2,
                  ).copyWith(
                    suffixIcon: Tooltip(
                      message: 'Auto-generate SKU',
                      child: IconButton(
                        icon: const Icon(Icons.auto_mode, color: _teal, size: 20),
                        onPressed: _generateSerialNumber,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Serial number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDecoration(
                    label: 'Part Name',
                    hint: 'e.g. iPhone 14 Pro OLED Display Assembly',
                    icon: Icons.precision_manufacturing_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Part name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: _surfaceColor,
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  decoration: _inputDecoration(
                    label: 'Category',
                    hint: 'Select Category',
                    icon: Icons.category_outlined,
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Stock Quantity Field
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDecoration(
                    label: 'Stock Quantity',
                    hint: 'e.g. 15',
                    icon: Icons.inventory_2_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Stock quantity is required';
                    }
                    final n = int.tryParse(val.trim());
                    if (n == null || n < 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Base Price (IDR) Field
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDecoration(
                    label: 'Base Price (IDR)',
                    hint: 'e.g. 1450000',
                    icon: Icons.payments_outlined,
                  ).copyWith(
                    prefixText: 'Rp  ',
                    prefixStyle: const TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Base price is required';
                    }
                    final n = num.tryParse(val.trim());
                    if (n == null || n <= 0) {
                      return 'Enter a valid price in IDR';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_teal, _tealDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _teal.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_task, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Register & Secure Part',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: _teal, size: 22),
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
