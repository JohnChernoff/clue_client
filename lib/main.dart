import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_client.dart';
import 'clue_client.dart';
import 'main_page.dart';

//TODO: trim victory/defeat sounds, add async playing
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ZugUtils.getIniDefaults("cluechess.ini").then((defaults) {
    ZugUtils.getPrefs().then((prefs) {
      String domain = defaults["domain"] ?? "cluechess.com";
      int port = int.parse(defaults["port"] ?? "9898");
      String endPoint = defaults["endpoint"] ?? "cluechess";
      bool localServer = bool.parse(defaults["localServer"] ?? "true");
      log("Starting ClueChess Client, domain: $domain, port: $port, endpoint: $endPoint, localServer: $localServer");
      ClueClient client = ClueClient(domain,port,endPoint,prefs,localServer : localServer);
      runApp(ClueApp(client,"ClueChessApp"));
    });
  });
}

class ClueApp extends ZugApp {
  ClueApp(super.client, super.appName, {super.key, super.logLevel = Level.INFO, super.noNav = true});

  @override
  AppBar createAppBar(BuildContext context, ZugClient client, {Widget? txt, Color? color}) {
    return AppBar(
      backgroundColor: Colors.black,
      title: Text("Welcome to ClueChess, ${client.userName?.name ?? "Unknown User"}! ",
          style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget createMainPage(client) {
    return MainPage(client);
  }

}