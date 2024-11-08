import 'dart:convert';
import 'package:country_state_city/country_state_city.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infosha/config/api_endpoints.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/followerscreen/model/followers_list_model.dart';
import 'package:infosha/followerscreen/model/following_list_model.dart';
import 'package:infosha/followerscreen/model/top_followers_model.dart';
import 'package:infosha/followerscreen/model/top_visitors_model.dart';

class FollowersController extends ChangeNotifier {
  bool isLoading = false;
  FollowersListModel followerListModel = FollowersListModel();

  Future getFollowers(String number) async {
    try {
      isLoading = true;
      notifyListeners();
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.MultipartRequest(
          'POST', Uri.parse("${ApiEndPoints.followersList}?page=1"));
      request.headers.addAll(headers);
      request.fields.addAll({
        'number': number
      });


      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("FollowingList ==> $decodeData");

      if (response.statusCode == 200) {
        followerListModel = FollowersListModel.fromJson(decodeData);
        isLoading = false;
        notifyListeners();
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future fetchMoreFollowing(String number, int page) async {
    try {
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };


      var request = http.MultipartRequest(
          'POST', Uri.parse("${ApiEndPoints.followersList}?page=$page&number=$number"));

      request.headers.addAll(headers);
      request.fields.addAll({
        'number': number
      });

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("FollowingList ==> $decodeData");

      if (response.statusCode == 200) {
        var temp = FollowersListModel.fromJson(decodeData);
        followerListModel.data!.addAll(temp.data ?? []);
      }
    } catch (e) {
      rethrow;
    }
  }
}
