// import 'dart:async';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/variance_reports.dart';
// import 'package:icheck_stelacom/constants.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class APIVerificationScreen extends StatefulWidget {
//   final int index;

//   const APIVerificationScreen({super.key, required this.index});

//   @override
//   _APIVerificationScreenState createState() => _APIVerificationScreenState();
// }

// class _APIVerificationScreenState extends State<APIVerificationScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _rotationController;
//   late AnimationController _progressController;
//   late Animation<double> _progressAnimation;
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;

//   @override
//   void initState() {
//     super.initState();
//     _rotationController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     );
//     _progressController = AnimationController(
//       duration: Duration(seconds: 3),
//       vsync: this,
//     );
//     _progressAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
//     );

//     _rotationController.repeat();
//     _progressController.forward();

//     // Auto navigate after 4 seconds
//     Timer(Duration(seconds: 4), () {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (context) => VarianceReportScreen(index: widget.index)),
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _rotationController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }

// // SIDE MENU BAR UI
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
//       backgroundColor: Colors.grey[50],
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
//                       "Verification",
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
//             // Verification Content
//             Container(
//               height: size.height * 0.7,
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Rotating Icon
//                     Expanded(
//                       flex: 4,
//                       child: AnimatedBuilder(
//                         animation: _rotationController,
//                         builder: (context, child) {
//                           return Transform.rotate(
//                             angle: _rotationController.value * 2 * 3.14159,
//                             child: Container(
//                               width: 80,
//                               height: 80,
//                               decoration: BoxDecoration(
//                                 color: Colors.orange,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(Icons.refresh,
//                                   color: Colors.white, size: 40),
//                             ),
//                           );
//                         },
//                       ),
//                     ),

//                     Expanded(
//                       flex: 4,
//                       child: Column(
//                         children: [
//                           Text(
//                             'Verifying IMEI Numbers',
//                             style: TextStyle(
//                                 fontSize: 24, fontWeight: FontWeight.bold),
//                             textAlign: TextAlign.center,
//                           ),
//                           SizedBox(height: 20),
//                           Text(
//                             'Checking system inventory against\nscanned items...',
//                             style: TextStyle(
//                                 color: Colors.grey[600], fontSize: 16),
//                             textAlign: TextAlign.center,
//                           ),
//                           SizedBox(height: 40),
//                         ],
//                       ),
//                     ),

//                     // Progress Bar
//                     Expanded(
//                       flex: 4,
//                       child: AnimatedBuilder(
//                         animation: _progressAnimation,
//                         builder: (context, child) {
//                           return Column(
//                             children: [
//                               LinearProgressIndicator(
//                                 value: _progressAnimation.value,
//                                 backgroundColor: Colors.grey[300],
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                     Colors.orange),
//                                 minHeight: 8,
//                               ),
//                               SizedBox(height: 10),
//                               Text(
//                                 'Processing... Please wait',
//                                 style: TextStyle(
//                                     fontSize: 14, color: Colors.grey[600]),
//                               ),
//                               SizedBox(height: 30),
//                               // Continue Button
//                             ],
//                           );
//                         },
//                       ),
//                     ),
//                     _buildButton(
//                       'Continue to Report',
//                       Colors.orange,
//                       () => Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 VarianceReportScreen(index: widget.index)),
//                       ),
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

//   Widget _buildButton(String text, Color color, VoidCallback onPressed) {
//     return Container(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             foregroundColor: Colors.white,
//             padding: EdgeInsets.symmetric(vertical: 18),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             elevation: 2,
//             fixedSize: Size(double.infinity, 60)),
//         child: Text(text,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//       ),
//     );
//   }
// }
