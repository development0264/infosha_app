import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:infosha/Controller/models/vote_status_mode.dart';
import 'package:infosha/config/api_endpoints.dart';
import 'package:infosha/config/const.dart';
import 'package:infosha/screens/feed/model/feed_list_model.dart';
import 'package:infosha/screens/feed/model/feed_reaction_model.dart';
import 'package:infosha/screens/feed/model/feed_vote_model.dart';
import 'package:infosha/views/app_icons.dart';
import 'package:infosha/views/ui_helpers.dart';

class FeedModel extends ChangeNotifier {
  bool isUploading = false;
  bool isLoading = true;
  bool isViewLoading = false;
  bool isAddComment = false;
  bool isLoadingMorePost = false;
  bool isReactionOfComment = false;

  FeedListModel feedListModel = FeedListModel();
  FeedListModel viewFeedListModel = FeedListModel();
  FeedVoteModel feedVoteModel = FeedVoteModel();
  FeedReactionModel feedReactionModel = FeedReactionModel();

  Future addPost(String? description, XFile? file) async {
    try {
      isUploading = true;
      notifyListeners();
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request =
          http.MultipartRequest('POST', Uri.parse(ApiEndPoints.addFeed));

      request.fields
          .addAll({"description": description!.isEmpty ? '' : description});
      request.headers.addAll(headers);
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("addPost ==> $decodeData");

      if (response.statusCode == 200) {
        fetchPosts();
        Get.back();
        Get.back();
        UIHelper.showMySnak(
            title: "Upload",
            message: "Feed is uploaded successfully",
            isError: false);
        isUploading = false;
        notifyListeners();
      } else {
        UIHelper.showMySnak(
            title: "Upload", message: decodeData["message"], isError: true);
        isUploading = false;
        notifyListeners();
      }
    } catch (e) {
      isUploading = false;
      notifyListeners();
    }
  }

  Future fetchPosts() async {
    try {
      isLoading = true;
      notifyListeners();
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request =
          http.Request('GET', Uri.parse("${ApiEndPoints.feed}?page=1"));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("fetchPosts ==> $decodeData");

      if (response.statusCode == 200) {
        feedListModel = FeedListModel.fromJson(decodeData);

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

  Future fetchSinglePosts(String id) async {
    try {
      isViewLoading = true;
      notifyListeners();
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request(
          'GET', Uri.parse("${ApiEndPoints.feed}?page=1&feed_id=$id"));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("fetchPosts ==> $decodeData");

      if (response.statusCode == 200) {
        viewFeedListModel = FeedListModel.fromJson(decodeData);

        isViewLoading = false;
        notifyListeners();
      } else {
        isViewLoading = false;
        notifyListeners();
      }
    } catch (e) {
      isViewLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future fetchMorePosts(int page) async {
    try {
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request =
          http.Request('GET', Uri.parse("${ApiEndPoints.feed}?page=$page"));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("fetchMorePosts ==> $decodeData");

      if (response.statusCode == 200) {
        FeedListModel feed = FeedListModel.fromJson(decodeData);

        if (feed.data!.data != null && feed.data!.data!.isNotEmpty) {
          feedListModel.data!.data!.addAll(feed.data!.data!);
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future fetchPostsData(String id) async {
    isAddComment = true;
    notifyListeners();
    try {
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request(
          'GET', Uri.parse("${ApiEndPoints.feed}?page=1&feed_id=$id"));

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      if (response.statusCode == 200) {
        FeedListModel data = FeedListModel.fromJson(decodeData);

        isAddComment = false;
        notifyListeners();
        return data.data!.data![0];
      } else {
        isAddComment = false;
        notifyListeners();
        return FeedListData();
      }
    } catch (e) {
      isAddComment = false;
      notifyListeners();
      rethrow;
      // return FeedListData();
    }
  }

  Future<VoteStatusModel> likeDislikeFeed(String feedId, bool isLike) async {
    // int status = -1;
    VoteStatusModel status =
        VoteStatusModel(status: -1, likeCount: 0, disLikeCount: 0);
    try {
      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
        'Content-Type': 'application/json'
      };
      var request = http.Request(
          'POST',
          Uri.parse(
              isLike ? ApiEndPoints.addFeedLike : ApiEndPoints.addFeedDislike));
      request.body = json.encode({"feed_id": feedId});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      if (response.statusCode == 200) {
        print("likeDislikeReview ==> $decodeData");
        if (decodeData["message"]
            .toString()
            .contains("Your dislike added successfully in comment")) {
          // status = 1;
          status = VoteStatusModel(
              status: 1,
              likeCount: decodeData["data"]["like"],
              disLikeCount: decodeData["data"]["dislike"]);
        } else if (decodeData["message"]
            .toString()
            .contains("Your dislike removed successfully in comment")) {
          // status = -1;
          status = VoteStatusModel(
              status: -1,
              likeCount: decodeData["data"]["like"],
              disLikeCount: decodeData["data"]["dislike"]);
        } else if (decodeData["message"]
            .toString()
            .contains("Your like removed successfully in comment.")) {
          // status = -1;
          status = VoteStatusModel(
              status: -1,
              likeCount: decodeData["data"]["like"],
              disLikeCount: decodeData["data"]["dislike"]);
        } else if (decodeData["message"]
            .toString()
            .contains("Your like added successfully in comment")) {
          // status = 0;
          status = VoteStatusModel(
              status: 0,
              likeCount: decodeData["data"]["like"],
              disLikeCount: decodeData["data"]["dislike"]);
        } else {
          // status = -1;
          status = VoteStatusModel(
              status: -1,
              likeCount: decodeData["data"]["like"],
              disLikeCount: decodeData["data"]["dislike"]);
        }

        return status;
      } else {
        print(response.reasonPhrase);
        return status;
      }
    } catch (e) {
      return status;
    }
  }

  Future feedReport(String id) async {
    try {
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('POST', Uri.parse(ApiEndPoints.reportFeed));
      request.body = json.encode({"feed_report_user_id": id});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("feedReport ==> $decodeData");
      if (response.statusCode == 200) {
        UIHelper.showMySnak(
            title: "Report",
            message: 'User reported successfully',
            isError: false);
      } else {
        UIHelper.showMySnak(
            title: "Report",
            message: 'This user is already reported',
            isError: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future addFeedReply(String feedId, String comment) async {
    try {
      isAddComment = true;
      notifyListeners();
      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
        'Content-Type': 'application/json'
      };
      var request =
          http.Request('POST', Uri.parse(ApiEndPoints.addFeedReplies));
      request.body = json.encode({"feed_id": feedId, "comment": comment});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("addReply ==> $decodeData ==> $feedId");
      if (response.statusCode == 200) {
        isAddComment = false;
        notifyListeners();
      } else {
        UIHelper.showMySnak(
            title: "Error", message: decodeData["message"], isError: true);

        isAddComment = false;
        notifyListeners();
      }
    } catch (e) {
      isAddComment = false;
      notifyListeners();

      // return [];
    }
  }

  /// used to add review reply
  Future addReviewReply(String feedId, String comment) async {
    try {
      isAddComment = true;
      notifyListeners();
      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
        'Content-Type': 'application/json'
      };
      var request =
          http.Request('POST', Uri.parse(ApiEndPoints.addReviewReply));
      request.body = json.encode({"feed_reply_id": feedId, "comment": comment});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("addReviewReply ==> $decodeData ==> $feedId");
      if (response.statusCode == 200) {
        isAddComment = false;
        notifyListeners();
      } else {
        UIHelper.showMySnak(
            title: "Error", message: decodeData["message"], isError: true);

        isAddComment = false;
        notifyListeners();
      }
    } catch (e) {
      isAddComment = false;
      notifyListeners();

      // return [];
    }
  }

  Future blockUser(String id) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('POST', Uri.parse(ApiEndPoints.blockUser));
      request.body = json.encode({"block_user_id": id});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      print("block user ==> ${decodeData}");

      if (response.statusCode == 200) {
        UIHelper.showMySnak(
            title: "Block",
            message: 'User blocked successfully',
            isError: false);
        fetchPosts();
      } else {
        UIHelper.showMySnak(
            title: "Block", message: decodeData["message"], isError: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future deleteFeed(String id) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('POST', Uri.parse(ApiEndPoints.deleteFeed));
      request.body = json.encode({"feed_id": id});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("deleteFeed ==> $decodeData");
      if (response.statusCode == 200) {
        UIHelper.showMySnak(
            title: "Delete",
            message: 'Feed successfully deleted',
            isError: true);
        fetchPosts();
      } else {
        UIHelper.showMySnak(
            title: "Delete", message: decodeData["message"], isError: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future editPost(String? description, XFile? file, String id) async {
    try {
      isUploading = true;
      notifyListeners();
      var headers = {
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request =
          http.MultipartRequest('POST', Uri.parse(ApiEndPoints.updateFeed));

      request.fields.addAll({
        "description": description!.isEmpty ? '' : description,
        'feed_id': id
      });
      request.headers.addAll(headers);
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("editPost ==> $decodeData");

      if (response.statusCode == 200) {
        fetchPosts();

        Get.back();
        UIHelper.showMySnak(
            title: "Edit",
            message: "Feed is updated successfully",
            isError: false);
        isUploading = false;
        notifyListeners();
      } else {
        UIHelper.showMySnak(
            title: "Edit", message: decodeData["message"], isError: true);
        isUploading = false;
        notifyListeners();
      }
    } catch (e) {
      isUploading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// used to get list of user who give up/down vote
  Future getUserList(String id, bool isLike) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request = http.Request('GET', Uri.parse(ApiEndPoints.feedVoteList));
      request.body = json
          .encode({"feed_id": id, "user_type": isLike ? "like" : "dislike"});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      print("getUserList ==> $decodeData");

      if (response.statusCode == 200) {
        feedVoteModel = FeedVoteModel.fromJson(decodeData);
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  ///used to react on feed
  Future<int> addFeedReaction(String commentId, String name) async {
    try {
      var headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
        'Content-Type': 'application/json'
      };
      var request =
          http.Request('POST', Uri.parse(ApiEndPoints.addFeedReaction));
      request.body = json.encode({"feed_id": commentId, "reaction_name": name});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);

      if (response.statusCode == 200) {
        debugPrint("addReaction ==> $commentId $decodeData");
        return decodeData["data"]["reactionCount"];
      } else {
        return decodeData["data"]["reactionCount"];
      }
    } catch (e) {
      return 0;
    }
  }

  /// used to get reaction list of any review
  Future getReactionOfFeed(String id) async {
    try {
      isReactionOfComment = true;
      notifyListeners();
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Params.UserToken}',
      };
      var request =
          http.Request('GET', Uri.parse(ApiEndPoints.getFeedReactionList));
      request.body = json.encode({"feed_id": id});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var result = await http.Response.fromStream(response);
      final decodeData = jsonDecode(result.body);
      debugPrint("getReactionOfFeed ==> $decodeData");

      if (response.statusCode == 200) {
        feedReactionModel = FeedReactionModel.fromJson(decodeData);
        isReactionOfComment = false;
        notifyListeners();
      } else {
        isReactionOfComment = false;
        notifyListeners();
      }
    } catch (e) {
      isReactionOfComment = false;
      notifyListeners();
      rethrow;
    }
  }

  /// used to get icon path from id
  String convertReactionIdToPath(int id) {
    var path = APPICONS.reactionpng;
    switch (id) {
      case -1:
        path = path;
        break;
      case 0:
        path = APPICONS.lovepng;
        break;
      case 1:
        path = APPICONS.wowpng;
        break;
      case 2:
        path = APPICONS.lolpng;
        break;
      case 3:
        path = APPICONS.sadpng;
        break;
      case 4:
        path = APPICONS.angrypng;
        break;
      default:
    }
    return path;
  }

  String convertReactionIdToPathNew(int id) {
    var path = APPICONS.reactionpng;
    switch (id) {
      case -1:
        path = path;
        break;
      case 2:
        path = APPICONS.lovepng;
        break;
      case 4:
        path = APPICONS.wowpng;
        break;
      case 5:
        path = APPICONS.angrypng;
        break;
      case 6:
        path = APPICONS.sadpng;
        break;
      default:
    }
    return path;
  }
}
