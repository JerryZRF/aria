import "package:aria/utils.dart";
import "package:encrypt/encrypt.dart" as encrypt;
import 'package:http/http.dart' as http;
import "dart:convert";

import "package:http/http.dart";

String changeLength(String text) {
  var pad = 16 - text.length % 16;
  String c = String.fromCharCode(pad);
  for (int i = 0; i < pad; i++) {
    text += c;
  }
  return text;
}

String aes(String text, String key) {
  final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromUtf8(key), mode: encrypt.AESMode.cbc));
  var encrypted = encrypter.encrypt(changeLength(text),
      iv: encrypt.IV.fromUtf8("0102030405060708"));
  return encrypted.base64;
}

String b(String data, String str) {
  var first = aes(data, "0CoJUm6Qyw8W8jud");
  return aes(first, str);
}

String c(String text) {
  var e = "010001";
  var f =
      "00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7";
  BigInt tt = BigInt.parse("65387592075003861606687669663359381809", radix: 10);
  tt = tt.modPow(BigInt.parse(e, radix: 16), BigInt.parse(f, radix: 16));
  return tt.toRadixString(16).padLeft(131, "0");
}

Map _getFinalParam(String text, String str) {
  var params = b(text, str);
  var encSecKey = c(str);
  return {"params": params, "encSecKey": encSecKey};
}

Future<Response> _getMusicList(String params, String encSecKey) async {
  var url = "https://music.163.com/weapi/cloudsearch/get/web?csrf_token=";
  var headers = {
    'authority': 'music.163.com',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36',
    'content-type': 'application/x-www-form-urlencoded',
    'accept': '*/*',
    'origin': 'https://music.163.com',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-mode': 'cors',
    'sec-fetch-dest': 'empty',
    'referer': 'https://music.163.com/search/',
    'accept-language': 'zh-CN,zh;q=0.9',
  };
  return http.post(Uri.parse(url),
      headers: headers, body: {"params": params, "encSecKey": encSecKey});
}

Future<Response> _getSongInfo(String params, String encSecKey) {
  var url =
      "https://music.163.com/weapi/song/enhance/player/url/v1?csrf_token=";
  var headers = {
    'authority': 'music.163.com',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36',
    'content-type': 'application/x-www-form-urlencoded',
    'accept': '*/*',
    'origin': 'https://music.163.com',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-mode': 'cors',
    'sec-fetch-dest': 'empty',
    'referer': 'https://music.163.com/',
    'accept-language': 'zh-CN,zh;q=0.9',
  };
  return http.post(Uri.parse(url),
      headers: headers, body: {"params": params, "encSecKey": encSecKey});
}

Future<Response> getSongLyric(int id) {
  var url = "https://music.163.com/api/song/media?id=$id";
  var headers = {
    'authority': 'music.163.com',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36',
    'content-type': 'application/x-www-form-urlencoded',
    'accept': '*/*',
    'origin': 'https://music.163.com',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-mode': 'cors',
    'sec-fetch-dest': 'empty',
    'referer': 'https://music.163.com/',
    'accept-language': 'zh-CN,zh;q=0.9',
  };
  return http.get(Uri.parse(url), headers: headers);
}

//TODO 包装SongInfo
Future<Response> getSongInfo(int id) async {
  var d = {
    "ids": "[$id]",
    "level": "exhigh",
    "encodeType": "",
    "csrf_token": ""
  };
  var dd = format(json.encoder.convert(d));
  var param = _getFinalParam(dd, _randStr);
  return _getSongInfo(param['params'], param['encSecKey']);
}

String _randStr = "1111111111111111";

Future<Response> searchSongs(String name) {
  var d = {
    "hlpretag": "<span class=\"s-fc7\">",
    "hlposttag": "</span>",
    "s": name,
    "type": "1",
    "offset": "0",
    "total": "true",
    "limit": "30",
    "csrf_token": ""
  };
  // print(json.encoder.convert(d));
  var dd = json.encoder.convert(d);
  dd = format(dd);
  var param = _getFinalParam(dd, _randStr);
  // print(param["params"]);
  // print(param["encSecKey"]);
  return _getMusicList(param["params"], param["encSecKey"]);
}
