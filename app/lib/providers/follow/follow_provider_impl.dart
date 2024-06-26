import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earth_and_i/providers/follow/follow_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowProviderImpl implements FollowProvider {
  const FollowProviderImpl({
    required FirebaseFirestore storage,
  }) : _storage = storage;

  final FirebaseFirestore _storage;

  @override
  Future<void> postFollowing(String id) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    await _storage.collection('follows').doc(uid).update({
      'followings': FieldValue.arrayUnion([id])
    });
  }

  @override
  Future<void> deleteFollowing(String id) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    await _storage.collection('follows').doc(uid).update({
      'followings': FieldValue.arrayRemove([id])
    });
  }

  @override
  Future<List<dynamic>> getFollowings() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    List<dynamic> followings =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followings'];

    if (followings.isEmpty) {
      return [];
    }

    // Map<String, dynamic>으로 바꾸고 isFollowing 추가
    List<dynamic> users = (await _storage
            .collection("users")
            .where("id", whereIn: followings)
            .get())
        .docs
        .map((e) => e.data())
        .toList();

    return users.map((user) {
      user['is_following'] = true;
      return user;
    }).toList();
  }

  @override
  Future<List<dynamic>> getFollowers() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    List<dynamic> followers =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followers'];

    if (followers.isEmpty) {
      return [];
    }

    Map<String, bool> isFollowings = {
      for (var e in followers) e as String: false
    };

    List<dynamic> followingIds =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followings'];

    for (int i = 0; i < followers.length; i++) {
      if (followingIds.contains(followers[i])) {
        isFollowings[followers[i]] = true;
      }
    }

    List<dynamic> users = (await _storage
            .collection("users")
            .where("id", whereIn: followers)
            .get())
        .docs
        .map((e) => e.data())
        .toList();

    return users.asMap().entries.map((e) {
      e.value['is_following'] = isFollowings[e.value['id']];
      return e.value;
    }).toList();
  }

  @override
  Future<List<dynamic>> getTopRankings() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // get FollowerIds
    List<dynamic> followers =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followers'];

    // get followingIds
    List<dynamic> followingIds =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followings'];

    List<String> friendIds = [uid];

    // refine friendIds
    for (int i = 0; i < followers.length; i++) {
      if (followingIds.contains(followers[i])) {
        friendIds.add(followers[i]);
      }
    }

    if (friendIds.isEmpty) {
      return [];
    }

    // get Friend Data
    List<dynamic> users = (await _storage
            .collection("users")
            .where("id", whereIn: friendIds)
            .get())
        .docs
        .map((e) => e.data())
        .toList();

    // sort by totalDeltaCO2
    users.sort((a, b) {
      double aTotalDeltaCO2 =
          a['total_negative_delta_co2'] + a['total_positive_delta_co2'];
      double bTotalDeltaCO2 =
          b['total_negative_delta_co2'] + b['total_positive_delta_co2'];
      return aTotalDeltaCO2.compareTo(bTotalDeltaCO2);
    });

    // return top 3
    return users.sublist(0, users.length > 3 ? 3 : users.length);
  }

  @override
  Future<List> getRankings() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // get FollowerIds
    List<dynamic> followers =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followers'];

    // get followingIds
    List<dynamic> followingIds =
        (await _storage.collection('follows').doc(uid).get())
            .data()!['followings'];

    List<String> friendIds = [uid];

    // refine friendIds
    for (int i = 0; i < followers.length; i++) {
      if (followingIds.contains(followers[i])) {
        friendIds.add(followers[i]);
      }
    }

    if (friendIds.isEmpty || friendIds.length < 3) {
      return [];
    }

    // get Friend Data
    List<dynamic> users = (await _storage
            .collection("users")
            .where("id", whereIn: friendIds)
            .get())
        .docs
        .map((e) => e.data())
        .toList();

    // sort by totalDeltaCO2
    users.sort((a, b) {
      double aTotalDeltaCO2 =
          a['total_negative_delta_co2'] + a['total_positive_delta_co2'];
      double bTotalDeltaCO2 =
          b['total_negative_delta_co2'] + b['total_positive_delta_co2'];
      return aTotalDeltaCO2.compareTo(bTotalDeltaCO2);
    });

    return users.sublist(3, users.length);
  }
}
