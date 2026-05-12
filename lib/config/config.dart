class AppConfig {
  static const String baseUrl = "https://cadevapicdn02.freeli.io"; // API Host
  static const String graphqlUrl = "$baseUrl/workfreeli";

  static const String fileServerUrl = "http://62.151.182.241:4055";

  static const String xmppDomain = "cadevquecdn02.freeli.io"; // XMPP Host
  static const String xmppWsUrl = "wss://$xmppDomain/ws";

  static Map<String, String> getUrls() {
    return {
      "serverUrl": baseUrl,
      "xmpp_server": xmppWsUrl,
      "file_server": fileServerUrl,
    };
  }
}
