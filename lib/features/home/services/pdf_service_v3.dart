import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transport_bill_data.dart';
import '../utils/number_to_words.dart';

class PdfServiceV3 {
  static const int _fixedRowCount = 10; // Fixed number of rows to fill the page

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
                      pw.SizedBox(height: 260), // Lower region to clear letterhead
                      
                      // Billed To & Date Row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.Text(billData.billedTo, style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("Date: ${billData.formattedDate}", style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 20),

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
                      _buildStaticTable(billData, mainFont),

                      pw.SizedBox(height: 20),

                      // Rupees in Words
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
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
                                ),
                              ),
                              pw.TextSpan(
                                text: NumberToWords.convert(billData.totalAmount.toInt()),
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex("#FF0000"), // Red
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      pw.Spacer(),

                      // Signature area
                      pw.Align(
                        alignment: pw.Alignment.bottomRight,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.SizedBox(height: 40),
                            pw.Text("Proprietor Sign", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 85.5),
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

  static pw.Widget _buildStaticTable(TransportBillData billData, pw.Font font) {
    const tableBorderColor = PdfColors.grey;
    final headerStyle = pw.TextStyle(
      color: PdfColors.black,
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
    );
    final cellTextStyle = pw.TextStyle(fontSize: 10);

    return pw.Table(
      border: pw.TableBorder.all(color: tableBorderColor),
      columnWidths: {
        0: const pw.FixedColumnWidth(55), // Date
        1: const pw.FixedColumnWidth(70), // Lorry No
        2: const pw.FixedColumnWidth(65), // Material
        3: const pw.FixedColumnWidth(55), // Challan
        4: const pw.FixedColumnWidth(35), // Trips
        5: const pw.FixedColumnWidth(110), // Site
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
                _pCell(item.date, cellTextStyle),
                _pCell(item.lorryNo, cellTextStyle),
                _pCell(item.material, cellTextStyle),
                _pCell(item.challanNo, cellTextStyle),
                _pCell(item.trips.toString(), cellTextStyle, align: pw.TextAlign.center),
                _pCell(item.site, cellTextStyle),
                _pCell(item.rate.toInt().toString(), cellTextStyle, align: pw.TextAlign.right),
                _pCell(item.amount.toInt().toString(), cellTextStyle, align: pw.TextAlign.right),
              ],
            );
          } else {
            // Empty rows
            return pw.TableRow(
              children: List.generate(8, (_) => pw.SizedBox(height: 20)),
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
            _pCell("${billData.totalTrips} trips", pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), align: pw.TextAlign.center),
            pw.SizedBox(),
            _pCell("TOTAL", pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold, fontSize: 10), align: pw.TextAlign.right),
            _pCell(billData.totalAmount.toInt().toString(), pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), align: pw.TextAlign.right),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pCell(String text, pw.TextStyle style, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }
}
