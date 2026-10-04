import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _authHelper = AuthHelper();

  int _rating = 5;
  String _selectedCategory = 'App Performance & Usability';
  String _selectedSeverity = 'Medium';
  bool _isSubmitting = false;
  String _technicianName = 'Technician';

  final List<String> _categories = [
    'App Performance & Usability',
    'Inventory & Parts Management',
    'Barcode, QR & Blockchain Scanner',
    'GPS Delivery & Location Tracking',
    'Bug Report / Crash Diagnostic',
    'Feature Request & Workflow Proposal',
  ];

  final List<String> _severityLevels = [
    'Low (Minor cosmetic / Suggestion)',
    'Medium (Workflow friction)',
    'High (Critical blocker / Data issue)',
  ];

  @override
  void initState() {
    super.initState();
    _loadTechnicianName();
  }

  Future<void> _loadTechnicianName() async {
    final name = await _authHelper.getUsername();
    if (mounted) {
      setState(() {
        _technicianName = name;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _suggestionsController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Exceptional — Highly efficient for repair shop operations';
      case 4:
        return 'Good — Reliable tool for daily workshop tasks';
      case 3:
        return 'Average — Functional but needs minor workflow improvements';
      case 2:
        return 'Fair — Encountered operational friction or slow responses';
      case 1:
        return 'Critical — Significant blockers impede service tasks';
      default:
        return '';
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 650));

    // Generate random mock diagnostic ticket ID
    final randomId = 1000 + Random().nextInt(9000);
    final ticketNumber = 'SF-$randomId';

    // Show local notification as feedback submission receipt
    await NotificationHelper().showNotification(
      id: 201,
      title: 'Feedback Logged (Ticket $ticketNumber)',
      body: 'Your service shop evaluation has been recorded into the SmartFix diagnostic system.',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Color(0xFF14B8A6), size: 48),
          title: const Text('Feedback Submitted!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thank you, $_technicianName! Your evaluation and bug report have been logged under Ticket #$ticketNumber.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Ticket Ref: $ticketNumber',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: $_selectedCategory • Severity: $_selectedSeverity',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _titleController.clear();
                _descriptionController.clear();
                _suggestionsController.clear();
                setState(() {
                  _rating = 5;
                  _selectedCategory = _categories.first;
                  _selectedSeverity = 'Medium (Workflow friction)';
                });
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Feedback & Bug Report'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Workshop Diagnostics Banner ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E).withValues(alpha: 0.15),
                      const Color(0xFF14B8A6).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.build_circle, color: Color(0xFF0F766E), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'SmartFix Workshop Operations Hub',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Service Shop Performance & Bug Diagnostics',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Help us optimize spare parts inventory tracking, repair time estimation, and shop workflows for technicians.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Star Rating Section ───────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Overall Repair Shop App Experience',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            iconSize: 38,
                            icon: Icon(
                              starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                            ),
                            onPressed: () => setState(() => _rating = starIndex),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRatingLabel(_rating),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Category Dropdown ─────────────────────────────────────────
              Text(
                'Feedback Category',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // ── Severity Level (If applicable) ────────────────────────────
              Text(
                'Issue Impact / Severity',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _severityLevels[1],
                items: _severityLevels
                    .map((sev) => DropdownMenuItem(
                          value: sev,
                          child: Text(sev, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSeverity = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.report_problem_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // ── Title / Summary ───────────────────────────────────────────
              Text(
                'Issue Summary / Subject',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Barcode scanner takes multiple attempts on small camera modules',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.short_text_rounded),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a brief summary' : null,
              ),

              const SizedBox(height: 16),

              // ── Detailed Experience / Bug Observations ─────────────────────
              Text(
                'Detailed Experience & Observations',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Describe the repair shop situation, error messages encountered, or how the feature behaved during shop hours...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please provide detailed observations'
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Suggestions for App Improvement ────────────────────────────
              Text(
                'Suggestions for Workshop Efficiency',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _suggestionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'What changes or additions would help technicians repair phones faster and manage inventory better?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please share suggestions to improve the app'
                    : null,
              ),

              const SizedBox(height: 24),

              // ── Diagnostics Meta Info ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Device telemetry (OS, network latency, app build) is bundled automatically for diagnostic review.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit Button ─────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Logging Ticket...' : 'Submit Shop Feedback & Report',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
