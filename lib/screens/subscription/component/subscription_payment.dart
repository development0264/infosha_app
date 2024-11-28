import 'dart:convert';

// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infosha/Controller/Viewmodel/userviewmodel.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/screens/home/home_screen.dart';
import 'package:infosha/utils/error_boundary.dart';
import 'package:infosha/views/colors.dart';
import 'package:infosha/views/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SubscriptionPayment extends StatefulWidget {
  String paymentLink;
  bool isNewUser;
  SubscriptionPayment(
      {super.key, required this.paymentLink, required this.isNewUser});

  @override
  State<SubscriptionPayment> createState() => _SubscriptionPaymentState();
}

class _SubscriptionPaymentState extends State<SubscriptionPayment> {
  late WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    /* controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..setOnConsoleMessage((message) async {
      //   print('${message.level}: ${message.message} (${message.toString()})');
      //   var response = json.decode(message.toString());
      //   print("response ==> 1 ${response}");
      //   var response1 = json.decode(response);
      //   print("response ==> 2 $response1");
      // })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              isLoading = true;
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) async {
            print("url ==> $url");
            final response = await controller.runJavaScriptReturningResult(
                "document.documentElement.innerText");
            var json1 = jsonEncode(response);
            print("checkjson ==>  ${json}");
            var responseData = json.decode(json1);
            print("checkjson ==> 1 $responseData");
            var checkjson = json.decode(responseData);
            print("checkjson ==> 2 $checkjson");

            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            print("url ==> 1 ${request}");

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentLink)); */
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(body: SafeArea(
          child: /* isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: baseColor))
                  : */
              Consumer<UserViewModel>(builder: (context, provider, child) {
        return WebView(
            zoomEnabled: true,
            // javascriptChannels: Set.from(elements),

            initialUrl: widget.paymentLink,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (navigation) async {
              print("navigation ==> $navigation");
              return NavigationDecision.navigate;
            },
            onWebViewCreated: (controller1) {
              controller = controller1;
              // webViewController!.runJavascriptReturningResult('"document.body.scrollHeight * 100"');
            },
            onPageStarted: ((url) async {
              // await webViewController!.runJavascriptReturningResult("document.documentElement.body.scrollHeight");
            }),
            onPageFinished: (finish) async {
              final response = await controller.runJavascriptReturningResult(
                  "document.documentElement.innerText");

              var responseData = json.decode(response);
              var checkjson = json.decode(responseData);

              if (checkjson != null) {
                if (checkjson["message"] ==
                    "Subscription create successfully") {
                  provider.userModel =
                      await provider.getUserProfileById(Params.UserToken);
                  Get.offAll(() => const HomeScreen());
                  UIHelper.showMySnak(
                      title: "Subscription",
                      message: "Subscription create successfully".tr,
                      isError: false);
                } else {
                  provider.userModel =
                      await provider.getUserProfileById(Params.UserToken);
                  Get.offAll(() => const HomeScreen());
                }
              }

              setState(() {
                isLoading = false;
              });
            });
      }) /* WebViewWidget(controller: controller) */)),
    );
  }
}
