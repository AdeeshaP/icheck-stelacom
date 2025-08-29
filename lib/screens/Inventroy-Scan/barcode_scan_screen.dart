// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/imei_selection_screen.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/variance_reports.dart';
// import '../enroll/code_verification.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../constants.dart';

// class BarcodeScannerScreen extends StatefulWidget {
//   final int index;

//   BarcodeScannerScreen({super.key, required this.index});

//   @override
//   _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
// }

// class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _animation;
//   int scannedItems = 3;
//   int totalItems = 10;
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   String employeeCode = "";
//   String userData = "";

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     );
//     _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.linear),
//     );
//     _animationController.repeat();
//     getSharedPrefs();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> getSharedPrefs() async {
//     _storage = await SharedPreferences.getInstance();
//     userData = _storage.getString('user_data')!;
//     employeeCode = _storage.getString('employee_code') ?? "";

//     userObj = jsonDecode(userData);
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
//           crossAxisAlignment: CrossAxisAlignment.stretch,
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
//                       "Inventory Scanner",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: screenHeadingColor,
//                         fontSize: Responsive.isMobileSmall(context)
//                             ? 22
//                             : Responsive.isMobileMedium(context) ||
//                                     Responsive.isMobileLarge(context)
//                                 ? 26
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
//               margin: EdgeInsets.all(20),
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Container(
//                     width: 200,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.orange, width: 2),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   AnimatedBuilder(
//                     animation: _animation,
//                     builder: (context, child) {
//                       return Positioned(
//                         top: 50 + (100 * _animation.value),
//                         left: 0,
//                         right: 0,
//                         child: Container(
//                           height: 2,
//                           margin: EdgeInsets.symmetric(horizontal: 87.5),
//                           decoration: BoxDecoration(
//                             color: Colors.orange,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.orange.withOpacity(0.5),
//                                 blurRadius: 4,
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),

//             // Instruction Text
//             Text(
//               'Point camera at barcode to scan inventory items',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey[600], fontSize: 14),
//             ),
//             SizedBox(height: 20),

//             // Scan Progress
//             Container(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   Text(
//                     'Scanned Items: $scannedItems/$totalItems',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 10),
//                   LinearProgressIndicator(
//                     value: scannedItems / totalItems,
//                     backgroundColor: Colors.grey[300],
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//                     minHeight: 8,
//                   ),
//                 ],
//               ),
//             ),

//             // Buttons
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   _buildButton(
//                     'View Scanned Items ($scannedItems)',
//                     actionBtnColor,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => IMEISelectionScreen(
//                                 index: widget.index,
//                                 imeiList: [
//                                   {
//                                     'imei': '356938035643809',
//                                     'model': 'iPhone 13 Pro',
//                                     'status': 'In Stock',
//                                   },
//                                   {
//                                     'imei': '356938035643810',
//                                     'model': 'iPhone 13 Pro',
//                                     'status': 'In Stock',
//                                   },
//                                   {
//                                     'imei': '356938035643811',
//                                     'model': 'iPhone 13 Pro',
//                                     'status': 'Reserved',
//                                   },
//                                 ],
//                               ),),
//                     ),
//                   ),
//                   SizedBox(height: 15),
//                   _buildButton(
//                     'Complete Scan & Generate Report',
//                     actionBtnColor,
//                     () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => VarianceReportScreen(
//                                 index: widget.index,
//                               )),
//                     ),
//                   ),
//                   // SizedBox(height: 15),
//                   // _buildButton(
//                   //   '← Back',
//                   //   Colors.grey,
//                   //   () => Navigator.pop(context),
//                   // ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(String text, Color color, VoidCallback onPressed) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor:
//               color == Colors.grey ? Colors.grey[600] : Colors.white,
//           padding: EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           elevation: 2,
//         ),
//         child: Text(
//           text,
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }
// }
