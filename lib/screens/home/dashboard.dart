// import 'dart:async';
// import 'package:icheck_stelacom/services/api_service.dart';
// import 'package:icheck_stelacom/main.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/enhanced_barcode_scan.dart';
// import 'package:icheck_stelacom/screens/Visits/capture_screen.dart';
// import 'package:icheck_stelacom/screens/checkin-checkout/checkin_capture_screen.dart';
// import 'package:icheck_stelacom/screens/checkin-checkout/checkout_capture_screen.dart';
// import 'package:icheck_stelacom/services/location_service.dart';
// import '../enroll/code_verification.dart';
// import 'package:icheck_stelacom/constants.dart';
// import 'package:icheck_stelacom/screens/location_restrictions/location_restrictions.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/providers/appstate_provieder.dart';
// import 'package:icheck_stelacom/providers/loxcation_provider.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:flutter/material.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import '../../components/utils/custom_error_dialog.dart';
// import '../../components/utils/dialogs.dart';
// import 'package:flutter/services.dart';
// import 'package:jiffy/jiffy.dart';
// import 'package:new_version_plus/new_version_plus.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:app_version_update/app_version_update.dart';

// class Dashboard extends StatefulWidget {
//   Dashboard({super.key, required this.index3});

//   final int index3;
//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   Map<String, dynamic>? lastCheckIn;
//   String workedTime = "";
//   late DateTime? lastCheckInTime;
//   String employeeCode = "";
//   VersionStatus? versionstatus;
//   DateTime? NOTIFCATION_POPUP_DISPLAY_TIME;
//   String inTime = "";
//   String outTime = "";
//   String attendanceId = "";
//   final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
//   late AppState appState;
//   String formattedDuration = "";
//   String formattedDate = "";
//   String formattedInTime = "";
//   String formattedOutTime = "";
//   late AnimationController _pulseController;
//   late AnimationController _buttonController;

//   @override
//   void setState(fn) {
//     if (mounted) {
//       super.setState(fn);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     appState = Provider.of<AppState>(context, listen: false);

//     WidgetsBinding.instance.addObserver(this);
//     getSharedPrefs();

//     Timer.periodic(Duration(milliseconds: 200), (timer) {
//       appState.updateOfficeDate(
//           Jiffy.now().format(pattern: "EEEE") + ", " + Jiffy.now().yMMMMd);
//       appState.updateOfficeTime(Jiffy.now().format(pattern: "hh:mm:ss a"));
//     });

//     Timer.periodic(Duration(seconds: 1), (timer) {
//       updateWorkTime();
//     });

//     _pulseController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);

//     _buttonController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pulseController.dispose();
//     _buttonController.dispose();
//     super.dispose();
//   }

//   Future<void> getSharedPrefs() async {
//     await getVersionStatus();

//     _storage = await SharedPreferences.getInstance();
//     String? userData = _storage.getString('user_data');
//     employeeCode = _storage.getString('employee_code') ?? "";

//     if (userData == null) {
//       await loadUserData();
//     } else {
//       userObj = jsonDecode(userData);

//       if (mounted) appState.updateOfficeAddress(userObj!["OfficeAddress"]);
//       await loadLastCheckIn();
//     }

//     if (versionstatus != null) {
//       Future.delayed(Duration(seconds: 2), () async {
//         _verifyVersion();
//       });
//     }
//   }

// // --------GET App Version Status--------------//
//   Future<VersionStatus> getVersionStatus() async {
//     NewVersionPlus? newVersion =
//         NewVersionPlus(androidId: "com.aura.icheckapp");

//     VersionStatus? status = await newVersion.getVersionStatus();
//     setState(() {
//       versionstatus = status;
//     });
//     print(newVersion);

//     // if (versionstatus != null) {
//     return versionstatus!;
//     // }
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
//             index3: 0,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[1]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return AboutUs(
//             index3: 0,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[2]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return ContactUs(
//             index3: 0,
//           );
//         }),
//       );
//     } else if (choice == _menuOptions[3]) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) {
//           return TermsAndConditions(
//             index3: 0,
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

//   // VERSION UPDATE

//   Future<void> _verifyVersion() async {
//     AppVersionUpdate.checkForUpdates(
//       appleId: '1581265618',
//       playStoreId: 'com.aura.icheckapp',
//       country: 'us',
//     ).then(
//       (result) async {
//         if (result.canUpdate!) {
//           await AppVersionUpdate.showAlertUpdate(
//             appVersionResult: result,
//             context: context,
//             backgroundColor: Colors.grey[100],
//             title: '      Update Available',
//             titleTextStyle: TextStyle(
//               color: normalTextColor,
//               fontWeight: FontWeight.w600,
//               fontSize: Responsive.isMobileSmall(context) ||
//                       Responsive.isMobileMedium(context) ||
//                       Responsive.isMobileLarge(context)
//                   ? 24
//                   : Responsive.isTabletPortrait(context)
//                       ? 28
//                       : 27,
//             ),
//             content:
//                 "You're currently using iCheck ${versionstatus!.localVersion}, but new version ${result.storeVersion} is now available on the Play Store. Update now for the latest features!",
//             contentTextStyle: TextStyle(
//                 color: normalTextColor,
//                 fontWeight: FontWeight.w400,
//                 fontSize: Responsive.isMobileSmall(context) ||
//                         Responsive.isMobileMedium(context) ||
//                         Responsive.isMobileLarge(context)
//                     ? 16
//                     : Responsive.isTabletPortrait(context)
//                         ? 25
//                         : 24,
//                 height: 1.5),
//             updateButtonText: 'UPDATE',
//             updateTextStyle: TextStyle(
//               fontSize: Responsive.isMobileSmall(context)
//                   ? 14
//                   : Responsive.isMobileMedium(context) ||
//                           Responsive.isMobileLarge(context)
//                       ? 16
//                       : Responsive.isTabletPortrait(context)
//                           ? 18
//                           : 18,
//             ),
//             updateButtonStyle: ButtonStyle(
//                 foregroundColor: WidgetStateProperty.all(actionBtnTextColor),
//                 backgroundColor: WidgetStateProperty.all(Colors.green[800]),
//                 minimumSize: Responsive.isMobileSmall(context)
//                     ? WidgetStateProperty.all(Size(90, 40))
//                     : Responsive.isMobileMedium(context) ||
//                             Responsive.isMobileLarge(context)
//                         ? WidgetStateProperty.all(Size(100, 45))
//                         : Responsive.isTabletPortrait(context)
//                             ? WidgetStateProperty.all(Size(160, 60))
//                             : WidgetStateProperty.all(Size(140, 50)),
//                 shape: WidgetStateProperty.all(
//                   RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(0)),
//                 )),
//             cancelButtonText: 'NO THANKS',
//             cancelButtonStyle: ButtonStyle(
//                 foregroundColor: WidgetStateProperty.all(actionBtnTextColor),
//                 backgroundColor: WidgetStateProperty.all(Colors.red[800]),
//                 minimumSize: Responsive.isMobileSmall(context)
//                     ? WidgetStateProperty.all(Size(90, 40))
//                     : Responsive.isMobileMedium(context) ||
//                             Responsive.isMobileLarge(context)
//                         ? WidgetStateProperty.all(Size(100, 45))
//                         : Responsive.isTabletPortrait(context)
//                             ? WidgetStateProperty.all(Size(160, 60))
//                             : WidgetStateProperty.all(Size(140, 50)),
//                 shape: WidgetStateProperty.all(
//                   RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(0)),
//                 )),
//             cancelTextStyle: TextStyle(
//               fontSize: Responsive.isMobileSmall(context)
//                   ? 14
//                   : Responsive.isMobileMedium(context) ||
//                           Responsive.isMobileLarge(context)
//                       ? 16
//                       : Responsive.isTabletPortrait(context)
//                           ? 18
//                           : 18,
//             ),
//           );
//         }
//       },
//     );
//   }

//   // MOVE TO TURN ON DEVICE LOCATION

//   void switchOnLocation() async {
//     closeDialog(context);
//     bool ison = await Geolocator.isLocationServiceEnabled();
//     if (!ison) {
//       await Geolocator.openLocationSettings();
//     }
//   }

//   bool get isCheckedIn =>
//       lastCheckIn != null && lastCheckIn!["OutTime"] == null;

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;

//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) {
//         if (didPop) {
//           return;
//         }
//         SystemNavigator.pop();
//       },
//       child: Consumer<AppState>(
//         builder: (context, appState, child) {
//           return Scaffold(
//             key: firstTabNavKey,
//             backgroundColor: screenbgcolor,
//             appBar: AppBar(
//               backgroundColor: appbarBgColor,
//               shadowColor: Colors.grey[100],
//               toolbarHeight: Responsive.isMobileSmall(context) ||
//                       Responsive.isMobileMedium(context) ||
//                       Responsive.isMobileLarge(context)
//                   ? 40
//                   : Responsive.isTabletPortrait(context)
//                       ? 80
//                       : 90,
//               automaticallyImplyLeading: false,
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // --------- App Logo ---------- //
//                   SizedBox(
//                     width: Responsive.isMobileSmall(context) ||
//                             Responsive.isMobileMedium(context) ||
//                             Responsive.isMobileLarge(context)
//                         ? 90.0
//                         : Responsive.isTabletPortrait(context)
//                             ? 150
//                             : 170,
//                     height: Responsive.isMobileSmall(context) ||
//                             Responsive.isMobileMedium(context) ||
//                             Responsive.isMobileLarge(context)
//                         ? 40.0
//                         : Responsive.isTabletPortrait(context)
//                             ? 120
//                             : 100,
//                     child: Image.asset(
//                       'assets/images/iCheck_logo_2024.png',
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                   SizedBox(width: size.width * 0.25),
//                   // --------- Company Logo ---------- //
//                   SizedBox(
//                     width: Responsive.isMobileSmall(context) ||
//                             Responsive.isMobileMedium(context) ||
//                             Responsive.isMobileLarge(context)
//                         ? 90.0
//                         : Responsive.isTabletPortrait(context)
//                             ? 150
//                             : 170,
//                     height: Responsive.isMobileSmall(context) ||
//                             Responsive.isMobileMedium(context) ||
//                             Responsive.isMobileLarge(context)
//                         ? 40.0
//                         : Responsive.isTabletPortrait(context)
//                             ? 120
//                             : 100,
//                     child: userObj != null
//                         ? CachedNetworkImage(
//                             imageUrl: userObj!['CompanyProfileImage'],
//                             placeholder: (context, url) => Text("..."),
//                             errorWidget: (context, url, error) =>
//                                 Icon(Icons.error),
//                           )
//                         : Text(""),
//                   ),
//                 ],
//               ),
//               actions: <Widget>[
//                 PopupMenuButton<String>(
//                   onSelected: choiceAction,
//                   itemBuilder: (BuildContext context) {
//                     return _menuOptions.map((String choice) {
//                       return PopupMenuItem<String>(
//                         value: choice,
//                         child: Text(
//                           choice,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w400,
//                             fontSize: Responsive.isMobileSmall(context)
//                                 ? 15
//                                 : Responsive.isMobileMedium(context) ||
//                                         Responsive.isMobileLarge(context)
//                                     ? 17
//                                     : Responsive.isTabletPortrait(context)
//                                         ? size.width * 0.025
//                                         : size.width * 0.018,
//                           ),
//                         ),
//                       );
//                     }).toList();
//                   },
//                 )
//               ],
//             ),
//             body: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   _buildTimeCard(size),
//                   SizedBox(height: 20),
//                   _buildActionButtons(size),
//                   SizedBox(height: 22),
//                   _buildWorkTimeCard(size),
//                   SizedBox(height: 22),
//                   _buildProfileCard(size, isCheckedIn),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTimeCard3(Size size) {
//     return // Welcome Card
//         Container(
//       width: size.width * 0.9,
//       margin: EdgeInsets.only(top: 20),
//       padding: EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 2),
//           ),
//         ],
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.white, Color(0xFFFAFAFA)],
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             Icons.waving_hand,
//             // color: Color.fromRGBO(234, 88, 12, 1),
//             color: actionBtnColor,
//             size: 30,
//           ),
//           SizedBox(height: 12),
//           Text(
//             userObj != null
//                 ? userObj!['LastName'] != null
//                     ? 'Welcome ${userObj!["FirstName"]}!'
//                     : userObj!['LastName']
//                 : "",
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFFFF8C00),
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Manage your attendance records and inventories daily.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeCard2(Size size) {
//     return Container(
//       width: size.width * 0.9,
//       margin: EdgeInsets.only(top: 20),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 2),
//           ),
//         ],
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.white, Color(0xFFFAFAFA)],
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               color: actionBtnColor,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.supervisor_account,
//               color: Colors.white,
//               size: 28,
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   userObj != null
//                       ? userObj!['LastName'] != null
//                           ? 'Welcome ${userObj!["FirstName"]}!'
//                           : userObj!['LastName']
//                       : "",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                     letterSpacing: 1,
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 Text(
//                   userObj!['Id'],
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeCard(Size size) {
//     return Container(
//       width: size.width * 0.9,
//       margin: EdgeInsets.only(top: 20),
//       padding: EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.white, Color(0xFFFAFAFA)],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Current Time
//           Text(
//             appState.officeTime,
//             style: TextStyle(
//               fontSize: 25,
//               fontWeight: FontWeight.w300,
//               color: Color(0xFFFF8C00),
//               letterSpacing: 1.5,
//             ),
//           ),

//           SizedBox(height: 8),

//           // Current Date
//           Text(
//             appState.officeDate,
//             style: TextStyle(
//               fontSize: 16,
//               color: Color(0xFF64748B),
//               fontWeight: FontWeight.w500,
//             ),
//           ),

//           SizedBox(height: 16),

//           // Office Address
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: Color(0xFFFF8C00).withOpacity(0.08),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.location_on_outlined,
//                   size: 22,
//                   color: Color(0xFFFF8C00),
//                 ),
//                 SizedBox(width: 10),
//                 Flexible(
//                   child: Text(
//                     userObj?['OfficeAddress'] ?? '',
//                     style: TextStyle(
//                       fontSize: Responsive.isMobileSmall(context)
//                           ? 12
//                           : Responsive.isMobileMedium(context) ||
//                                   Responsive.isMobileLarge(context)
//                               ? 13
//                               : Responsive.isTabletPortrait(context)
//                                   ? 18
//                                   : 20,
//                       color: Color(0xFF64748B),
//                       fontWeight: FontWeight.w500,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWorkTimeCard(Size size) {
//     return Container(
//       width: isCheckedIn ? size.width * 0.6 : size.width * 0.75,
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 15,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Work Time Icon - Changed to a more neutral color
//           Expanded(
//             flex: 3,
//             child: Container(
//               height: 50,
//               width: 50,
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: isCheckedIn
//                     ? Color(0xFFFF8C00).withOpacity(0.1)
//                     : Color(0xFF9CA3AF).withOpacity(
//                         0.2), // Green when active, gray when inactive
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 Icons.access_time,
//                 color: isCheckedIn ? Color(0xFFFF8C00) : Color(0xFF9CA3AF),
//                 size: 24,
//               ),
//             ),
//           ),

//           Expanded(
//             child: SizedBox(),
//             flex: 1,
//           ),
//           // Work Time Info
//           Expanded(
//             flex: isCheckedIn ? 7 : 8,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Work Time',
//                   style: TextStyle(
//                     fontSize: Responsive.isMobileSmall(context)
//                         ? 17
//                         : Responsive.isMobileMedium(context) ||
//                                 Responsive.isMobileLarge(context)
//                             ? 19
//                             : Responsive.isTabletPortrait(context)
//                                 ? 22
//                                 : 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 AnimatedDefaultTextStyle(
//                   duration: Duration(milliseconds: 300),
//                   style: TextStyle(
//                     fontSize: Responsive.isMobileSmall(context)
//                         ? workedTime == "Not checked in yet"
//                             ? 16
//                             : 20
//                         : Responsive.isMobileMedium(context) ||
//                                 Responsive.isMobileLarge(context)
//                             ? workedTime == "Not checked in yet"
//                                 ? 19
//                                 : 23
//                             : Responsive.isTabletPortrait(context)
//                                 ? workedTime == "Not checked in yet"
//                                     ? 22
//                                     : 25
//                                 : 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[600],
//                     letterSpacing: workedTime == "Not checked in yet" ? 0 : 1,
//                   ),
//                   child: Text(
//                     workedTime,
//                     style: TextStyle(
//                       fontSize: Responsive.isMobileSmall(context)
//                           ? workedTime == "Not checked in yet"
//                               ? 16
//                               : 20
//                           : Responsive.isMobileMedium(context) ||
//                                   Responsive.isMobileLarge(context)
//                               ? workedTime == "Not checked in yet"
//                                   ? 19
//                                   : 23
//                               : Responsive.isTabletPortrait(context)
//                                   ? workedTime == "Not checked in yet"
//                                       ? 22
//                                       : 25
//                                   : 16,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Removed the duplicate "Active" status badge from here
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileCard(Size size, bool isCheckedIn) {
//     return Container(
//       width: size.width * 0.9,
//       padding: EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 15,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Profile Image with Status Ring
//           Stack(
//             children: [
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: isCheckedIn ? Colors.green : Color(0xFF9CA3AF),
//                     width: 1,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color:
//                           (isCheckedIn ? Color(0xFF10B981) : Color(0xFF9CA3AF))
//                               .withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: ClipOval(
//                   child: userObj != null && userObj!["ProfileImage"] != null
//                       ? userObj!["ProfileImage"] !=
//                               "https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckfaceimages&image=None"
//                           ? Image.network(
//                               userObj!["ProfileImage"],
//                               width: 64,
//                               height: 64,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return Container(
//                                   width: 64,
//                                   height: 64,
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [
//                                         Color(0xFF6B7280),
//                                         Color(0xFF9CA3AF)
//                                       ],
//                                     ),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Icon(
//                                     Icons.person,
//                                     color: Colors.white,
//                                     size: 32,
//                                   ),
//                                 );
//                               },
//                             )
//                           : Container(
//                               width: 64,
//                               height: 64,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [
//                                     Color(0xFF6B7280),
//                                     Color(0xFF9CA3AF)
//                                   ],
//                                 ),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(
//                                 Icons.person,
//                                 color: Colors.white,
//                                 size: 32,
//                               ),
//                             )
//                       : Image.network(
//                           "https://www.pngall.com/wp-content/uploads/5/User-Profile-PNG.png",
//                         ),
//                 ),
//               ),

//               // Status indicator dot
//               Positioned(
//                 bottom: 2,
//                 right: 2,
//                 child: Container(
//                   width: 16,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     color: isCheckedIn ? Colors.green : Color(0xFF9CA3AF),
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(width: size.width * 0.1),

//           // User Info - Keep only this status indicator
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   userObj != null
//                       ? userObj!['LastName'] != null
//                           ? userObj!["FirstName"] + " " + userObj!["LastName"]
//                           : userObj!['LastName']
//                       : "",
//                   style: TextStyle(
//                     fontSize: Responsive.isMobileSmall(context)
//                         ? 18
//                         : Responsive.isMobileMedium(context) ||
//                                 Responsive.isMobileLarge(context)
//                             ? 20
//                             : Responsive.isTabletPortrait(context)
//                                 ? 25
//                                 : 25,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: isCheckedIn ? Color(0xFF10B981) : Colors.grey,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Text(
//                       isCheckedIn ? 'Available' : 'Not Available',
//                       style: TextStyle(
//                         fontSize: Responsive.isMobileSmall(context)
//                             ? 14
//                             : Responsive.isMobileMedium(context) ||
//                                     Responsive.isMobileLarge(context)
//                                 ? 16
//                                 : Responsive.isTabletPortrait(context)
//                                     ? 20
//                                     : 20,
//                         color: isCheckedIn ? Color(0xFF10B981) : Colors.grey,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // GET the status of  the last event type (checkin or CheckoutCapture)

//   void updateWorkTime() {
//     if (lastCheckIn != null && lastCheckIn!["OutTime"] == null) {
//       lastCheckInTime = DateTime.parse(lastCheckIn!["InTime"]);
//       Duration duration = DateTime.now().difference(lastCheckInTime!);
//       if (!mounted) return;

//       setState(() {
//         String twoDigits(int n) => n.toString().padLeft(2, "0");
//         String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//         String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//         workedTime =
//             "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
//       });
//     } else {
//       workedTime = "Not checked in yet";
//     }
//   }

//   // LOAD LAST CHECKIN

//   Future<void> loadLastCheckIn() async {
//     showProgressDialog(context);
//     String userId = userObj!['Id'];
//     String customerId = userObj!['CustomerId'];
//     var response = await ApiService.getTodayCheckInCheckOut(userId, customerId);
//     closeDialog(context);
//     if (response != null && response.statusCode == 200) {
//       dynamic item = jsonDecode(response.body);
//       print("item $item");

//       if (item != null) {
//         if (item["enrolled"] == 'pending' || item["enrolled"] == null) {
//           await _storage.clear();
//           while (Navigator.canPop(context)) {
//             Navigator.pop(context);
//           }
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) {
//               return MyApp(_storage);
//             }),
//           );
//         } else if (item["Data"] == 'Yes') {
//           lastCheckIn = item;
//           _storage.setString('last_check_in', jsonEncode(item));
//         }
//       }
//     }
//   }

//   String formatDuration(Duration duration) {
//     int hours = duration.inHours;
//     int minutes = (duration.inMinutes % 60);
//     int seconds = (duration.inSeconds % 60);

//     String formattedDuration = '';

//     if (hours > 0) {
//       formattedDuration += '${hours.toString().padLeft(2, '0')} hr ';
//     }

//     if (minutes > 0) {
//       formattedDuration += '${minutes.toString().padLeft(2, '0')} min ';
//     }

//     if (seconds > 0 || (hours == 0 && minutes == 0)) {
//       formattedDuration += '${seconds.toString().padLeft(2, '0')} sec';
//     }

//     return formattedDuration.trim();
//   }

//   void noHandler() {
//     closeDialog(context);
//   }

//   // LOAD USER DATA

//   Future<void> loadUserData() async {
//     showProgressDialog(context);
//     var response = await ApiService.verifyUserWithEmpCode(employeeCode);
//     closeDialog(context);
//     if (response != null &&
//         response.statusCode == 200 &&
//         response.body == "NoRecordsFound") {
//       await _storage.clear();
//       while (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) {
//             return MyApp(_storage);
//           },
//         ),
//       );
//     } else if (response != null && response.statusCode == 200) {
//       userObj = jsonDecode(response.body);

//       _storage.setString('user_data', response.body);
//       String? lastCheckInData = _storage.getString('last_check_in');
//       if (lastCheckInData == null) {
//         await loadLastCheckIn();
//       } else {
//         lastCheckIn = jsonDecode(lastCheckInData);
//       }
//     }
//   }

//   int calculateDayDifference(DateTime date) {
//     DateTime now = DateTime.now();
//     return DateTime(date.year, date.month, date.day)
//         .difference(DateTime(now.year, now.month, now.day))
//         .inDays;
//   }

//   Widget _buildActionButtons(Size size) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                   child: _buildActionButton(
//                 context: context,
//                 size: size,
//                 label: 'Check In',
//                 icon: Icons.login,
//                 isPrimary: true,
//                 onPressed: () {
//                   if (lastCheckIn == null || lastCheckIn!["OutTime"] != null) {
//                     Geolocator.isLocationServiceEnabled()
//                         .then((bool serviceEnabled) {
//                       //check whether user is deactivated or not
//                       if (userObj!['Deleted'] == 0) {
//                         if (serviceEnabled) {
//                           if (userObj!['EnableLocation'] > 0) {
//                             if (userObj!['EnableLocationRestriction'] == 1) {
//                               _storage.setString('Action', 'checkin');
//                               Navigator.of(context).push(
//                                 MaterialPageRoute(
//                                   builder: (context) => ChangeNotifierProvider(
//                                     create: (context) =>
//                                         LocationRestrictionState(),
//                                     child: ValidateLocation(
//                                       widget.index3,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             } else {
//                               Navigator.of(context, rootNavigator: true).push(
//                                 MaterialPageRoute(
//                                   builder: (context) => ChangeNotifierProvider(
//                                       create: (context) => AppState(),
//                                       child: CheckInCapture()),
//                                 ),
//                               );
//                             }
//                           } else {
//                             Navigator.of(context, rootNavigator: true).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ChangeNotifierProvider(
//                                     create: (context) => AppState(),
//                                     child: CheckInCapture()),
//                               ),
//                             );
//                           }
//                         } else {
//                           Geolocator.checkPermission()
//                               .then((LocationPermission permission) {
//                             if (permission == LocationPermission.denied ||
//                                 permission ==
//                                     LocationPermission.deniedForever) {
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => CustomErrorDialog(
//                                     title: 'Location Service Disabled.',
//                                     message:
//                                         'Please enable location service before trying visit.',
//                                     onOkPressed: switchOnLocation,
//                                     iconData: Icons.error_outline),
//                               );
//                             } else {
//                               if (userObj!['EnableLocation'] > 0) {
//                                 if (userObj!['EnableLocationRestriction'] ==
//                                     1) {
//                                   _storage.setString('Action', 'checkin');
//                                   Navigator.of(context).push(
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           ChangeNotifierProvider(
//                                               create: (context) =>
//                                                   LocationRestrictionState(),
//                                               child: ValidateLocation(
//                                                   widget.index3)),
//                                     ),
//                                   );
//                                 } else {
//                                   Navigator.of(context, rootNavigator: true)
//                                       .push(
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           ChangeNotifierProvider(
//                                               create: (context) => AppState(),
//                                               child: CheckInCapture()),
//                                     ),
//                                   );
//                                 }
//                               } else {
//                                 Navigator.of(context, rootNavigator: true).push(
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         ChangeNotifierProvider(
//                                             create: (context) => AppState(),
//                                             child: CheckInCapture()),
//                                   ),
//                                 );
//                               }
//                             }
//                           });
//                         }
//                       } else {
//                         //Tell user that his account is deactivated
//                         showDialog(
//                           context: context,
//                           builder: (context) => CustomErrorDialog(
//                               title: 'Inactive User',
//                               message:
//                                   'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
//                               onOkPressed: () => Navigator.of(context).pop(),
//                               iconData: Icons.no_accounts_sharp),
//                         );
//                       }
//                     });
//                   } else {}
//                 },
//                 bgColor:
//                     (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                         ? actionBtnColor
//                         : Color(0xFFBDBDBD),
//                 fontColor:
//                     (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                         ? Colors.white
//                         : Colors.black54,
//               )),

//               SizedBox(width: 12),

//               // Check Out Button
//               Expanded(
//                 child: _buildActionButton(
//                   context: context,
//                   size: size,
//                   label: 'Check Out',
//                   icon: Icons.logout,
//                   isPrimary: false,
//                   onPressed: () {
//                     if ((lastCheckIn == null ||
//                         lastCheckIn!["OutTime"] != null)) {
//                     } else {
//                       Geolocator.isLocationServiceEnabled().then(
//                         (bool serviceEnabled) {
//                           //check whether user is deactivated or not
//                           if (userObj!['Deleted'] == 0) {
//                             if (serviceEnabled) {
//                               if (userObj!['EnableLocation'] > 0) {
//                                 if (userObj!['EnableLocationRestriction'] ==
//                                     1) {
//                                   _storage.setString('Action', 'checkout');
//                                   Navigator.of(context).push(
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           ChangeNotifierProvider(
//                                         create: (context) =>
//                                             LocationRestrictionState(),
//                                         child: ValidateLocation(
//                                           widget.index3,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 } else {
//                                   Navigator.of(context, rootNavigator: true)
//                                       .push(
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           ChangeNotifierProvider(
//                                               create: (context) => AppState(),
//                                               child: CheckoutCapture()),
//                                     ),
//                                   );
//                                 }
//                               } else {
//                                 Navigator.of(context, rootNavigator: true).push(
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         ChangeNotifierProvider(
//                                       create: (context) => AppState(),
//                                       child: CheckoutCapture(),
//                                     ),
//                                   ),
//                                 );
//                               }
//                             } else {
//                               Geolocator.checkPermission()
//                                   .then((LocationPermission permission) {
//                                 if (permission == LocationPermission.denied ||
//                                     permission ==
//                                         LocationPermission.deniedForever) {
//                                   showDialog(
//                                     context: context,
//                                     builder: (context) => CustomErrorDialog(
//                                         title: 'Location Service Disabled.',
//                                         message:
//                                             'Please enable location service before trying visit.',
//                                         onOkPressed: () =>
//                                             Navigator.of(context).pop(),
//                                         iconData: Icons.error_outline),
//                                   );
//                                 } else {
//                                   if (userObj!['EnableLocation'] > 0) {
//                                     if (userObj!['EnableLocationRestriction'] ==
//                                         1) {
//                                       _storage.setString('Action', 'checkout');
//                                       Navigator.of(context).push(
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               ChangeNotifierProvider(
//                                             create: (context) =>
//                                                 LocationRestrictionState(),
//                                             child:
//                                                 ValidateLocation(widget.index3),
//                                           ),
//                                         ),
//                                       );
//                                     } else {
//                                       Navigator.of(context, rootNavigator: true)
//                                           .push(
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               ChangeNotifierProvider(
//                                             create: (context) => AppState(),
//                                             child: CheckoutCapture(),
//                                           ),
//                                         ),
//                                       );
//                                     }
//                                   } else {
//                                     Navigator.of(context, rootNavigator: true)
//                                         .push(
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             ChangeNotifierProvider(
//                                           create: (context) => AppState(),
//                                           child: CheckoutCapture(),
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 }
//                               });
//                             }
//                           } else {
//                             //Tell user that his account is deactivated
//                             showDialog(
//                               context: context,
//                               builder: (context) => CustomErrorDialog(
//                                   title: 'Inactive User',
//                                   message:
//                                       'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
//                                   onOkPressed: () =>
//                                       Navigator.of(context).pop(),
//                                   iconData: Icons.no_accounts_sharp),
//                             );
//                           }
//                         },
//                       );
//                     }
//                   },
//                   bgColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Color(0XFFBDBDBD)
//                           : actionBtnColor,
//                   fontColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Colors.black54
//                           : Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Row(
//             children: [
//               // Visit Button
//               Expanded(
//                 child: _buildActionButton(
//                   context: context,
//                   size: size,
//                   label: 'Visit',
//                   icon: Icons.login,
//                   isPrimary: false,
//                   onPressed: () {
//                     if ((lastCheckIn == null || //additional line
//                         lastCheckIn!["OutTime"] != null)) {
//                       //additional line
//                     } else {
//                       //additional line
//                       Geolocator.isLocationServiceEnabled()
//                           .then((bool serviceEnabled) {
//                         if (userObj!['Deleted'] == 0) {
//                           if (serviceEnabled) {
//                             Navigator.of(context, rootNavigator: true).push(
//                               MaterialPageRoute(
//                                 builder: (context) => ChangeNotifierProvider(
//                                     create: (context) => AppState(),
//                                     child: VisitCapture()),
//                               ),
//                             );
//                           } else {
//                             Geolocator.checkPermission()
//                                 .then((LocationPermission permission) {
//                               if (permission == LocationPermission.denied ||
//                                   permission ==
//                                       LocationPermission.deniedForever) {
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => CustomErrorDialog(
//                                       title: 'Location Service Disabled.',
//                                       message:
//                                           'Please enable location service before trying visit.',
//                                       onOkPressed: () =>
//                                           Navigator.of(context).pop(),
//                                       iconData: Icons.error_outline),
//                                 );
//                               } else {
//                                 Navigator.of(context, rootNavigator: true).push(
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         ChangeNotifierProvider(
//                                       create: (context) => AppState(),
//                                       child: VisitCapture(),
//                                     ),
//                                   ),
//                                 );
//                               }
//                             });
//                           }
//                         } else {
//                           //Tell user that his account is deactivated
//                           showDialog(
//                             context: context,
//                             builder: (context) => CustomErrorDialog(
//                                 title: 'Inactive User',
//                                 message:
//                                     'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
//                                 onOkPressed: () => Navigator.of(context).pop(),
//                                 iconData: Icons.no_accounts_sharp),
//                           );
//                         }
//                       });
//                     }
//                   },
//                   bgColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Color(0XFFBDBDBD)
//                           : actionBtnColor,
//                   fontColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Colors.black54
//                           : Colors.white,
//                 ),
//               ),

//               SizedBox(width: 12),

//               // Inventory Scan Button
//               Expanded(
//                 child: _buildActionButton(
//                   context: context,
//                   size: size,
//                   label: 'Inventory Scan',
//                   icon: Icons.qr_code_scanner,
//                   isPrimary: false,
//                   onPressed: () {
//                     if ((lastCheckIn == null ||
//                         lastCheckIn!["OutTime"] != null)) {
//                     } else {
//                       Geolocator.isLocationServiceEnabled()
//                           .then((bool serviceEnabled) async {
//                         if (userObj!['Deleted'] == 0) {
//                           if (serviceEnabled) {
//                             bool isLocationValid =
//                                 await LocationValidationService
//                                     .validateLocationForInventoryScan(context);

//                             if (isLocationValid) {
//                               // Navigate to Inventory Scan screen
//                               Navigator.of(context, rootNavigator: true).push(
//                                 MaterialPageRoute(
//                                     builder: (context) =>
//                                         EnhancedBarcodeScannerScreen(
//                                             index: widget.index3)),
//                               );
//                             }
//                           } else {
//                             Geolocator.checkPermission()
//                                 .then((LocationPermission permission) {
//                               if (permission == LocationPermission.denied ||
//                                   permission ==
//                                       LocationPermission.deniedForever) {
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => CustomErrorDialog(
//                                       title: 'Location Service Disabled.',
//                                       message:
//                                           'Please enable location service before trying visit.',
//                                       onOkPressed: () =>
//                                           Navigator.of(context).pop(),
//                                       iconData: Icons.error_outline),
//                                 );
//                               }
//                             });
//                           }
//                         } else {
//                           //Tell user that his account is deactivated
//                           showDialog(
//                             context: context,
//                             builder: (context) => CustomErrorDialog(
//                                 title: 'Inactive User',
//                                 message:
//                                     'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
//                                 onOkPressed: () => Navigator.of(context).pop(),
//                                 iconData: Icons.no_accounts_sharp),
//                           );
//                         }
//                       });
//                     }
//                   },
//                   bgColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Color(0XFFBDBDBD)
//                           : actionBtnColor,
//                   fontColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Colors.black54
//                           : Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Visit Button
//               SizedBox(
//                 width: size.width * 0.5,
//                 child: _buildActionButton(
//                   context: context,
//                   size: size,
//                   label: 'Inventory GRN',
//                   icon: Icons.inventory,
//                   isPrimary: false,
//                   onPressed: () {},
//                   bgColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Color(0XFFBDBDBD)
//                           : actionBtnColor,
//                   fontColor:
//                       (lastCheckIn == null || lastCheckIn!["OutTime"] != null)
//                           ? Colors.black54
//                           : Colors.white,
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required BuildContext context,
//     required Size size,
//     required String label,
//     required IconData icon,
//     required bool isPrimary,
//     required VoidCallback onPressed,
//     required Color bgColor,
//     required Color fontColor,
//   }) {
//     return AnimatedContainer(
//       duration: Duration(milliseconds: 300),
//       width: size.width,
//       height: 64,
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         icon: Icon(
//           icon,
//           size: 22,
//           color: fontColor,
//         ),
//         label: Text(
//           label,
//           style: TextStyle(
//             fontSize: Responsive.isMobileSmall(context)
//                 ? 14
//                 : Responsive.isMobileMedium(context)
//                     ? 16
//                     : Responsive.isMobileLarge(context)
//                         ? 16
//                         : Responsive.isTabletPortrait(context)
//                             ? 18
//                             : 18,
//             fontWeight: FontWeight.w600,
//             color: fontColor,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: bgColor,
//           foregroundColor: fontColor,
//           elevation: 1,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           padding: EdgeInsets.symmetric(vertical: 16),
//         ),
//       ),
//     );
//   }
// }
