import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_webapi_first_course/services/web_client.dart';

// TODO: HANDLE INVALID TOKEN

class AuthService {
  String url = WebService.url;
  http.Client client = WebService.start();

  Future<bool> login({required String email, required String password}) async {
    http.Response response = await client
        .post(
      Uri.http(url, "/login"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"email": email, "password": password}),
    )
        .catchError((error) {
      throw TimeoutException("Our Servers Are Probably Down.");
    }, test: (error) => error is TimeoutException);

    if (response.statusCode != 202) {
      Map<String, dynamic> content = json.decode(response.body);
      throw HttpException(content["Error"]);
    }
    saveUserInfo(response.body);
    return true;
  }

  Future<bool> signup({required String email, required String password}) async {
    http.Response response = await client
        .post(
      Uri.http(url, "/signup"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"email": email, "password": password}),
    )
        .catchError((error) {
      throw TimeoutException("Our Servers Are Probably Down.");
    }, test: (error) => error is TimeoutException);

    if (response.statusCode != 202) {
      Map<String, dynamic> content = json.decode(response.body);
      throw HttpException(content["Error"]);
    }
    saveUserInfo(response.body);
    return true;
  }

  saveUserInfo(String response) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    Map<String, dynamic> jSON = json.decode(response);

    preferences.setString("token", jSON["Token"]);
    preferences.setString("email", jSON["User"]["Email"]);
    preferences.setInt("id", jSON["User"]["ID"]);
  }

  logout() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.clear();
  }
}
