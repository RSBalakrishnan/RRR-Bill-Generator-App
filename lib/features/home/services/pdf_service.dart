import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill_data.dart';

class PdfService {
  static Future<void> generateAndPreview(
    material.BuildContext context,
    BillData billData,
  ) async {
    final pdf = pw.Document();

    // Load Template Image
    final ByteData bytes = await rootBundle.load('assets/images/RRR-bill-template.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    final pw.ImageProvider templateImage = pw.MemoryImage(imageData);

    // Try to load Kingred Modern font, fallback to Times Bold
    pw.Font? kingredFont;
    try {
      final fontData = await rootBundle.load("assets/fonts/kingred.otf");
      kingredFont = pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback to standard serif font if custom font is missing
      kingredFont = pw.Font.timesBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                // Background Template
                pw.Image(templateImage, fit: pw.BoxFit.fill),

                // Billed To Text
                pw.Positioned(
                  left: 150, // Approximate X
                  top: 260, // Approximate Y
                  child: pw.Text(
                    billData.billedTo,
                    style: pw.TextStyle(font: kingredFont, fontSize: 16),
                  ),
                ),

                // Date Text
                pw.Positioned(
                  left: 150,
                  top: 295,
                  child: pw.Text(
                    billData.formattedDate,
                    style: pw.TextStyle(font: kingredFont, fontSize: 16),
                  ),
                ),

                // Services Table Implementation
                pw.Positioned(
                  // left: 15,
                  top: 410,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: List.generate(billData.services.length, (index) {
                      final item = billData.services[index];
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Row(
                          children: [
                            // S.No
                            pw.SizedBox(
                              width: 140,
                              child: pw.Text(
                                (index + 1).toString().padLeft(2, '0'),
                                style: pw.TextStyle(font: kingredFont, fontSize: 16),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            // Service
                            pw.SizedBox(
                              width: 120,
                              child: pw.Text(
                                item.service,
                                style: pw.TextStyle(font: kingredFont, fontSize: 16),
                              ),
                            ),
                            // Count
                            pw.SizedBox(
                              width: 140,
                              child: pw.Text(
                                item.count.toString().padLeft(2, '0'),
                                style: pw.TextStyle(font: kingredFont, fontSize: 16),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            // Amount (per load)
                            pw.SizedBox(
                              width: 100,
                              child: pw.Text(
                                item.amountPerLoad.toInt().toString(),
                                style: pw.TextStyle(font: kingredFont, fontSize: 16),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // Total Amount
                pw.Positioned(
                  right: 100,
                  bottom: 200, // Adjusted based on template layout
                  child: pw.Text(
                    billData.formattedTotal,
                    style: pw.TextStyle(
                      font: kingredFont,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Show Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
