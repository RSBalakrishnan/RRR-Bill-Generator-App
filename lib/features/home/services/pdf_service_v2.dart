import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transport_bill_data.dart';
import '../utils/number_to_words.dart';

class PdfServiceV2 {
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
                      pw.SizedBox(height: 180), // Adjust to clear letterhead
                      
                      // Billed To & Date Row
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("To:", style: pw.TextStyle(font: boldFont, color: PdfColors.grey700, fontSize: 10)),
                              pw.Text(billData.billedTo, style: pw.TextStyle(font: mainFont, color: PdfColors.grey700, fontSize: 12)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("Date: ${billData.formattedDate}", style: pw.TextStyle(font: mainFont, color: PdfColors.grey700, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 20),

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
                                  font: boldFont,
                                  color: PdfColors.grey700,
                                  fontSize: 10,
                                ),
                              ),
                              pw.TextSpan(
                                text: NumberToWords.convert(billData.totalAmount.toInt()),
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

                      pw.Spacer(),

                      // Signature area
                      pw.Align(
                        alignment: pw.Alignment.bottomRight,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              "Rajamani Transport",
                              style: pw.TextStyle(
                                font: boldFont,
                                color: PdfColors.black,
                                fontSize: 14,
                              ),
                            ),
                             pw.SizedBox(height: 40),
                            pw.Text("Proprietor Sign", style: pw.TextStyle(font: boldFont, color: PdfColors.grey700, fontSize: 12)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 20), // Lowered from 40
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

  static pw.Widget _buildTable(TransportBillData billData, pw.Font mainFont, pw.Font boldFont) {
    const tableBorderColor = PdfColors.grey;
    final headerStyle = pw.TextStyle(
      font: boldFont,
      color: PdfColors.black,
      fontSize: 10,
    );
    final cellTextStyle = pw.TextStyle(font: mainFont, color: PdfColors.black, fontSize: 10);

    return pw.Table(
      border: pw.TableBorder.all(color: tableBorderColor),
      columnWidths: {
        0: const pw.FixedColumnWidth(55), // Date
        1: const pw.FixedColumnWidth(85), // Lorry No (Increased)
        2: const pw.FixedColumnWidth(60), // Material
        3: const pw.FixedColumnWidth(55), // Challan
        4: const pw.FixedColumnWidth(35), // Trips
        5: const pw.FixedColumnWidth(100), // Site
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
        // Rows
        ...billData.items.map((item) => pw.TableRow(
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
        )),
        // Footer (Summary)
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            _pCell("${billData.totalTrips} trips", pw.TextStyle(font: boldFont, fontSize: 10), align: pw.TextAlign.center),
            pw.SizedBox(),
            _pCell("TOTAL", pw.TextStyle(font: boldFont, color: PdfColors.grey700, fontSize: 10), align: pw.TextAlign.right),
            _pCell(billData.totalAmount.toInt().toString(), pw.TextStyle(font: boldFont, color: PdfColors.black, fontSize: 10), align: pw.TextAlign.right),
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
