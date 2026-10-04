import 'package:flutter/material.dart';

class BlockchainVerifyScreen extends StatefulWidget {
  const BlockchainVerifyScreen({super.key});

  @override
  State<BlockchainVerifyScreen> createState() => _BlockchainVerifyScreenState();
}

class _BlockchainVerifyScreenState extends State<BlockchainVerifyScreen> {
  final TextEditingController _hashController = TextEditingController(
    text: '0x8f3c71a9b24e6d30f1e8a9310c842b109e2cf38a19280d9472',
  );

  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;

  void _verifyPartHash() async {
    final hash = _hashController.text.trim();
    if (hash.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _isVerifying = false;
      // Simulated blockchain ledger lookup
      if (hash.toLowerCase().contains('8f3c') || hash.toLowerCase().contains('genuine')) {
        _verificationResult = {
          'isAuthentic': true,
          'partName': 'iPhone 14 Pro Super Retina XDR Display',
          'manufacturer': 'Samsung Display Co. Ltd (OEM Apple Tier 1)',
          'batchId': 'BATCH-2024-09-XDR-4401',
          'blockHeight': '19,842,109',
          'timestamp': '2024-08-15 03:22:11 UTC',
          'distributor': 'SmartFix Authorized Global Logistics',
        };
      } else {
        _verificationResult = {
          'isAuthentic': false,
          'partName': 'Unrecognized Third-Party Component',
          'warning': 'Part cryptographic signature does not match manufacturer root certificate. Risk of counterfeit or recycled IC.',
        };
      }
    });
  }

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Part Verifier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Decentralized Provenance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Validate hardware cryptographic serial hashes against the supply chain ledger.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input hash field
            TextField(
              controller: _hashController,
              decoration: InputDecoration(
                labelText: 'Part Hash / Cryptographic Chip ID',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste',
                  onPressed: () {},
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick preset test chips
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Test OEM Screen', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _hashController.text = '0x8f3c71a9b24e6d30f1e8a9310c842b109e2cf38a19280d9472';
                    _verifyPartHash();
                  },
                ),
                ActionChip(
                  label: const Text('Test Counterfeit', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _hashController.text = '0xdeadbeef00000000000000000000000000000000';
                    _verifyPartHash();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _isVerifying ? null : _verifyPartHash,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified),
              label: const Text('Verify On Ledger'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Verification Result
            if (_verificationResult != null) ...[
              Card(
                elevation: 0,
                color: _verificationResult!['isAuthentic']
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _verificationResult!['isAuthentic'] ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _verificationResult!['isAuthentic']
                                ? Icons.verified_user
                                : Icons.gpp_bad,
                            color: _verificationResult!['isAuthentic']
                                ? Colors.green
                                : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _verificationResult!['isAuthentic']
                                  ? 'AUTHENTIC OEM PART'
                                  : 'COUNTERFEIT WARNING',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _verificationResult!['isAuthentic']
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        _verificationResult!['partName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      if (_verificationResult!['isAuthentic']) ...[
                        _buildResultRow('Manufacturer:', _verificationResult!['manufacturer']),
                        _buildResultRow('Batch Identifier:', _verificationResult!['batchId']),
                        _buildResultRow('Block Height:', _verificationResult!['blockHeight']),
                        _buildResultRow('Ledger Timestamp:', _verificationResult!['timestamp']),
                        _buildResultRow('Distributor:', _verificationResult!['distributor']),
                      ] else ...[
                        Text(
                          _verificationResult!['warning'],
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
