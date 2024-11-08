import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feed_reaction/widgets/emoji_reaction.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infosha/Controller/Viewmodel/reaction.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/main.dart';
import 'package:infosha/screens/feed/component/comment_bottomsheet.dart';
import 'package:infosha/screens/feed/component/edit_feed.dart';
import 'package:infosha/screens/feed/component/feed_reaction_bottomsheet.dart';
import 'package:infosha/screens/feed/component/feed_tile.dart';
import 'package:infosha/screens/feed/component/view_feed_bottomsheet.dart';
import 'package:infosha/screens/feed/controller/feed_model.dart';
import 'package:infosha/screens/feed/model/feed_list_model.dart';
import 'package:infosha/screens/otherprofile/reaction_bottomsheet.dart';
import 'package:infosha/screens/otherprofile/view_profile_screen.dart';
import 'package:infosha/views/app_icons.dart';
import 'package:infosha/views/colors.dart';
import 'package:infosha/views/custom_text.dart';
import 'package:infosha/views/text_styles.dart';
import 'package:infosha/views/ui_helpers.dart';
import 'package:infosha/views/widgets/feed_vote_button.dart';
import 'package:infosha/views/widgets/locked_widget.dart';
import 'package:infosha/views/widgets/vote_button.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ViewFeed extends StatefulWidget {
  String postUrl;

  ViewFeed({required this.postUrl});

  @override
  State<ViewFeed> createState() => _ViewFeedState();
}

class _ViewFeedState extends State<ViewFeed> {
  late FeedModel provider;
  VideoPlayerController? controller;
  bool isVisible = false;
  late UserViewModel userProvider;
  int selectedReactionId = -1;

  @override
  void initState() {
    provider = Provider.of<FeedModel>(context, listen: false);
    userProvider = Provider.of<UserViewModel>(context, listen: false);

    List<String> parts = widget.postUrl.split('/');
    String feedId = parts.last;
    print('Feed ID: $feedId');

    Future.microtask(
        () => context.read<FeedModel>().fetchSinglePosts(feedId).then((value) {
              print("post ==> ${provider.viewFeedListModel.data}");
              if (provider.viewFeedListModel.data!.data![0].fileUrl != null) {
                if (provider.viewFeedListModel.data!.data![0].fileUrl!
                        .contains('.mp4') ||
                    provider.viewFeedListModel.data!.data![0].fileUrl!
                        .contains('.m4v') ||
                    provider.viewFeedListModel.data!.data![0].fileUrl!
                        .contains('.mov')) {
                  initializaVideo();
                }
              }
            }));
    initialDynamic = "null";

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (provider.viewFeedListModel.data!.data![0].fileUrl != null) {
      if (provider.viewFeedListModel.data!.data![0].fileUrl!.contains('.mp4') ||
          provider.viewFeedListModel.data!.data![0].fileUrl!.contains('.m4v') ||
          provider.viewFeedListModel.data!.data![0].fileUrl!.contains('.mov')) {
        if (controller != null) {
          controller!.dispose();
        }
      }
    }
  }

  Future<void> initializaVideo() async {
    controller = VideoPlayerController.networkUrl(
        Uri.parse(provider.viewFeedListModel.data!.data![0].fileUrl!))
      ..initialize().then((value) {
        setState(() {});
      })
      ..setLooping(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1EBEC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0BA7C1),
        title: Text(
          "Feeds".tr,
          style: textStyleWorkSense(fontSize: 22),
        ),
      ),
      body: Consumer<FeedModel>(builder: (context, provider, child) {
        return provider.isViewLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: baseColor,
                ),
              )
            : Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      APPICONS.feedBackground,
                      height: Get.height * 0.4,
                      width: Get.width,
                      fit: BoxFit.fill,
                    ),
                  ),
                  provider.viewFeedListModel.data == null
                      ? SizedBox(
                          width: Get.width,
                          height: Get.height,
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.not_interested,
                                size: 50,
                                color: Colors.black,
                              ),
                              Text(
                                "Post Not Found",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 24),
                              )
                            ],
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(10.0),
                          width: Get.width,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5,
                                    spreadRadius: 2)
                              ]),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                headingContainer(
                                    provider.viewFeedListModel.data!.data![0]
                                            .user!.profile!.profileUrl ??
                                        "",
                                    provider.viewFeedListModel.data!.data![0].user == null
                                        ? ""
                                        : provider.viewFeedListModel.data!
                                                .data![0].user!.username ??
                                            "",
                                    provider.viewFeedListModel.data!.data![0].user == null
                                        ? ""
                                        : provider.viewFeedListModel.data!.data![0].user!.number ??
                                            "",
                                    provider
                                        .viewFeedListModel.data!.data![0].userId
                                        .toString(),
                                    provider.viewFeedListModel.data!.data![0].id
                                        .toString(),
                                    provider
                                                .viewFeedListModel
                                                .data!
                                                .data![0]
                                                .user!
                                                .activeSubscriptionPlanName !=
                                            null
                                        ? provider
                                                .viewFeedListModel
                                                .data!
                                                .data![0]
                                                .user!
                                                .activeSubscriptionPlanName ??
                                            ""
                                        : "",
                                    true,
                                    (provider.viewFeedListModel.data!.data![0].user!.isLocked != null &&
                                        provider.viewFeedListModel.data!.data![0].user!.isLocked == true)),
                                if (provider.viewFeedListModel.data!.data![0]
                                            .fileUrl !=
                                        null &&
                                    (provider.viewFeedListModel.data!.data![0]
                                            .fileUrl!
                                            .contains(".png") ||
                                        provider.viewFeedListModel.data!
                                            .data![0].fileUrl!
                                            .contains(".jpg"))) ...[
                                  imagePostContainer()
                                ],
                                if (provider.viewFeedListModel.data!.data![0]
                                            .fileUrl !=
                                        null &&
                                    (provider.viewFeedListModel.data!.data![0]
                                            .fileUrl!
                                            .contains('.mp4') ||
                                        provider.viewFeedListModel.data!
                                            .data![0].fileUrl!
                                            .contains('.m4v') ||
                                        provider.viewFeedListModel.data!
                                            .data![0].fileUrl!
                                            .contains('.mov'))) ...[
                                  videoPostContainer()
                                ],
                                if (provider.viewFeedListModel.data!.data![0]
                                        .description !=
                                    null) ...[textPostContainer()],
                                voteContainer()
                              ],
                            ),
                          ),
                        ),
                ],
              );
      }),
    );
  }

  headingContainer(String image, String name, String number, String id,
      String feedid, String plan, bool isActive, bool isLocked) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ViewProfileScreen(id: id));
      },
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: ClipOval(
                  child: SizedBox.fromSize(
                    size: Size.fromRadius(Get.height * 0.05),
                    child: image.isEmpty
                        ? Image.asset(APPICONS.profileicon)
                        : isBase64(image)
                            ? Image.memory(base64Decode(image),
                                fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: image,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    Image.asset(APPICONS.profileicon),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: baseColor),
                                ),
                              ),
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 0),
                  title: Wrap(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CustomText(
                        text: name,
                        color: const Color(0xFF46464F),
                        weight: fontWeightSemiBold,
                        fontSize: 14,
                      ),
                      if (plan.isNotEmpty) ...[
                        // const SizedBox(width: 5),
                        Image(
                          height: 30,
                          image: AssetImage(plan.contains("lord")
                              ? APPICONS.lordicon
                              : plan.contains("god")
                                  ? APPICONS.godstatuspng
                                  : APPICONS.kingstutspicpng),
                        )
                      ],
                      /* const Icon(
                        Icons.verified,
                        color: Color(0xFF007EFF),
                        size: 18,
                      ), */
                    ],
                  ),
                  subtitle: CustomText(
                    text: number,
                    color: const Color(0xFFABAAB4),
                    weight: fontWeightSemiBold,
                    fontSize: 14,
                  ),
                  trailing: PopupMenuButton(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    elevation: 10,
                    offset: const Offset(-10, 5),
                    position: PopupMenuPosition.under,
                    iconSize: 22,
                    icon: const Icon(
                      Icons.more_vert,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    itemBuilder: (context) {
                      return [
                        if (Params.Id == id) ...[
                          PopupMenuItem<int>(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              value: 0,
                              onTap: () {
                                showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                          // shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.white),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          title: Column(
                                            children: [
                                              Center(
                                                child: Text(
                                                  'Are you sure you want to delete?'
                                                      .tr,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 24),
                                                ),
                                              ),
                                            ],
                                          ),

                                          content: Text(
                                            'In order to delete this comment, you have to purchase status subscriptions'
                                                .tr,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),

                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, 'OK'),
                                              child: Text(
                                                'Cancel'.tr,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xff1B2870),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, 'OK');
                                                provider.deleteFeed(feedid);
                                              },
                                              child: Text(
                                                'Continue'.tr,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xff1B2870),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 10),
                                  const Image(
                                    image: AssetImage("images/delete.png"),
                                    height: 20,
                                    width: 20,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text("Delete Post".tr),
                                ],
                              )),
                          PopupMenuItem<int>(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              value: 3,
                              onTap: () {
                                Get.to(() => EditFeed(
                                    feedListData: provider
                                        .viewFeedListModel.data!.data![0]));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 10),
                                  const Image(
                                    image: AssetImage("images/edit.png"),
                                    height: 20,
                                    width: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text("Edit Post".tr),
                                ],
                              ))
                        ],
                        if (Params.Id != id.toString()) ...[
                          PopupMenuItem<int>(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              value: 1,
                              onTap: () {
                                provider.feedReport(id);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 10),
                                  Image.asset(
                                    'images/reportUser.png',
                                    height: 20,
                                    width: 20,
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Text("Report User".tr),
                                ],
                              )),
                          PopupMenuItem<int>(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              value: 2,
                              onTap: () {
                                showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                          // shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.white),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          title: Column(
                                            children: [
                                              Center(
                                                child: Text(
                                                  'Are you sure you want to block?'
                                                      .tr,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 24),
                                                ),
                                              ),
                                            ],
                                          ),

                                          content: Text(
                                            'In order to delete this comment, you have to purchase status subscriptions'
                                                .tr,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),

                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, 'OK'),
                                              child: Text(
                                                'Cancel'.tr,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xff1B2870),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, 'OK');
                                                provider.blockUser(id);
                                              },
                                              child: Text(
                                                'Continue'.tr,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xff1B2870),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 10),
                                  const Image(
                                    image: AssetImage("images/delete.png"),
                                    height: 20,
                                    width: 20,
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Text("Block User".tr),
                                ],
                              ))
                        ],
                      ];
                    },
                  ),
                ),
              ),
            ],
          ),
          if (isLocked) ...[LockWidget()]
        ],
      ),
    );
  }

  bool isBase64(String str) {
    try {
      base64.decode(str);

      return true;
    } catch (e) {
      return false;
    }
  }

  headingCommentContainer(
      String image, String name, String number, String id, String feedid) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ViewProfileScreen(id: id));
      },
      child: Row(
        children: [
          SizedBox(
            width: Get.width * 0.21,
            height: Get.height * 0.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: image.isEmpty
                  ? Image.asset(APPICONS.profileicon)
                  : isBase64(image)
                      ? Image.memory(base64Decode(image), fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.fill,
                          errorWidget: (context, url, error) =>
                              Image.asset(APPICONS.profileicon),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: baseColor),
                          ),
                        ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomText(
                    text: name,
                    color: const Color(0xFF46464F),
                    weight: fontWeightSemiBold,
                    fontSize: 14,
                  ),
                  /* UIHelper.horizontalSpaceSm,
                  Image(
                    height: 20,
                    image: AssetImage(
                      APPICONS.lordicon,
                    ),
                  ), */
                ],
              ),
              subtitle: CustomText(
                text: number,
                color: const Color(0xFFABAAB4),
                weight: fontWeightSemiBold,
                fontSize: 14,
              ),
              trailing: Params.Id == id.toString()
                  ? const SizedBox.shrink()
                  : PopupMenuButton(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      elevation: 10,
                      offset: const Offset(-10, 5),
                      position: PopupMenuPosition.under,
                      iconSize: 22,
                      icon: const Icon(
                        Icons.more_vert,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      itemBuilder: (context) {
                        return [
                          if (Params.Id == id) ...[
                            PopupMenuItem<int>(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                value: 0,
                                onTap: () {
                                  showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            // shadowColor: Colors.transparent,
                                            elevation: 0,
                                            shape: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                  color: Colors.white),
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            title: Column(
                                              children: [
                                                Center(
                                                  child: Text(
                                                    'Are you sure you want to delete?'
                                                        .tr,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 24),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            content: Text(
                                              'In order to delete this comment, you have to purchase status subscriptions'
                                                  .tr,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54),
                                            ),

                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, 'OK'),
                                                child: Text(
                                                  'Cancel'.tr,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xff1B2870),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context, 'OK');
                                                  provider.deleteFeed(feedid);
                                                },
                                                child: Text(
                                                  'Continue'.tr,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xff1B2870),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ));
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 10),
                                    const Image(
                                      image: AssetImage("images/delete.png"),
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text("Delete Post".tr),
                                  ],
                                )),
                            PopupMenuItem<int>(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                value: 3,
                                onTap: () {
                                  Get.to(() => EditFeed(
                                      feedListData: provider
                                          .viewFeedListModel.data!.data![0]));
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 10),
                                    const Image(
                                      image: AssetImage("images/edit.png"),
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text("Edit Post".tr),
                                  ],
                                ))
                          ],
                          if (Params.Id != id) ...[
                            PopupMenuItem<int>(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                value: 1,
                                onTap: () {
                                  provider.feedReport(id);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 10),
                                    Image.asset(
                                      'images/reportUser.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Text("Report User".tr),
                                  ],
                                )),
                            PopupMenuItem<int>(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                value: 2,
                                onTap: () {
                                  showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                            // shadowColor: Colors.transparent,
                                            elevation: 0,
                                            shape: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                  color: Colors.white),
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            title: Column(
                                              children: [
                                                Center(
                                                  child: Text(
                                                    'Are you sure you want to block?'
                                                        .tr,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 24),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            content: Text(
                                              'In order to delete this comment, you have to purchase status subscriptions'
                                                  .tr,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54),
                                            ),

                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, 'OK'),
                                                child: Text(
                                                  'Cancel'.tr,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xff1B2870),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context, 'OK');
                                                  provider.blockUser(id);
                                                },
                                                child: Text(
                                                  'Continue'.tr,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xff1B2870),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ));
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 10),
                                    const Image(
                                      image: AssetImage("images/delete.png"),
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Text("Block User".tr),
                                  ],
                                ))
                          ],
                        ];
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  imagePostContainer() {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
      height: Get.height * 0.44,
      width: Get.width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: provider.viewFeedListModel.data!.data![0].fileUrl == null
            ? Image.asset(APPICONS.profileicon)
            : CachedNetworkImage(
                imageUrl: provider.viewFeedListModel.data!.data![0].fileUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: baseColor)),
                errorWidget: (context, url, error) {
                  return Image.asset(APPICONS.profileicon);
                },
              ),
      ),
    );
  }

  videoPostContainer() {
    return VisibilityDetector(
      key: Key("0"),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction < 0.9) {
          if (mounted) {
            controller!.pause();
            setState(() {});
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
        height: Get.height * 0.44,
        width: Get.width,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: controller == null
              ? const CircularProgressIndicator(color: baseColor)
              : controller!.value.isInitialized == false
                  ? const CircularProgressIndicator(color: baseColor)
                  : InkWell(
                      onTap: () {
                        setState(() {
                          if (controller!.value.isPlaying) {
                            controller!.pause();
                          } else {
                            controller!.play();
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: SizedBox(
                                      width: constraints.maxWidth *
                                          controller!.value.aspectRatio,
                                      height: controller!.value.aspectRatio,
                                      child: VideoPlayer(
                                        controller!,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (controller!.value.isPlaying == false) ...[
                            const Align(
                                child: Icon(
                              Icons.play_circle_outline_rounded,
                              color: Colors.white,
                              size: 50,
                            ))
                          ]
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  voteContainer() {
    var model = provider.viewFeedListModel.data!.data![0];
    selectedReactionId = getReactionId(model.reactionName ?? "");

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 15, top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    FeedReactionBottomSheet().showReactions(
                        context,
                        provider.viewFeedListModel.data!.data![0].id
                            .toString());
                  },
                  child: Row(
                    children: [
                      Image(
                        width: 40,
                        image:
                            AssetImage(provider.convertReactionIdToPathNew(-1)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                          provider.viewFeedListModel.data!.data![0]
                              .totalReactionCount
                              .toString(),
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
                Text(
                    "${provider.viewFeedListModel.data!.data![0].totalRepliesComment.toString()} comments",
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold))
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FlutterFeedReaction(
                reactions: EmojiReactions.reactions,
                spacing: 0.0,
                dragStart: 20,
                dragSpace: 40.0,
                containerWidth: Get.width * 0.9,
                prefix:
                    Consumer<FeedModel>(builder: (context, provider, child) {
                  return Container(
                    height: 50,
                    constraints: BoxConstraints(
                        minWidth: Get.width * 0.3, maxHeight: Get.width * 0.35),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        selectedReactionId == -1
                            ? const SizedBox(
                                width: 30,
                                child:
                                    Text('👍', style: TextStyle(fontSize: 22)))
                            : getReactionEmoji(selectedReactionId),
                        const SizedBox(
                          width: 5,
                        ),
                        InkWell(
                          onTap: () {
                            FeedReactionBottomSheet().showReactions(
                                context,
                                provider.viewFeedListModel.data!.data![0].id
                                    .toString());
                          },
                          child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(5),
                              child: Text(getReactionName(selectedReactionId),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: selectedReactionId == -1
                                          ? Colors.black
                                          : primaryColor,
                                      fontWeight: selectedReactionId == -1
                                          ? FontWeight.normal
                                          : FontWeight
                                              .w600)) /* Text(
                              provider.feedListModel.data!.data![0]
                                  .totalReactionCount
                                  .toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ), */
                              ),
                        ),
                      ],
                    ),
                  );
                }),
                onReactionSelected: (val) {
                  String name = getReactionName(val.id);
                  setState(() {
                    selectedReactionId = val.id;
                    provider.viewFeedListModel.data!.data![0].reactionName =
                        name;
                  });

                  provider
                      .addFeedReaction(
                          provider.viewFeedListModel.data!.data![0].id
                              .toString(),
                          name)
                      .then((value) {
                    setState(() {
                      if (int.parse(provider.viewFeedListModel.data!.data![0]
                              .totalReactionCount
                              .toString()) >
                          value) {
                        selectedReactionId = -1;
                        provider.viewFeedListModel.data!.data![0].reactionName =
                            null;
                      }
                      provider.viewFeedListModel.data!.data![0]
                          .totalReactionCount = value;
                    });
                  });
                },
                onPressed: () {
                  if (provider.viewFeedListModel.data!.data![0].reactionName !=
                      null) {
                    provider
                        .addFeedReaction(
                            provider.viewFeedListModel.data!.data![0].id
                                .toString(),
                            provider
                                .viewFeedListModel.data!.data![0].reactionName!)
                        .then((value) {
                      selectedReactionId = -1;
                      provider.viewFeedListModel.data!.data![0].reactionName =
                          null;

                      provider.viewFeedListModel.data!.data![0]
                          .totalReactionCount = value;
                      setState(() {});
                    });
                  } else {
                    provider
                        .addFeedReaction(
                            provider.viewFeedListModel.data!.data![0].id
                                .toString(),
                            "like")
                        .then((value) {
                      selectedReactionId = 0;
                      provider.viewFeedListModel.data!.data![0].reactionName =
                          "like";

                      provider.viewFeedListModel.data!.data![0]
                          .totalReactionCount = value;
                      setState(() {});
                    });
                  }
                },
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.black38,
              ),
              /* Expanded(
                child: FeedVoteButton(
                  usercounts: int.parse(provider
                      .viewFeedListModel.data!.data![0].totalLikes
                      .toString()),
                  isLikeButton: true,
                  likestatus: 0,
                  isActive: provider.viewFeedListModel.data!.data![0].isLiked ??
                      false,
                  color: Colors.white,
                  onTap: () {
                    if ((userProvider.userModel.is_subscription_active ==
                                true &&
                            userProvider
                                .userModel.active_subscription_plan_name!
                                .contains("god")) ||
                        (userProvider.userModel.is_subscription_active ==
                                true &&
                            userProvider
                                .userModel.active_subscription_plan_name!
                                .contains("king"))) {
                      FeedVoteBottomSheet().showFeedVote(
                          context,
                          provider.feedListModel.data!.data![0].id.toString(),
                          true);
                    }
                  },
                  oncallback: (value) {
                    provider
                        .likeDislikeFeed(
                            provider.viewFeedListModel.data!.data![0].id
                                .toString(),
                            true)
                        .then((value) {
                      if (value.status == 0) {
                        setState(() {
                          provider.viewFeedListModel.data!.data![0].isLiked =
                              true;
                          provider.viewFeedListModel.data!.data![0].isDisliked =
                              false;
                          provider.viewFeedListModel.data!.data![0].totalLikes =
                              value.likeCount;
                          provider.viewFeedListModel.data!.data![0]
                              .totalDislikes = value.disLikeCount;
                        });
                      } else {
                        setState(() {
                          provider.viewFeedListModel.data!.data![0].isLiked =
                              false;
                          provider.viewFeedListModel.data!.data![0].isDisliked =
                              false;
                          provider.viewFeedListModel.data!.data![0].totalLikes =
                              value.likeCount;
                          provider.viewFeedListModel.data!.data![0]
                              .totalDislikes = value.disLikeCount;
                        });
                      }
                    });
                  },
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.black38,
              ),
              Expanded(
                child: FeedVoteButton(
                  usercounts: int.parse(provider
                      .viewFeedListModel.data!.data![0].totalDislikes
                      .toString()),
                  isLikeButton: false,
                  likestatus: 1,
                  isActive:
                      provider.viewFeedListModel.data!.data![0].isDisliked ??
                          false,
                  color: Colors.white,
                  onTap: () {
                    if ((userProvider.userModel.is_subscription_active ==
                                true &&
                            userProvider
                                .userModel.active_subscription_plan_name!
                                .contains("god")) ||
                        (userProvider.userModel.is_subscription_active ==
                                true &&
                            userProvider
                                .userModel.active_subscription_plan_name!
                                .contains("king"))) {
                      FeedVoteBottomSheet().showFeedVote(
                          context,
                          provider.feedListModel.data!.data![0].id.toString(),
                          false);
                    }
                  },
                  oncallback: (value) {
                    provider
                        .likeDislikeFeed(
                            provider.viewFeedListModel.data!.data![0].id
                                .toString(),
                            false)
                        .then((value) {
                      if (value.status == 1) {
                        setState(() {
                          provider.viewFeedListModel.data!.data![0].isLiked =
                              false;
                          provider.viewFeedListModel.data!.data![0].isDisliked =
                              true;
                          provider.viewFeedListModel.data!.data![0].totalLikes =
                              value.likeCount;
                          provider.viewFeedListModel.data!.data![0]
                              .totalDislikes = value.disLikeCount;
                        });
                      } else {
                        setState(() {
                          provider.viewFeedListModel.data!.data![0].isLiked =
                              false;
                          provider.viewFeedListModel.data!.data![0].isDisliked =
                              false;
                          provider.viewFeedListModel.data!.data![0].totalLikes =
                              value.likeCount;
                          provider.viewFeedListModel.data!.data![0]
                              .totalDislikes = value.disLikeCount;
                        });
                      }
                    });
                  },
                ),
              ), 
              Container(
                width: 1,
                height: 24,
                color: Colors.black38,
              ),*/
              SizedBox(
                width: Get.width * 0.3,
                child: InkWell(
                  onTap: () {
                    CommentBottomSheet().showComments(context, 0);
                    /* setState(() {
                      // widget.onButtonTap();
                      isVisible = !isVisible;
                    }); */
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isVisible
                          ? const Image(
                              height: 17,
                              // width: 30,
                              image: AssetImage('images/fillComment.png'))
                          : const Image(
                              height: 17,
                              // width: 30,
                              image: AssetImage('images/comments.png')),
                      const SizedBox(width: 10),
                      Text(
                          "Comments"
                          /* provider.viewFeedListModel.data!.data![0]
                              .totalRepliesComment
                              .toString() */
                          ,
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Colors.black38,
              ),
              SizedBox(
                width: Get.width * 0.25,
                child: InkWell(
                  onTap: () async {
                    Share.share(
                        'https://infosha.org/feed/${provider.viewFeedListModel.data!.data![0].id}');
                  },
                  child: SizedBox(
                    // width: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                            height: 17,
                            // width: 30,
                            image: AssetImage(APPICONS.shareIcon)),
                        const SizedBox(width: 10),
                        Text("Share".tr,
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // commentContainer()
        ],
      );
    });
  }

  textPostContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(
            height: 5,
            thickness: 2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            provider.viewFeedListModel.data!.data![0].description ?? "",
            style: GoogleFonts.workSans(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(
            height: 5,
            thickness: 2,
          ),
        )
      ],
    );
  }

  /* commentContainer() {
    return Visibility(
      visible: isVisible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Divider(
              height: 5,
              thickness: 2,
            ),
          ),
          Container(
            width: Get.width,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    // height: Get.height * 0.055,
                    alignment: Alignment.center,
                    child: Form(
                      key: provider.viewFeedListModel.data!.data![0].formKey,
                      child: TextFormField(
                        focusNode:
                            provider.viewFeedListModel.data!.data![0].focusNode,
                        // autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: Key("1"),
                        controller: provider
                            .viewFeedListModel.data!.data![0].replyController!,
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return "Please write reply".tr;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(left: 10),
                            focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(3.0),
                                ),
                                borderSide: BorderSide(
                                    color: Color(0xFf767680), width: 2)),
                            border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(3.0),
                                ),
                                borderSide: BorderSide(
                                    color: Color(0xFf767680), width: 2)),
                            hintText: "Write Reply...".tr,
                            hintStyle: textStyleWorkSense(
                                fontSize: 14.0,
                                color: const Color(0xFF46464F),
                                weight: fontWeightRegular)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Get.width * 0.02),
                GestureDetector(
                  onTap: () {
                    if (provider
                        .viewFeedListModel.data!.data![0].formKey!.currentState!
                        .validate()) {
                      provider
                          .addFeedReply(
                              provider.viewFeedListModel.data!.data![0].id
                                  .toString(),
                              provider.viewFeedListModel.data!.data![0]
                                  .replyController!.text
                                  .trim())
                          .then((value) {
                        provider.fetchPostsData(0).then((value) {
                          setState(() {
                            provider.viewFeedListModel.data!.data![0] = value;
                          });
                        });
                        provider
                            .viewFeedListModel.data!.data![0].replyController!
                            .clear();

                        provider.viewFeedListModel.data!.data![0].focusNode!
                            .unfocus();
                      });
                    }
                  },
                  child: provider.isAddComment
                      ? const CircularProgressIndicator(color: baseColor)
                      : Image.asset(
                          "images/sendIcon.png",
                          height: Get.height * 0.06,
                          // width: Get.width * 0.2,
                        ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: provider.viewFeedListModel.data!.data![0]
                        .repliesComment!.isEmpty
                    ? 10
                    : 0),
            child: Text(
              "Comments",
              style: GoogleFonts.workSans(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (provider.viewFeedListModel.data!.data![0].repliesComment !=
              null) ...[
            ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: provider
                  .viewFeedListModel.data!.data![0].repliesComment!.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var data = provider
                    .viewFeedListModel.data!.data![0].repliesComment![index];
                return replyCommentContainer(index, data);
              },
            ),
            const Padding(
              padding: EdgeInsets.all(5.0),
              child: Divider(
                height: 10,
                thickness: 2,
                color: Colors.transparent,
              ),
            ),
          ]
        ],
      ),
    );
  }
 */
  replyCommentContainer(int index, RepliesComment data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 10),
            child: headingCommentContainer(
                data.profile ?? "",
                data.username ?? "",
                data.number ?? "",
                data.addedBy.toString(),
                "")),
        Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 10, bottom: 15, top: 5),
          child: Text(
            data.comment ?? "",
            style: GoogleFonts.workSans(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        /* Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                VoteButtonSmall(
                  usercounts: 10,
                  isLikeButton: true,
                  likestatus: 0,
                  isActive: false,
                  color: Colors.white,
                  oncallback: (value) {},
                ),
                VoteButtonSmall(
                  usercounts: 10,
                  isLikeButton: false,
                  likestatus: 1,
                  isActive: false,
                  color: Colors.white,
                  oncallback: (value) {},
                ),
                GestureDetector(
                  onTap: () async {},
                  child: Container(
                    width: null,
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      //  mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(APPICONS.replyIcon,
                            height: Get.height * 0.025),
                        UIHelper.horizontalSpaceSm,
                        Text("Reply".tr,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ), */
      ],
    );
  }
}
