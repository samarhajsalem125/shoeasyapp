import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminReturnsScreen extends StatefulWidget {
  final String token;

  const AdminReturnsScreen({required this.token, Key? key}) : super(key: key);

  @override
  _AdminReturnsScreenState createState() => _AdminReturnsScreenState();
}

class _AdminReturnsScreenState extends State<AdminReturnsScreen> {
  List<dynamic> _returnsList = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _scrollController = ScrollController();

  final TextStyle _montserratStyle = GoogleFonts.montserrat();
  final TextStyle _montserratBoldStyle =
      GoogleFonts.montserrat(fontWeight: FontWeight.bold);
  final TextStyle _montserratMediumStyle =
      GoogleFonts.montserrat(fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();
    _fetchReturns();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {}

  Future<void> _fetchReturns() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/admin/returns'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _returnsList = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load returns: ${response.statusCode}');
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timeout. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReturnAction(String returnId, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $action', style: _montserratBoldStyle),
        content: Text('Are you sure you want to $action this return?', style: _montserratStyle),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: _montserratStyle)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action,
                style: _montserratStyle.copyWith(
                    color: action == 'Approve' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final endpoint = action.toLowerCase();
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/admin/returns/$returnId/$endpoint'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await _fetchReturns();
        _showSuccessSnackbar('Return $action successfully');
      } else {
        throw Exception('Failed to $action return: ${response.body}');
      }
    } on TimeoutException {
      _showErrorSnackbar('Request timeout. Please try again.');
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  Future<void> _deleteReturn(String returnId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Deletion', style: _montserratBoldStyle),
        content: Text('This action cannot be undone. Delete this return?',
            style: _montserratStyle),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: _montserratStyle)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: _montserratStyle.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/admin/returns/$returnId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await _fetchReturns();
        _showSuccessSnackbar('Return deleted successfully');
      } else {
        throw Exception('Failed to delete return: ${response.body}');
      }
    } on TimeoutException {
      _showErrorSnackbar('Request timeout. Please try again.');
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status.capitalize(),
          style: _montserratMediumStyle.copyWith(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  Widget _buildReturnItem(Map<String, dynamic> returnItem) {
    final createdAt = returnItem['createdAt'] != null
        ? DateTime.parse(returnItem['createdAt']).toLocal()
        : DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);
    final status = returnItem['status']?.toString() ?? 'Pending';
    final order = returnItem['order'];
    final user = returnItem['user'];
    final items = returnItem['items'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text('Return #${returnItem['_id']?.toString().substring(0, 8)}',
            style: _montserratBoldStyle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order != null ? 'Order #${order['orderNumber'] ?? ''}' : 'No order reference',
                style: _montserratStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            _buildStatusChip(status),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Text('Customer: ${user['name']} (${user['email']})',
                      style: _montserratStyle),
                const SizedBox(height: 8),
                Text('Date: $formattedDate', style: _montserratStyle),
                const SizedBox(height: 12),
                Text('Reason: ${returnItem['reason']}', style: _montserratStyle),
                const SizedBox(height: 12),
                Text('Items:', style: _montserratBoldStyle),
                if (items.isEmpty)
                  Text('No items found', style: _montserratStyle)
                else
                  ...items.map<Widget>((item) {
                    final shoe = item['shoe'];
                    return ListTile(
                      leading: (shoe != null && shoe['image'] != null)
                          ? Image.network(shoe['image'],
                              width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.shopping_bag),
                      title: Text(shoe?['name'] ?? 'Unknown', style: _montserratMediumStyle),
                      subtitle: Text('Qty: ${item['quantity'] ?? 1}', style: _montserratStyle),
                      trailing: Text(
                          '\$${(shoe?['price'] ?? 0).toString()}',
                          style: _montserratMediumStyle),
                    );
                  }).toList(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => _deleteReturn(returnItem['_id']),
                        child: Text('Delete', style: TextStyle(color: Colors.red))),
                    if (status.toLowerCase() == 'pending') ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _handleReturnAction(returnItem['_id'], 'Reject'),
                        child: Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handleReturnAction(returnItem['_id'], 'Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text('Approve', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('Return Management', style: _montserratBoldStyle),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchReturns),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: _montserratStyle))
              : _returnsList.isEmpty
                  ? Center(child: Text('No returns found', style: _montserratStyle))
                  : RefreshIndicator(
                      onRefresh: _fetchReturns,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _returnsList.length,
                        itemBuilder: (ctx, i) =>
                            _buildReturnItem(Map<String, dynamic>.from(_returnsList[i])),
                      ),
                    ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
}
