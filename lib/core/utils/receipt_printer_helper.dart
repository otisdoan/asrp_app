import 'dart:typed_data';
import 'package:flutter/material.dart' hide Table, TableRow;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/order_provider.dart';

class ReceiptPrinterHelper {
  /// Generate PDF Document for 80mm Thermal Receipt
  static Future<Uint8List> generateReceiptPdf(
    MockOrder order, {
    String? cashierName,
    String? tableName,
  }) async {
    final pdf = pw.Document();

    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final dateFormatter = DateFormat('dd/MM/yyyy (HH:mm - HH:mm)');
    final nowStr = dateFormatter.format(order.orderTime);

    final displayCashier = cashierName ?? 'Hoàng Hiền';
    final displayTable = tableName ?? (order.pagerNumber?.isNotEmpty == true ? order.pagerNumber! : '207');

    // Calculate totals
    final rawTotal = order.totalAmount;
    final discountPercent = order.discountPercentage;
    final totalAfterDiscount = rawTotal;
    final isPaid = order.paymentStatus.toLowerCase() == 'paid' || order.paymentStatus.toLowerCase() == 'đã tt';

    // Load fonts supporting full Vietnamese Unicode
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();
    final fontBoldItalic = await PdfGoogleFonts.robotoBoldItalic();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          boldItalic: fontBoldItalic,
        ),
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              pw.Center(
                child: pw.Text(
                  'HÓA ĐƠN THANH TOÁN',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Số: ${order.orderNumber}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),

              // 2. Order Details Metadata
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 55,
                    child: pw.Text('Ngày:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    child: pw.Text(nowStr, style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 55,
                    child: pw.Text('Bàn:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Text(displayTable, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 55,
                    child: pw.Text('Thu ngân:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Text(displayCashier, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 6),

              // 3. Items Grid Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text('Tên món', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                          ),
                          pw.SizedBox(
                            width: 18,
                            child: pw.Text('SL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('ĐG', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                          ),
                          pw.Container(
                            width: 26,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dashed)),
                            ),
                            child: pw.Text('% KM', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('Thành tiền', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                    ),

                    // Table Items
                    ...order.items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      int itemToppingSum = 0;
                      if (item.extras != null && item.extras!.isNotEmpty) {
                        final regExp = RegExp(r'\(\+(\d[\d\.]*)đ\)');
                        final matches = regExp.allMatches(item.extras!);
                        for (final match in matches) {
                          final strVal = match.group(1)?.replaceAll('.', '') ?? '0';
                          itemToppingSum += int.tryParse(strVal) ?? 0;
                        }
                      }
                      final lineTotal = (item.price + itemToppingSum) * item.quantity;
                      final itemKm = discountPercent > 0 ? '$discountPercent' : '';

                      final List<String> subDetails = [];
                      if (item.sizeLabel != null && item.sizeLabel!.trim().isNotEmpty) {
                        subDetails.add('Size: ${item.sizeLabel}');
                      }
                      if (item.extras != null && item.extras!.trim().isNotEmpty) {
                        final cleanExtras = item.extras!.split('\n').where((s) => s.trim().isNotEmpty).join(', ');
                        if (cleanExtras.isNotEmpty) {
                          subDetails.add(cleanExtras);
                        }
                      }

                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        decoration: pw.BoxDecoration(
                          border: idx < order.items.length - 1
                              ? const pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dashed))
                              : null,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  flex: 4,
                                  child: pw.Text(
                                    item.name,
                                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                                pw.SizedBox(
                                  width: 18,
                                  child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.center),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(currencyFormatter.format(item.price), style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.right),
                                ),
                                pw.SizedBox(
                                  width: 26,
                                  child: pw.Text(itemKm, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                                ),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(currencyFormatter.format(lineTotal), style: const pw.TextStyle(fontSize: 8.5), textAlign: pw.TextAlign.right),
                                ),
                              ],
                            ),
                            if (subDetails.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 1, left: 2),
                                child: pw.Text(
                                  '+ ${subDetails.join(' | ')}',
                                  style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic),
                                ),
                              ),
                            if (item.note != null && item.note!.trim().isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 1, left: 2),
                                child: pw.Text(
                                  'Ghi chú: ${item.note}',
                                  style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // 4. Financial Summary
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Tổng thanh toán', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${currencyFormatter.format(totalAfterDiscount)}đ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Tiền mặt', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(isPaid ? '${currencyFormatter.format(totalAfterDiscount)}đ' : '0đ', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Trả lại khách', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('0đ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // 5. Discount note if applicable
              if (discountPercent > 0) ...[
                pw.Text('HĐ đã được KM:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, top: 2),
                  child: pw.Text('Giảm giá toàn bộ đồ uống nhà hàng ($discountPercent%)', style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.SizedBox(height: 10),
              ],

              // 6. Footer
              pw.Center(
                child: pw.Text(
                  'Trân trọng cảm ơn!',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('.', style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct print layout to connected hardware printer or OS printer dialog
  static Future<void> printOrderBill(
    BuildContext context,
    MockOrder order, {
    String? cashierName,
    String? tableName,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      order,
      cashierName: cashierName,
      tableName: tableName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'HoaDon_${order.orderNumber}',
    );
  }

  /// Display high-fidelity on-screen Printable Receipt Modal matching exact user sample image
  static void showBillPreviewModal(
    BuildContext context,
    MockOrder order, {
    String? cashierName,
    String? tableName,
    VoidCallback? onPrintConfirmed,
  }) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final dateFormatter = DateFormat('dd/MM/yyyy (HH:mm - HH:mm)');
    final nowStr = dateFormatter.format(order.orderTime);
    final displayCashier = cashierName ?? 'Hoàng Hiền';
    final displayTable = tableName ?? (order.pagerNumber?.isNotEmpty == true ? order.pagerNumber! : '207');
    final discountPercent = order.discountPercentage;
    final isPaid = order.paymentStatus.toLowerCase() == 'paid' || order.paymentStatus.toLowerCase() == 'đã tt';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long, color: Color(0xFFE65100)),
                      SizedBox(width: 8),
                      Text(
                        'Xem trước Hóa đơn in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Receipt Paper Slip Frame
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HÓA ĐƠN THANH TOÁN
                        const Text(
                          'HÓA ĐƠN THANH TOÁN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Số: ${order.orderNumber}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Info metadata
                        Row(
                          children: [
                            const SizedBox(width: 70, child: Text('Ngày:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))),
                            Expanded(child: Text(nowStr, style: const TextStyle(fontSize: 12, color: Colors.black))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 70, child: Text('Bàn:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))),
                            Text(displayTable, style: const TextStyle(fontSize: 12, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 70, child: Text('Thu ngân:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black))),
                            Text(displayCashier, style: const TextStyle(fontSize: 12, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Table Grid Box
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.2),
                          ),
                          child: Column(
                            children: [
                              // Grid Header
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black, width: 1.2)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 4, child: Text('Tên món', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
                                    SizedBox(width: 24, child: Text('SL', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
                                    Expanded(flex: 3, child: Text('ĐG', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
                                    SizedBox(
                                      width: 32,
                                      child: Text('% KM', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                    Expanded(flex: 3, child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
                                  ],
                                ),
                              ),

                              // Items List Rows
                              ...order.items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                int itemToppingSum = 0;
                                if (item.extras != null && item.extras!.isNotEmpty) {
                                  final regExp = RegExp(r'\(\+(\d[\d\.]*)đ\)');
                                  final matches = regExp.allMatches(item.extras!);
                                  for (final match in matches) {
                                    final strVal = match.group(1)?.replaceAll('.', '') ?? '0';
                                    itemToppingSum += int.tryParse(strVal) ?? 0;
                                  }
                                }
                                final lineTotal = (item.price + itemToppingSum) * item.quantity;
                                final itemKm = discountPercent > 0 ? '$discountPercent' : '';

                                final List<String> subDetails = [];
                                if (item.sizeLabel != null && item.sizeLabel!.trim().isNotEmpty) {
                                  subDetails.add('Size: ${item.sizeLabel}');
                                }
                                if (item.extras != null && item.extras!.trim().isNotEmpty) {
                                  final cleanExtras = item.extras!.split('\n').where((s) => s.trim().isNotEmpty).join(', ');
                                  if (cleanExtras.isNotEmpty) {
                                    subDetails.add(cleanExtras);
                                  }
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  decoration: BoxDecoration(
                                    border: idx < order.items.length - 1
                                        ? Border(bottom: BorderSide(color: Colors.grey[400]!, width: 0.8, style: BorderStyle.solid))
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(flex: 4, child: Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
                                          SizedBox(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black))),
                                          Expanded(flex: 3, child: Text(currencyFormatter.format(item.price), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black))),
                                          SizedBox(width: 32, child: Text(itemKm, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black))),
                                          Expanded(flex: 3, child: Text(currencyFormatter.format(lineTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black))),
                                        ],
                                      ),
                                      if (subDetails.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2, left: 4),
                                          child: Text(
                                            '+ ${subDetails.join(' | ')}',
                                            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                          ),
                                        ),
                                      if (item.note != null && item.note!.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2, left: 4),
                                          child: Text('Ghi chú: ${item.note}', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[800])),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Financial Summary Section
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 1.2),
                              bottom: BorderSide(color: Colors.black, width: 1.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng thanh toán', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                                  Text('${currencyFormatter.format(order.totalAmount)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tiền mặt', style: TextStyle(fontSize: 12, color: Colors.black)),
                                  Text(isPaid ? '${currencyFormatter.format(order.totalAmount)}đ' : '0đ', style: const TextStyle(fontSize: 12, color: Colors.black)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Trả lại khách', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                                  Text('0đ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (discountPercent > 0) ...[
                          const Text('HĐ đã được KM:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('Giảm giá toàn bộ đồ uống nhà hàng ($discountPercent%)', style: const TextStyle(fontSize: 11, color: Colors.black)),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Footer
                        const Text('Trân trọng cảm ơn!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 4),
                        const Text('.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      label: const Text('Đóng', style: TextStyle(color: Colors.grey)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (onPrintConfirmed != null) {
                          onPrintConfirmed();
                        }
                        await printOrderBill(
                          context,
                          order,
                          cashierName: displayCashier,
                          tableName: displayTable,
                        );
                      },
                      icon: const Icon(Icons.print_rounded, color: Colors.white),
                      label: const Text(
                        'In bill ngay',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
