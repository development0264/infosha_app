import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:infosha/screens/viewUnregistered/model/unregistered_user_model.dart';

import 'package:infosha/views/app_icons.dart';
import 'package:infosha/views/colors.dart';
import 'package:infosha/views/custom_text.dart';
import 'package:infosha/views/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

// ignore: must_be_immutable
class StateCountryView extends StatefulWidget {
  List<GetAddress> nickName;

  StateCountryView({Key? key, required this.nickName}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AddressViewState createState() => _AddressViewState();
}

class _AddressViewState extends State<StateCountryView> {
  late String selectedName;
  bool isLoaidng = false;

  @override
  void initState() {
    super.initState();
    if (widget.nickName.isNotEmpty) {
      setState(() {
        isLoaidng = true;
      });
      widget.nickName.removeWhere((address) =>
          (address.address!.city == null || address.address!.city!.isEmpty) &&
          (address.address!.state == null || address.address!.state!.isEmpty) &&
          (address.address!.country == null ||
              address.address!.country!.isEmpty));
      if (widget.nickName.isNotEmpty) {
        String formattedAddress = [
          widget.nickName.first.address!.city,
          widget.nickName.first.address!.state,
          widget.nickName.first.address!.country
        ].where((part) => part != null).join(', ');

        selectedName = formattedAddress;
      }
      setState(() {
        isLoaidng = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant StateCountryView oldWidget) {
    if (widget.nickName.isNotEmpty) {
      setState(() {
        isLoaidng = true;
      });
      widget.nickName.removeWhere((address) =>
          (address.address!.city == null || address.address!.city!.isEmpty) &&
          (address.address!.state == null || address.address!.state!.isEmpty) &&
          (address.address!.country == null ||
              address.address!.country!.isEmpty));
      if (widget.nickName.isNotEmpty) {
        String formattedAddress = [
          widget.nickName.first.address!.city,
          widget.nickName.first.address!.state,
          widget.nickName.first.address!.country
        ].where((part) => part != null).join(', ');

        selectedName = formattedAddress;
      }
      setState(() {
        isLoaidng = false;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return isLoaidng
        ? Container()
        : widget.nickName.isEmpty
            ? Container()
            : PopupMenuButton(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                constraints: BoxConstraints(
                    maxHeight: Get.height * 0.6,
                    maxWidth: Get.width * 0.4,
                    minWidth: Get.width * 0.2),
                position: PopupMenuPosition.under,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                          minWidth: 0, maxWidth: Get.width * 0.62),
                      child: Text(selectedName,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: fontWeightMedium,
                              fontSize: 16.sp)),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Image(
                      fit: BoxFit.cover,
                      height: 35,
                      width: 35,
                      filterQuality: FilterQuality.high,
                      image: AssetImage(APPICONS.copyicon),
                    ),
                  ],
                ),
                itemBuilder: (context) {
                  return widget.nickName.map((e) {
                    String formattedAddress = [
                      e.address!.city,
                      e.address!.state,
                      e.address!.country
                    ].where((part) => part != null).join(', ');
                    return PopupMenuItem<String>(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        value: formattedAddress,
                        child: RichText(
                            text: TextSpan(children: [
                          WidgetSpan(
                              child: CustomText(
                            text: formattedAddress,
                            color: Colors.black,
                            fontSize: 16.sp,
                            weight: fontWeightMedium,
                          )),
                          if ((Provider.of<UserViewModel>(context,
                                              listen: false)
                                          .userModel
                                          .is_subscription_active !=
                                      null &&
                                  Provider.of<UserViewModel>(context,
                                              listen: false)
                                          .userModel
                                          .is_subscription_active ==
                                      true) &&
                              (Provider.of<UserViewModel>(context,
                                          listen: false)
                                      .userModel
                                      .active_subscription_plan_name!
                                      .contains("god") ||
                                  Provider.of<UserViewModel>(context,
                                          listen: false)
                                      .userModel
                                      .active_subscription_plan_name!
                                      .contains("king"))) ...[
                            WidgetSpan(
                                child: CustomText(
                              text: " (${e.addedBy})",
                              color: hintColor,
                              fontSize: 14.sp,
                              weight: fontWeightRegular,
                            ))
                          ]
                        ])));
                  }).toList();
                },
                onSelected: (data) {
                  setState(() {
                    selectedName = data;
                  });
                },
              );
  }
}