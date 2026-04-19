import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transport_bill_data.dart';
import '../utils/number_to_words.dart';

class PdfServiceV4 {
  static const int _fixedRowCount = 18; 

  static Future<void> generateAndPreview(
    material.BuildContext context,
    TransportBillData billData,
  ) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/transport-bill-template.png');
    final Uint8List imageData = bytes.buffer.asUint8List();
    final pw.ImageProvider templateImage = pw.MemoryImage(imageData);

    // Font loading
    pw.Font? mainFont;
    try {
      final fontData = await rootBundle.load("assets/fonts/kingred.otf");
      mainFont = pw.Font.ttf(fontData);
    } catch (e) {
      mainFont = pw.Font.timesBold();
    }

    final labelColor = PdfColors.grey700; // Grey as requested for labels
    final underlineColor = PdfColors.grey400; // Light grey for underlines

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                // Background
                pw.Image(templateImage, fit: pw.BoxFit.fill),

                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 230), // Lower region to clear letterhead
                      
                      // Bill No & Date Row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildUnderlinedLabel("Bill No.", billData.billNo, labelColor, underlineColor),
                          _buildUnderlinedLabel("Date", billData.formattedDate, labelColor, underlineColor),
                        ],
                      ),

                      pw.SizedBox(height: 10),

                      // To Section
                      _buildUnderlinedLabel("To,", billData.billedTo, labelColor, underlineColor, isFullWidth: true),

                      pw.SizedBox(height: 15),

                      // Title
                      pw.Center(
                        child: pw.Text(
                          "Only Transporting Bill Charges",
                          style: pw.TextStyle(
                            color: PdfColor.fromHex("#FF0000"), // Red
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      // Table
                      _buildTable(billData, mainFont),

                      pw.SizedBox(height: 10),
                    ],
                  ),
                ),

                // Rupees in Words - Forced visibility via Positioned
                pw.Positioned(
                  left: 40,
                  right: 40,
                  bottom: 110,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                    ),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: "RUPEES IN WORDS: ",
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.TextSpan(
                            text: (NumberToWords.convert(billData.totalAmount.toInt()).toUpperCase() + " ONLY"),
                            style: pw.TextStyle(
                              color: PdfColor.fromHex("#FF0000"), // Red
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Signature area - Forced visibility via Positioned
                pw.Positioned(
                  right: 40,
                  bottom: 15, // Further lowered from 25
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Proprietor Sign", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildUnderlinedLabel(String label, String value, PdfColor labelColor, PdfColor underlineColor, {bool isFullWidth = false}) {
    return pw.Container(
      width: isFullWidth ? double.infinity : null,
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: underlineColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label + " ", style: pw.TextStyle(color: labelColor, fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.Expanded(
            child: pw.Center(
               child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(TransportBillData billData, pw.Font font) {
    const tableBorderColor = PdfColors.grey;
    final headerStyle = pw.TextStyle(
      color: PdfColors.black,
      fontWeight: pw.FontWeight.bold,
      fontSize: 9, // Smaller for T4
    );
    final cellTextStyle = pw.TextStyle(fontSize: 9); // Smaller for T4

    return pw.Table(
      border: pw.TableBorder.all(color: tableBorderColor),
      columnWidths: {
        0: const pw.FixedColumnWidth(50), // Date
        1: const pw.FixedColumnWidth(80), // Lorry No
        2: const pw.FixedColumnWidth(60), // Material
        3: const pw.FixedColumnWidth(55), // Challan
        4: const pw.FixedColumnWidth(35), // Trips
        5: const pw.FixedColumnWidth(120), // Site
        6: const pw.FixedColumnWidth(50), // Rate
        7: const pw.FixedColumnWidth(60), // Amount
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _pCell("Date", headerStyle, align: pw.TextAlign.center),
            _pCell("Lorry No.", headerStyle, align: pw.TextAlign.center),
            _pCell("Material", headerStyle, align: pw.TextAlign.center),
            _pCell("Challan No.", headerStyle, align: pw.TextAlign.center),
            _pCell("Trips", headerStyle, align: pw.TextAlign.center),
            _pCell("Site", headerStyle, align: pw.TextAlign.center),
            _pCell("Rate", headerStyle, align: pw.TextAlign.center),
            _pCell("Amount", headerStyle, align: pw.TextAlign.center),
          ],
        ),
        // Rows (Static count)
        ...List.generate(_fixedRowCount, (index) {
          if (index < billData.items.length) {
            final item = billData.items[index];
            return pw.TableRow(
              children: [
                _pCell(item.date, cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.lorryNo, cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.material, cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.challanNo, cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.trips.toString(), cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.site, cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.rate.toInt().toString(), cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.amount.toInt().toString(), cellTextStyle, align: pw.TextAlign.center),
              ],
            );
          } else {
            // Empty rows (Compact height = 15 instead of 25)
            return pw.TableRow(
              children: List.generate(8, (_) => pw.SizedBox(height: 15)),
            );
          }
        }),
        // Footer (Summary)
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            _pCell("${billData.totalTrips} trips", pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), align: pw.TextAlign.center),
            pw.SizedBox(),
            _pCell("TOTAL", pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold, fontSize: 9), align: pw.TextAlign.center),
            _pCell(billData.totalAmount.toInt().toString(), pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), align: pw.TextAlign.center),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pCell(String text, pw.TextStyle style, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3), // Reduced padding for compact
      child: pw.Text(text, style: style, textAlign: align),
    );
  }
}
