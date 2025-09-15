
import 'package:flutter/material.dart';
import 'package:icheck_stelacom/models/transfer_order.dart';

class OrderDetailsScreen extends StatelessWidget {
  final TransferOrder order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(order.transferId),
        actions: [
          if (order.status == 'Assigned' || order.status == 'In-Transit')
            TextButton(
              onPressed: () => _showGRNDialog(context),
              child: Text(
                'START GRN',
                style: TextStyle(
                  color: Color(0xFFFF8C00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8C00),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Transfer ID', order.transferId),
                    _buildInfoRow('From', order.fromLocation),
                    _buildInfoRow('To', order.toLocation),
                    _buildInfoRow('Assigned Date', order.assignedDate),
                    _buildInfoRow('Status', order.status),
                    _buildInfoRow('Total Items', '${order.totalItems}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Items List
            Text(
              'Items (${order.items.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            ...order.items.map((item) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFFFF8C00).withOpacity(0.1),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: Color(0xFFFF8C00),
                  ),
                ),
                title: Text(
                  item.model,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.brand} • ${item.category}'),
                    if (item.serialized) Text('ID: ${item.identifier}'),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Qty: ${item.quantity}'),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'device':
        return Icons.phone_android;
      case 'accessory':
        return Icons.cable;
      case 'laptop':
        return Icons.laptop;
      case 'projector':
        return Icons.videocam;
      case 'router':
        return Icons.router;
      default:
        return Icons.inventory;
    }
  }

  void _showGRNDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start GRN Process'),
          content: Text('Do you want to start the Good Receipt Note process for ${order.transferId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to GRN scanning screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('GRN process started for ${order.transferId}')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8C00),
              ),
              child: Text('Start GRN', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}