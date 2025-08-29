// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:icheck_stelacom/models/scanned_item.dart';
// import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/api_verification_screen.dart';
// import 'package:icheck_stelacom/constants.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class IMEISelectionScreen extends StatefulWidget {
//   final int index;
//   // final List<Map<String, dynamic>> imeiList;
//   final List<ScannedItem> scannedItems;

//   const IMEISelectionScreen(
//       {super.key,
//       required this.index,
//       // required this.imeiList,
//       required this.scannedItems});

//   @override
//   _IMEISelectionScreenState createState() => _IMEISelectionScreenState();
// }

// class _IMEISelectionScreenState extends State<IMEISelectionScreen> {
//   int? selectedIMEI;
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   List<ScannedItem> filteredItems = [];
//   String userData = "";
//   String? selectedBarcode;

//   @override
//   void initState() {
//     super.initState();
//     filteredItems = List.from(
//         widget.scannedItems); // Create a copy to avoid reference issues
//     print('Filtered items count: ${filteredItems.length}'); // Debug print
//     getSharedPrefs();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> getSharedPrefs() async {
//     _storage = await SharedPreferences.getInstance();
//     userData = _storage.getString('user_data')!;

//     userObj = jsonDecode(userData);
//   }

// // Convert ScannedItem to display format
//   Map<String, dynamic> _getItemDisplayData(ScannedItem item, int index) {
//     return {
//       'imei': item.imei,
//       'model': item.deviceModel ?? 'Unknown Device',
//       'status': _getItemStatus(item),
//       'barcode': item.barcode,
//       'timestamp': item.timestamp,
//       'originalItem': item,
//     };
//   }

//   String _getItemStatus(ScannedItem item) {
//     // Simulate API status check based on IMEI
//     final List<String> statuses = [
//       'In Stock',
//       'Reserved',
//       'Available',
//       'Pending'
//     ];
//     return statuses[item.imei.hashCode.abs() % statuses.length];
//   }

//   void _onItemSelected(int index) {
//     // Add bounds checking
//     if (index >= 0 && index < filteredItems.length) {
//       setState(() {
//         selectedIMEI = index;
//         selectedBarcode = filteredItems[index].barcode;
//       });
//       print('Selected index: $index, barcode: $selectedBarcode'); // Debug print
//     } else {
//       print(
//           'Error: Index $index is out of bounds for list of length ${filteredItems.length}');
//     }
//   }

//   // SIDE MENU BAR UI
//   List<String> _menuOptions = [
//     'Help',
//     'About Us',
//     'Contact Us',
//     'T & C',
//     'Log Out'
//   ];

//   // --------- Side Menu Bar Navigation ---------- //
//   void choiceAction(String choice) {
//     if (choice == _menuOptions[0]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return HelpScreen(
//             index3: widget.index,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[1]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return AboutUs(
//             index3: widget.index,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[2]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return ContactUs(
//             index3: widget.index,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[3]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return TermsAndConditions(
//             index3: widget.index,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[4]) {
//       if (!mounted)
//         return;
//       else {
//         _storage.clear();
//         Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
//           (route) => false,
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
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
//             // --------- App Logo ---------- //
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
//               child: Image.asset(
//                 'assets/images/iCheck_logo_2024.png',
//                 fit: BoxFit.contain,
//               ),
//             ),
//             SizedBox(width: size.width * 0.25),
//             // --------- Company Logo ---------- //
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
//               child: userObj != null
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
//                   child: Text(
//                     choice,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontSize: Responsive.isMobileSmall(context)
//                           ? 15
//                           : Responsive.isMobileMedium(context) ||
//                                   Responsive.isMobileLarge(context)
//                               ? 17
//                               : Responsive.isTabletPortrait(context)
//                                   ? size.width * 0.025
//                                   : size.width * 0.018,
//                     ),
//                   ),
//                 );
//               }).toList();
//             },
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
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
//                     icon: Icon(
//                       Icons.arrow_back,
//                       color: screenHeadingColor,
//                       size: Responsive.isMobileSmall(context)
//                           ? 20
//                           : Responsive.isMobileMedium(context) ||
//                                   Responsive.isMobileLarge(context)
//                               ? 24
//                               : Responsive.isTabletPortrait(context)
//                                   ? 31
//                                   : 35,
//                     ),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                   Expanded(
//                     flex: 6,
//                     child: Text(
//                       "IMEI Selection",
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
//                   Expanded(
//                     flex: 1,
//                     child: Text(""),
//                   )
//                 ],
//               ),
//             ),
//             Container(
//               height: size.height * 0.7,
//               child: Padding(
//                 padding: EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // Instruction
//                     Text(
//                       'Multiple IMEI numbers found for scanned barcode.\nPlease select the correct one:',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                     ),
//                     SizedBox(height: 30),

//                     // IMEI List
//                     Expanded(
//                       child: Container(
//                         height: 200,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 10,
//                               offset: Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         padding: EdgeInsets.all(12),
//                         child: ListView.builder(
//                           itemCount: filteredItems.length,
//                           itemBuilder: (context, index) {
                            
//                             final itemData =
//                                 _getItemDisplayData(filteredItems[index], index);
//                             return GestureDetector(
//                               onTap: () => _onItemSelected(index),
//                               child: Container(
//                                 margin: EdgeInsets.only(
//                                     bottom: index == filteredItems.length - 1
//                                         ? 0
//                                         : 15),
//                                 padding: EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: selectedIMEI == index
//                                       ? Colors.orange.withOpacity(0.1)
//                                       : Colors.transparent,
//                                   borderRadius: BorderRadius.circular(10),
//                                   border: selectedIMEI == index
//                                       ? Border.all(color: Colors.orange)
//                                       : Border.all(
//                                           color: Colors.grey[200]!, width: 1),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Radio<int>(
//                                       value: index,
//                                       groupValue: selectedIMEI,
//                                       onChanged: (value) => value != null
//                                           ? _onItemSelected(value)
//                                           : null,
//                                       activeColor: Colors.orange,
//                                     ),
//                                     SizedBox(width: 15),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             'IMEI: ${itemData['imei']}',
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 16),
//                                           ),
//                                           // SizedBox(height: 5),
//                                           // Text(
//                                           //   'Model: ${widget.imeiList[index]['model']} | Status: ${widget.imeiList[index]['status']}',
//                                           //   style: TextStyle(
//                                           //       color: Colors.grey[600],
//                                           //       fontSize: 14),
//                                           // ),
//                                           Container(
//                                             padding: EdgeInsets.symmetric(
//                                                 horizontal: 8, vertical: 2),
//                                             decoration: BoxDecoration(
//                                               color: _getStatusColor(
//                                                   itemData['status']),
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                             child: Text(
//                                               itemData['status'],
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 10,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     SizedBox(height: 6),
//                                     Text(
//                                       'Model: ${itemData['model']}',
//                                       style: TextStyle(
//                                           color: Colors.grey[600], fontSize: 13),
//                                     ),
//                                     SizedBox(height: 4),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.qr_code,
//                                             size: 14, color: Colors.grey[500]),
//                                         SizedBox(width: 4),
//                                         Text(
//                                           'Barcode: ${itemData['barcode']}',
//                                           style: TextStyle(
//                                               color: Colors.grey[500],
//                                               fontSize: 11),
//                                         ),
//                                         Spacer(),
//                                         Icon(Icons.access_time,
//                                             size: 12, color: Colors.grey[400]),
//                                         SizedBox(width: 2),
//                                         Text(
//                                           _formatScanTime(itemData['timestamp']),
//                                           style: TextStyle(
//                                               color: Colors.grey[400],
//                                               fontSize: 11),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 30),

//                     // Buttons
//                     _buildButton(
//                       'Confirm Selection',
//                       Colors.orange,
//                       Icons.check_circle,
//                       selectedIMEI != null
//                           ? () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => APIVerificationScreen(
//                                           index: widget.index,
//                                         )),
//                               )
//                           : null,
//                     ),
//                     SizedBox(height: 15),
//                     _buildButton(
//                       'Back to Scanner',
//                       actionBtnColor,
//                       Icons.center_focus_strong,
//                       () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'in stock':
//       case 'available':
//         return Colors.green;
//       case 'reserved':
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.blue;
//     }
//   }

//   String _formatScanTime(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);

//     if (difference.inMinutes < 1) {
//       return 'Just now';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
//     }
//   }

//   Widget _buildButton(
//       String text, Color color, IconData icon, VoidCallback? onPressed) {
//     return Container(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: onPressed != null ? color : Colors.grey[300],
//           foregroundColor: onPressed != null
//               ? (color == Colors.grey ? Colors.grey[600] : Colors.white)
//               : Colors.grey[600],
//           padding: EdgeInsets.symmetric(vertical: 18),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           elevation: onPressed != null ? 2 : 0,
//         ),
//         // child: Row(
//         //   children: [
//         //     Expanded(
//         //       flex: 6,
//         //       child: Icon(
//         //         icon,
//         //         size: 25,
//         //         color: onPressed != null ? Colors.white : Colors.grey[300],
//         //       ),
//         //     ),
//         //     Expanded(
//         //       flex: 8,
//         //       child: Text(text,
//         //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//         //     ),
//         //   ],
//         // ),
//         child: Text(text,
//             style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
//       ),
//     );
//   }
// }
