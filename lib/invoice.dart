class Invoice {
  String invoiceNo;
  String date;

  Contact billTo;
  Contact billFrom;

  List<InvoiceItem> items;
  String grandTotal;

  Invoice({
    required this.invoiceNo,
    required this.date,
    required this.billTo,
    required this.billFrom,
    required this.items,
    required this.grandTotal,
  });
}

class Contact {
  String name;
  String address;
  String mobile;

  Contact({required this.name, required this.address, required this.mobile});
}

class InvoiceItem {
  int no;
  String description;
  String rate;
  String total;

  InvoiceItem({
    required this.no,
    required this.description,
    required this.rate,
    required this.total,
  });
}
