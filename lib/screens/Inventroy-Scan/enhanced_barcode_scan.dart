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
          await rootBundle.loadString('assets/json/imei_list2.json');

      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      List<dynamic> devices = jsonData['devices'];
      // String assignedDate = jsonData['assigned_date'] ?? _getTodayDateString();
      // String username = jsonData['username'] ?? 'Unknown User';

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

  // Get today's date as string (YYYY-MM-DD format)
  // String _getTodayDateString() {
  //   DateTime now = DateTime.now();
  //   return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  // }

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
                      Text('Scanning Verified: $verifiedCount / $totalCount',
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
