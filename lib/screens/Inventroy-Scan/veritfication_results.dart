// import 'dart:convert';
// import 'package:icheck_stelacom/constants.dart';
// import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:icheck_stelacom/models/imei_item.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class VerificationResultsScreen extends StatefulWidget {
//   final int index;
//   final List<IMEIItem> imeiList;

//   const VerificationResultsScreen({
//     super.key,
//     required this.index,
//     required this.imeiList,
//   });

//   @override
//   _VerificationResultsScreenState createState() =>
//       _VerificationResultsScreenState();
// }

// class _VerificationResultsScreenState extends State<VerificationResultsScreen> {
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   String employeeCode = "";
//   String userData = "";

//   List<IMEIItem> imeiList = [];
//   String searchQuery = "";
//   String filterStatus = "All"; // All, Verified, Unverified

//   // Pagination variables
//   int _currentPage = 0;
//   int _rowsPerPage = 10;
//   IMEIDataSource? _dataSource;

//   @override
//   void initState() {
//     super.initState();
//     imeiList = List.from(widget.imeiList);
//     _initializeDataSource();
//     getSharedPrefs();
//   }

//   void _initializeDataSource() {
//     _dataSource = IMEIDataSource(
//       imeiList: filteredIMEIList,
//       context: context,
//       onUnverifiedAction: _showUnverifiedItemActions,
//     );
//   }

//   Future<void> getSharedPrefs() async {
//     _storage = await SharedPreferences.getInstance();
//     userData = _storage.getString('user_data') ?? "";
//     employeeCode = _storage.getString('employee_code') ?? "";

//     if (userData.isNotEmpty) {
//       try {
//         userObj = jsonDecode(userData);
//         setState(() {});
//       } catch (e) {
//         print('Error parsing user data: $e');
//       }
//     }
//   }

//   // Save updated IMEI list to storage (removed - no longer using SharedPreferences for IMEI)
//   Future<void> _saveIMEIListToStorage() async {
//     // No longer saving IMEI data to storage
//     print('IMEI list saved to memory only');
//   }

//   // SIDE MENU BAR UI
//   List<String> _menuOptions = [
//     'Help',
//     'About Us',
//     'Contact Us',
//     'T & C',
//     'Log Out'
//   ];

//   void choiceAction(String choice) {
//     if (choice == _menuOptions[0]) {
//       Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => HelpScreen(index3: widget.index)));
//     } else if (choice == _menuOptions[1]) {
//       Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => AboutUs(index3: widget.index)));
//     } else if (choice == _menuOptions[2]) {
//       Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => ContactUs(index3: widget.index)));
//     } else if (choice == _menuOptions[3]) {
//       Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => TermsAndConditions(index3: widget.index)));
//     } else if (choice == _menuOptions[4]) {
//       if (!mounted) return;
//       _storage.clear();
//       Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
//         (route) => false,
//       );
//     }
//   }

//   // Filter IMEI list based on search and status filter
//   List<IMEIItem> get filteredIMEIList {
//     List<IMEIItem> filtered = imeiList;

//     // Apply status filter
//     if (filterStatus == "Verified") {
//       filtered = filtered.where((item) => item.isVerified).toList();
//     } else if (filterStatus == "Unverified") {
//       filtered = filtered.where((item) => !item.isVerified).toList();
//     }

//     // Apply search filter
//     if (searchQuery.isNotEmpty) {
//       filtered = filtered
//           .where((item) =>
//               item.imei.toLowerCase().contains(searchQuery.toLowerCase()) ||
//               item.model.toLowerCase().contains(searchQuery.toLowerCase()))
//           .toList();
//     }

//     return filtered;
//   }

//   int get verifiedCount => imeiList.where((item) => item.isVerified).length;
//   int get totalCount => imeiList.length;

//   // Update data source when filters change
//   void _updateDataSource() {
//     setState(() {
//       _dataSource = IMEIDataSource(
//         imeiList: filteredIMEIList,
//         context: context,
//         onUnverifiedAction: _showUnverifiedItemActions,
//       );
//     });
//   }

//   // Show dialog for unverified item actions
//   void _showUnverifiedItemActions(IMEIItem item) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Unverified Item Actions'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('IMEI: ${item.imei}'),
//               Text('Model: ${item.model}'),
//               SizedBox(height: 16),
//               Text('Choose an action:',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Please scan the barcode for: ${item.model}'),
//                     backgroundColor: Colors.blue,
//                     duration: Duration(seconds: 3),
//                   ),
//                 );
//                 // _showRescanDialog(item);
//               },
//               child: Text('Rescan',
//                   style: TextStyle(
//                       color: actionBtnColor, fontWeight: FontWeight.w600)),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _showVarianceReasonDialog(item);
//               },
//               child: Text('Add Variance Reason',
//                   style: TextStyle(
//                       color: actionBtnColor, fontWeight: FontWeight.w600)),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel',
//                   style: TextStyle(
//                       color: Colors.red, fontWeight: FontWeight.w600)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Show variance reason input dialog
//   void _showVarianceReasonDialog(IMEIItem item) {
//     TextEditingController reasonController = TextEditingController();
//     String? selectedReason;

//     List<String> commonReasons = [
//       'Item damaged',
//       'Item missing',
//       'Item not in location',
//       'Barcode unreadable',
//       'Item sold out',
//       'Other'
//     ];

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: Text('Variance Reason'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('IMEI: ${item.imei}'),
//                   Text('Model: ${item.model}'),
//                   SizedBox(height: 16),
//                   Text('Select reason:',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                   SizedBox(height: 8),
//                   Container(
//                     height: 150,
//                     width: double.maxFinite,
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: commonReasons.length,
//                       itemBuilder: (context, index) {
//                         return RadioListTile<String>(
//                           activeColor: actionBtnColor,
//                           title: Text(commonReasons[index]),
//                           value: commonReasons[index],
//                           groupValue: selectedReason,
//                           onChanged: (value) {
//                             setDialogState(() {
//                               selectedReason = value;
//                               if (value != 'Other') {
//                                 reasonController.text = value!;
//                               } else {
//                                 reasonController.text = '';
//                               }
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                   if (selectedReason == 'Other')
//                     TextField(
//                       controller: reasonController,
//                       decoration: InputDecoration(
//                         hintText: 'Enter custom reason...',
//                         border: OutlineInputBorder(),
//                       ),
//                       maxLines: 2,
//                     ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text(
//                     'Cancel',
//                     style: TextStyle(color: Colors.red),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: selectedReason != null &&
//                           (selectedReason != 'Other' ||
//                               reasonController.text.trim().isNotEmpty)
//                       ? () {
//                           // Update the item with variance reason
//                           setState(() {
//                             item.varianceReason =
//                                 reasonController.text.trim().isEmpty
//                                     ? selectedReason
//                                     : reasonController.text.trim();
//                           });
//                           _saveIMEIListToStorage();
//                           _updateDataSource(); // Refresh data source
//                           Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                   'Variance reason added for ${item.model}'),
//                               backgroundColor: Colors.green,
//                             ),
//                           );
//                         }
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: actionBtnColor,
//                       foregroundColor: Colors.white),
//                   child: Text(
//                     'Submit',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     List<IMEIItem> filteredList = filteredIMEIList;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: appbarBgColor,
//         toolbarHeight: Responsive.isMobileSmall(context) ||
//                 Responsive.isMobileMedium(context) ||
//                 Responsive.isMobileLarge(context)
//             ? 40
//             : Responsive.isTabletPortrait(context)
//                 ? 80
//                 : 90,
//         automaticallyImplyLeading: false,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             SizedBox(
//               width: Responsive.isMobileSmall(context) ||
//                       Responsive.isMobileMedium(context) ||
//                       Responsive.isMobileLarge(context)
//                   ? 90.0
//                   : Responsive.isTabletPortrait(context)
//                       ? 150
//                       : 170,
//               height: Responsive.isMobileSmall(context) ||
//                       Responsive.isMobileMedium(context) ||
//                       Responsive.isMobileLarge(context)
//                   ? 40.0
//                   : Responsive.isTabletPortrait(context)
//                       ? 120
//                       : 100,
//               child: Image.asset('assets/images/iCheck_logo_2024.png',
//                   fit: BoxFit.contain),
//             ),
//             SizedBox(width: size.width * 0.25),
//             SizedBox(
//               width: Responsive.isMobileSmall(context) ||
//                       Responsive.isMobileMedium(context) ||
//                       Responsive.isMobileLarge(context)
//                   ? 90.0
//                   : Responsive.isTabletPortrait(context)
//                       ? 150
//                       : 170,
//               height: Responsive.isMobileSmall(context) ||
//                       Responsive.isMobileMedium(context) ||
//                       Responsive.isMobileLarge(context)
//                   ? 40.0
//                   : Responsive.isTabletPortrait(context)
//                       ? 120
//                       : 100,
//               child: userObj != null && userObj!['CompanyProfileImage'] != null
//                   ? CachedNetworkImage(
//                       imageUrl: userObj!['CompanyProfileImage'],
//                       placeholder: (context, url) => Text("..."),
//                       errorWidget: (context, url, error) => Icon(Icons.error),
//                     )
//                   : Text(""),
//             ),
//           ],
//         ),
//         actions: <Widget>[
//           PopupMenuButton<String>(
//             onSelected: choiceAction,
//             itemBuilder: (BuildContext context) {
//               return _menuOptions.map((String choice) {
//                 return PopupMenuItem<String>(
//                   value: choice,
//                   child: Text(choice,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontSize: Responsive.isMobileSmall(context)
//                             ? 15
//                             : Responsive.isMobileMedium(context) ||
//                                     Responsive.isMobileLarge(context)
//                                 ? 17
//                                 : Responsive.isTabletPortrait(context)
//                                     ? size.width * 0.025
//                                     : size.width * 0.018,
//                       )),
//                 );
//               }).toList();
//             },
//           )
//         ],
//       ),
//       backgroundColor: Colors.grey[50],
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(30),
//                   bottomRight: Radius.circular(30),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     spreadRadius: 2,
//                     blurRadius: 10,
//                     offset: Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.arrow_back,
//                         color: screenHeadingColor,
//                         size: Responsive.isMobileSmall(context)
//                             ? 20
//                             : Responsive.isMobileMedium(context) ||
//                                     Responsive.isMobileLarge(context)
//                                 ? 24
//                                 : Responsive.isTabletPortrait(context)
//                                     ? 31
//                                     : 35),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                   Expanded(
//                     flex: 6,
//                     child: Text(
//                       "Verification Results",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: screenHeadingColor,
//                         fontSize: Responsive.isMobileSmall(context)
//                             ? 22
//                             : Responsive.isMobileMedium(context) ||
//                                     Responsive.isMobileLarge(context)
//                                 ? 25
//                                 : Responsive.isTabletPortrait(context)
//                                     ? 28
//                                     : 32,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   Expanded(flex: 1, child: Text("")),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10),

//             // Summary Cards
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 15),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Card(
//                       color: Colors.white,
//                       elevation: 2,
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           children: [
//                             Icon(Icons.check_circle,
//                                 color: Colors.green, size: 24),
//                             SizedBox(height: 8),
//                             Text('$verifiedCount',
//                                 style: TextStyle(
//                                     fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Verified', style: TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Card(
//                       color: Colors.white,
//                       elevation: 2,
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           children: [
//                             Icon(Icons.cancel, color: Colors.red, size: 24),
//                             SizedBox(height: 8),
//                             Text('${totalCount - verifiedCount}',
//                                 style: TextStyle(
//                                     fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Unverified', style: TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Card(
//                       color: Colors.white,
//                       elevation: 2,
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           children: [
//                             Icon(Icons.inventory, color: Colors.grey, size: 24),
//                             SizedBox(height: 8),
//                             Text('$totalCount',
//                                 style: TextStyle(
//                                     fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Total', style: TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),

//             // Search and Filter
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 15),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 5,
//                     child: TextField(
//                       onChanged: (value) {
//                         setState(() {
//                           searchQuery = value;
//                         });
//                         _updateDataSource();
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Search IMEI or Model...',
//                         hintStyle: TextStyle(fontSize: 15),
//                         prefixIcon: Icon(Icons.search),
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     flex: 3,
//                     child: DropdownButtonFormField<String>(
//                       value: filterStatus,
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       items:
//                           ['All', 'Verified', 'Unverified'].map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(
//                             value,
//                             style: TextStyle(fontSize: 15),
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           filterStatus = value!;
//                         });
//                         _updateDataSource();
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),

//             // DataTable with Pagination
//             Expanded(
//               child: Container(
//                 margin: EdgeInsets.symmetric(horizontal: 15),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: filteredList.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.search_off,
//                                 size: 64, color: Colors.grey),
//                             SizedBox(height: 16),
//                             Text('No items found',
//                                 style: TextStyle(
//                                     fontSize: 18, color: Colors.grey)),
//                           ],
//                         ),
//                       )
//                     : Column(
//                         children: [
//                           // Rows per page selector
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 8),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text('Results: ${filteredList.length}',
//                                     style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500)),
//                                 Row(
//                                   children: [
//                                     Text('Rows per page: ',
//                                         style: TextStyle(fontSize: 14)),
//                                     DropdownButton<int>(
//                                       value: _rowsPerPage,
//                                       underline: SizedBox(),
//                                       items: [5, 10, 25, 50].map((int value) {
//                                         return DropdownMenuItem<int>(
//                                           value: value,
//                                           child: Text(value.toString()),
//                                         );
//                                       }).toList(),
//                                       onChanged: (value) {
//                                         setState(() {
//                                           _rowsPerPage = value!;
//                                           _currentPage =
//                                               0; // Reset to first page
//                                         });
//                                         _updateDataSource();
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Divider(height: 1),

//                           // DataTable
//                           Expanded(
//                             child: _dataSource != null
//                                 ? SingleChildScrollView(
//                                     child: PaginatedDataTable(
//                                       header: null,
//                                       headingRowColor: WidgetStatePropertyAll(
//                                           Colors.grey[100]),
//                                       columns: [
//                                         DataColumn(
//                                           label: Text('IMEI',
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13)),
//                                         ),
//                                         DataColumn(
//                                           label: Text('Device\nModel',
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13)),
//                                         ),
//                                         DataColumn(
//                                           label: Text('Verify\nStatus',
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13)),
//                                         ),
//                                         DataColumn(
//                                           label: Text('Action',
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 13)),
//                                         ),
//                                       ],
//                                       source: _dataSource!,
//                                       rowsPerPage: _rowsPerPage,
//                                       showCheckboxColumn: false,
//                                       columnSpacing: 20,
//                                       horizontalMargin: 10,
//                                       showFirstLastButtons: true,
//                                     ),
//                                   )
//                                 : Center(
//                                     child: CircularProgressIndicator(),
//                                   ),
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//             SizedBox(height: 20),

//             // Action Buttons
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 15),
//               child: Column(
//                 children: [
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // Generate and submit report
//                         // _showSubmissionDialog();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: actionBtnColor,
//                         padding: EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: Text('Submit Verification Report',
//                           style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSubmissionDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Submit Verification Report'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Summary:'),
//               SizedBox(height: 8),
//               Text('• Verified: $verifiedCount items'),
//               Text('• Unverified: ${totalCount - verifiedCount} items'),
//               Text('• Total: $totalCount items'),
//               SizedBox(height: 16),
//               Text('Are you sure you want to submit this verification report?'),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 // Save final report
//                 _saveIMEIListToStorage();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content:
//                         Text('Verification report submitted successfully!'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//                 // Navigate back to main screen or dashboard
//                 Navigator.popUntil(context, (route) => route.isFirst);
//               },
//               child: Text('Submit'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// // DataSource class for PaginatedDataTable
// class IMEIDataSource extends DataTableSource {
//   final List<IMEIItem> imeiList;
//   final BuildContext context;
//   final Function(IMEIItem) onUnverifiedAction;

//   IMEIDataSource({
//     required this.imeiList,
//     required this.context,
//     required this.onUnverifiedAction,
//   });

//   @override
//   DataRow? getRow(int index) {
//     if (index >= imeiList.length) return null;
//     final item = imeiList[index];

//     return DataRow(
//       cells: [
//         // IMEI Cell
//         DataCell(
//           Container(
//             width: 80,
//             child: Text(
//               item.imei,
//               style: TextStyle(
//                 fontFamily: 'monospace',
//                 fontSize: 10,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ),

//         // Device Model Cell - 2 lines default
//         DataCell(
//           Container(
//             width: 75,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   item.model,
//                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 // if (item.varianceReason != null) ...[
//                 //   SizedBox(height: 4),
//                 //   Text(
//                 //     'Reason: ${item.varianceReason}',
//                 //     style: TextStyle(
//                 //       fontSize: 9,
//                 //       color: Colors.grey[600],
//                 //       fontStyle: FontStyle.italic,
//                 //     ),
//                 //     maxLines: 3,
//                 //     overflow: TextOverflow.ellipsis,
//                 //   ),
//                 // ],
//               ],
//             ),
//           ),
//         ),

//         // Status Cell
//         DataCell(
//           Container(
//             width: 50,
//             child: Center(
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: item.isVerified
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.red.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       item.isVerified ? Icons.check_circle : Icons.cancel,
//                       color: item.isVerified ? Colors.green : Colors.red,
//                       size: 16,
//                     ),
//                     // SizedBox(width: 4),
//                     // Text(
//                     //   item.isVerified ? 'Verified' : 'Unverified',
//                     //   style: TextStyle(
//                     //     fontSize: 10,
//                     //     fontWeight: FontWeight.w500,
//                     //     color: item.isVerified ? Colors.green : Colors.red,
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),

//         // Action/Time Cell
//         DataCell(
//           Container(
//             width: 50,
//             child: Center(
//               // child: !item.isVerified
//               //     ? IconButton(
//               //         icon: Icon(Icons.edit_document,
//               //             color: Colors.grey[400], size: 20),
//               //         onPressed: () => onUnverifiedAction(item),
//               //         padding: EdgeInsets.all(4),
//               //         constraints: BoxConstraints(
//               //           minWidth: 32,
//               //           minHeight: 32,
//               //         ),
//               //       )
//               //     : item.verificationTime != null
//               //         ? Column(
//               //             mainAxisAlignment: MainAxisAlignment.center,
//               //             children: [
//               //               Icon(Icons.access_time,
//               //                   size: 14, color: Colors.grey[600]),
//               //               SizedBox(height: 2),
//               //               Text(
//               //                 '${item.verificationTime!.hour.toString().padLeft(2, '0')}:${item.verificationTime!.minute.toString().padLeft(2, '0')}',
//               //                 style: TextStyle(
//               //                   fontSize: 9,
//               //                   color: Colors.grey[600],
//               //                 ),
//               //               ),
//               //             ],
//               //           )
//               //         : Text('-',
//               //             style:
//               //                 TextStyle(fontSize: 10, color: Colors.grey[600])),
//               child: !item.isVerified
//                   ? item.varianceReason != null
//                       // If unverified item has variance reason, show only the reason
//                       ? Text(
//                           '${item.varianceReason}',
//                           style: TextStyle(
//                             fontSize: 9,
//                             color: Colors.grey,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 3,
//                           overflow: TextOverflow.ellipsis,
//                           textAlign: TextAlign.center,
//                         )
//                       // If unverified item has no variance reason, show edit button
//                       : IconButton(
//                           icon: Icon(Icons.edit_document,
//                               color: Colors.grey[400], size: 20),
//                           onPressed: () => onUnverifiedAction(item),
//                           padding: EdgeInsets.all(4),
//                           constraints: BoxConstraints(
//                             minWidth: 32,
//                             minHeight: 32,
//                           ),
//                         )
//                   : item.verificationTime != null
//                       ? Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.access_time,
//                                 size: 14, color: Colors.grey[600]),
//                             SizedBox(height: 2),
//                             Text(
//                               '${item.verificationTime!.hour.toString().padLeft(2, '0')}:${item.verificationTime!.minute.toString().padLeft(2, '0')}',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         )
//                       : Text('-',
//                           style:
//                               TextStyle(fontSize: 10, color: Colors.grey[600])),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   bool get isRowCountApproximate => false;

//   @override
//   int get rowCount => imeiList.length;

//   @override
//   int get selectedRowCount => 0;
// }

import 'dart:convert';
import 'package:icheck_stelacom/constants.dart';
import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
import 'package:icheck_stelacom/screens/menu/about_us.dart';
import 'package:icheck_stelacom/screens/menu/contact_us.dart';
import 'package:icheck_stelacom/screens/menu/help.dart';
import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:icheck_stelacom/models/imei_item.dart';
import 'package:icheck_stelacom/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationResultsScreen extends StatefulWidget {
  final int index;
  final List<IMEIItem> imeiList;

  const VerificationResultsScreen({
    super.key,
    required this.index,
    required this.imeiList,
  });

  @override
  _VerificationResultsScreenState createState() =>
      _VerificationResultsScreenState();
}

class _VerificationResultsScreenState extends State<VerificationResultsScreen> {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";

  List<IMEIItem> imeiList = [];
  String searchQuery = "";
  String filterStatus = "All"; // All, Verified, Unverified

  // Pagination variables
  int _currentPage = 0;
  int _rowsPerPage = 10;
  IMEIDataSource? _dataSource;

  @override
  void initState() {
    super.initState();
    imeiList = List.from(widget.imeiList);
    _initializeDataSource();
    getSharedPrefs();
  }

  void _initializeDataSource() {
    _dataSource = IMEIDataSource(
      imeiList: filteredIMEIList,
      context: context,
      onUnverifiedAction: _showUnverifiedItemActions,
    );
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
    userData = _storage.getString('user_data') ?? "";
    employeeCode = _storage.getString('employee_code') ?? "";

    if (userData.isNotEmpty) {
      try {
        userObj = jsonDecode(userData);
        setState(() {});
      } catch (e) {
        print('Error parsing user data: $e');
      }
      print(_currentPage);
    }
  }

  // Save updated IMEI list to storage (removed - no longer using SharedPreferences for IMEI)
  Future<void> _saveIMEIListToStorage() async {
    // No longer saving IMEI data to storage
    print('IMEI list saved to memory only');
  }

  // SIDE MENU BAR UI
  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out'
  ];

  void choiceAction(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HelpScreen(index3: widget.index)));
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AboutUs(index3: widget.index)));
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ContactUs(index3: widget.index)));
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TermsAndConditions(index3: widget.index)));
    } else if (choice == _menuOptions[4]) {
      if (!mounted) return;
      _storage.clear();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
        (route) => false,
      );
    }
  }

  // Filter IMEI list based on search and status filter
  List<IMEIItem> get filteredIMEIList {
    List<IMEIItem> filtered = imeiList;

    // Apply status filter
    if (filterStatus == "Verified") {
      filtered = filtered.where((item) => item.isVerified).toList();
    } else if (filterStatus == "Unverified") {
      filtered = filtered.where((item) => !item.isVerified).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.imei.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.model.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  int get verifiedCount => imeiList.where((item) => item.isVerified).length;
  int get totalCount => imeiList.length;
  bool get allItemsVerified => verifiedCount == totalCount;

  // Update data source when filters change
  void _updateDataSource() {
    setState(() {
      _dataSource = IMEIDataSource(
        imeiList: filteredIMEIList,
        context: context,
        onUnverifiedAction: _showUnverifiedItemActions,
      );
    });
  }

  // Show dialog for unverified item actions
  void _showUnverifiedItemActions(IMEIItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unverified Item Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IMEI: ${item.imei}'),
              Text('Model: ${item.model}'),
              SizedBox(height: 16),
              Text('Choose an action:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please scan the barcode for: ${item.model}'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 3),
                  ),
                );
                // _showRescanDialog(item);
              },
              child: Text('Rescan',
                  style: TextStyle(
                      color: actionBtnColor, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showVarianceReasonDialog(item);
              },
              child: Text('Add Variance Reason',
                  style: TextStyle(
                      color: actionBtnColor, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  // Show variance reason input dialog
  void _showVarianceReasonDialog(IMEIItem item) {
    TextEditingController reasonController = TextEditingController();
    String? selectedReason;

    List<String> commonReasons = [
      'Item damaged',
      'Item missing',
      'Item not in location',
      'Barcode unreadable',
      'Item sold out',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Variance Reason'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IMEI: ${item.imei}'),
                  Text('Model: ${item.model}'),
                  SizedBox(height: 16),
                  Text('Select reason:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: commonReasons.length,
                      itemBuilder: (context, index) {
                        return RadioListTile<String>(
                          activeColor: actionBtnColor,
                          title: Text(commonReasons[index]),
                          value: commonReasons[index],
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedReason = value;
                              if (value != 'Other') {
                                reasonController.text = value!;
                              } else {
                                reasonController.text = '';
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  if (selectedReason == 'Other')
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        hintText: 'Enter custom reason...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason != null &&
                          (selectedReason != 'Other' ||
                              reasonController.text.trim().isNotEmpty)
                      ? () {
                          // Update the item with variance reason and mark as verified
                          setState(() {
                            item.varianceReason =
                                reasonController.text.trim().isEmpty
                                    ? selectedReason
                                    : reasonController.text.trim();
                            // Mark item as verified when variance reason is added
                            item.isVerified = true;
                            // Set verification time to current time
                            item.verificationTime = DateTime.now();
                          });
                          _saveIMEIListToStorage();
                          _updateDataSource(); // Refresh data source
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Variance reason added and item verified for ${item.model}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: actionBtnColor,
                      foregroundColor: Colors.white),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<IMEIItem> filteredList = filteredIMEIList;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appbarBgColor,
        toolbarHeight: Responsive.isMobileSmall(context) ||
                Responsive.isMobileMedium(context) ||
                Responsive.isMobileLarge(context)
            ? 40
            : Responsive.isTabletPortrait(context)
                ? 80
                : 90,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 90.0
                  : Responsive.isTabletPortrait(context)
                      ? 150
                      : 170,
              height: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 40.0
                  : Responsive.isTabletPortrait(context)
                      ? 120
                      : 100,
              child: Image.asset('assets/images/iCheck_logo_2024.png',
                  fit: BoxFit.contain),
            ),
            SizedBox(width: size.width * 0.25),
            SizedBox(
              width: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 90.0
                  : Responsive.isTabletPortrait(context)
                      ? 150
                      : 170,
              height: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 40.0
                  : Responsive.isTabletPortrait(context)
                      ? 120
                      : 100,
              child: userObj != null && userObj!['CompanyProfileImage'] != null
                  ? CachedNetworkImage(
                      imageUrl: userObj!['CompanyProfileImage'],
                      placeholder: (context, url) => Text("..."),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Text(""),
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: choiceAction,
            itemBuilder: (BuildContext context) {
              return _menuOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 15
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 17
                                : Responsive.isTabletPortrait(context)
                                    ? size.width * 0.025
                                    : size.width * 0.018,
                      )),
                );
              }).toList();
            },
          )
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: screenHeadingColor,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 24
                                : Responsive.isTabletPortrait(context)
                                    ? 31
                                    : 35),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      "Verification Results",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: screenHeadingColor,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 22
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 25
                                : Responsive.isTabletPortrait(context)
                                    ? 28
                                    : 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(flex: 1, child: Text("")),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Summary Cards
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                            SizedBox(height: 8),
                            Text('$verifiedCount',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Verified', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 24),
                            SizedBox(height: 8),
                            Text('${totalCount - verifiedCount}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Unverified', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.inventory, color: Colors.grey, size: 24),
                            SizedBox(height: 8),
                            Text('$totalCount',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Total', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Search and Filter
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        _updateDataSource();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search IMEI or Model...',
                        hintStyle: TextStyle(fontSize: 15),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: filterStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items:
                          ['All', 'Verified', 'Unverified'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontSize: 15),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          filterStatus = value!;
                        });
                        _updateDataSource();
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // DataTable with Pagination
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No items found',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Rows per page selector
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Results: ${filteredList.length}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                Row(
                                  children: [
                                    Text('Rows per page: ',
                                        style: TextStyle(fontSize: 14)),
                                    DropdownButton<int>(
                                      value: _rowsPerPage,
                                      underline: SizedBox(),
                                      items: [5, 10, 25, 50].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(value.toString()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _rowsPerPage = value!;
                                          _currentPage =
                                              0; // Reset to first page
                                        });
                                        _updateDataSource();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1),

                          // DataTable
                          Expanded(
                            child: _dataSource != null
                                ? SingleChildScrollView(
                                    child: PaginatedDataTable(
                                      header: null,
                                      headingRowColor: WidgetStatePropertyAll(
                                          Colors.grey[100]),
                                      columns: [
                                        DataColumn(
                                          label: Text('IMEI',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                        ),
                                        DataColumn(
                                          label: Text('Device\nModel',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                        ),
                                        DataColumn(
                                          label: Text('Verify\nStatus',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                        ),
                                        DataColumn(
                                          label: Text('Action',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                        ),
                                      ],
                                      source: _dataSource!,
                                      rowsPerPage: _rowsPerPage,
                                      showCheckboxColumn: false,
                                      columnSpacing: 20,
                                      horizontalMargin: 10,
                                      showFirstLastButtons: true,
                                    ),
                                  )
                                : Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: allItemsVerified
                          ? () {
                              _showSubmissionDialog();
                            }
                          : null, // Disabled when not all items are verified
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            allItemsVerified ? actionBtnColor : Colors.grey,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          allItemsVerified
                              ? 'Submit Verification Report'
                              : 'Submit Verification Report (${totalCount - verifiedCount} items pending)',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showSubmissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Submit Verification Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary:'),
              SizedBox(height: 8),
              Text('• Verified: $verifiedCount items'),
              Text('• Unverified: ${totalCount - verifiedCount} items'),
              Text('• Total: $totalCount items'),
              SizedBox(height: 16),
              Text('Are you sure you want to submit this verification report?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Save final report
                _saveIMEIListToStorage();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Verification report submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Navigate back to main screen or dashboard
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: actionBtnColor,
                  foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }
}

// DataSource class for PaginatedDataTable
class IMEIDataSource extends DataTableSource {
  final List<IMEIItem> imeiList;
  final BuildContext context;
  final Function(IMEIItem) onUnverifiedAction;

  IMEIDataSource({
    required this.imeiList,
    required this.context,
    required this.onUnverifiedAction,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= imeiList.length) return null;
    final item = imeiList[index];

    return DataRow(
      cells: [
        // IMEI Cell
        DataCell(
          Container(
            width: 80,
            child: Text(
              item.imei,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Device Model Cell - 2 lines default
        DataCell(
          Container(
            width: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.model,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Status Cell
        DataCell(
          Container(
            width: 50,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isVerified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isVerified ? Icons.check_circle : Icons.cancel,
                      color: item.isVerified ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action/Time Cell
        DataCell(
          Container(
            width: 50,
            child: Center(
              child: !item.isVerified
                  ? item.varianceReason != null
                      // If unverified item has variance reason, show only the reason (this shouldn't happen now)
                      ? Text(
                          '${item.varianceReason}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        )
                      // If unverified item has no variance reason, show edit button
                      : IconButton(
                          icon: Icon(Icons.edit_document,
                              color: Colors.grey[400], size: 20),
                          onPressed: () => onUnverifiedAction(item),
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        )
                  : item.varianceReason != null
                      // If verified item has variance reason, show the reason
                      ? Text(
                          '${item.varianceReason}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        )
                      // If verified item has no variance reason, show verification time
                      : item.verificationTime != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey[600]),
                                SizedBox(height: 2),
                                Text(
                                  '${item.verificationTime!.hour.toString().padLeft(2, '0')}:${item.verificationTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            )
                          : Text('-',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => imeiList.length;

  @override
  int get selectedRowCount => 0;
}
