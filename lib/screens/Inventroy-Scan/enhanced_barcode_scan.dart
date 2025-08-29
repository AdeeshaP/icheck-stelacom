import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icheck_stelacom/constants.dart';
import 'package:icheck_stelacom/models/imei_item.dart';
import 'package:icheck_stelacom/models/scanned_item.dart';
import 'package:icheck_stelacom/responsive.dart';
import 'package:icheck_stelacom/screens/Inventroy-Scan/veritfication_results.dart';
import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
import 'package:icheck_stelacom/screens/menu/about_us.dart';
import 'package:icheck_stelacom/screens/menu/contact_us.dart';
import 'package:icheck_stelacom/screens/menu/help.dart';
import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class EnhancedBarcodeScannerScreen extends StatefulWidget {
  final int index;

  const EnhancedBarcodeScannerScreen({super.key, required this.index});

  @override
  _EnhancedBarcodeScannerScreenState createState() =>
      _EnhancedBarcodeScannerScreenState();
}

class _EnhancedBarcodeScannerScreenState
    extends State<EnhancedBarcodeScannerScreen> with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // IMEI verification system - No SharedPreferences for IMEI storage
  List<IMEIItem> imeiList = [];
  List<ScannedItem> scannedItems = [];
  Set<String> scannedBarcodes = {};

  bool isScanning = true;
  bool flashEnabled = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  // int verifiedCount = 0;
  // int totalCount = 0;
  // Only keep user-related SharedPreferences keys
  static const String STORAGE_KEY_USER_DATA = 'user_data';
  static const String STORAGE_KEY_EMPLOYEE_CODE = 'employee_code';

  // Duplicate prevention
  String? lastScannedBarcode;
  DateTime? lastScanTime;
  Timer? _scanCooldownTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _initializeAnimations();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    _storage = await SharedPreferences.getInstance();
    userData = _storage.getString(STORAGE_KEY_USER_DATA) ?? "";
    employeeCode = _storage.getString(STORAGE_KEY_EMPLOYEE_CODE) ?? "";

    if (userData.isNotEmpty) {
      try {
        userObj = jsonDecode(userData);
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    await _loadIMEIFromJSON(); // Always load fresh from JSON
  }

  // Always load IMEI from the JSON file - no caching
  Future<void> _loadIMEIFromJSON() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/json/imei_list.json');

      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      List<dynamic> devices = jsonData['devices'];
      String assignedDate = jsonData['assigned_date'] ?? _getTodayDateString();
      String username = jsonData['username'] ?? 'Unknown User';

      setState(() {
        // Always create fresh list with no verification status
        imeiList = devices
            .map((device) => IMEIItem(
                  imei: device['imei'].toString(),
                  model: device['model'].toString(),
                  isVerified: false, // Always start fresh
                  verificationTime: null, // Always start fresh
                ))
            .toList();

        // verifiedCount = imeiList.where((item) => item.isVerified).length;
        // totalCount = imeiList.length;

        // Reset scan tracking
        scannedItems.clear();
        scannedBarcodes.clear();
      });

      print('Loaded ${imeiList.length} IMEIs from JSON for user');
    } catch (e) {
      print('Error loading IMEI from JSON: $e');
      _showErrorSnackBar('Failed to load IMEI list from file');
    }
  }

  // Manual refresh method to reload IMEI list
  // Future<void> refreshIMEIList() async {
  //   await _loadIMEIFromJSON();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('IMEI list refreshed from file'),
  //       backgroundColor: Colors.blue,
  //     ),
  //   );
  // }

  // Get today's date as string (YYYY-MM-DD format)
  String _getTodayDateString() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // Show error message to user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 4),
        backgroundColor: Colors.red,
      ),
    );
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

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text('This app needs camera access to scan barcodes.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (!isScanning || _isProcessing || imeiList.isEmpty) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    // Process all barcodes in the frame
    _isProcessing = true;

    bool foundMatch = false;
    for (final barcode in barcodes) {
      final String code = barcode.rawValue ?? '';

      if (_isDuplicateBarcode(code) || !_isValidDeviceBarcode(code)) {
        continue;
      }

      // Check if this barcode matches any IMEI in the list
      IMEIItem? matchedIMEI = _findMatchingIMEI(code);

      if (matchedIMEI != null && !matchedIMEI.isVerified) {
        // Mark as verified
        setState(() {
          matchedIMEI.isVerified = true;
          matchedIMEI.verificationTime = DateTime.now();
        });

        // Add to scanned items
        _addScannedItem(code, matchedIMEI);

        // Show success message
        _showVerificationSuccess(matchedIMEI);

        foundMatch = true;
        print('IMEI verified: ${matchedIMEI.imei} - ${matchedIMEI.model}');
        break; // Process one match per scan
      }
    }

    if (!foundMatch) {
      // No matching IMEI found
      _showNoMatchFound();
    }

    // Provide feedback and set cooldown
    _provideFeedback(foundMatch);

    // Update last scan info
    lastScanTime = DateTime.now();

    // Set cooldown
    setState(() => isScanning = false);
    _scanCooldownTimer?.cancel();
    _scanCooldownTimer = Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isScanning = true);
        _isProcessing = false;
      }
    });
  }

  IMEIItem? _findMatchingIMEI(String scannedCode) {
    // Check if scanned code matches any IMEI exactly
    for (IMEIItem item in imeiList) {
      if (item.imei == scannedCode) {
        return item;
      }
    }

    // Additional matching logic if needed (e.g., partial matches)
    for (IMEIItem item in imeiList) {
      if (scannedCode.contains(item.imei) || item.imei.contains(scannedCode)) {
        return item;
      }
    }

    return null;
  }

  void _showVerificationSuccess(IMEIItem imei) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'IMEI verified successfully!\n${imei.model}',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showNoMatchFound() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Text('No matching IMEI found in inventory'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _isDuplicateBarcode(String code) {
    if (scannedBarcodes.contains(code)) return true;

    if (lastScannedBarcode == code && lastScanTime != null) {
      final timeDifference = DateTime.now().difference(lastScanTime!);
      if (timeDifference.inSeconds < 3) return true;
    }

    return false;
  }

  bool _isValidDeviceBarcode(String code) {
    if (code.trim().isEmpty) return false;
    if (code.length == 15 && RegExp(r'^\d{15}$').hasMatch(code)) return true;
    if (code.length >= 8 &&
        code.length <= 20 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase())) return true;
    return false;
  }

  void _addScannedItem(String barcode, IMEIItem imeiItem) {
    final ScannedItem item = ScannedItem(
      barcode: barcode,
      imei: imeiItem.imei,
      timestamp: DateTime.now(),
      deviceModel: imeiItem.model,
    );

    setState(() {
      scannedItems.add(item);
      scannedBarcodes.add(barcode);
    });
  }

  void _provideFeedback(bool success) {
    Vibration.vibrate(duration: success ? 100 : 200);

    if (success) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  void _toggleFlash() {
    setState(() => flashEnabled = !flashEnabled);
    cameraController.toggleTorch();
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    cameraController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  get verifiedCount => imeiList.where((item) => item.isVerified).length;
  get totalCount => imeiList.length;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

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
                                      : size.width * 0.018)),
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 3))
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
                    child: Text("IMEI Verification",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: screenHeadingColor,
                            fontSize: Responsive.isMobileSmall(context)
                                ? 22
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 26
                                    : Responsive.isTabletPortrait(context)
                                        ? 28
                                        : 32),
                        textAlign: TextAlign.center),
                  ),
                  // Add refresh button
                  // IconButton(
                  //   icon: Icon(Icons.refresh,
                  //       color: screenHeadingColor,
                  //       size: Responsive.isMobileSmall(context)
                  //           ? 20
                  //           : Responsive.isMobileMedium(context) ||
                  //                   Responsive.isMobileLarge(context)
                  //               ? 24
                  //               : Responsive.isTabletPortrait(context)
                  //                   ? 31
                  //                   : 35),
                  //   onPressed: refreshIMEIList,
                  //   tooltip: 'Refresh IMEI List',
                  // ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Camera Scanner View
            Expanded(
              flex: 8,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      MobileScanner(
                          controller: cameraController,
                          onDetect: _handleBarcodeDetection),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.transparent)),
                        child: Stack(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5))),
                            Center(
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 300,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: _isProcessing
                                                ? Colors.orange
                                                : isScanning
                                                    ? Colors.green
                                                    : Colors.red,
                                            width: 3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: _isProcessing
                                  ? Colors.orange
                                  : isScanning
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  _isProcessing
                                      ? Icons.hourglass_empty
                                      : isScanning
                                          ? Icons.camera_alt
                                          : Icons.pause,
                                  color: Colors.white,
                                  size: 16),
                              SizedBox(width: 4),
                              Text(
                                  _isProcessing
                                      ? 'Processing...'
                                      : isScanning
                                          ? 'Scanning...'
                                          : 'Cooldown',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Instruction Text
            Text(
                'Point camera at device barcode to verify IMEI against inventory',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            SizedBox(height: 10),

            // Verification Progress
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verified: $verifiedCount / $totalCount',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                              onPressed: _toggleFlash,
                              icon: Icon(
                                  flashEnabled
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                                  color: flashEnabled
                                      ? Colors.orange
                                      : Colors.grey),
                              tooltip: 'Toggle flash'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: totalCount > 0 ? verifiedCount / totalCount : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                  SizedBox(height: 8),
                  Text('${totalCount - verifiedCount} items remaining',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton(
                    'View Verification Results',
                    actionBtnColor,
                    imeiList.isNotEmpty
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => VerificationResultsScreen(
                                    index: widget.index, imeiList: imeiList)))
                        : null,
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey[300],
          foregroundColor: onPressed != null
              ? (color == Colors.grey ? Colors.grey[600] : Colors.white)
              : Colors.grey[600],
          padding: EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: onPressed != null ? 2 : 0,
        ),
        child: Text(text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:icheck_stelacom/constants.dart';
// import 'package:icheck_stelacom/models/imei_item.dart';
// import 'package:icheck_stelacom/models/scanned_item.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/veritfication_results.dart';
// import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vibration/vibration.dart';

// class EnhancedBarcodeScannerScreen extends StatefulWidget {
//   final int index;

//   const EnhancedBarcodeScannerScreen({super.key, required this.index});

//   @override
//   _EnhancedBarcodeScannerScreenState createState() =>
//       _EnhancedBarcodeScannerScreenState();
// }

// class _EnhancedBarcodeScannerScreenState
//     extends State<EnhancedBarcodeScannerScreen> with TickerProviderStateMixin {
//   MobileScannerController cameraController = MobileScannerController(
//     detectionSpeed: DetectionSpeed.noDuplicates,
//     facing: CameraFacing.back,
//     torchEnabled: false,
//   );

//   // IMEI verification system
//   List<IMEIItem> imeiList = [];
//   List<ScannedItem> scannedItems = [];
//   Set<String> scannedBarcodes = {};

//   bool isScanning = true;
//   bool flashEnabled = false;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   String employeeCode = "";
//   String userData = "";

//   // Daily reset tracking
//   static const String STORAGE_KEY_IMEI_LIST = 'imei_list';
//   static const String STORAGE_KEY_LAST_UPDATED = 'imei_list_last_updated';
//   static const String STORAGE_KEY_ASSIGNED_DATE = 'imei_assigned_date';

//   // Duplicate prevention
//   String? lastScannedBarcode;
//   DateTime? lastScanTime;
//   Timer? _scanCooldownTimer;
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _requestCameraPermission();
//     _initializeAnimations();
//     getSharedPrefs();
//   }

//   Future<void> getSharedPrefs() async {
//     _storage = await SharedPreferences.getInstance();
//     userData = _storage.getString('user_data') ?? "";
//     employeeCode = _storage.getString('employee_code') ?? "";

//     if (userData.isNotEmpty) {
//       try {
//         userObj = jsonDecode(userData);
//       } catch (e) {
//         print('Error parsing user data: $e');
//       }
//     }

//     // Load IMEI list after SharedPreferences is initialized
//     await _loadIMEIListWithDailyReset();
//   }

//   // Main method to handle daily reset and loading
//   Future<void> _loadIMEIListWithDailyReset() async {
//     try {
//       String today = _getTodayDateString();
//       String? lastUpdated = _storage.getString(STORAGE_KEY_LAST_UPDATED);

//       print('Today: $today, Last updated: $lastUpdated');

//       // Check if we need to reset (new day or first time)
//       if (lastUpdated == null || lastUpdated != today) {
//         print('Resetting IMEI list for new day');
//         await _resetAndLoadFreshIMEIList(today);
//       } else {
//         // Load existing data from storage
//         print('Loading existing IMEI list from storage');
//         await _loadIMEIListFromStorage();
//       }
//     } catch (e) {
//       print('Error in daily reset logic: $e');
//       // Fallback to loading from JSON
//       await _loadIMEIFromJSON();
//     }
//   }

//   // Reset and load fresh IMEI list
//   Future<void> _resetAndLoadFreshIMEIList(String today) async {
//     try {
//       // Clear existing IMEI data
//       await _storage.remove(STORAGE_KEY_IMEI_LIST);

//       // Load fresh data from JSON file
//       await _loadIMEIFromJSON();

//       // Update the last updated date
//       await _storage.setString(STORAGE_KEY_LAST_UPDATED, today);

//       print('Fresh IMEI list loaded and date updated');
//     } catch (e) {
//       print('Error resetting IMEI list: $e');
//     }
//   }

//   // Get today's date as string (YYYY-MM-DD format)
//   String _getTodayDateString() {
//     DateTime now = DateTime.now();
//     return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
//   }

//   // Load IMEI list from storage (existing verified states preserved)
//   Future<void> _loadIMEIListFromStorage() async {
//     try {
//       String? storedIMEIList = _storage.getString(STORAGE_KEY_IMEI_LIST);

//       if (storedIMEIList != null) {
//         List<dynamic> jsonList = jsonDecode(storedIMEIList);
//         setState(() {
//           imeiList = jsonList.map((json) => IMEIItem.fromJson(json)).toList();
//         });
//         print('Loaded ${imeiList.length} IMEIs from storage');
//       } else {
//         // If no stored data, load from JSON
//         await _loadIMEIFromJSON();
//       }
//     } catch (e) {
//       print('Error loading IMEI list from storage: $e');
//       await _loadIMEIFromJSON();
//     }
//   }

//   // Load IMEI from the attached JSON file
//   Future<void> _loadIMEIFromJSON() async {
//     try {
//       // Load JSON from assets
//       String jsonString =
//           await rootBundle.loadString('assets/json/imei_list.json');

//       Map<String, dynamic> jsonData = jsonDecode(jsonString);
//       List<dynamic> devices = jsonData['devices'];
//       String assignedDate = jsonData['assigned_date'] ?? _getTodayDateString();
//       String username = jsonData['username'] ?? 'Unknown User';

//       setState(() {
//         imeiList = devices
//             .map((device) => IMEIItem(
//                   imei: device['imei'].toString(),
//                   model: device['model'].toString(),
//                   isVerified: false, // Reset verification status
//                   verificationTime: null, // Reset verification time
//                 ))
//             .toList();
//       });

//       // Save to storage with today's date
//       await _saveIMEIListToStorage();
//       await _storage.setString(STORAGE_KEY_ASSIGNED_DATE, assignedDate);

//       print(
//           'Loaded ${imeiList.length} IMEIs from JSON for user: $username on $assignedDate');
//     } catch (e) {
//       print('Error loading IMEI from JSON: $e');
//       // Show error to user
//       _showErrorSnackBar('Failed to load IMEI list from file');
//     }
//   }

//   // Alternative method to load IMEI from API response
//   Future<void> loadIMEIFromAPI(Map<String, dynamic> apiResponse) async {
//     try {
//       List<dynamic> devices = apiResponse['devices'];
//       String assignedDate =
//           apiResponse['assigned_date'] ?? _getTodayDateString();
//       String username = apiResponse['username'] ?? 'Unknown User';

//       setState(() {
//         imeiList = devices
//             .map((device) => IMEIItem(
//                   imei: device['imei'].toString(),
//                   model: device['model'].toString(),
//                   isVerified: false,
//                   verificationTime: null,
//                 ))
//             .toList();
//       });

//       // Save to storage
//       await _saveIMEIListToStorage();
//       await _storage.setString(STORAGE_KEY_ASSIGNED_DATE, assignedDate);
//       await _storage.setString(STORAGE_KEY_LAST_UPDATED, _getTodayDateString());

//       print('Loaded ${imeiList.length} IMEIs from API for user: $username');
//     } catch (e) {
//       print('Error loading IMEI from API: $e');
//       _showErrorSnackBar('Failed to load IMEI list from API');
//     }
//   }

//   // Save IMEI list to storage
//   Future<void> _saveIMEIListToStorage() async {
//     try {
//       List<Map<String, dynamic>> jsonList =
//           imeiList.map((item) => item.toJson()).toList();
//       await _storage.setString(STORAGE_KEY_IMEI_LIST, jsonEncode(jsonList));
//     } catch (e) {
//       print('Error saving IMEI list: $e');
//     }
//   }

//   // Clear all IMEI related data (useful for manual reset)
//   Future<void> clearIMEIData() async {
//     try {
//       await _storage.remove(STORAGE_KEY_IMEI_LIST);
//       await _storage.remove(STORAGE_KEY_LAST_UPDATED);
//       await _storage.remove(STORAGE_KEY_ASSIGNED_DATE);

//       setState(() {
//         imeiList.clear();
//         scannedItems.clear();
//         scannedBarcodes.clear();
//       });

//       print('IMEI data cleared successfully');
//     } catch (e) {
//       print('Error clearing IMEI data: $e');
//     }
//   }

//   // Show error message to user
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.error, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         duration: Duration(seconds: 4),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   // SIDE MENU BAR UI
//   List<String> _menuOptions = [
//     'Help',
//     'About Us',
//     'Contact Us',
//     'T & C',
//     'Reset IMEI List', // Added option to manually reset
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
//       // Manual reset option
//       _showResetConfirmationDialog();
//     } else if (choice == _menuOptions[5]) {
//       if (!mounted) return;
//       _storage.clear();
//       Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
//         (route) => false,
//       );
//     }
//   }

//   void _showResetConfirmationDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Reset IMEI List'),
//         content: Text(
//             'Are you sure you want to reset the IMEI list? This will clear all verification progress.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await clearIMEIData();
//               await _loadIMEIFromJSON();
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('IMEI list has been reset'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             child: Text('Reset'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _initializeAnimations() {
//     _pulseController = AnimationController(
//       duration: Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//   }

//   Future<void> _requestCameraPermission() async {
//     final status = await Permission.camera.request();
//     if (status.isDenied) {
//       _showPermissionDialog();
//     }
//   }

//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Camera Permission Required'),
//         content: Text('This app needs camera access to scan barcodes.'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context), child: Text('Cancel')),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             child: Text('Settings'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleBarcodeDetection(BarcodeCapture capture) {
//     if (!isScanning || _isProcessing || imeiList.isEmpty) return;

//     final List<Barcode> barcodes = capture.barcodes;
//     if (barcodes.isEmpty) return;

//     // Process all barcodes in the frame
//     _isProcessing = true;

//     bool foundMatch = false;
//     for (final barcode in barcodes) {
//       final String code = barcode.rawValue ?? '';

//       if (_isDuplicateBarcode(code) || !_isValidDeviceBarcode(code)) {
//         continue;
//       }

//       // Check if this barcode matches any IMEI in the list
//       IMEIItem? matchedIMEI = _findMatchingIMEI(code);

//       if (matchedIMEI != null && !matchedIMEI.isVerified) {
//         // Mark as verified
//         setState(() {
//           matchedIMEI.isVerified = true;
//           matchedIMEI.verificationTime = DateTime.now();
//         });

//         // Add to scanned items
//         _addScannedItem(code, matchedIMEI);

//         // Save updated list
//         _saveIMEIListToStorage();

//         // Show success message
//         _showVerificationSuccess(matchedIMEI);

//         foundMatch = true;
//         print('IMEI verified: ${matchedIMEI.imei} - ${matchedIMEI.model}');
//         break; // Process one match per scan
//       }
//     }

//     if (!foundMatch) {
//       // No matching IMEI found
//       _showNoMatchFound();
//     }

//     // Provide feedback and set cooldown
//     _provideFeedback(foundMatch);

//     // Update last scan info
//     lastScanTime = DateTime.now();

//     // Set cooldown
//     setState(() => isScanning = false);
//     _scanCooldownTimer?.cancel();
//     _scanCooldownTimer = Timer(Duration(seconds: 2), () {
//       if (mounted) {
//         setState(() => isScanning = true);
//         _isProcessing = false;
//       }
//     });
//   }

//   IMEIItem? _findMatchingIMEI(String scannedCode) {
//     // Check if scanned code matches any IMEI exactly
//     for (IMEIItem item in imeiList) {
//       if (item.imei == scannedCode) {
//         return item;
//       }
//     }

//     // Additional matching logic if needed (e.g., partial matches)
//     for (IMEIItem item in imeiList) {
//       if (scannedCode.contains(item.imei) || item.imei.contains(scannedCode)) {
//         return item;
//       }
//     }

//     return null;
//   }

//   void _showVerificationSuccess(IMEIItem imei) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'IMEI verified successfully!\n${imei.model}',
//                 style:
//                     TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//         duration: Duration(seconds: 3),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showNoMatchFound() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.white),
//             SizedBox(width: 8),
//             Text('No matching IMEI found in inventory'),
//           ],
//         ),
//         duration: Duration(seconds: 2),
//         backgroundColor: Colors.orange,
//       ),
//     );
//   }

//   bool _isDuplicateBarcode(String code) {
//     if (scannedBarcodes.contains(code)) return true;

//     if (lastScannedBarcode == code && lastScanTime != null) {
//       final timeDifference = DateTime.now().difference(lastScanTime!);
//       if (timeDifference.inSeconds < 3) return true;
//     }

//     return false;
//   }

//   bool _isValidDeviceBarcode(String code) {
//     if (code.trim().isEmpty) return false;
//     if (code.length == 15 && RegExp(r'^\d{15}$').hasMatch(code)) return true;
//     if (code.length >= 8 &&
//         code.length <= 20 &&
//         RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase())) return true;
//     return false;
//   }

//   void _addScannedItem(String barcode, IMEIItem imeiItem) {
//     final ScannedItem item = ScannedItem(
//       barcode: barcode,
//       imei: imeiItem.imei,
//       timestamp: DateTime.now(),
//       deviceModel: imeiItem.model,
//     );

//     setState(() {
//       scannedItems.add(item);
//       scannedBarcodes.add(barcode);
//     });
//   }

//   void _provideFeedback(bool success) {
//     Vibration.vibrate(duration: success ? 100 : 200);

//     if (success) {
//       _pulseController.forward().then((_) => _pulseController.reverse());
//     }
//   }

//   void _toggleFlash() {
//     setState(() => flashEnabled = !flashEnabled);
//     cameraController.toggleTorch();
//   }

//   int get verifiedCount => imeiList.where((item) => item.isVerified).length;
//   int get totalCount => imeiList.length;

//   @override
//   void dispose() {
//     _scanCooldownTimer?.cancel();
//     cameraController.dispose();
//     _pulseController.dispose();
//     super.dispose();
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
//                           fontWeight: FontWeight.w400,
//                           fontSize: Responsive.isMobileSmall(context)
//                               ? 15
//                               : Responsive.isMobileMedium(context) ||
//                                       Responsive.isMobileLarge(context)
//                                   ? 17
//                                   : Responsive.isTabletPortrait(context)
//                                       ? size.width * 0.025
//                                       : size.width * 0.018)),
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
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(30),
//                     bottomRight: Radius.circular(30)),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.grey.withOpacity(0.1),
//                       spreadRadius: 2,
//                       blurRadius: 10,
//                       offset: Offset(0, 3))
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
//                     child: Text("IMEI Verification",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: screenHeadingColor,
//                             fontSize: Responsive.isMobileSmall(context)
//                                 ? 22
//                                 : Responsive.isMobileMedium(context) ||
//                                         Responsive.isMobileLarge(context)
//                                     ? 26
//                                     : Responsive.isTabletPortrait(context)
//                                         ? 28
//                                         : 32),
//                         textAlign: TextAlign.center),
//                   ),
//                   Expanded(flex: 1, child: Text("")),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10),

//             // Camera Scanner View
//             Expanded(
//               flex: 6,
//               child: Container(
//                 margin: EdgeInsets.symmetric(horizontal: 20),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: Offset(0, 5))
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: Stack(
//                     children: [
//                       MobileScanner(
//                           controller: cameraController,
//                           onDetect: _handleBarcodeDetection),
//                       Container(
//                         decoration: BoxDecoration(
//                             border: Border.all(color: Colors.transparent)),
//                         child: Stack(
//                           children: [
//                             Container(
//                                 decoration: BoxDecoration(
//                                     color: Colors.black.withOpacity(0.5))),
//                             Center(
//                               child: AnimatedBuilder(
//                                 animation: _pulseAnimation,
//                                 builder: (context, child) {
//                                   return Transform.scale(
//                                     scale: _pulseAnimation.value,
//                                     child: Container(
//                                       width: 250,
//                                       height: 150,
//                                       decoration: BoxDecoration(
//                                         border: Border.all(
//                                             color: _isProcessing
//                                                 ? Colors.orange
//                                                 : isScanning
//                                                     ? Colors.green
//                                                     : Colors.red,
//                                             width: 3),
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Positioned(
//                         top: 20,
//                         right: 20,
//                         child: Container(
//                           padding:
//                               EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                               color: _isProcessing
//                                   ? Colors.orange
//                                   : isScanning
//                                       ? Colors.green
//                                       : Colors.red,
//                               borderRadius: BorderRadius.circular(20)),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                   _isProcessing
//                                       ? Icons.hourglass_empty
//                                       : isScanning
//                                           ? Icons.camera_alt
//                                           : Icons.pause,
//                                   color: Colors.white,
//                                   size: 16),
//                               SizedBox(width: 4),
//                               Text(
//                                   _isProcessing
//                                       ? 'Processing...'
//                                       : isScanning
//                                           ? 'Scanning...'
//                                           : 'Cooldown',
//                                   style: TextStyle(
//                                       color: Colors.white, fontSize: 12)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),

//             // Instruction Text
//             Text(
//                 'Point camera at device barcode to verify IMEI against inventory',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey[600], fontSize: 14)),
//             SizedBox(height: 20),

//             // Verification Progress
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 20),
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: Offset(0, 2))
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text('Verified: $verifiedCount / $totalCount',
//                           style: TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold)),
//                       Row(
//                         children: [
//                           IconButton(
//                               onPressed: _toggleFlash,
//                               icon: Icon(
//                                   flashEnabled
//                                       ? Icons.flash_on
//                                       : Icons.flash_off,
//                                   color: flashEnabled
//                                       ? Colors.orange
//                                       : Colors.grey),
//                               tooltip: 'Toggle flash'),
//                         ],
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10),
//                   LinearProgressIndicator(
//                     value: totalCount > 0 ? verifiedCount / totalCount : 0,
//                     backgroundColor: Colors.grey[300],
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//                     minHeight: 8,
//                   ),
//                   SizedBox(height: 8),
//                   Text('${totalCount - verifiedCount} items remaining',
//                       style: TextStyle(color: Colors.grey[600], fontSize: 12)),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),

//             // Action Buttons
//             Expanded(
//               flex: 2,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   _buildButton(
//                     'View Verification Results',
//                     actionBtnColor,
//                     imeiList.isNotEmpty
//                         ? () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => VerificationResultsScreen(
//                                     index: widget.index, imeiList: imeiList)))
//                         : null,
//                   ),
//                   SizedBox(height: 15),
//                 ],
//               ),
//             ),
//             SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(String text, Color color, VoidCallback? onPressed) {
//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: onPressed != null ? color : Colors.grey[300],
//           foregroundColor: onPressed != null
//               ? (color == Colors.grey ? Colors.grey[600] : Colors.white)
//               : Colors.grey[600],
//           padding: EdgeInsets.symmetric(vertical: 15),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: onPressed != null ? 2 : 0,
//         ),
//         child: Text(text,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//       ),
//     );
//   }
// }
// import 'dart:convert';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:icheck_stelacom/constants.dart';
// import 'package:icheck_stelacom/models/scanned_item.dart';
// import 'package:icheck_stelacom/responsive.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/variance_reports.dart';
// import 'package:icheck_stelacom/screens/Inventroy-Scan/xyz.dart';
// import 'package:icheck_stelacom/screens/enroll/code_verification.dart';
// import 'package:icheck_stelacom/screens/menu/about_us.dart';
// import 'package:icheck_stelacom/screens/menu/contact_us.dart';
// import 'package:icheck_stelacom/screens/menu/help.dart';
// import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vibration/vibration.dart';
// import 'dart:async';

// // Enhanced Barcode Scanner Screen with Real Scanning
// class EnhancedBarcodeScannerScreen extends StatefulWidget {
//   final int index;

//   const EnhancedBarcodeScannerScreen({super.key, required this.index});

//   @override
//   _EnhancedBarcodeScannerScreenState createState() =>
//       _EnhancedBarcodeScannerScreenState();
// }

// class _EnhancedBarcodeScannerScreenState
//     extends State<EnhancedBarcodeScannerScreen> with TickerProviderStateMixin {
//   MobileScannerController cameraController = MobileScannerController(
//     detectionSpeed: DetectionSpeed.noDuplicates,
//     facing: CameraFacing.back,
//     torchEnabled: false,
//   );
//   List<ScannedItem> scannedItems = [];
//   bool isScanning = true;
//   bool flashEnabled = false;
//   int expectedItems = 10;
//   Set<String> scannedBarcodes = {}; // To prevent duplicates
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   String employeeCode = "";
//   String userData = "";

//   // Additional duplicate prevention
//   String? lastScannedBarcode;
//   DateTime? lastScanTime;
//   Timer? _scanCooldownTimer;
//   bool _isProcessing = false; // Prevent multiple simultaneous processing

//   @override
//   void initState() {
//     super.initState();
//     _requestCameraPermission();
//     _initializeAnimations();
//     getSharedPrefs();
//   }

//   Future<void> getSharedPrefs() async {
//     _storage = await SharedPreferences.getInstance();
//     userData = _storage.getString('user_data') ?? "";
//     employeeCode = _storage.getString('employee_code') ?? "";

//     if (userData.isNotEmpty) {
//       try {
//         userObj = jsonDecode(userData);
//       } catch (e) {
//         print('Error parsing user data: $e');
//       }
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
//       if (!mounted) return;
//       _storage.clear();
//       Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
//         (route) => false,
//       );
//     }
//   }

//   void _initializeAnimations() {
//     _pulseController = AnimationController(
//       duration: Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//   }

//   Future<void> _requestCameraPermission() async {
//     final status = await Permission.camera.request();
//     if (status.isDenied) {
//       _showPermissionDialog();
//     }
//   }

//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Camera Permission Required'),
//         content: Text('This app needs camera access to scan barcodes.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             child: Text('Settings'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleBarcodeDetection(BarcodeCapture capture) {
//     // Enhanced duplicate prevention
//     if (!isScanning || _isProcessing) {
//       print('Scanning disabled or processing in progress');
//       return;
//     }

//     final List<Barcode> barcodes = capture.barcodes;
//     if (barcodes.isEmpty) return;

//     // Process only the first barcode to avoid multiple simultaneous processing
//     final barcode = barcodes.first;
//     final String code = barcode.rawValue ?? '';

//     // Comprehensive duplicate checking
//     if (_isDuplicateBarcode(code)) {
//       print('Duplicate barcode detected: $code');
//       return;
//     }

//     // Validate if it looks like an IMEI or device barcode
//     if (!_isValidDeviceBarcode(code)) {
//       print('Invalid barcode format: $code');
//       return;
//     }

//     // Set processing flag to prevent simultaneous processing
//     _isProcessing = true;

//     print('Processing barcode: $code');
//     _addScannedItem(code);
//     _provideFeedback();

//     // Update last scan info
//     lastScannedBarcode = code;
//     lastScanTime = DateTime.now();

//     // Disable scanning temporarily with longer cooldown
//     setState(() => isScanning = false);

//     // Cancel any existing timer
//     _scanCooldownTimer?.cancel();

//     // Set a longer cooldown period (3 seconds)
//     _scanCooldownTimer = Timer(Duration(seconds: 3), () {
//       if (mounted) {
//         setState(() => isScanning = true);
//         _isProcessing = false;
//         print('Scanning re-enabled');
//       }
//     });
//   }

//   bool _isDuplicateBarcode(String code) {
//     // Check if already in scanned set
//     if (scannedBarcodes.contains(code)) {
//       return true;
//     }

//     // Check against last scanned barcode with time threshold
//     if (lastScannedBarcode == code && lastScanTime != null) {
//       final timeDifference = DateTime.now().difference(lastScanTime!);
//       if (timeDifference.inSeconds < 5) {
//         // 5-second threshold
//         return true;
//       }
//     }

//     // Check in scanned items list (additional safety)
//     for (var item in scannedItems) {
//       if (item.barcode == code) {
//         return true;
//       }
//     }

//     return false;
//   }

//   bool _isValidDeviceBarcode(String code) {
//     // More strict validation
//     if (code.trim().isEmpty) return false;

//     // Check for IMEI (15 digits)
//     if (code.length == 15 && RegExp(r'^\d{15}$').hasMatch(code)) return true;

//     // Check for other device barcode patterns (8-20 alphanumeric characters)
//     if (code.length >= 8 &&
//         code.length <= 20 &&
//         RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase())) return true;

//     // Check for numeric barcodes (10-15 digits)
//     if (code.length >= 10 &&
//         code.length <= 15 &&
//         RegExp(r'^\d+$').hasMatch(code)) return true;

//     print('Invalid barcode format: $code (length: ${code.length})');
//     return false;
//   }

//   void _addScannedItem(String barcode) {
//     final String mockIMEI = _generateMockIMEI(barcode);
//     final ScannedItem item = ScannedItem(
//       barcode: barcode,
//       imei: mockIMEI,
//       timestamp: DateTime.now(),
//       deviceModel: _getMockDeviceModel(),
//     );

//     setState(() {
//       scannedItems.add(item);
//       scannedBarcodes.add(barcode);
//     });

//     print('Added item - Total scanned: ${scannedItems.length}');
//     print('Barcode: $barcode, IMEI: $mockIMEI');
//   }

//   String _generateMockIMEI(String barcode) {
//     // Generate more realistic IMEI based on barcode
//     final String base = '35693803564';
//     // Use a more deterministic approach for the suffix
//     final int hash = barcode.hashCode.abs();
//     final String suffix = (hash % 10000).toString().padLeft(4, '0');
//     return base + suffix;
//   }

//   String _getMockDeviceModel() {
//     final List<String> models = [
//       'iPhone 13 Pro',
//       'iPhone 14 Pro Max',
//       'Samsung Galaxy S23',
//       'Google Pixel 7',
//       'OnePlus 11',
//       'Xiaomi 13 Pro',
//     ];
//     // Use timestamp to get different models for different scans
//     return models[DateTime.now().millisecond % models.length];
//   }

//   void _provideFeedback() {
//     // Vibration feedback
//     Vibration.vibrate(duration: 100);

//     // Visual feedback
//     _pulseController.forward().then((_) => _pulseController.reverse());

//     // Show snackbar for confirmation
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content:
//             Text('Barcode scanned successfully! Total: ${scannedItems.length}'),
//         duration: Duration(seconds: 2),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _toggleFlash() {
//     setState(() => flashEnabled = !flashEnabled);
//     cameraController.toggleTorch();
//   }

//   void _clearAllScans() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Clear All Scans'),
//         content: Text('Are you sure you want to clear all scanned items?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 scannedItems.clear();
//                 scannedBarcodes.clear();
//                 lastScannedBarcode = null;
//                 lastScanTime = null;
//                 _isProcessing = false;
//               });
//               _scanCooldownTimer?.cancel();
//               setState(() => isScanning = true);
//             },
//             child: Text('Clear', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _scanCooldownTimer?.cancel();
//     cameraController.dispose();
//     _pulseController.dispose();
//     super.dispose();
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
//             SizedBox(height: 10),
//             // Camera Scanner View
//             Expanded(
//               flex: 3,
//               child: Container(
//                 margin: EdgeInsets.symmetric(horizontal: 20),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: Stack(
//                     children: [
//                       MobileScanner(
//                         controller: cameraController,
//                         onDetect: _handleBarcodeDetection,
//                       ),

//                       // Scanning Overlay
//                       Container(
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.transparent),
//                         ),
//                         child: Stack(
//                           children: [
//                             // Dark overlay with cutout
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withOpacity(0.5),
//                               ),
//                             ),

//                             // Scanning frame
//                             Center(
//                               child: AnimatedBuilder(
//                                 animation: _pulseAnimation,
//                                 builder: (context, child) {
//                                   return Transform.scale(
//                                     scale: _pulseAnimation.value,
//                                     child: Container(
//                                       width: 250,
//                                       height: 150,
//                                       decoration: BoxDecoration(
//                                         border: Border.all(
//                                           color: _isProcessing
//                                               ? Colors.orange
//                                               : isScanning
//                                                   ? Colors.green
//                                                   : Colors.red,
//                                           width: 3,
//                                         ),
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Stack(
//                                         children: [
//                                           // Corner decorations
//                                           ...List.generate(4, (index) {
//                                             return Positioned(
//                                               top: index < 2 ? 0 : null,
//                                               bottom: index >= 2 ? 0 : null,
//                                               left: index % 2 == 0 ? 0 : null,
//                                               right: index % 2 == 1 ? 0 : null,
//                                               child: Container(
//                                                 width: 20,
//                                                 height: 20,
//                                                 decoration: BoxDecoration(
//                                                   border: Border(
//                                                     top: index < 2
//                                                         ? BorderSide(
//                                                             color: isScanning
//                                                                 ? Colors.green
//                                                                 : Colors.red,
//                                                             width: 4)
//                                                         : BorderSide.none,
//                                                     bottom: index >= 2
//                                                         ? BorderSide(
//                                                             color: isScanning
//                                                                 ? Colors.green
//                                                                 : Colors.red,
//                                                             width: 4)
//                                                         : BorderSide.none,
//                                                     left: index % 2 == 0
//                                                         ? BorderSide(
//                                                             color: isScanning
//                                                                 ? Colors.green
//                                                                 : Colors.red,
//                                                             width: 4)
//                                                         : BorderSide.none,
//                                                     right: index % 2 == 1
//                                                         ? BorderSide(
//                                                             color: isScanning
//                                                                 ? Colors.green
//                                                                 : Colors.red,
//                                                             width: 4)
//                                                         : BorderSide.none,
//                                                   ),
//                                                 ),
//                                               ),
//                                             );
//                                           }),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Scan status indicator
//                       Positioned(
//                         top: 20,
//                         right: 20,
//                         child: Container(
//                           padding:
//                               EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: _isProcessing
//                                 ? Colors.orange
//                                 : isScanning
//                                     ? Colors.green
//                                     : Colors.red,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 _isProcessing
//                                     ? Icons.hourglass_empty
//                                     : isScanning
//                                         ? Icons.camera_alt
//                                         : Icons.pause,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 _isProcessing
//                                     ? 'Processing...'
//                                     : isScanning
//                                         ? 'Scanning...'
//                                         : 'Cooldown',
//                                 style: TextStyle(
//                                     color: Colors.white, fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),

//             // Instruction Text
//             Text(
//               'Point camera at each barcode individually. Each barcode will be scanned only once.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey[600], fontSize: 14),
//             ),
//             SizedBox(height: 20),

//             // Scan Progress
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 20),
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Scanned Items: ${scannedItems.length}',
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                       Row(
//                         children: [
//                           IconButton(
//                             onPressed: _toggleFlash,
//                             icon: Icon(
//                               flashEnabled ? Icons.flash_on : Icons.flash_off,
//                               color: flashEnabled ? Colors.orange : Colors.grey,
//                             ),
//                             tooltip: 'Toggle flash',
//                           ),
//                           IconButton(
//                             onPressed:
//                                 scannedItems.isNotEmpty ? _clearAllScans : null,
//                             icon: Icon(Icons.clear_all, color: Colors.red),
//                             tooltip: 'Clear all scans',
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10),
//                   LinearProgressIndicator(
//                     value: scannedItems.length / expectedItems,
//                     backgroundColor: Colors.grey[300],
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
//                     minHeight: 8,
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Target: $expectedItems items',
//                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             // Buttons
//             Expanded(
//               flex: 2,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   _buildButton(
//                     'View Scanned Items (${scannedItems.length})',
//                     actionBtnColor,
//                     scannedItems.isNotEmpty
//                         ? () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => XYZ(
//                                   index: widget.index,
//                                   scannedItems: scannedItems,
//                                 ),
//                               ),
//                             )
//                         : null,
//                   ),
//                   SizedBox(height: 15),
//                   _buildButton(
//                     'Complete Scan & Generate Report',
//                     actionBtnColor,
//                     scannedItems.isNotEmpty
//                         ? () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => VarianceReportScreen(
//                                         index: widget.index,
//                                       )),
//                             )
//                         : null,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(String text, Color color, VoidCallback? onPressed) {
//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: onPressed != null ? color : Colors.grey[300],
//           foregroundColor: onPressed != null
//               ? (color == Colors.grey ? Colors.grey[600] : Colors.white)
//               : Colors.grey[600],
//           padding: EdgeInsets.symmetric(vertical: 15),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: onPressed != null ? 2 : 0,
//         ),
//         child: Text(text,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//       ),
//     );
//   }
// }
