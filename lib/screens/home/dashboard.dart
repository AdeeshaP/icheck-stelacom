import 'dart:async';
import 'package:icheck_stelacom/services/api_service.dart';
import 'package:icheck_stelacom/main.dart';
import 'package:icheck_stelacom/screens/Inventroy-Scan/enhanced_barcode_scan.dart';
import 'package:icheck_stelacom/screens/Visits/capture_screen.dart';
import 'package:icheck_stelacom/screens/checkin-checkout/checkin_capture_screen.dart';
import 'package:icheck_stelacom/screens/checkin-checkout/checkout_capture_screen.dart';
import 'package:icheck_stelacom/services/location_service.dart';
import '../enroll/code_verification.dart';
import 'package:icheck_stelacom/constants.dart';
import 'package:icheck_stelacom/screens/location_restrictions/location_restrictions.dart';
import 'package:icheck_stelacom/screens/menu/contact_us.dart';
import 'package:icheck_stelacom/screens/menu/help.dart';
import 'package:icheck_stelacom/providers/appstate_provieder.dart';
import 'package:icheck_stelacom/providers/loxcation_provider.dart';
import 'package:icheck_stelacom/responsive.dart';
import 'package:flutter/material.dart';
import 'package:icheck_stelacom/screens/menu/about_us.dart';
import 'package:icheck_stelacom/screens/menu/terms_conditions.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/dialogs.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_version_update/app_version_update.dart';

class Dashboard extends StatefulWidget {
  Dashboard({super.key, required this.index3});

  final int index3;
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  Map<String, dynamic>? lastCheckIn;
  String workedTime = "";
  late DateTime? lastCheckInTime;
  String employeeCode = "";
  VersionStatus? versionstatus;
  DateTime? NOTIFCATION_POPUP_DISPLAY_TIME;
  String inTime = "";
  String outTime = "";
  String attendanceId = "";
  final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
  late AppState appState;
  String formattedDuration = "";
  String formattedDate = "";
  String formattedInTime = "";
  String formattedOutTime = "";

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AppState>(context, listen: false);

    WidgetsBinding.instance.addObserver(this);
    getSharedPrefs();

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      appState.updateOfficeDate(
          Jiffy.now().format(pattern: "EEEE") + ", " + Jiffy.now().yMMMMd);
      appState.updateOfficeTime(Jiffy.now().format(pattern: "hh:mm:ss a"));
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      updateWorkTime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    await getVersionStatus();

    _storage = await SharedPreferences.getInstance();
    String? userData = _storage.getString('user_data');
    employeeCode = _storage.getString('employee_code') ?? "";

    if (userData == null) {
      await loadUserData();
    } else {
      userObj = jsonDecode(userData);

      if (mounted) appState.updateOfficeAddress(userObj!["OfficeAddress"]);
      await loadLastCheckIn();
    }

    if (versionstatus != null) {
      Future.delayed(Duration(seconds: 2), () async {
        _verifyVersion();
      });
    }
  }

// --------GET App Version Status--------------//
  Future<VersionStatus> getVersionStatus() async {
    NewVersionPlus? newVersion =
        NewVersionPlus(androidId: "com.aura.icheckapp");

    VersionStatus? status = await newVersion.getVersionStatus();
    setState(() {
      versionstatus = status;
    });
    print(newVersion);

    // if (versionstatus != null) {
    return versionstatus!;
    // }
  }

  // SIDE MENU BAR UI
  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out'
  ];

  // --------- Side Menu Bar Navigation ---------- //
  void choiceAction(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return HelpScreen(
            index3: 0,
          );
        }),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs(
            index3: 0,
          );
        }),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs(
            index3: 0,
          );
        }),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions(
            index3: 0,
          );
        }),
      );
    } else if (choice == _menuOptions[4]) {
      if (!mounted)
        return;
      else {
        _storage.clear();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
          (route) => false,
        );
      }
    }
  }

  // VERSION UPDATE

  Future<void> _verifyVersion() async {
    AppVersionUpdate.checkForUpdates(
      appleId: '1581265618',
      playStoreId: 'com.aura.icheckapp',
      country: 'us',
    ).then(
      (result) async {
        if (result.canUpdate!) {
          await AppVersionUpdate.showAlertUpdate(
            appVersionResult: result,
            context: context,
            backgroundColor: Colors.grey[100],
            title: '      Update Available',
            titleTextStyle: TextStyle(
              color: normalTextColor,
              fontWeight: FontWeight.w600,
              fontSize: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 24
                  : Responsive.isTabletPortrait(context)
                      ? 28
                      : 27,
            ),
            content:
                "You're currently using iCheck ${versionstatus!.localVersion}, but new version ${result.storeVersion} is now available on the Play Store. Update now for the latest features!",
            contentTextStyle: TextStyle(
                color: normalTextColor,
                fontWeight: FontWeight.w400,
                fontSize: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 16
                    : Responsive.isTabletPortrait(context)
                        ? 25
                        : 24,
                height: 1.5),
            updateButtonText: 'UPDATE',
            updateTextStyle: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
            ),
            updateButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(actionBtnTextColor),
                backgroundColor: WidgetStateProperty.all(Colors.green[800]),
                minimumSize: Responsive.isMobileSmall(context)
                    ? WidgetStateProperty.all(Size(90, 40))
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? WidgetStateProperty.all(Size(100, 45))
                        : Responsive.isTabletPortrait(context)
                            ? WidgetStateProperty.all(Size(160, 60))
                            : WidgetStateProperty.all(Size(140, 50)),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0)),
                )),
            cancelButtonText: 'NO THANKS',
            cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(actionBtnTextColor),
                backgroundColor: WidgetStateProperty.all(Colors.red[800]),
                minimumSize: Responsive.isMobileSmall(context)
                    ? WidgetStateProperty.all(Size(90, 40))
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? WidgetStateProperty.all(Size(100, 45))
                        : Responsive.isTabletPortrait(context)
                            ? WidgetStateProperty.all(Size(160, 60))
                            : WidgetStateProperty.all(Size(140, 50)),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0)),
                )),
            cancelTextStyle: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
            ),
          );
        }
      },
    );
  }

  // MOVE TO TURN ON DEVICE LOCATION

  void switchOnLocation() async {
    closeDialog(context);
    bool ison = await Geolocator.isLocationServiceEnabled();
    if (!ison) {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        SystemNavigator.pop();
      },
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return Scaffold(
            key: firstTabNavKey,
            backgroundColor: screenbgcolor,
            appBar: AppBar(
              backgroundColor: appbarBgColor,
              shadowColor: Colors.grey[100],
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
                  // --------- App Logo ---------- //
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
                    child: Image.asset(
                      'assets/images/iCheck_logo_2024.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: size.width * 0.25),
                  // --------- Company Logo ---------- //
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
                    child: userObj != null
                        ? CachedNetworkImage(
                            imageUrl: userObj!['CompanyProfileImage'],
                            placeholder: (context, url) => Text("..."),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
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
                        child: Text(
                          choice,
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
                          ),
                        ),
                      );
                    }).toList();
                  },
                )
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Time and Date Section
                  Container(
                    height: 160,
                    width: size.width * 0.9,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          appState.officeTime,
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 25
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 30
                                    : Responsive.isTabletPortrait(context)
                                        ? 35
                                        : 35,
                            fontWeight: FontWeight.bold,
                            color: screenHeadingColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          appState.officeDate,
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 16
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 18
                                    : Responsive.isTabletPortrait(context)
                                        ? 20
                                        : 22,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            appState.officeAddress,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 14
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 15.5
                                      : Responsive.isTabletPortrait(context)
                                          ? 18
                                          : 20,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 20.0),
                    child: Column(
                      children: [
                        //------------- Check In Button-------------
                        ElevatedButton(
                          onPressed: () {
                            if (lastCheckIn == null ||
                                lastCheckIn!["OutTime"] != null) {
                              Geolocator.isLocationServiceEnabled()
                                  .then((bool serviceEnabled) {
                                //check whether user is deactivated or not
                                if (userObj!['Deleted'] == 0) {
                                  if (serviceEnabled) {
                                    if (userObj!['EnableLocation'] > 0) {
                                      if (userObj![
                                              'EnableLocationRestriction'] ==
                                          1) {
                                        _storage.setString('Action', 'checkin');
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider(
                                              create: (context) =>
                                                  LocationRestrictionState(),
                                              child: ValidateLocation(
                                                widget.index3,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider(
                                                    create: (context) =>
                                                        AppState(),
                                                    child: CheckInCapture()),
                                          ),
                                        );
                                      }
                                    } else {
                                      Navigator.of(context, rootNavigator: true)
                                          .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider(
                                                  create: (context) =>
                                                      AppState(),
                                                  child: CheckInCapture()),
                                        ),
                                      );
                                    }
                                  } else {
                                    Geolocator.checkPermission()
                                        .then((LocationPermission permission) {
                                      if (permission ==
                                              LocationPermission.denied ||
                                          permission ==
                                              LocationPermission
                                                  .deniedForever) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => CustomErrorDialog(
                                              title:
                                                  'Location Service Disabled.',
                                              message:
                                                  'Please enable location service before trying visit.',
                                              onOkPressed: switchOnLocation,
                                              iconData: Icons.error_outline),
                                        );
                                      } else {
                                        if (userObj!['EnableLocation'] > 0) {
                                          if (userObj![
                                                  'EnableLocationRestriction'] ==
                                              1) {
                                            _storage.setString(
                                                'Action', 'checkin');
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                        create: (context) =>
                                                            LocationRestrictionState(),
                                                        child: ValidateLocation(
                                                            widget.index3)),
                                              ),
                                            );
                                          } else {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                        create: (context) =>
                                                            AppState(),
                                                        child:
                                                            CheckInCapture()),
                                              ),
                                            );
                                          }
                                        } else {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChangeNotifierProvider(
                                                      create: (context) =>
                                                          AppState(),
                                                      child: CheckInCapture()),
                                            ),
                                          );
                                        }
                                      }
                                    });
                                  }
                                } else {
                                  //Tell user that his account is deactivated
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomErrorDialog(
                                        title: 'Inactive User',
                                        message:
                                            'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
                                        onOkPressed: () =>
                                            Navigator.of(context).pop(),
                                        iconData: Icons.no_accounts_sharp),
                                  );
                                }
                              });
                            } else {}
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(size.width, 60),
                            backgroundColor: (lastCheckIn == null ||
                                    lastCheckIn!["OutTime"] != null)
                                ? actionBtnColor
                                : Color(0xFFBDBDBD),
                            foregroundColor: (lastCheckIn == null ||
                                    lastCheckIn!["OutTime"] != null)
                                ? Colors.white
                                : Colors.black54,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Check In',
                            style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context)
                                        ? 18
                                        : Responsive.isMobileLarge(context)
                                            ? 19
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 12),

                        // ----------Check Out Button--------------
                        ElevatedButton(
                          onPressed: () {
                            if ((lastCheckIn == null ||
                                lastCheckIn!["OutTime"] != null)) {
                            } else {
                              Geolocator.isLocationServiceEnabled().then(
                                (bool serviceEnabled) {
                                  //check whether user is deactivated or not
                                  if (userObj!['Deleted'] == 0) {
                                    if (serviceEnabled) {
                                      if (userObj!['EnableLocation'] > 0) {
                                        if (userObj![
                                                'EnableLocationRestriction'] ==
                                            1) {
                                          _storage.setString(
                                              'Action', 'checkout');
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChangeNotifierProvider(
                                                create: (context) =>
                                                    LocationRestrictionState(),
                                                child: ValidateLocation(
                                                  widget.index3,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ChangeNotifierProvider(
                                                      create: (context) =>
                                                          AppState(),
                                                      child: CheckoutCapture()),
                                            ),
                                          );
                                        }
                                      } else {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider(
                                              create: (context) => AppState(),
                                              child: CheckoutCapture(),
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      Geolocator.checkPermission().then(
                                          (LocationPermission permission) {
                                        if (permission ==
                                                LocationPermission.denied ||
                                            permission ==
                                                LocationPermission
                                                    .deniedForever) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => CustomErrorDialog(
                                                title:
                                                    'Location Service Disabled.',
                                                message:
                                                    'Please enable location service before trying visit.',
                                                onOkPressed: () =>
                                                    Navigator.of(context).pop(),
                                                iconData: Icons.error_outline),
                                          );
                                        } else {
                                          if (userObj!['EnableLocation'] > 0) {
                                            if (userObj![
                                                    'EnableLocationRestriction'] ==
                                                1) {
                                              _storage.setString(
                                                  'Action', 'checkout');
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChangeNotifierProvider(
                                                    create: (context) =>
                                                        LocationRestrictionState(),
                                                    child: ValidateLocation(
                                                        widget.index3),
                                                  ),
                                                ),
                                              );
                                            } else {
                                              Navigator.of(context,
                                                      rootNavigator: true)
                                                  .push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChangeNotifierProvider(
                                                    create: (context) =>
                                                        AppState(),
                                                    child: CheckoutCapture(),
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                  create: (context) =>
                                                      AppState(),
                                                  child: CheckoutCapture(),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      });
                                    }
                                  } else {
                                    //Tell user that his account is deactivated
                                    showDialog(
                                      context: context,
                                      builder: (context) => CustomErrorDialog(
                                          title: 'Inactive User',
                                          message:
                                              'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
                                          onOkPressed: () =>
                                              Navigator.of(context).pop(),
                                          iconData: Icons.no_accounts_sharp),
                                    );
                                  }
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(size.width, 60),
                            backgroundColor: (lastCheckIn == null ||
                                    lastCheckIn!["OutTime"] != null)
                                ? Color(0XFFBDBDBD)
                                : actionBtnColor,
                            foregroundColor: (lastCheckIn == null ||
                                    lastCheckIn!["OutTime"] != null)
                                ? Colors.black54
                                : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Check Out',
                            style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context)
                                        ? 18
                                        : Responsive.isMobileLarge(context)
                                            ? 19
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 12),

                        //------------ Visit Button------------------
                        ElevatedButton(
                          onPressed: () {
                            if ((lastCheckIn == null || //additional line
                                lastCheckIn!["OutTime"] != null)) {
                              //additional line
                            } else {
                              //additional line
                              Geolocator.isLocationServiceEnabled()
                                  .then((bool serviceEnabled) {
                                if (userObj!['Deleted'] == 0) {
                                  if (serviceEnabled) {
                                    Navigator.of(context, rootNavigator: true)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChangeNotifierProvider(
                                                create: (context) => AppState(),
                                                child: VisitCapture()),
                                      ),
                                    );
                                  } else {
                                    Geolocator.checkPermission()
                                        .then((LocationPermission permission) {
                                      if (permission ==
                                              LocationPermission.denied ||
                                          permission ==
                                              LocationPermission
                                                  .deniedForever) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => CustomErrorDialog(
                                              title:
                                                  'Location Service Disabled.',
                                              message:
                                                  'Please enable location service before trying visit.',
                                              onOkPressed: () =>
                                                  Navigator.of(context).pop(),
                                              iconData: Icons.error_outline),
                                        );
                                      } else {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider(
                                              create: (context) => AppState(),
                                              child: VisitCapture(),
                                            ),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                } else {
                                  //Tell user that his account is deactivated
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomErrorDialog(
                                        title: 'Inactive User',
                                        message:
                                            'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
                                        onOkPressed: () =>
                                            Navigator.of(context).pop(),
                                        iconData: Icons.no_accounts_sharp),
                                  );
                                }
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(size.width, 60),
                            backgroundColor: (lastCheckIn == null ||
                                    lastCheckIn!["OutTime"] != null)
                                ? Color(0XFFBDBDBD)
                                : actionBtnColor,
                            foregroundColor: (lastCheckIn == null ||
                                    lastCheckIn!["OutTime"] != null)
                                ? Colors.black54
                                : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Visit',
                            style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context)
                                        ? 18
                                        : Responsive.isMobileLarge(context)
                                            ? 19
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 12),
                        //------------ Inventory Scan Button------------------
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              bool isLocationValid =
                                  await LocationValidationService
                                      .validateLocationForInventoryScan(
                                          context);

                              if (isLocationValid) {
                                // Navigate to Inventory Scan screen
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EnhancedBarcodeScannerScreen(
                                              index: widget.index3)),
                                );
                              }
                              // Error dialog is automatically shown if location is invalid
                              // If location is invalid, error dialog is already shown by the service
                              // if ((lastCheckIn == null ||
                              //     lastCheckIn!["OutTime"] != null)) {
                              // } else {
                              //   //additional line
                              //   Geolocator.isLocationServiceEnabled()
                              //       .then((bool serviceEnabled) {
                              //     if (userObj!['Deleted'] == 0) {
                              //       if (serviceEnabled) {
                              //         Navigator.push(
                              //           context,
                              //           MaterialPageRoute(
                              //               builder: (context) =>
                              //                   BarcodeScannerScreen()),
                              //         );
                              //       } else {
                              //         Geolocator.checkPermission().then(
                              //             (LocationPermission permission) {
                              //           if (permission ==
                              //                   LocationPermission.denied ||
                              //               permission ==
                              //                   LocationPermission
                              //                       .deniedForever) {
                              //             showDialog(
                              //               context: context,
                              //               builder: (context) => CustomErrorDialog(
                              //                   title:
                              //                       'Location Service Disabled.',
                              //                   message:
                              //                       'Please enable location service before trying visit.',
                              //                   onOkPressed: () =>
                              //                       Navigator.of(context).pop(),
                              //                   iconData: Icons.error_outline),
                              //             );
                              //           } else {
                              //             Navigator.push(
                              //               context,
                              //               MaterialPageRoute(
                              //                   builder: (context) =>
                              //                       BarcodeScannerScreen()),
                              //             );
                              //           }
                              //         });
                              //       }
                              //     } else {
                              //       //Tell user that his account is deactivated
                              //       showDialog(
                              //         context: context,
                              //         builder: (context) => CustomErrorDialog(
                              //             title: 'Inactive User',
                              //             message:
                              //                 'This user has been deactivated \nand access to this function is restricted. \nPlease contact the system administrator.',
                              //             onOkPressed: () =>
                              //                 Navigator.of(context).pop(),
                              //             iconData: Icons.no_accounts_sharp),
                              //       );
                              //     }
                              //   });
                              // }
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => BarcodeScannerScreen(
                              //       index: widget.index3,
                              //     ),
                              //   ),
                              // );
                              // Navigator.of(context).push(
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         EnhancedBarcodeScannerScreen(
                              //             index: widget.index3),
                              //   ),
                              // );
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(size.width, 60),
                              backgroundColor: (lastCheckIn == null ||
                                      lastCheckIn!["OutTime"] != null)
                                  ? Color(0XFFBDBDBD)
                                  : actionBtnColor,
                              foregroundColor: (lastCheckIn == null ||
                                      lastCheckIn!["OutTime"] != null)
                                  ? Colors.black54
                                  : Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Inventory Scan',
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 16
                                      : Responsive.isMobileMedium(context)
                                          ? 18
                                          : Responsive.isMobileLarge(context)
                                              ? 19
                                              : Responsive.isTabletPortrait(
                                                      context)
                                                  ? 20
                                                  : 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Work Time Status
                  Container(
                    // width: size.width * 0.7,
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Work Time : ',
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 17
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 19
                                    : Responsive.isTabletPortrait(context)
                                        ? 22
                                        : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          workedTime,
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? workedTime == "Not checked in yet"
                                    ? 16
                                    : 20
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? workedTime == "Not checked in yet"
                                        ? 19
                                        : 23
                                    : Responsive.isTabletPortrait(context)
                                        ? workedTime == "Not checked in yet"
                                            ? 22
                                            : 25
                                        : 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Section
                  Container(
                    margin: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: userObj != null &&
                                  userObj!["ProfileImage"] != null
                              ? userObj!["ProfileImage"] !=
                                      "https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckfaceimages&image=None"
                                  ? NetworkImage(userObj!["ProfileImage"])
                                  : NetworkImage(
                                      "https://www.pngall.com/wp-content/uploads/5/User-Profile-PNG.png",
                                    )
                              : NetworkImage(
                                  "https://www.pngall.com/wp-content/uploads/5/User-Profile-PNG.png",
                                ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          userObj != null
                              ? userObj!['LastName'] != null
                                  ? userObj!["FirstName"] +
                                      " " +
                                      userObj!["LastName"]
                                  : userObj!['LastName']
                              : "",
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 18
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 20
                                    : Responsive.isTabletPortrait(context)
                                        ? 25
                                        : 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // GET the status of  the last event type (checkin or CheckoutCapture)

  void updateWorkTime() {
    if (lastCheckIn != null && lastCheckIn!["OutTime"] == null) {
      lastCheckInTime = DateTime.parse(lastCheckIn!["InTime"]);
      Duration duration = DateTime.now().difference(lastCheckInTime!);
      if (!mounted) return;

      setState(() {
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
        workedTime =
            "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      });
    } else {
      workedTime = "Not checked in yet";
    }
  }

  // LOAD LAST CHECKIN

  Future<void> loadLastCheckIn() async {
    showProgressDialog(context);
    String userId = userObj!['Id'];
    String customerId = userObj!['CustomerId'];
    var response = await ApiService.getTodayCheckInCheckOut(userId, customerId);
    closeDialog(context);
    if (response != null && response.statusCode == 200) {
      dynamic item = jsonDecode(response.body);
      print("item $item");

      if (item != null) {
        if (item["enrolled"] == 'pending' || item["enrolled"] == null) {
          await _storage.clear();
          while (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return MyApp(_storage);
            }),
          );
        } else if (item["Data"] == 'Yes') {
          lastCheckIn = item;
          _storage.setString('last_check_in', jsonEncode(item));
        }
      }
    }
  }

  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = (duration.inMinutes % 60);
    int seconds = (duration.inSeconds % 60);

    String formattedDuration = '';

    if (hours > 0) {
      formattedDuration += '${hours.toString().padLeft(2, '0')} hr ';
    }

    if (minutes > 0) {
      formattedDuration += '${minutes.toString().padLeft(2, '0')} min ';
    }

    if (seconds > 0 || (hours == 0 && minutes == 0)) {
      formattedDuration += '${seconds.toString().padLeft(2, '0')} sec';
    }

    return formattedDuration.trim();
  }

  void noHandler() {
    closeDialog(context);
  }

  // LOAD USER DATA

  Future<void> loadUserData() async {
    showProgressDialog(context);
    var response = await ApiService.verifyUserWithEmpCode(employeeCode);
    closeDialog(context);
    if (response != null &&
        response.statusCode == 200 &&
        response.body == "NoRecordsFound") {
      await _storage.clear();
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MyApp(_storage);
          },
        ),
      );
    } else if (response != null && response.statusCode == 200) {
      userObj = jsonDecode(response.body);

      _storage.setString('user_data', response.body);
      String? lastCheckInData = _storage.getString('last_check_in');
      if (lastCheckInData == null) {
        await loadLastCheckIn();
      } else {
        lastCheckIn = jsonDecode(lastCheckInData);
      }
    }
  }

  int calculateDayDifference(DateTime date) {
    DateTime now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }
}
