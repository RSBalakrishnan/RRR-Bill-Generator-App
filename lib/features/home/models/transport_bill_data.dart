import 'package:intl/intl.dart';

class TransportServiceItem {
  String date;
  String lorryNo;
  String material;
  String challanNo;
  int trips;
  String site;
  double rate;

  TransportServiceItem({
    required this.date,
    required this.lorryNo,
    required this.material,
    required this.challanNo,
    required this.trips,
    required this.site,
    required this.rate,
  });

  double get amount => trips * rate;
}

class TransportBillData {
  String billNo;
  String billedTo;
  DateTime billDate;
  List<TransportServiceItem> items;

  TransportBillData({
    required this.billNo,
    required this.billedTo,
    required this.billDate,
    required this.items,
  });

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.amount);
  }

  int get totalTrips {
    return items.fold(0, (sum, item) => sum + item.trips);
  }

  String get formattedDate => DateFormat('dd-MM-yyyy').format(billDate);
  String get formattedTotal => 'Rs. ${NumberFormat("#,##,###").format(totalAmount.toInt())}';
}
