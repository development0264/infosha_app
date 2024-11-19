import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:infosha/followerscreen/controller/topfollowers_model.dart';
import 'package:country_state_city/country_state_city.dart' as con;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/followerscreen/topfollowers.dart';
import 'package:infosha/main.dart';
import 'package:infosha/screens/ProfileScreen/profilescreen.dart';
import 'package:infosha/screens/ProfileScreen/visitor_screen.dart';
import 'package:infosha/screens/feed/component/feed_tile.dart';
import 'package:infosha/screens/feed/component/upload_feed.dart';
import 'package:infosha/screens/feed/component/view_feed.dart';
import 'package:infosha/screens/feed/controller/feed_model.dart';
import 'package:infosha/screens/hscreen/contact_list.dart';
import 'package:infosha/searchscreens/searchscreen.dart';
import 'package:infosha/screens/hscreen/settings.dart';
import 'package:infosha/views/app_icons.dart';
import 'package:infosha/views/colors.dart';
import 'package:infosha/views/text_styles.dart';
import 'package:infosha/views/ui_helpers.dart';
import 'package:infosha/views/widgets/namewithlabel_view.dart';
import 'package:infosha/views/widgets/nickname_view.dart';
import 'package:infosha/views/widgets/setting_widget.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shape_of_view_null_safe/shape_of_view_null_safe.dart';

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
}
