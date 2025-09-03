// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:jiffy/jiffy.dart';

// class ModernDashboard extends StatefulWidget {
//   ModernDashboard({super.key, required this.index3});

//   final int index3;
//   @override
//   State<ModernDashboard> createState() => _ModernDashboardState();
// }

// class _ModernDashboardState extends State<ModernDashboard>
//     with TickerProviderStateMixin {
//   // Sample data - replace with your actual data
//   Map<String, dynamic>? userObj = {
//     'FirstName': 'Adeesha',
//     'LastName': 'Perera',
//     'ProfileImage':
//         'https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckfaceimages&image=adfc4027-484f-4a7a-9f28-fa8e824bc129_TEST022_CAP841000192460763151.jpg',
//     'OfficeAddress': '410/118 Bauddhaloka Mawatha, Colombo 00700'
//   };

//   Map<String, dynamic>? lastCheckIn;
//   String workedTime = "Not checked in yet";
//   String currentTime = "";
//   String currentDate = "";

//   late AnimationController _pulseController;
//   late AnimationController _buttonController;
//   Timer? _timeTimer;
//   Timer? _workTimeTimer;

//   @override
//   void initState() {
//     super.initState();

//     _pulseController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);

//     _buttonController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );

//     // Update time every 200ms like in your original code
//     _timeTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
//       if (mounted) {
//         setState(() {
//           currentDate =
//               Jiffy.now().format(pattern: "EEEE") + ", " + Jiffy.now().yMMMMd;
//           currentTime = Jiffy.now().format(pattern: "hh:mm:ss a");
//         });
//       }
//     });

//     // Update work time every second
//     _workTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//       updateWorkTime();
//     });
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _buttonController.dispose();
//     _timeTimer?.cancel();
//     _workTimeTimer?.cancel();
//     super.dispose();
//   }

//   bool get isCheckedIn =>
//       lastCheckIn != null && lastCheckIn!["OutTime"] == null;

//   void updateWorkTime() {
//     if (lastCheckIn != null && lastCheckIn!["OutTime"] == null) {
//       DateTime lastCheckInTime = DateTime.parse(lastCheckIn!["InTime"]);
//       Duration duration = DateTime.now().difference(lastCheckInTime);

//       if (mounted) {
//         setState(() {
//           String twoDigits(int n) => n.toString().padLeft(2, "0");
//           String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//           String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//           workedTime =
//               "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
//         });
//       }
//     } else {
//       if (mounted) {
//         setState(() {
//           workedTime = "Not checked in yet";
//         });
//       }
//     }
//   }

//   // Mock check-in function - replace with your actual API calls
//   void _handleCheckIn() {
//     setState(() {
//       lastCheckIn = {
//         "InTime": DateTime.now().toIso8601String(),
//         "OutTime": null,
//       };
//     });
//     _buttonController.forward();
//   }

//   void _handleCheckOut() {
//     setState(() {
//       lastCheckIn!["OutTime"] = DateTime.now().toIso8601String();
//     });
//     _buttonController.reverse();
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Color(0xFFF5F7FA),
//       appBar: _buildAppBar(size),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             _buildTimeCard(size),
//             SizedBox(height: 24),
//             _buildActionButtons(size),
//             SizedBox(height: 24),
//             _buildWorkTimeCard(size),
//             SizedBox(height: 24),
//             _buildProfileCard(size),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(Size size) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       elevation: 2,
//       shadowColor: Colors.grey.withOpacity(0.1),
//       toolbarHeight: 70,
//       automaticallyImplyLeading: false,
//       title: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // iCheck Logo
//           Container(
//             child: Row(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Color(0xFFFF8C00).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     Icons.location_on,
//                     color: Color(0xFFFF8C00),
//                     size: 20,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Text(
//                   'iCheck',
//                   style: TextStyle(
//                     color: Color(0xFF2D3748),
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Company Logo
//           Container(
//             width: 100,
//             height: 40,
//             child: userObj != null
//                 ? Image.network(
//                     'https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckmisc&image=1_STL_123.png',
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         decoration: BoxDecoration(
//                           color: Color(0xFFFF8C00).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.business, color: Color(0xFFFF8C00)),
//                       );
//                     },
//                   )
//                 : Container(),
//           ),
//         ],
//       ),
//       actions: [
//         PopupMenuButton<String>(
//           icon: Icon(Icons.more_vert, color: Color(0xFF2D3748)),
//           onSelected: (String choice) {
//             // Handle menu selection - connect to your choiceAction method
//             print('Selected: $choice');
//           },
//           itemBuilder: (BuildContext context) {
//             return ['Help', 'About Us', 'Contact Us', 'T & C', 'Log Out']
//                 .map((String choice) {
//               return PopupMenuItem<String>(
//                 value: choice,
//                 child: Text(choice),
//               );
//             }).toList();
//           },
//         ),
//       ],
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
//           // Status Indicator
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AnimatedBuilder(
//                 animation: _pulseController,
//                 builder: (context, child) {
//                   return Container(
//                     width: 12,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       color: isCheckedIn
//                           ? Color(0xFF10B981)
//                               .withOpacity(0.5 + 0.5 * _pulseController.value)
//                           : Color(0xFF6B7280),
//                       shape: BoxShape.circle,
//                     ),
//                   );
//                 },
//               ),
//               SizedBox(width: 8),
//               Text(
//                 isCheckedIn ? 'Checked In' : 'Ready to Check In',
//                 style: TextStyle(
//                   color: isCheckedIn ? Color(0xFF10B981) : Color(0xFF6B7280),
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(height: 16),

//           // Current Time
//           Text(
//             currentTime,
//             style: TextStyle(
//               fontSize: 42,
//               fontWeight: FontWeight.w300,
//               color: Color(0xFFFF8C00),
//               letterSpacing: 1.5,
//             ),
//           ),

//           SizedBox(height: 8),

//           // Current Date
//           Text(
//             currentDate,
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
//                   size: 16,
//                   color: Color(0xFFFF8C00),
//                 ),
//                 SizedBox(width: 8),
//                 Flexible(
//                   child: Text(
//                     userObj?['OfficeAddress'] ?? '',
//                     style: TextStyle(
//                       fontSize: 12,
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

//   Widget _buildActionButtons(Size size) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _buildActionButton(
//                   context: context,
//                   size: size,
//                   label: 'Check In',
//                   icon: Icons.login,
//                   isEnabled: !isCheckedIn,
//                   isPrimary: true,
//                   onPressed: _handleCheckIn,
//                 ),
//               ),

//               SizedBox(width: 12),

//               // Check Out Button
//               Expanded(
//                 child: _buildActionButton(
//                   context: context,
//                   size: size,
//                   label: 'Check Out',
//                   icon: Icons.logout,
//                   isEnabled: isCheckedIn,
//                   isPrimary: false,
//                   onPressed: _handleCheckOut,
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
//                   icon: Icons.visibility,
//                   isEnabled: isCheckedIn,
//                   isPrimary: false,
//                   onPressed: () => _showSnackBar('Visit functionality'),
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
//                   isEnabled: isCheckedIn,
//                   isPrimary: false,
//                   onPressed: () => _showSnackBar('Inventory scan functionality'),
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
//     required bool isEnabled,
//     required bool isPrimary,
//     required VoidCallback onPressed,
//   }) {
//     return AnimatedContainer(
//       duration: Duration(milliseconds: 300),
//       width: size.width,
//       height: 64,
//       child: ElevatedButton.icon(
//         onPressed: isEnabled ? onPressed : null,
//         icon: Icon(
//           icon,
//           size: 22,
//           color: isEnabled ? Colors.white : Colors.black54,
//         ),
//         label: Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: isEnabled ? Colors.white : Colors.black54,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: isEnabled
//               ? (isPrimary ? Color(0xFFFF8C00) : Color(0xFFFF8C00))
//               : Color(0xFFBDBDBD),
//           foregroundColor: isEnabled ? Colors.white : Colors.black54,
//           elevation: isEnabled ? 6 : 1,
//           shadowColor: isEnabled
//               ? Color(0xFFFF8C00).withOpacity(0.3)
//               : Colors.grey.withOpacity(0.1),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           padding: EdgeInsets.symmetric(vertical: 16),
//         ),
//       ),
//     );
//   }

//   Widget _buildWorkTimeCard(Size size) {
//     return Container(
//       width: size.width * 0.9,
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
//           // Work Time Icon
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: isCheckedIn
//                     ? [Color(0xFFFF8C00), Color(0xFFFFB347)]
//                     : [Color(0xFF9CA3AF), Color(0xFF6B7280)],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: (isCheckedIn ? Color(0xFFFF8C00) : Color(0xFF9CA3AF))
//                       .withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Icon(
//               Icons.access_time,
//               color: Colors.white,
//               size: 24,
//             ),
//           ),

//           SizedBox(width: 16),

//           // Work Time Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Work Time',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Color(0xFF64748B),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 AnimatedDefaultTextStyle(
//                   duration: Duration(milliseconds: 300),
//                   style: TextStyle(
//                     fontSize: workedTime == "Not checked in yet" ? 16 : 24,
//                     fontWeight: FontWeight.bold,
//                     color: isCheckedIn ? Color(0xFFFF8C00) : Color(0xFF9CA3AF),
//                     letterSpacing: workedTime == "Not checked in yet" ? 0 : 1,
//                   ),
//                   child: Text(workedTime),
//                 ),
//               ],
//             ),
//           ),

//           // Status Badge
//           if (isCheckedIn)
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Color(0xFF10B981).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: Color(0xFF10B981).withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 6,
//                     height: 6,
//                     decoration: BoxDecoration(
//                       color: Color(0xFF10B981),
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   SizedBox(width: 6),
//                   Text(
//                     'Active',
//                     style: TextStyle(
//                       color: Color(0xFF10B981),
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileCard(Size size) {
//     return Container(
//       width: size.width * 0.9,
//       padding: EdgeInsets.all(24),
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
//                 width: 64,
//                 height: 64,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: isCheckedIn ? Color(0xFF10B981) : Color(0xFF9CA3AF),
//                     width: 3,
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
//                       ? Image.network(
//                           userObj!["ProfileImage"],
//                           width: 64,
//                           height: 64,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               width: 64,
//                               height: 64,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [
//                                     Color(0xFFFF8C00),
//                                     Color(0xFFFFB347)
//                                   ],
//                                 ),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(
//                                 Icons.person,
//                                 color: Colors.white,
//                                 size: 32,
//                               ),
//                             );
//                           },
//                         )
//                       : Container(
//                           width: 64,
//                           height: 64,
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
//                             ),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.person,
//                             color: Colors.white,
//                             size: 32,
//                           ),
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
//                     color: isCheckedIn ? Color(0xFF10B981) : Color(0xFF9CA3AF),
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(width: 16),

//           // User Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   userObj != null
//                       ? "${userObj!['FirstName']} ${userObj!['LastName'] ?? ''}"
//                       : "User Name",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D3748),
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: isCheckedIn
//                         ? Color(0xFF10B981).withOpacity(0.1)
//                         : Color(0xFF9CA3AF).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     isCheckedIn ? 'Currently Working' : 'Not Working',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color:
//                           isCheckedIn ? Color(0xFF10B981) : Color(0xFF6B7280),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Quick Info
//           if (isCheckedIn)
//             Container(
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Color(0xFFFF8C00).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.work,
//                 color: Color(0xFFFF8C00),
//                 size: 20,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Color(0xFFFF8C00),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         margin: EdgeInsets.all(16),
//       ),
//     );
//   }
// }
