import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transport_bill_data.dart';

class TransportServiceItemCard extends StatelessWidget {
  final TransportServiceItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final Function(TransportServiceItem) onChanged;

  const TransportServiceItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onAdd,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Entry #${index + 1}",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // First Row: Date and Lorry No
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: "Date",
                    initialValue: item.date,
                    onChanged: (val) {
                      item.date = val;
                      onChanged(item);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: "Lorry No.",
                    initialValue: item.lorryNo,
                    onChanged: (val) {
                      item.lorryNo = val;
                      onChanged(item);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Second Row: Material and Challan No
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: "Material",
                    initialValue: item.material,
                    onChanged: (val) {
                      item.material = val;
                      onChanged(item);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: "Challan No.",
                    initialValue: item.challanNo,
                    onChanged: (val) {
                      item.challanNo = val;
                      onChanged(item);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Third Row: Trips and Rate
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: "Trips",
                    initialValue: item.trips.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      item.trips = int.tryParse(val) ?? 0;
                      onChanged(item);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: "Rate",
                    initialValue: item.rate.toInt().toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      item.rate = double.tryParse(val) ?? 0;
                      onChanged(item);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fourth Row: Site (Full width)
            _buildTextField(
              label: "Site",
              initialValue: item.site,
              onChanged: (val) {
                item.site = val;
                onChanged(item);
              },
            ),
            
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add Another Entry"),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}
