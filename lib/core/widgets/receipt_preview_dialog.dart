import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../utils/receipt_printer.dart';

/// Thermal receipt print preview dialog supporting 58mm and 80mm paper widths.
/// Displays the exact rasterized receipt image used by [ReceiptPrinter.printReceipt].
class ReceiptPreviewDialog extends StatefulWidget {
  final ReceiptData data;

  const ReceiptPreviewDialog({super.key, required this.data});

  static Future<void> show(
    BuildContext context, {
    required ReceiptData data,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReceiptPreviewDialog(data: data),
    );
  }

  @override
  State<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends State<ReceiptPreviewDialog> {
  ReceiptPaperSize _paperSize = ReceiptPaperSize.mm80;
  late Future<RenderedReceiptImage> _previewFuture;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _previewFuture = _loadPreview();
  }

  Future<RenderedReceiptImage> _loadPreview() {
    return ReceiptPrinter.buildReceiptImage(
      widget.data,
      paperSize: _paperSize,
    );
  }

  void _selectPaperSize(ReceiptPaperSize size) {
    if (_paperSize == size) return;
    setState(() {
      _paperSize = size;
      _previewFuture = _loadPreview();
    });
  }

  Future<void> _handlePrint() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await ReceiptPrinter.printReceipt(widget.data, paperSize: _paperSize);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: screen.height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Print Preview (មើលវិក្កយបត្រ)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<ReceiptPaperSize>(
                segments: const [
                  ButtonSegment(
                    value: ReceiptPaperSize.mm80,
                    label: Text('80mm Thermal'),
                  ),
                  ButtonSegment(
                    value: ReceiptPaperSize.mm58,
                    label: Text('58mm Thermal'),
                  ),
                ],
                selected: {_paperSize},
                onSelectionChanged: (selected) =>
                    _selectPaperSize(selected.first),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: FutureBuilder<RenderedReceiptImage>(
                      future: _previewFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Preview error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final rendered = snapshot.data!;
                        final previewWidth =
                            _paperSize == ReceiptPaperSize.mm58 ? 250.0 : 340.0;
                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 2.5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            child: Center(
                              child: Container(
                                width: previewWidth,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Image.memory(
                                  rendered.pngBytes,
                                  fit: BoxFit.fitWidth,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('បិទ (Close)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _printing ? null : _handlePrint,
                      icon: _printing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_outlined, size: 18),
                      label: const Text('បោះពុម្ព (Print)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
