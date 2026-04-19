import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bill_data.dart';
import '../models/transport_bill_data.dart';
import '../services/pdf_service.dart';
import '../services/pdf_service_v2.dart';
import '../widgets/billed_to_field.dart';
import '../widgets/date_selector.dart';
import '../widgets/service_item_card.dart';
import '../widgets/transport_service_item_card.dart';
import '../widgets/generate_bill_button.dart';

enum BillTemplate { standard, transport }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billedToController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  BillTemplate _currentTemplate = BillTemplate.standard;

  // Template 1 State
  final List<ServiceItem> _standardServices = [
    ServiceItem(service: '', count: 1, amountPerLoad: 0),
  ];

  // Template 2 State
  final List<TransportServiceItem> _transportItems = [
    TransportServiceItem(
      date: '',
      lorryNo: '',
      material: '',
      challanNo: '',
      trips: 1,
      site: '',
      rate: 0,
    ),
  ];

  void _addService() {
    setState(() {
      if (_currentTemplate == BillTemplate.standard) {
        _standardServices.add(ServiceItem(service: '', count: 1, amountPerLoad: 0));
      } else {
        _transportItems.add(TransportServiceItem(
          date: '',
          lorryNo: '',
          material: '',
          challanNo: '',
          trips: 1,
          site: '',
          rate: 0,
        ));
      }
    });
  }

  void _removeService(int index) {
    setState(() {
      if (_currentTemplate == BillTemplate.standard) {
        if (_standardServices.length > 1) _standardServices.removeAt(index);
      } else {
        if (_transportItems.length > 1) _transportItems.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Bill Generator',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Standard Bill"),
                    selected: _currentTemplate == BillTemplate.standard,
                    onSelected: (val) => setState(() => _currentTemplate = BillTemplate.standard),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text("Transport Bill"),
                    selected: _currentTemplate == BillTemplate.transport,
                    onSelected: (val) => setState(() => _currentTemplate = BillTemplate.transport),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(
                "Bill Details",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Divider(color: Colors.grey.shade300),
              
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      BilledToField(
                        controller: _billedToController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DateSelector(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) => setState(() => _selectedDate = date),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                _currentTemplate == BillTemplate.standard ? 'Services' : 'Transport Entries',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Divider(color: Colors.grey.shade300),
              
              if (_currentTemplate == BillTemplate.standard)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _standardServices.length,
                  itemBuilder: (context, index) {
                    return ServiceItemCard(
                      service: _standardServices[index],
                      index: index,
                      onRemove: () => _removeService(index),
                      onAdd: _addService,
                      onNameChanged: (value) => _standardServices[index].service = value,
                      onCountChanged: (value) => _standardServices[index].count = value,
                      onAmountChanged: (value) => _standardServices[index].amountPerLoad = value,
                    );
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transportItems.length,
                  itemBuilder: (context, index) {
                    return TransportServiceItemCard(
                      item: _transportItems[index],
                      index: index,
                      onRemove: () => _removeService(index),
                      onAdd: _addService,
                      onChanged: (updatedItem) {
                        setState(() {
                          _transportItems[index] = updatedItem;
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: GenerateBillButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (_currentTemplate == BillTemplate.standard) {
                final billData = BillData(
                  billedTo: _billedToController.text,
                  date: _selectedDate,
                  services: _standardServices,
                );
                await PdfService.generateAndPreview(context, billData);
              } else {
                final transportData = TransportBillData(
                  billedTo: _billedToController.text,
                  billDate: _selectedDate,
                  items: _transportItems,
                );
                await PdfServiceV2.generateAndPreview(context, transportData);
              }
            }
          },
        ),
      ),
    );
  }
}

