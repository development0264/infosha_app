import 'dart:async';
import 'dart:convert';
import 'package:country_state_city/country_state_city.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infosha/config/api_endpoints.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/followerscreen/model/category_model.dart';
import 'package:infosha/followerscreen/model/top_followers_model.dart';
import 'package:infosha/followerscreen/model/top_visitors_model.dart';

class TopFollowVisitorModel extends ChangeNotifier {
  bool isTopFollowers = false;
  bool isTopVisitor = false;
  bool worldWide = false;
  List<Country> countryList = [];
  Country selectedCountry = Country(
      name: "Country",
      isoCode: "isoCode",
      phoneCode: "phoneCode",
      flag: "flag",
      currency: "currency",
      latitude: "latitude",
      longitude: "longitude");
  TopFollowersModel topFollowersModel = TopFollowersModel();
  TopVisitorsModel topVisitorsModel = TopVisitorsModel();
  TopVisitorsModel uniqueVisitorsModel = TopVisitorsModel();
  TopVisitorsModel nonUniqueVisitorsModel = TopVisitorsModel();
  ValueNotifier<double> progressFollower = ValueNotifier(0.0);
  ValueNotifier<double> progressVisitor = ValueNotifier(0.0);

  late Timer timerFollower;
  late Timer timerVisitor;

  String visitType = "Unique Visit";

  List<CategoryData> categoryList = [];
  CategoryData selectedCategory = CategoryData(categoryName: "Category", id: 0);

  TopFollowVisitorModel() {
    fetchCountry();
    fetchCategory();
  }

  fetchCategory() async {
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Params.UserToken}',
    };
    var request = http.Request('GET', Uri.parse(ApiEndPoints.categoryList));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    var result = await http.Response.fromStream(response);
    final decodeData = jsonDecode(result.body);

    print("fetchCategory ===> $decodeData");

    if (response.statusCode == 200) {
      categoryList.clear();
      var data = CategoryModel.fromJson(decodeData);
      if (data.data != null && data.data!.isNotEmpty) {
        categoryList.addAll(data.data!);
      }
      categoryList.insert(0, CategoryData(categoryName: "Category", id: 0));
      selectedCategory = categoryList.first;
    }
  }

  fetchCountry() async {
    countryList = await getAllCountries();

    if (countryList.isNotEmpty) {
      countryList.insert(
          0,
          Country(
              name: "Country",
              isoCode: "isoCode",
              phoneCode: "phoneCode",
              flag: "flag",
              currency: "currency",
              latitude: "latitude",
              longitude: "longitude"));
      selectedCountry = countryList.first;
    }
  }

  startTimerFollower() {
    progressFollower.value = 0.0;
    progressFollower.notifyListeners();
    const totalSteps = 99;
    const duration = Duration(seconds: 20);
    final stepTime = duration ~/ totalSteps;

    int step = 0;
    timerFollower = Timer.periodic(stepTime, (timer) {
      step++;
      progressFollower.value = (step / totalSteps).clamp(0.0, 1.0);
      progressFollower.notifyListeners();

      if (step >= totalSteps) {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  startTimerVisitor() {
    progressVisitor.value = 0.0;
    progressVisitor.notifyListeners();
    const totalSteps = 99;
    const duration = Duration(seconds: 20);
    final stepTime = duration ~/ totalSteps;

    int step = 0;
    timerVisitor = Timer.periodic(stepTime, (timer) {
      step++;
      progressVisitor.value = (step / totalSteps).clamp(0.0, 1.0);
      progressVisitor.notifyListeners();

      if (step >= totalSteps) {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  /// used to get top followers
  Future fetchTopFollowers() async {
    try {
      isTopFollowers = true;
      notifyListeners();
      startTimerFollower();

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('GET', Uri.parse(ApiEndPoints.topFollowers));
      request.body = json.encode({
        "country": selectedCountry.name == "Country" && worldWide
            ? ""
            : worldWide == false && selectedCountry.name == "Country"
                ? ""
                : selectedCountry.name,
        "category": selectedCategory.categoryName == "Category"
            ? ""
            : selectedCategory.id
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("request.body ==> ${decodeData}");

      if (response.statusCode == 200) {
        var temp = TopFollowersModel.fromJson(decodeData);
        topFollowersModel = temp;

        timerFollower.cancel();
        progressFollower.value = 1.0;
        progressFollower.notifyListeners();
        Future.delayed(const Duration(seconds: 1), () {
          isTopFollowers = false;
          notifyListeners();
        });
      } else {
        timerFollower.cancel();
        progressFollower.value = 1.0;
        progressFollower.notifyListeners();
        Future.delayed(const Duration(seconds: 1), () {
          isTopFollowers = false;
          notifyListeners();
        });
      }
    } catch (e) {
      timerFollower.cancel();
      progressFollower.value = 1.0;
      progressFollower.notifyListeners();
      Future.delayed(const Duration(seconds: 1), () {
        isTopFollowers = false;
        notifyListeners();
      });
      rethrow;
    }
  }

  /// used to get top visitors
  Future fetchTopVisitors() async {
    try {
      isTopVisitor = true;
      notifyListeners();
      startTimerVisitor();

      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('GET', Uri.parse(ApiEndPoints.topVisitors));
      request.body = json.encode({
        "country": selectedCountry.name == "Country" && worldWide
            ? ""
            : worldWide == false && selectedCountry.name == "Country"
                ? ""
                : selectedCountry.name,
        "is_unique_visit": 1 /* visitType == "Unique Visit" ? 1 : 0 */,
        "category": selectedCategory.categoryName == "Category"
            ? ""
            : selectedCategory.id
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("top visitor ==> $decodeData");

      if (response.statusCode == 200) {
        topVisitorsModel = TopVisitorsModel.fromJson(decodeData);
        uniqueVisitorsModel = topVisitorsModel;
        getNonUniqueVisitor();
        timerVisitor.cancel();
        progressVisitor.value = 1.0;
        progressVisitor.notifyListeners();
        Future.delayed(const Duration(seconds: 1), () {
          isTopVisitor = false;
          notifyListeners();
        });
      } else {
        timerVisitor.cancel();
        progressVisitor.value = 1.0;
        progressVisitor.notifyListeners();
        Future.delayed(const Duration(seconds: 1), () {
          isTopVisitor = false;
          notifyListeners();
        });
      }
    } catch (e) {
      timerVisitor.cancel();
      progressVisitor.value = 1.0;
      progressVisitor.notifyListeners();
      Future.delayed(const Duration(seconds: 1), () {
        isTopVisitor = false;
        notifyListeners();
      });
    }
  }

  getNonUniqueVisitor() async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('GET', Uri.parse(ApiEndPoints.topVisitors));
      request.body = json.encode({
        "country": selectedCountry.name == "Country" && worldWide
            ? ""
            : worldWide == false && selectedCountry.name == "Country"
                ? ""
                : selectedCountry.name,
        "is_unique_visit": 0,
        "category": selectedCategory.categoryName == "Category"
            ? ""
            : selectedCategory.id
      });

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("getNonUniqueVisitor ==> $decodeData");

      if (response.statusCode == 200) {
        var temp = TopVisitorsModel.fromJson(decodeData);
        nonUniqueVisitorsModel = temp;
        if (visitType != "Unique Visit") {
          topVisitorsModel = nonUniqueVisitorsModel;
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  void changeType(String? newValue) {
    visitType = newValue!;

    if (visitType == "Unique Visit") {
      topVisitorsModel = uniqueVisitorsModel;
    } else {
      topVisitorsModel = nonUniqueVisitorsModel;
    }
  }

  setInit() {
    fetchCategory();
    visitType = "Unique Visit";
    topVisitorsModel = uniqueVisitorsModel;
  }
}
