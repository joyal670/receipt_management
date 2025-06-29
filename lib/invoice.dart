import 'package:firebase_ai/firebase_ai.dart';

class Invoice {
  String? invoiceNo;
  String? date;
  BillTo? billTo;
  BillFrom? billFrom;
  List<Items>? items;
  String? grandTotal;

  Invoice({this.invoiceNo, this.date, this.billTo, this.billFrom, this.items, this.grandTotal});

  Invoice copyWith({
    String? invoiceNo,
    String? date,
    BillTo? billTo,
    BillFrom? billFrom,
    List<Items>? items,
    String? grandTotal,
  }) {
    return Invoice(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      billTo: billTo ?? this.billTo,
      billFrom: billFrom ?? this.billFrom,
      items: items ?? this.items,
      grandTotal: grandTotal ?? this.grandTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNo': invoiceNo,
      'date': date,
      'billTo': billTo,
      'billFrom': billFrom,
      'items': items,
      'grandTotal': grandTotal,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNo: json['invoiceNo'] as String?,
      date: json['date'] as String?,
      billTo: json['billTo'] == null
          ? null
          : BillTo.fromJson(json['billTo'] as Map<String, dynamic>),
      billFrom: json['billFrom'] == null
          ? null
          : BillFrom.fromJson(json['billFrom'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Items.fromJson(e as Map<String, dynamic>))
          .toList(),
      grandTotal: json['grandTotal'] as String?,
    );
  }

  @override
  String toString() =>
      "Invoice(invoiceNo: $invoiceNo,date: $date,billTo: $billTo,billFrom: $billFrom,items: $items,grandTotal: $grandTotal)";

  @override
  int get hashCode => Object.hash(invoiceNo, date, billTo, billFrom, items, grandTotal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice &&
          runtimeType == other.runtimeType &&
          invoiceNo == other.invoiceNo &&
          date == other.date &&
          billTo == other.billTo &&
          billFrom == other.billFrom &&
          items == other.items &&
          grandTotal == other.grandTotal;
}

class BillTo {
  String? name;
  String? address;
  String? mobile;

  BillTo({this.name, this.address, this.mobile});

  BillTo copyWith({String? name, String? address, String? mobile}) {
    return BillTo(
      name: name ?? this.name,
      address: address ?? this.address,
      mobile: mobile ?? this.mobile,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'address': address, 'mobile': mobile};
  }

  factory BillTo.fromJson(Map<String, dynamic> json) {
    return BillTo(
      name: json['name'] as String?,
      address: json['address'] as String?,
      mobile: json['mobile'] as String?,
    );
  }

  @override
  String toString() => "BillTo(name: $name,address: $address,mobile: $mobile)";

  @override
  int get hashCode => Object.hash(name, address, mobile);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillTo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          mobile == other.mobile;
}

class BillFrom {
  String? name;
  String? address;
  String? mobile;

  BillFrom({this.name, this.address, this.mobile});

  BillFrom copyWith({String? name, String? address, String? mobile}) {
    return BillFrom(
      name: name ?? this.name,
      address: address ?? this.address,
      mobile: mobile ?? this.mobile,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'address': address, 'mobile': mobile};
  }

  factory BillFrom.fromJson(Map<String, dynamic> json) {
    return BillFrom(
      name: json['name'] as String?,
      address: json['address'] as String?,
      mobile: json['mobile'] as String?,
    );
  }

  @override
  String toString() => "BillFrom(name: $name,address: $address,mobile: $mobile)";

  @override
  int get hashCode => Object.hash(name, address, mobile);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillFrom &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          mobile == other.mobile;
}

class Items {
  int? no;
  String? description;
  String? rate;
  String? total;

  Items({this.no, this.description, this.rate, this.total});

  Items copyWith({int? no, String? description, String? rate, String? total}) {
    return Items(
      no: no ?? this.no,
      description: description ?? this.description,
      rate: rate ?? this.rate,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toJson() {
    return {'no': no, 'description': description, 'rate': rate, 'total': total};
  }

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      no: json['no'] as int?,
      description: json['description'] as String?,
      rate: json['rate'] as String?,
      total: json['total'] as String?,
    );
  }

  @override
  String toString() => "Items(no: $no,description: $description,rate: $rate,total: $total)";

  @override
  int get hashCode => Object.hash(no, description, rate, total);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Items &&
          runtimeType == other.runtimeType &&
          no == other.no &&
          description == other.description &&
          rate == other.rate &&
          total == other.total;
}

final invoiceSchema = Schema.object(
  properties: {
    'invoiceNo': Schema.string(description: 'Unique invoice number'),
    'date': Schema.string(description: 'Invoice date in YYYY-MM-DD format'),
    'billTo': Schema.object(
      properties: {
        'name': Schema.string(description: 'Name of the recipient'),
        'address': Schema.string(description: 'Address of the recipient'),
        'mobile': Schema.string(description: 'Mobile number of the recipient'),
      },
      description: 'Contact details of the recipient',
    ),
    'billFrom': Schema.object(
      properties: {
        'name': Schema.string(description: 'Name of the sender'),
        'address': Schema.string(description: 'Address of the sender'),
        'mobile': Schema.string(description: 'Mobile number of the sender'),
      },
      description: 'Contact details of the sender',
    ),
    'items': Schema.array(
      description: 'List of invoice items',
      items: Schema.object(
        properties: {
          'no': Schema.integer(description: 'Item number'),
          'description': Schema.string(description: 'Description of the item'),
          'rate': Schema.string(description: 'Rate per unit (e.g., "5000.00")'),
          'total': Schema.string(description: 'Total for the item (e.g., "5000.00")'),
        },
        description: 'An individual invoice item',
      ),
    ),
    'grandTotal': Schema.string(
      description: 'Overall grand total of the invoice (e.g., "7700.00")',
    ),
  },
  description: "Schema for an Invoice object",
);
