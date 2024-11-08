import 'dart:developer';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:infosha/followerscreen/controller/topfollowers_model.dart';
import 'package:country_state_city/country_state_city.dart' as con;
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:infosha/Controller/models/contact_model.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/followerscreen/topfollowers.dart';
import 'package:infosha/main.dart';
import 'package:infosha/screens/ProfileScreen/profilescreen.dart';
import 'package:infosha/screens/ProfileScreen/visitor_screen.dart';
import 'package:infosha/screens/feed/component/feed_screen.dart';
import 'package:infosha/screens/feed/component/feed_tile.dart';
import 'package:infosha/screens/feed/component/upload_feed.dart';
import 'package:infosha/screens/feed/component/view_feed.dart';
import 'package:infosha/screens/feed/controller/feed_model.dart';
import 'package:infosha/screens/hscreen/contact_list.dart';
import 'package:infosha/screens/otherprofile/view_profile_screen.dart';
import 'package:infosha/screens/viewUnregistered/component/view_unregistered_user.dart';
import 'package:infosha/searchscreens/searchscreen.dart';
import 'package:infosha/screens/home/SectonView/section_view.dart';
import 'package:infosha/screens/hscreen/settings.dart';
import 'package:infosha/utils/error_boundary.dart';
import 'package:infosha/views/app_icons.dart';
import 'package:infosha/views/colors.dart';
import 'package:infosha/views/custom_text.dart';
import 'package:infosha/views/full_screen_image.dart';
import 'package:infosha/views/text_styles.dart';
import 'package:infosha/views/ui_helpers.dart';
import 'package:infosha/views/widgets/common_dialog_with_button.dart';
import 'package:infosha/views/widgets/namewithlabel_view.dart';
import 'package:infosha/views/widgets/nickname_view.dart';
import 'package:infosha/views/widgets/profile_image_view_me.dart';
import 'package:infosha/views/widgets/rating_view.dart';
import 'package:infosha/views/widgets/setting_widget.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shape_of_view_null_safe/shape_of_view_null_safe.dart';
import 'package:system_alert_window/system_alert_window.dart';

import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScrollController scrollController = ScrollController();

  late UserViewModel provider;
  late FeedModel providerFeed;
  DateTime? lastBackPressedTime;
  bool isLoadingMorePost = false;
  int page = 1;
  int visibleTextIndex = -1;

  @override
  void initState() {
    initialmessage();
    provider = Provider.of<UserViewModel>(context, listen: false);
    providerFeed = Provider.of<FeedModel>(context, listen: false);
    Future.microtask(() => context.read<FeedModel>().fetchPosts());

    Future.microtask(
        () => context.read<TopFollowVisitorModel>().fetchCountry());

    Future.microtask(() =>
        context.read<TopFollowVisitorModel>().selectedCountry = con.Country(
            name: "Country",
            isoCode: "isoCode",
            phoneCode: "phoneCode",
            flag: "flag",
            currency: "currency",
            latitude: "latitude",
            longitude: "longitude"));

    Future.microtask(() => context
        .read<TopFollowVisitorModel>()
        .fetchTopFollowers()
        .then((value) => Future.microtask(
            () => context.read<TopFollowVisitorModel>().fetchTopVisitors())));

    if (initialDynamic != "null") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewFeed(postUrl: initialDynamic)));
      });
    }

    // getProfileData();

    scrollController.addListener(_scrollListener);

    startBackService();

    super.initState();
  }

  startBackService() async {
    if (await FlutterBackgroundService().isRunning() == false) {
      await initializeService();
      await FlutterBackgroundService().startService();
    }
  }

  initialmessage() async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null &&
        message.data["user_id"] != "" &&
        message.data["user_id"] != null) {
      Future.microtask(() => context
          .read<UserViewModel>()
          .loadSharedPref()
          .then((value) => Get.to(() => VisitorScreen(id: Params.Id))));
    }
  }

  Future<void> deeplinkemthod() async {
    print("initialDynamic ==> $initialDynamic");
    if (initialDynamic != "null") {
      try {
        if (initialDynamic.contains("feed")) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ViewFeed(postUrl: initialDynamic)));
          });
        } else {}
      } catch (e) {
        rethrow;
      }
    }
  }

  /// used to get logged user's data
  getProfileData() async {
    provider.userModel = await provider.getUserProfileById(Params.UserToken);
    provider.getProfessionByOtherUser(provider.userModel.id.toString(), true);
  }

  /// used to fetch more data if pagination added
  void _scrollListener() {
    if (scrollController.offset == scrollController.position.maxScrollExtent) {
      if (scrollController.offset ==
              scrollController.position.maxScrollExtent &&
          isLoadingMorePost == false) {
        setState(() {
          isLoadingMorePost = true;
        });
        page += 1;
        providerFeed.fetchMorePosts(page).then((value) {
          setState(() {
            isLoadingMorePost = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<UserViewModel>(
        builder: (context, provider, child) {
          return Obx(
            () => provider.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      color: baseColor,
                    ),
                  )
                : CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.white,
                        expandedHeight: Get.height * 0.41,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: ShapeOfView(
                                  elevation: 3.0,
                                  shape: ArcShape(
                                      direction: ArcDirection.Outside,
                                      height: 30,
                                      position: ArcPosition.Bottom),
                                  child: Container(
                                    height: Get.height * 0.42,
                                    width: Get.width,
                                    color: secondaryColor,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        UIHelper.verticalSpaceSm,
                                        if (provider.userModel.profile != null)
                                          userProfilePhotoModel(
                                              provider.userModel.profile!
                                                  .profileUrl,
                                              provider.userModel.username),
                                        UIHelper.verticalSpaceSm,
                                        NamewithlabelView(
                                          displayName:
                                              provider.userModel.username!,
                                          fontsize: 18.0.sp,
                                          iconsize: 22.0,
                                          iconname: provider.userModel
                                                      .is_subscription_active ==
                                                  true
                                              ? provider.userModel
                                                  .active_subscription_plan_name
                                              : null,
                                          showIcon: provider
                                              .userModel.is_subscription_active,
                                        ),
                                        UIHelper.verticalSpaceSm,
                                        NicknameView(
                                            nickName: provider
                                                    .userModel.getNickName ??
                                                []),
                                        UIHelper.verticalSpaceSm,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.call_outlined,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              provider.userModel.number!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.followprofilesvg,
                                        ontap: () {
                                          Get.to(() => TopFollowersScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.profilesvg,
                                        ontap: () {
                                          Get.to(() => const ProfileScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.searchsvg,
                                        ontap: () {
                                          Get.to(() => const SearchScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(
                                            () => VisitorScreen(id: Params.Id));
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Image.asset(
                                          "images/visitor.png",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.settingsvg,
                                        ontap: () {
                                          Get.to(() => const SettingScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    InkWell(
                                      onTap: () {
                                        Get.to(() => const ContactList());
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Image.asset(
                                          APPICONS.socialMedia,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Get.to(() => const UploadFeed());
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF0BA7C1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      "Upload".tr,
                                      style: textStyleWorkSense(
                                          fontSize: 14,
                                          color: Colors.white,
                                          weight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Consumer<FeedModel>(
                              builder: (context, feedProvider, child) {
                                return feedProvider.isLoading
                                    ? SizedBox(
                                        width: Get.width,
                                        height: Get.height * 0.4,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: baseColor,
                                          ),
                                        ),
                                      )
                                    : feedProvider.feedListModel.data == null ||
                                            feedProvider.feedListModel.data!
                                                .data!.isEmpty
                                        ? SizedBox(
                                            width: Get.width,
                                            height: Get.height * 0.4,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.not_interested,
                                                  color: Colors.black,
                                                  size: Get.width * 0.15,
                                                ),
                                                SizedBox(
                                                    height: Get.height * 0.02),
                                                Text(
                                                  'No Feed Found'.tr,
                                                  style: GoogleFonts.workSans(
                                                    color: Colors.black,
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: EdgeInsets.zero,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: feedProvider
                                                    .feedListModel
                                                    .data!
                                                    .data!
                                                    .length +
                                                1,
                                            itemBuilder: (context, index) {
                                              if (index <
                                                  feedProvider.feedListModel
                                                      .data!.data!.length) {
                                                return FeedTile(
                                                  index: index,
                                                  isVisible:
                                                      visibleTextIndex == index,
                                                  onButtonTap: () {
                                                    setState(() {
                                                      visibleTextIndex =
                                                          visibleTextIndex ==
                                                                  index
                                                              ? -1
                                                              : index;
                                                    });
                                                  },
                                                );
                                              } else if (isLoadingMorePost) {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: baseColor),
                                                );
                                              } else {
                                                return const SizedBox.shrink();
                                              }
                                            },
                                          );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<UserViewModel>(
        builder: (context, provider, child) {
          return Obx(
            () => provider.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      color: baseColor,
                    ),
                  )
                : SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        SizedBox(
                          height: Get.height * 0.44,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: ShapeOfView(
                                  elevation: 3.0,
                                  shape: ArcShape(
                                      direction: ArcDirection.Outside,
                                      height: 30,
                                      position: ArcPosition.Bottom),
                                  child: Container(
                                    height: Get.height * 0.42,
                                    width: Get.width,
                                    color: secondaryColor,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        UIHelper.verticalSpaceSm,
                                        if (provider.userModel.profile !=
                                            null) ...[
                                          userProfilePhotoModel(
                                              provider.userModel.profile!
                                                  .profileUrl,
                                              provider.userModel.username)
                                        ],
                                        UIHelper.verticalSpaceSm,
                                        NamewithlabelView(
                                          displayName:
                                              provider.userModel.username!,
                                          fontsize: 18.0.sp,
                                          iconsize: 22.0,
                                          iconname: provider.userModel
                                                      .is_subscription_active ==
                                                  true
                                              ? provider.userModel
                                                  .active_subscription_plan_name
                                              : null,
                                          showIcon: provider
                                              .userModel.is_subscription_active,
                                        ),
                                        UIHelper.verticalSpaceSm,
                                        NicknameView(
                                            nickName: provider
                                                    .userModel.getNickName ??
                                                []),
                                        UIHelper.verticalSpaceSm,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.call_outlined,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              provider.userModel.number!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.followprofilesvg,
                                        ontap: () {
                                          Get.to(() => TopFollowersScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.profilesvg,
                                        ontap: () {
                                          Get.to(() => const ProfileScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.searchsvg,
                                        ontap: () {
                                          Get.to(() => const SearchScreen());
                                        }),
                                    
                                    UIHelper.horizontalSpaceSm,
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(
                                            () => VisitorScreen(id: Params.Id));
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Image.asset(
                                          "images/visitor.png",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.settingsvg,
                                        ontap: () {
                                          Get.to(() => const SettingScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    InkWell(
                                      onTap: () {
                                        Get.to(() => const ContactList());
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Image.asset(
                                          APPICONS.socialMedia,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const UploadFeed());
                              },
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0BA7C1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  "Upload".tr,
                                  style: textStyleWorkSense(
                                      fontSize: 14,
                                      color: Colors.white,
                                      weight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Consumer<FeedModel>(
                            builder: (context, provider, child) {
                          return provider.isLoading
                              ? SizedBox(
                                  width: Get.width,
                                  height: Get.height * 0.4,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: baseColor,
                                    ),
                                  ),
                                )
                              : provider.feedListModel.data == null ||
                                      provider.feedListModel.data!.data!.isEmpty
                                  ? SizedBox(
                                      width: Get.width,
                                      height: Get.height * 0.4,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.not_interested,
                                            color: Colors.black,
                                            size: Get.width * 0.15,
                                          ),
                                          SizedBox(height: Get.height * 0.02),
                                          Text(
                                            'No Feed Found'.tr,
                                            style: GoogleFonts.workSans(
                                              color: Colors.black,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      // controller: scrollController,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: provider.feedListModel.data!
                                              .data!.length +
                                          1,
                                      itemBuilder: (context, index) {
                                        if (index <
                                            provider.feedListModel.data!.data!
                                                .length) {
                                          return FeedTile(
                                            index: index,
                                            isVisible:
                                                visibleTextIndex == index,
                                            onButtonTap: () {
                                              setState(() {
                                                visibleTextIndex =
                                                    visibleTextIndex == index
                                                        ? -1
                                                        : index;
                                              });
                                            },
                                          );
                                        } else if (isLoadingMorePost) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                                color: baseColor),
                                          );
                                        } else {}
                                      },
                                    );
                        }),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  } */
}

/* class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScrollController scrollController = ScrollController();

  late UserViewModel provider;
  DateTime? lastBackPressedTime;
  bool isLoadingMorePost = false;
  int page = 1;

  @override
  void initState() {
    initialmessage();

    Future.microtask(
        () => context.read<TopFollowVisitorModel>().fetchCountry());

    Future.microtask(() =>
        context.read<TopFollowVisitorModel>().selectedCountry = con.Country(
            name: "Country",
            isoCode: "isoCode",
            phoneCode: "phoneCode",
            flag: "flag",
            currency: "currency",
            latitude: "latitude",
            longitude: "longitude"));

    Future.microtask(() => context
        .read<TopFollowVisitorModel>()
        .fetchTopFollowers()
        .then((value) => Future.microtask(
            () => context.read<TopFollowVisitorModel>().fetchTopVisitors())));

    if (initialDynamic != "null") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewFeed(postUrl: initialDynamic)));
      });
    }

    provider = Provider.of<UserViewModel>(context, listen: false);

    getProfileData();

    scrollController.addListener(_scrollListener);

    super.initState();
  }

  initialmessage() async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null &&
        message.data["user_id"] != "" &&
        message.data["user_id"] != null) {
      Future.microtask(() => context
          .read<UserViewModel>()
          .loadSharedPref()
          .then((value) => Get.to(() => VisitorScreen(id: Params.Id))));
    }
  }

  Future<void> deeplinkemthod() async {
    print("initialDynamic ==> $initialDynamic");
    if (initialDynamic != "null") {
      try {
        if (initialDynamic.contains("feed")) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ViewFeed(postUrl: initialDynamic)));
          });
        } else {}
      } catch (e) {
        rethrow;
      }
    }
  }

  /// used to get logged user's data
  getProfileData() async {
    provider.userModel = await provider.getUserProfileById(Params.UserToken);
    provider.getProfessionByOtherUser(provider.userModel.id.toString(), true);
  }

  /// used to fetch more data if pagination added
  void _scrollListener() {
    log("list scrolled");
    if (scrollController.offset == scrollController.position.maxScrollExtent) {
      print("list ended");
      /* setState(() {
        isLoadingMorePost = true;
      });
      page += 1;
      provider.fetchMoreServerContacts(page).then((value) {
        setState(() {
          isLoadingMorePost = false;
        });
      });
      setState(() {}); */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<UserViewModel>(
        builder: (context, provider, child) {
          return Obx(
            () => provider.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      color: baseColor,
                    ),
                  )
                : NestedScrollView(
                    floatHeaderSlivers: true,
                    // controller: scrollController,
                    // physics: const NeverScrollableScrollPhysics(),
                    body: Consumer<FeedModel>(
                        builder: (context, providerFeed, child) {
                      return NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              if (notification.metrics.pixels ==
                                      notification.metrics.maxScrollExtent &&
                                  providerFeed.isLoadingMorePost == false) {
                                // setState(() {
                                providerFeed.isLoadingMorePost = true;
                                providerFeed.notifyListeners();
                                // });
                                page += 1;
                                providerFeed.fetchMorePosts(page).then((value) {
                                  // setState(() {
                                  providerFeed.isLoadingMorePost = false;
                                  providerFeed.notifyListeners();
                                  // });
                                });
                              }
                            }
                            return true;
                          },
                          child: FeedScreen());
                    }) /* Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Consumer<UserViewModel>(
                          builder: (context, provider, child) {
                        /// used to listen if page is ended or not to get more cotnact if pagination
                        return /* NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          if (notification.metrics.pixels ==
                                  notification.metrics.maxScrollExtent &&
                              isLoadingMorePost == false) {
                            setState(() {
                              isLoadingMorePost = true;
                            });
                            page += 1;
                            provider.fetchMoreServerContacts(page).then((value) {
                              setState(() {
                                isLoadingMorePost = false;
                              });
                            });
                          }
                        }
                        return true;
                      },
                      child: */
                            SectionView<
                                AlphabetHeader<
                                    MapEntry<String, List<ContactModel>>>,
                                ContactModel>(
                          source: convertListToAlphaHeader(
                              provider.groupedListContactsModel.entries
                                  .map((e) => e)
                                  .where((element) {
                                return element.key != "" &&
                                    isWellFormedUTF16(element.key) &&
                                    element.key.toString() != "�";
                              }),
                              (item) => item.key != "" &&
                                      isWellFormedUTF16(item.key) &&
                                      item.key.toString() != "�"
                                  ? (item.key).substring(0, 1).toUpperCase()
                                  : ""),
                          onFetchListData: (value) {
                            return value.items.isNotEmpty
                                ? value.items.first.value
                                : [];
                          },

                          onChange: (value) {
                            // if (value > 0) {
                            //   scrollController.animateTo(selectedHeaderTextHeight,
                            //       duration: Duration(milliseconds: 1), curve: Curves.ease);
                            // } else {
                            //   scrollController.animateTo(-selectedHeaderTextHeight,
                            //       duration: Duration(milliseconds: 1), curve: Curves.ease);
                            // }
                          },

                          // headerBuilder:
                          //     getDefaultHeaderBuilder(
                          //         (d) => d.alphabet),
                          headerBuilder: (context, list, index) {
                            return Container(
                              height: 50.0,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: Get.width,
                                child: Row(
                                  children: [
                                    CustomText(
                                      text: list.alphabet,
                                      fontSize: 22.0,
                                      color: Colors.black,
                                      weight: fontWeightExtraBold,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          alphabetInset: const EdgeInsets.only(left: 10),

                          alphabetBuilder: getDefaultAlphabetBuilder((d) {
                            return d.alphabet;
                          }),

                          tipBuilder: getDefaultTipBuilder((d) => d.alphabet),
                          itemBuilder: (context, day, itemIndex, headerData,
                              headerIndex) {
                            String country = day.code!;
                            String coutnryflag = "";

                            if (RegExp(r'\d').hasMatch(country)) {
                              coutnryflag =
                                  "images/flags/${CountryPickerUtils.getCountryByPhoneCode(country.replaceAll("+", "")).isoCode.toLowerCase()}.png";
                            } else {
                              coutnryflag = country.toLowerCase() != ""
                                  ? "images/flags/${country.toLowerCase()}.png"
                                  : "";
                            }
                            return GestureDetector(
                              onTap: () {
                                if (day.isFriend != null &&
                                    day.isFriend.toString() == "1") {
                                  Get.to(() => ViewProfileScreen(
                                      id: day.userId.toString()));
                                } else {
                                  Get.to(() => ViewUnregisteredUser(
                                      contactId: day.id.toString(),
                                      id: day.number.toString(),
                                      isOther: false));
                                }
                              },
                              child: adaptor(day, itemIndex, coutnryflag,
                                  provider, country),
                            );
                          },
                        );
                        // );
                      }),
                    ) */
                    ,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                            pinned: false,
                            floating: false,
                            automaticallyImplyLeading: false,
                            elevation: 0,
                            toolbarHeight: 40,
                            expandedHeight: Get.height * 0.4,
                            backgroundColor: Colors.white,
                            bottom: PreferredSize(
                                preferredSize:
                                    Size(Get.width, Get.height * 0.06),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.followprofilesvg,
                                        ontap: () {
                                          Get.to(() => TopFollowersScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.profilesvg,
                                        ontap: () {
                                          Get.to(() => const ProfileScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.searchsvg,
                                        ontap: () {
                                          Get.to(() => const SearchScreen());
                                        }),
                                    /* if (provider.userModel
                                                .is_subscription_active !=
                                            null
                                        ? provider.userModel
                                                .is_subscription_active ==
                                            true
                                        : false) ...[ */
                                    UIHelper.horizontalSpaceSm,
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(
                                            () => VisitorScreen(id: Params.Id));
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Image.asset(
                                          "images/visitor.png",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    // ],
                                    UIHelper.horizontalSpaceSm,
                                    SettingIconWidget(
                                        imagesvgpath: APPICONS.settingsvg,
                                        ontap: () {
                                          Get.to(() => const SettingScreen());
                                        }),
                                    UIHelper.horizontalSpaceSm,
                                    InkWell(
                                      onTap: () {
                                        Get.to(() => const ContactList());
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: Image.asset(
                                          APPICONS.socialMedia,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    /* const SizedBox(width: 5),
                                    InkWell(
                                      onTap: () {
                                        Get.to(() => const UploadFeed());
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle),
                                        child: const Icon(
                                          Icons.upload,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ), */
                                  ],
                                )),
                            flexibleSpace: FlexibleSpaceBar(
                                collapseMode: CollapseMode.parallax,
                                background: Column(
                                  children: [headerWidget()],
                                ))),
                      ];
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget userProfilePhoto(ContactModel day, double radius, itemIndex, country) {
    return InkWell(
      onTap: () {
        ///used to view profile image in full screen
        Get.to(() => FullScreenImage(
              image: "",
              name: day.name ?? "NA",
              isBase64: day.photo != null &&
                  day.photo!.isNotEmpty &&
                  day.photo!.contains("dummyimage") == false,
              base64Data: base64Decode(day.photo!),
            ));
      },
      child: day.photo != null &&
              day.photo!.isNotEmpty &&
              day.photo!.contains("dummyimage") == false
          ? CircleAvatar(
              backgroundImage: MemoryImage(base64Decode(day.photo!)),
              radius: radius,
            )
          : country != ""
              ? CircleAvatar(
                  backgroundImage: AssetImage(country),
                  radius: radius,
                  backgroundColor: Colors.white,
                )
              : CircleAvatar(
                  radius: radius,
                  backgroundColor: Colors.white,
                  child: CustomText(
                    text: UIHelper.getShortName(string: day.name, limitTo: 2),
                    fontSize: 20.0,
                    color: whiteColor,
                    weight: fontWeightMedium,
                  ),
                ),
    );
  }

  /// used in list to show each contact and it's details
  adaptor(ContactModel day, int itemIndex, String coutnryflag,
      UserViewModel provider, String country) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          userProfilePhoto(day, 33.0, itemIndex, coutnryflag),
          UIHelper.horizontalSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: day.profession ?? "",
                  weight: fontWeightMedium,
                  fontSize: 12.0,
                  color: const Color(0xffABAAB4),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    SizedBox(
                      width: day.isFriend != null && day.isFriend == 1
                          ? Get.width * 0.42
                          : Get.width * 0.51,
                      child: AutoSizeText(
                        day.name ?? "",
                        textAlign: TextAlign.start,
                        maxFontSize: 17.0,
                        minFontSize: 15,
                        maxLines: 1,
                        style: textStyleWorkSense(weight: fontWeightMedium),
                      ),
                    ),
                    day.isFriend != null && day.isFriend == 1
                        ? MyCustomRatingView(
                            starSize: 15.0,
                            ratinigValue: day.average_rating != null
                                ? double.parse(day.average_rating.toString())
                                : 0,
                            padding: 0.0,
                            fontsize: 12.0,
                          )
                        : InkWell(
                            onTap: () async {
                              Uri uri = Uri.parse(
                                  'sms:${day.number}?body=Welcome to Infosha, Please download app from https://play.google.com/store/apps/details?id=com.ktech.infosha');

                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch $uri';
                                }
                              }
                            },
                            child: Container(
                              // height: 30.0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: const Color(0xFfAAEDFF),
                                  borderRadius: BorderRadius.circular(22)),
                              child: Center(
                                  child: Text(
                                "Invite",
                                style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.w500, fontSize: 17),
                              )),
                            ),
                          )
                  ],
                ),
                UIHelper.verticalSpaceSm1,
                Row(
                  children: [
                    coutnryflag == ""
                        ? const SizedBox.shrink()
                        : Image.asset(
                            coutnryflag,
                            width: 15,
                          ),
                    UIHelper.horizontalSpace3m,
                    day.number != ""
                        ? CustomText(
                            text: day.number ?? "",
                            color: const Color(0xffABAAB4),
                            fontSize: 14.0,
                          )
                        : Container(),
                    UIHelper.horizontalSpaceSm,
                    if (day.activeSubscriptionPlanName != null) ...[
                      Image.asset(
                        day.activeSubscriptionPlanName.contains("lord")
                            ? APPICONS.lordicon
                            : day.activeSubscriptionPlanName.contains("god")
                                ? APPICONS.godstatuspng
                                : APPICONS.kingstutspicpng,
                        width: 16.0,
                      ),
                      const SizedBox(width: 5),
                    ],
                    if (day.isFriend != null &&
                        day.isFriend.toString() == "1") ...[
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF007EFF),
                        size: 18,
                      )
                    ],
                  ],
                ),
                CustomText(
                  text: country.toString(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// used for main top header of the app
  Widget headerWidget() {
    return Column(
      children: [
        Consumer<UserViewModel>(builder: (context, provider, child) {
          return provider.userModel.profile == null
              ? const SizedBox()
              : ShapeOfView(
                  elevation: 3.0,
                  shape: ArcShape(
                      direction: ArcDirection.Outside,
                      height: 30,
                      position: ArcPosition.Bottom),
                  child: Container(
                    height: Get.height * 0.42,
                    width: Get.width,
                    color: secondaryColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UIHelper.verticalSpaceSm,
                        userProfilePhotoModel(
                            provider.userModel.profile!.profileUrl,
                            provider.userModel.username),
                        UIHelper.verticalSpaceSm,
                        NamewithlabelView(
                          displayName: provider.userModel.username!,
                          fontsize: 18.0.sp,
                          iconsize: 22.0,
                          iconname: provider.userModel.is_subscription_active ==
                                  true
                              ? provider.userModel.active_subscription_plan_name
                              : null,
                          showIcon: provider.userModel.is_subscription_active,
                        ),
                        UIHelper.verticalSpaceSm,
                        NicknameView(
                            nickName: provider.userModel.getNickName ?? []),
                        UIHelper.verticalSpaceSm,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.call_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              provider.userModel.number!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
        }),
      ],
    );
  }
}
 */