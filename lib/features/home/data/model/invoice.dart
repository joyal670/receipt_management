import 'package:firebase_ai/firebase_ai.dart';

class Invoice {
  String? invoiceNo;
  String? date;
  BillTo? billTo;
  BillFrom? billFrom;
  List<Items>? items;
  String? grandTotal;
  String? image; // This field exists

  Invoice({
    this.invoiceNo,
    this.date,
    this.billTo,
    this.billFrom,
    this.items,
    this.grandTotal,
    this.image, // Include in constructor
  });

  Invoice copyWith({
    String? invoiceNo,
    String? date,
    BillTo? billTo,
    BillFrom? billFrom,
    List<Items>? items,
    String? grandTotal,
    String? image, // Include in copyWith
  }) {
    return Invoice(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      billTo: billTo ?? this.billTo,
      billFrom: billFrom ?? this.billFrom,
      items: items ?? this.items,
      grandTotal: grandTotal ?? this.grandTotal,
      image: image ?? this.image, // Handle image in copyWith
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNo': invoiceNo,
      'date': date,
      'billTo': billTo?.toJson(), // Call toJson on nested objects
      'billFrom': billFrom?.toJson(), // Call toJson on nested objects
      'items': items?.map((e) => e.toJson()).toList(), // Call toJson on each item
      'grandTotal': grandTotal,
      'image': image, // Include image in toJson
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
      image: json['image'] as String?, // Include image in fromJson
    );
  }

  @override
  String toString() =>
      "Invoice(invoiceNo: $invoiceNo, date: $date, billTo: $billTo, billFrom: $billFrom, items: $items, grandTotal: $grandTotal, image: $image)"; // Include image in toString

  @override
  int get hashCode => Object.hash(invoiceNo, date, billTo, billFrom, items, grandTotal, image); // Include image in hashCode

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
          grandTotal == other.grandTotal &&
          image == other.image; // Include image in operator==
}

// Your other classes (BillTo, BillFrom) remain the same as they are self-contained.

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
  String? quantity; // Added quantity field
  String? rate;
  String? total;

  Items({this.no, this.description, this.quantity, this.rate, this.total}); // Updated constructor

  Items copyWith({int? no, String? description, String? quantity, String? rate, String? total}) {
    // Updated copyWith
    return Items(
      no: no ?? this.no,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity, // Handle quantity in copyWith
      rate: rate ?? this.rate,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'description': description,
      'quantity': quantity, // Include quantity in toJson
      'rate': rate,
      'total': total,
    };
  }

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      no: json['no'] as int?,
      description: json['description'] as String?,
      quantity: json['quantity'] as String?, // Include quantity in fromJson
      rate: json['rate'] as String?,
      total: json['total'] as String?,
    );
  }

  @override
  String toString() =>
      "Items(no: $no,description: $description,quantity: $quantity,rate: $rate,total: $total)"; // Updated toString

  @override
  int get hashCode => Object.hash(no, description, quantity, rate, total); // Updated hashCode

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Items &&
          runtimeType == other.runtimeType &&
          no == other.no &&
          description == other.description &&
          quantity == other.quantity && // Include quantity in operator==
          rate == other.rate &&
          total == other.total;
}

// The schema does not need to include 'image' because the schema is for the *extracted data*,
// not for the original source image of the invoice. The 'image' field in your Dart class
// is typically a reference (e.g., a URL to a storage bucket) to the original image itself,
// which is handled separately from the AI's data extraction process.
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
          'quantity': Schema.string(
            description: 'Quantity of the item (e.g., "2", "1.5")',
          ), // Added quantity to schema
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
