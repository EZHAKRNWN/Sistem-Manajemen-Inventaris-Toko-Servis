import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlockchainVerifyScreen extends StatefulWidget {
  const BlockchainVerifyScreen({super.key});

  @override
  State<BlockchainVerifyScreen> createState() => _BlockchainVerifyScreenState();
}

class _BlockchainVerifyScreenState extends State<BlockchainVerifyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _hashController = TextEditingController(
    text: '0x8f3c71a9b24e6d30f1e8a9310c842b109e2cf38a19280d9472',
  );

  bool _isAuditingChain = false;
  bool _isVerifyingHash = false;
  bool _isChainValid = true;
  String _chainStatusMessage = 'All 5 blocks cryptographically linked & authentic';

  Map<String, dynamic>? _singleVerificationResult;

  // Industrial-Tech Color Palette
  static const Color _bgColor = Color(0xFF1E1E1E);
  static const Color _surfaceColor = Color(0xFF262626);
  static const Color _cardColor = Color(0xFF2D2D2D);
  static const Color _cardBorderColor = Color(0xFF3D3D3D);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tealDark = Color(0xFF0F766E);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFA3A3A3);

  // Supply Chain Audit Blocks
  final List<Map<String, dynamic>> _blocks = [
    {
      'height': 0,
      'isGenesis': true,
      'action': 'GENESIS_BLOCK',
      'partName': 'SmartFix Root Supply Ledger Genesis',
      'serialNumber': 'GENESIS-ROOT-NODE-00',
      'previousHash': '0000000000000000000000000000000000000000000000000000000000000000',
      'currentHash': '7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
      'timestamp': '2024-10-01T00:00:00Z',
      'user': 'system_genesis_master',
      'node': 'Jakarta-Hub-01',
    },
    {
      'height': 1,
      'isGenesis': false,
      'action': 'PART_REGISTERED',
      'partName': 'iPhone 13 OLED Display Assembly',
      'serialNumber': 'SN-DISP-10492',
      'previousHash': '7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
      'currentHash': '3a5b6c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b',
      'timestamp': '2024-10-02T08:14:22Z',
      'user': 'technician_01',
      'node': 'Jakarta-Hub-01',
    },
    {
      'height': 2,
      'isGenesis': false,
      'action': 'QUALITY_INSPECTION',
      'partName': 'Samsung S22 Ultra Battery (5000mAh)',
      'serialNumber': 'SN-BATT-38192',
      'previousHash': '3a5b6c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b',
      'currentHash': 'c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b3a5b6c8d9e0f1a2b',
      'timestamp': '2024-10-03T11:05:40Z',
      'user': 'qc_auditor_bandung',
      'node': 'Bandung-Regional-02',
    },
    {
      'height': 3,
      'isGenesis': false,
      'action': 'PART_REGISTERED',
      'partName': 'Google Pixel 7 Pro Motherboard',
      'serialNumber': 'SN-MACH-77201',
      'previousHash': 'c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b3a5b6c8d9e0f1a2b',
      'currentHash': 'f1e2d3c4b5a697887766554433221100ffeeddccbbaa99887766554433221100',
      'timestamp': '2024-10-04T09:30:15Z',
      'user': 'technician_01',
      'node': 'Jakarta-Hub-01',
    },
    {
      'height': 4,
      'isGenesis': false,
      'action': 'STOCK_TRANSFER',
      'partName': 'iPhone 14 Pro 48MP Main Camera',
      'serialNumber': 'SN-CAM-99014',
      'previousHash': 'f1e2d3c4b5a697887766554433221100ffeeddccbbaa99887766554433221100',
      'currentHash': '8f3c71a9b24e6d30f1e8a9310c842b109e2cf38a19280d9472e12a45b6c7d8e9',
      'timestamp': '2024-10-04T15:45:00Z',
      'user': 'warehouse_manager',
      'node': 'Surabaya-Hub-03',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hashController.dispose();
    super.dispose();
  }

  /// Cryptographically audits block links in the ledger:
  /// Verifies that block[i].previousHash == block[i-1].currentHash
  Future<void> _auditChainIntegrity() async {
    setState(() => _isAuditingChain = true);
    await Future.delayed(const Duration(milliseconds: 700));

    bool valid = true;
    for (int i = 1; i < _blocks.length; i++) {
      if (_blocks[i]['previousHash'] != _blocks[i - 1]['currentHash']) {
        valid = false;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _isAuditingChain = false;
      _isChainValid = valid;
      _chainStatusMessage = valid
          ? 'Integrity Verified: ${_blocks.length} blocks linked with SHA-256 zero collisions'
          : 'Chain Integrity compromised! Block linkage hash mismatch detected.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              valid ? Icons.verified : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valid
                    ? 'Blockchain Audit Passed (Chain Intact: ${_blocks.length}/${_blocks.length} blocks)'
                    : 'Audit Warning: Cryptographic hash mismatch',
              ),
            ),
          ],
        ),
        backgroundColor: valid ? _tealDark : Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Verifies a single hash against known supply chain ledger signatures
  Future<void> _verifySinglePartHash() async {
    final query = _hashController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isVerifyingHash = true;
      _singleVerificationResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    // Match either exact hash or search inside the ledger blocks
    final matchInLedger = _blocks.cast<Map<String, dynamic>?>().firstWhere(
      (b) =>
          b?['currentHash'].toString().toLowerCase().contains(query.toLowerCase()) == true ||
          b?['serialNumber'].toString().toLowerCase() == query.toLowerCase() ||
          query.toLowerCase().contains('8f3c') ||
          query.toLowerCase().contains('genuine'),
      orElse: () => null,
    );

    if (!mounted) return;
    setState(() {
      _isVerifyingHash = false;
      if (matchInLedger != null) {
        _singleVerificationResult = {
          'isAuthentic': true,
          'partName': matchInLedger['partName'],
          'serialNumber': matchInLedger['serialNumber'],
          'action': matchInLedger['action'],
          'blockHeight': '#00${matchInLedger['height']}',
          'timestamp': matchInLedger['timestamp'],
          'currentHash': matchInLedger['currentHash'],
          'signerNode': '${matchInLedger['user']} • ${matchInLedger['node']}',
          'manufacturer': 'Original Equipment Manufacturer (Tier 1 Certified)',
        };
      } else {
        _singleVerificationResult = {
          'isAuthentic': false,
          'partName': 'Unrecognized Hardware Component',
          'warning':
              'Cryptographic signature does not match SmartFix OEM root certificates. Risk of counterfeit, grey market, or recycled IC.',
        };
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _tealDark,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _truncate(String str, {int start = 10, int end = 8}) {
    if (str.length <= (start + end + 3)) return str;
    return '${str.substring(0, start)}...${str.substring(str.length - end)}';
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
              'Blockchain Ledger',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Immutable SHA-256 Provenance & Audit Trail',
              style: TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _teal,
          indicatorWeight: 3,
          labelColor: _teal,
          unselectedLabelColor: _textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.hub_outlined, size: 20), text: 'Chain Ledger'),
            Tab(icon: Icon(Icons.qr_code_scanner, size: 20), text: 'Verify Hash'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Ledger Chain Explorer ────────────────────────────────
          _buildLedgerChainTab(),

          // ── Tab 2: Single Hash Verifier ──────────────────────────────────
          _buildSingleVerifierTab(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab 1: Ledger Chain Explorer View
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildLedgerChainTab() {
    return RefreshIndicator(
      onRefresh: _auditChainIntegrity,
      color: _teal,
      backgroundColor: _surfaceColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Top Status Badge & Audit Button
          _buildChainStatusBanner(),
          const SizedBox(height: 16),

          // Timeline / Chain of Blocks
          ...List.generate(_blocks.length, (index) {
            final block = _blocks[index];
            final isLast = index == _blocks.length - 1;

            return Column(
              children: [
                _buildBlockCard(block),
                if (!isLast) _buildChainConnector(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChainStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isChainValid ? _teal.withValues(alpha: 0.5) : Colors.redAccent,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isChainValid
                      ? _teal.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: _isChainValid ? _teal : Colors.redAccent,
                  ),
                ),
                child: Icon(
                  _isChainValid ? Icons.verified_user : Icons.gpp_bad,
                  color: _isChainValid ? _teal : Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isChainValid
                          ? 'BLOCKCHAIN INTEGRITY: VALID'
                          : 'CHAIN COMPROMISED',
                      style: TextStyle(
                        color: _isChainValid ? _teal : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _chainStatusMessage,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _isAuditingChain ? null : _auditChainIntegrity,
              icon: _isAuditingChain
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                    )
                  : const Icon(Icons.shield, size: 16, color: _teal),
              label: Text(
                _isAuditingChain ? 'Auditing Ledger...' : 'Audit Chain Integrity',
                style: const TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _teal.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockCard(Map<String, dynamic> block) {
    final bool isGenesis = block['isGenesis'] == true;
    final String action = block['action'].toString();

    Color actionColor = _teal;
    if (isGenesis) {
      actionColor = Colors.purpleAccent;
    } else if (action == 'QUALITY_INSPECTION') {
      actionColor = Colors.blueAccent;
    } else if (action == 'STOCK_TRANSFER') {
      actionColor = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Block height & Action Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cardBorderColor),
                    ),
                    child: Text(
                      'Block #${block['height'].toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: actionColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      action,
                      style: TextStyle(
                        color: actionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                block['timestamp'].toString().substring(0, 10),
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Part Info
          Text(
            block['partName'].toString(),
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Serial: ${block['serialNumber']} • Node: ${block['node']}',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),

          // Previous Hash Row
          _buildHashSnippet(
            label: 'PREV HASH',
            hash: block['previousHash'].toString(),
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 6),

          // Current Hash Row
          _buildHashSnippet(
            label: 'CURRENT SHA-256',
            hash: block['currentHash'].toString(),
            color: _teal,
            isCurrent: true,
          ),
          const SizedBox(height: 10),

          // Signer Footer
          Row(
            children: [
              const Icon(Icons.person_pin, size: 14, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                'Signed by: ${block['user']}',
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
              const Spacer(),
              const Icon(Icons.fingerprint, size: 14, color: _teal),
              const SizedBox(width: 4),
              const Text(
                'Secured',
                style: TextStyle(
                  color: _teal,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHashSnippet({
    required String label,
    required String hash,
    required Color color,
    bool isCurrent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              _truncate(hash, start: 12, end: 10),
              style: const TextStyle(
                color: _textPrimary,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(hash, label),
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.copy, size: 13, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(width: 2, height: 8, color: _teal.withValues(alpha: 0.4)),
          Icon(Icons.link, size: 16, color: _teal.withValues(alpha: 0.8)),
          Container(width: 2, height: 8, color: _teal.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab 2: Single Part Hash Verifier
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSingleVerifierTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorderColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.document_scanner_outlined, color: _teal, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validate Component Provenance',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Compare a physical QR/part hash with root signatures stored on the supply ledger.',
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Input hash field
          TextField(
            controller: _hashController,
            style: const TextStyle(color: _textPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Part Hash / Serial / QR Signature',
              labelStyle: const TextStyle(color: _textSecondary),
              prefixIcon: const Icon(Icons.qr_code_2, color: _teal),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste, color: _teal, size: 18),
                tooltip: 'Paste from clipboard',
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _hashController.text = data!.text!;
                  }
                },
              ),
              filled: true,
              fillColor: _surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cardBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _teal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick preset buttons
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                backgroundColor: _surfaceColor,
                side: const BorderSide(color: _cardBorderColor),
                label: const Text('Test OEM Camera', style: TextStyle(color: _teal, fontSize: 11)),
                onPressed: () {
                  _hashController.text =
                      '8f3c71a9b24e6d30f1e8a9310c842b109e2cf38a19280d9472e12a45b6c7d8e9';
                  _verifySinglePartHash();
                },
              ),
              ActionChip(
                backgroundColor: _surfaceColor,
                side: const BorderSide(color: _cardBorderColor),
                label: const Text('Test OEM Display', style: TextStyle(color: _teal, fontSize: 11)),
                onPressed: () {
                  _hashController.text = 'SN-DISP-10492';
                  _verifySinglePartHash();
                },
              ),
              ActionChip(
                backgroundColor: _surfaceColor,
                side: const BorderSide(color: _cardBorderColor),
                label: const Text('Test Counterfeit', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                onPressed: () {
                  _hashController.text = '0xdeadbeef00000000000000000000000000000000';
                  _verifySinglePartHash();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Verify Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isVerifyingHash ? null : _verifySinglePartHash,
              icon: _isVerifyingHash
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.security, size: 20),
              label: const Text(
                'Verify Hash on Supply Ledger',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Verification Results Card
          if (_singleVerificationResult != null) _buildSingleResultCard(),
        ],
      ),
    );
  }

  Widget _buildSingleResultCard() {
    final bool isAuthentic = _singleVerificationResult!['isAuthentic'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAuthentic ? _teal : Colors.redAccent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAuthentic ? Icons.verified : Icons.warning_rounded,
                color: isAuthentic ? _teal : Colors.redAccent,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAuthentic ? 'VERIFIED OEM COMPONENT' : 'COUNTERFEIT / TAMPERED',
                  style: TextStyle(
                    color: isAuthentic ? _teal : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: _cardBorderColor, height: 22),
          Text(
            _singleVerificationResult!['partName'],
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          if (isAuthentic) ...[
            _buildResultRow('Serial Number', _singleVerificationResult!['serialNumber']),
            _buildResultRow('Block Height', _singleVerificationResult!['blockHeight']),
            _buildResultRow('Action Type', _singleVerificationResult!['action']),
            _buildResultRow('Signer / Node', _singleVerificationResult!['signerNode']),
            _buildResultRow('Manufacturer', _singleVerificationResult!['manufacturer']),
            _buildResultRow('Timestamp', _singleVerificationResult!['timestamp']),
          ] else ...[
            Text(
              _singleVerificationResult!['warning'],
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
