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

    // Use standard Helvetica fonts to match Python test script
    final pw.Font mainFont = pw.Font.helvetica();
    final pw.Font boldFont = pw.Font.helveticaBold();

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
                          _buildUnderlinedLabel("Bill No.", billData.billNo, labelColor, boldFont, 180, labelWidth: 50),
                          _buildUnderlinedLabel("Date", billData.formattedDate, labelColor, boldFont, 150, labelWidth: 40),
                        ],
                      ),

                      pw.SizedBox(height: 10),

                      // To Section
                      _buildUnderlinedLabel("To,", billData.billedTo, labelColor, boldFont, double.infinity, labelWidth: 50),

                      pw.SizedBox(height: 15),

                      // Title
                      pw.Center(
                        child: pw.Text(
                          "Base Freight Charge",
                          style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.grey700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      // Table
                      _buildTable(billData, mainFont, boldFont),

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
                              font: boldFont,
                              color: PdfColors.grey700,
                              fontSize: 10,
                            ),
                          ),
                          pw.TextSpan(
                            text: (NumberToWords.convert(billData.totalAmount.toInt()).toUpperCase()),
                            style: pw.TextStyle(
                              font: boldFont,
                              color: PdfColors.black,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Signature area - Moved up to avoid footer overlap
                pw.Positioned(
                  right: 40,
                  bottom: 50, // Moved up from 5
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("Proprietor Sign", style: pw.TextStyle(font: boldFont, color: PdfColors.grey700, fontSize: 11)),
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

  static pw.Widget _buildUnderlinedLabel(String label, String value, PdfColor labelColor, pw.Font font, double totalWidth, {double? labelWidth}) {
    return pw.Container(
      width: totalWidth,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(label, style: pw.TextStyle(font: font, color: labelColor, fontSize: 11)),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5),
              child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(TransportBillData billData, pw.Font mainFont, pw.Font boldFont) {
    const tableBorderColor = PdfColors.grey;
    final headerStyle = pw.TextStyle(
      font: boldFont,
      color: PdfColors.black,
      fontSize: 9, // Smaller for T4
    );
    final cellTextStyle = pw.TextStyle(
      font: mainFont,
      color: PdfColors.black,
      fontSize: 9,
    ); 


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
            _pCell("${billData.totalTrips} trips", pw.TextStyle(font: boldFont, color: PdfColors.grey700, fontSize: 9), align: pw.TextAlign.center),
            pw.SizedBox(),
            _pCell("TOTAL", pw.TextStyle(font: boldFont, color: PdfColors.grey700, fontSize: 9), align: pw.TextAlign.center),
            _pCell(billData.totalAmount.toInt().toString(), pw.TextStyle(font: boldFont, color: PdfColors.black, fontSize: 9), align: pw.TextAlign.center),
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
