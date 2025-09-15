// Data Models
class TransferItem {
  final String? imei;
  final String? serialNo;
  final String model;
  final String brand;
  final int quantity;
  final bool serialized;
  final String category;

  TransferItem({
    this.imei,
    this.serialNo,
    required this.model,
    required this.brand,
    required this.quantity,
    required this.serialized,
    required this.category,
  });

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      imei: json['imei'],
      serialNo: json['serial_no'],
      model: json['model'],
      brand: json['brand'],
      quantity: json['quantity'],
      serialized: json['serialized'],
      category: json['category'],
    );
  }

  String get identifier => imei ?? serialNo ?? 'N/A';
}

class TransferOrder {
  final String transferId;
  final String fromLocation;
  final String toLocation;
  final String assignedDate;
  final String status;
  final List<TransferItem> items;

  TransferOrder({
    required this.transferId,
    required this.fromLocation,
    required this.toLocation,
    required this.assignedDate,
    required this.status,
    required this.items,
  });

  factory TransferOrder.fromJson(Map<String, dynamic> json) {
    return TransferOrder(
      transferId: json['transfer_id'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      assignedDate: json['assigned_date'],
      status: json['status'],
      items: (json['items'] as List)
          .map((item) => TransferItem.fromJson(item))
          .toList(),
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
