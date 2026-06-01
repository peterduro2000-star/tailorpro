import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/order_model.dart';
import '../repositories/customer_repository.dart';

class DocumentService {
  final CustomerRepository _customerRepository = CustomerRepository();

  Future<File> generateReceipt(Order order) async {
    final customer =
        await _customerRepository.getCustomerById(order.customerId);
    final customerName = customer?.name ?? 'Customer #${order.customerId}';
    final customerPhone = customer?.phone ?? 'Not provided';

    final pdf = pw.Document();
    final generatedAt = DateTime.now();
    final receiptReference =
        'RCT-${generatedAt.millisecondsSinceEpoch.toString().substring(5)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(receiptReference, generatedAt),
              pw.SizedBox(height: 20),
              _buildSection(
                title: 'Customer',
                children: [
                  _buildRow('Name', customerName),
                  _buildRow('Phone', customerPhone),
                ],
              ),
              pw.SizedBox(height: 14),
              _buildSection(
                title: 'Order Details',
                children: [
                  _buildRow('Order Number', order.orderNumber),
                  _buildRow('Style / Order Name', order.orderTitle),
                  _buildRow('Order Date', _formatDate(order.createdAt)),
                  _buildRow('Due Date', _formatDate(order.deliveryDate)),
                  _buildRow('Status', Order.getStatusDisplay(order.status)),
                  _buildRow('Quantity', order.quantity.toString()),
                  if (order.fabricDetails?.isNotEmpty == true)
                    _buildRow('Fabric', order.fabricDetails!),
                ],
              ),
              pw.SizedBox(height: 14),
              _buildSection(
                title: 'Payment Summary',
                children: [
                  _buildPaymentHighlight(order),
                ],
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'Thank you for your patronage',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'TailorPro_Receipt_${_safeFilePart(order.orderNumber)}.pdf';
    final file = File('${tempDir.path}/$fileName');

    return file.writeAsBytes(await pdf.save());
  }

  pw.Widget _buildHeader(String receiptReference, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TailorPro',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Order Receipt',
                  style: const pw.TextStyle(
                    color: PdfColors.grey300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                receiptReference,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDate(generatedAt),
                style: const pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentHighlight(Order order) {
    return pw.Row(
      children: [
        _buildAmountBox('Total', _formatCurrency(order.totalAmount)),
        pw.SizedBox(width: 8),
        _buildAmountBox('Paid', _formatCurrency(order.paidAmount)),
        pw.SizedBox(width: 8),
        _buildAmountBox(
          'Balance',
          _formatCurrency(order.balance),
          emphasize: true,
        ),
      ],
    );
  }

  pw.Widget _buildAmountBox(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: emphasize ? PdfColors.grey900 : PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: emphasize ? PdfColors.grey900 : PdfColors.grey300,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                color: emphasize ? PdfColors.grey300 : PdfColors.grey700,
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: emphasize ? PdfColors.white : PdfColors.grey900,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatCurrency(double amount) {
    return 'NGN ${amount.toStringAsFixed(0)}';
  }

  String _safeFilePart(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
