import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:provider/provider.dart';

class LockWidget extends StatelessWidget {
  const LockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(builder: (context, provider, child) {
      return (provider.userModel.is_subscription_active == true &&
              (provider.userModel.active_subscription_plan_name != null &&
                  provider.userModel.active_subscription_plan_name!
                      .contains("god")))
          ? const SizedBox()
          : Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black38.withOpacity(0.1),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 28, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          "Profile Locked",
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
    });
  }
}
