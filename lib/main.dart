import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' as getx;
import 'package:flutter/services.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:infosha/Controller/locale_controller.dart';
import 'package:infosha/config/const.dart';

import 'package:infosha/dialog_overlay.dart';
import 'package:infosha/followerscreen/controller/followers_controller.dart';
import 'package:infosha/followerscreen/controller/following_model.dart';
import 'package:infosha/followerscreen/controller/topfollowers_model.dart';
import 'package:infosha/screens/ProfileScreen/visitor_screen.dart';
import 'package:infosha/screens/allKingsGods/controller/god_king_model.dart';
import 'package:infosha/screens/feed/component/view_feed.dart';
import 'package:infosha/screens/feed/controller/feed_model.dart';
import 'package:infosha/screens/hscreen/splashscreen.dart';
import 'package:infosha/screens/subscription/controller/subscription_model.dart';
import 'package:infosha/searchscreens/controller/search_model.dart';
import 'package:infosha/translation/translation_service.dart';
import 'package:infosha/views/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:uni_links/uni_links.dart';

bool isArabic = false;
bool isMainDark = true;
String userid = "null";
String initialDynamic = "null";
String initialRoute = "/";

/// used for local notifcation
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    "id", "name",
    description: "Description", importance: Importance.high, playSound: true);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

///used for call popup
///entry point of dialog
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.red,
      home: TrueCallerOverlay(),
    ),
  );
}

///used to initialize background service to detect calls
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );

  service.startService();
}

/// used to start background process and entry point of background process
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  PhoneState.stream.listen((event) {
    if (event != null) {
      handlePhoneState(event);
    }
  });

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Infosha",
      content: "Infosha works in background to detect call",
    );
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

/// used to handle call popup show and close
void handlePhoneState(PhoneState event) async {
  if (event.number != null) {
    if (event.status == PhoneStateStatus.CALL_INCOMING) {
      await handleCallIncoming(event.number!);
    } else if (event.status == PhoneStateStatus.CALL_ENDED) {
      Future.delayed(const Duration(seconds: 4), () async {
        await handleCallEnded();
      });
    } else if (event.status == PhoneStateStatus.CALL_STARTED) {
      await handleCallStarted(event.number!);
    }
  }
}

/// used when incoming call detected
Future<void> handleCallIncoming(String number) async {
  await Future.delayed(const Duration(milliseconds: 100));
  await SystemAlertWindow.showSystemWindow(
      height: 450,
      prefMode: SystemWindowPrefMode.OVERLAY,
      isDisableClicks: false,
      gravity: SystemWindowGravity.CENTER);
  await SystemAlertWindow.sendMessageToOverlay(number);
}

/// used to hide dialog and call ended
Future<void> handleCallEnded() async {
  await SystemAlertWindow.closeSystemWindow(
      prefMode: SystemWindowPrefMode.OVERLAY);
  await SystemAlertWindow.sendMessageToOverlay("null");
}

///used when started outgoing call
Future<void> handleCallStarted(String number) async {
  await Future.delayed(const Duration(milliseconds: 100));
  await SystemAlertWindow.showSystemWindow(
      height: 450,
      prefMode: SystemWindowPrefMode.OVERLAY,
      isDisableClicks: false,
      gravity: SystemWindowGravity.CENTER);
  await SystemAlertWindow.sendMessageToOverlay(number);
}

// const platform = MethodChannel('call_detecting');

Future<void> main() async {
  userid = "null";
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  requestPermission();

  linkStream.listen((String? link) async {
    print("link1 ==> ${link}");
    if (link != null) {
      try {
        if (link.contains("feed")) {
          initialRoute = "/viewpost";
          initialDynamic = link.toString();

          Get.to(() => ViewFeed(postUrl: initialDynamic));
        }
      } catch (e) {
        rethrow;
      }
    } else {
      initialRoute = "/";
    }
  }, onError: (err) {
    print('Error handling deep link: $err');
  });

  /* platform.setMethodCallHandler((call) async {
    print("setMethodCallHandler ==> ${call.arguments}");
    if (call.method == 'incomingCall' || call.method == 'outgoingCall') {
      if (await FlutterBackgroundService().isRunning() == false) {
        await initializeService();
        await FlutterBackgroundService().startService();
      }
    }
  }); */

  await initializeService();
  await FlutterBackgroundService().startService();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notificationicon');

  DarwinInitializationSettings initializationSettingsDarwin =
      const DarwinInitializationSettings(
          onDidReceiveLocalNotification: onDidReceiveLocalNotification);

  LinuxInitializationSettings initializationSettingsLinux =
      const LinuxInitializationSettings(defaultActionName: 'Open notification');

  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux);

  flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  /* if (kDebugMode) {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  }; */

  initialRoute = await handleDeepLink(initialRoute);
  print("initialRoute runapp ==> $initialRoute");

  MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      testDeviceIds: ['36383AAECA0448EFC6DFC030F3A7B80C']));

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> handleDeepLink(String initialRoute) async {
  try {
    String? initialLink = await getInitialLink();
    if (initialLink != null) {
      // The app was opened through a deep link
      print("opended through deep link $initialLink");
      initialDynamic = initialLink.toString();
      initialRoute = "/viewpost";
      return "/viewpost";
    } else {
      // The app was opened without a deep link
      print("opended noramaly");
      initialRoute = "/";
      return "/";
    }
  } on PlatformException {
    // Error occurred while getting the initial link
    return "/";
  }
}

/// used to ask permission to show notification
void requestPermission() async {
  bool check = await Permission.notification.isGranted;

  if (check == false) {
    Permission.notification.request();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }
}

///redirect when app is opended
void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  // Get.to(() => ViewProfileScreen(id: userid));
  Get.to(() => VisitorScreen(id: Params.Id));
}

void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) {
  // Get.to(() => ViewProfileScreen(id: userid));
  Get.to(() => VisitorScreen(id: Params.Id));
}

class MyApp extends StatefulWidget {
  String initialRoute;
  MyApp({required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final _receivePort = ReceivePort();
  SendPort? homePort;
  static const String _kPortNameHome = 'UI';
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  void initState() {
    // CallDetection.startCallDetection();

    if (homePort != null) return;
    final res = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _kPortNameHome,
    );

    _receivePort.listen((message) {
      log("message from OVERLAY: $message");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        RemoteNotification remoteNotification = message.notification!;
        if (message.notification != null) {
          print('Message also contained a notification: ${message.data}');
          userid = message.data["user_id"] ?? "";
        }

        flutterLocalNotificationsPlugin.show(
          0,
          remoteNotification.title,
          remoteNotification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, '',
              channelDescription: channel.description,
              playSound: true,
              icon: 'notificationicon',
              largeIcon:
                  const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              // subText: channel.name,
              color: baseColor,
              groupKey: channel.id,
              setAsGroupSummary: true,
              groupAlertBehavior: GroupAlertBehavior.children,
            ),
          ),
          // payload: action
        );
      }
    });

    ///redirect when app is in foreground
    FirebaseMessaging.onMessageOpenedApp.listen((event) async {
      // Get.to(() => ViewProfileScreen(id: event.data["user_id"]));
      Get.to(() => VisitorScreen(id: Params.Id));
    });
    // checkNetwork();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TranslationService translationService = TranslationService();

    return getx.SimpleBuilder(builder: (_) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserViewModel>(create: (_) => UserViewModel()),
          ChangeNotifierProvider<SearchModel>(create: (_) => SearchModel()),
          ChangeNotifierProvider<FeedModel>(create: (_) => FeedModel()),
          ChangeNotifierProvider<SubscriptionModel>(
              create: (_) => SubscriptionModel()),
          ChangeNotifierProvider<TopFollowVisitorModel>(
              create: (_) => TopFollowVisitorModel()),
          ChangeNotifierProvider<AllKingGodModel>(
              create: (_) => AllKingGodModel()),
          ChangeNotifierProvider<FollowingModel>(
              create: (_) => FollowingModel()),
          ChangeNotifierProvider<FollowersController>(
              create: (_) => FollowersController()),
        ],
        child: ConnectivityAppWrapper(
          app: ResponsiveSizer(builder: (context, orientation, screenType) {
            return GetMaterialApp(
              title: AppName,
              theme: ThemeData(
                  useMaterial3: false,
                  textTheme: TextTheme(
                    bodyMedium: GoogleFonts.workSans(),
                    bodyLarge: GoogleFonts.workSans(),
                    titleMedium: GoogleFonts.workSans(),
                    titleSmall: GoogleFonts.workSans(),
                    labelLarge: GoogleFonts.workSans(),
                    bodySmall: GoogleFonts.workSans(),
                    labelSmall: GoogleFonts.workSans(),
                    displayLarge: GoogleFonts.workSans(),
                  ),
                  primaryColor: whiteColor,
                  appBarTheme: const AppBarTheme(
                      iconTheme: IconThemeData(color: Colors.black))),
              themeMode: ThemeMode.system,
              /* initialRoute: widget.initialRoute,
              routes: <String, WidgetBuilder>{
                '/': (context) => const splashScreen(),
                '/viewpost': (context) => const HomeScreen()
              }, */
              navigatorKey: navigatorKey,
              home: const splashScreen(),
              fallbackLocale: LocalizationService.fallbackLocale,
              translations: translationService,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale("en"),
                Locale('ar'),
                Locale('fr'),
              ],
              locale: const Locale('en'),
            );
          }),
        ),
      );
    });
  }
}

/* class CallDetection {
  static const MethodChannel _channel =
      MethodChannel('com.ktech.infosha/call_detection');

  static Future<void> startCallDetection() async {
    _channel.setMethodCallHandler((call) async {
      print("call ==> ${call.method}");
    });
  }
}
 */