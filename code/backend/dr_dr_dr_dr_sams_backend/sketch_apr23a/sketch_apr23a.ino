#include <SPI.h>
#include <WiFiNINA.h>

const char ssid[] = "B535_E42E";
const char pass[] = "bqhgLamhB9T";

WiFiServer server(80);

bool gameStarted = false;
bool waitingForAck = false;
int currentRound = 0;

// Static test rounds:
// Round 1 -> Player 1 wins
// Round 2 -> Player 2 wins
// Round 3 -> Player 2 wins
const int roundP1[] = {0, 0, 2};
const int roundP2[] = {2, 1, 0};
const int roundCount = 3;

String getQueryParam(const String& query, const String& key) {
  String needle = key + "=";
  int start = query.indexOf(needle);
  if (start < 0) return "";
  start += needle.length();
  int end = query.indexOf('&', start);
  if (end < 0) end = query.length();
  return query.substring(start, end);
}

void sendJson(WiFiClient& client, int code, const String& body) {
  client.print("HTTP/1.1 ");
  client.print(code);
  client.println(" OK");
  client.println("Connection: close");
  client.println("Access-Control-Allow-Origin: *");
  client.println("Content-Type: application/json");
  client.print("Content-Length: ");
  client.println(body.length());
  client.println();
  client.print(body);
}

String readRequestLine(WiFiClient& client) {
  unsigned long t0 = millis();
  while (!client.available() && millis() - t0 < 1000) {}
  if (!client.available()) return "";

  String reqLine = client.readStringUntil('\r');
  client.readStringUntil('\n');

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    if (line == "\r" || line.length() <= 1) break;
  }

  return reqLine;
}

void handleRoute(WiFiClient& client, const String& method, const String& path, const String& query) {
  if (path == "/api/ping") {
    sendJson(client, 200, "{\"ok\":true}");
    return;
  }

  if (path == "/api/start") {
    gameStarted = true;
    waitingForAck = false;
    currentRound = 0;
    sendJson(client, 200, "{\"ok\":true,\"message\":\"start_ok\"}");
    return;
  }

  if (path == "/api/nextRound") {
    if (!gameStarted) {
      sendJson(client, 409, "{\"ok\":false,\"error\":\"game_not_started\"}");
      return;
    }
    if (waitingForAck) {
      sendJson(client, 409, "{\"ok\":false,\"error\":\"waiting_for_runde_ok\"}");
      return;
    }
    if (currentRound >= roundCount) {
      sendJson(client, 200, "{\"ok\":true,\"message\":\"series_done\"}");
      return;
    }

    int p1 = roundP1[currentRound];
    int p2 = roundP2[currentRound];
    String body = "{\"ok\":true,\"message\":\"runde_" + String(currentRound + 1) + "_" + String(p1) + "_" + String(p2) + "\"}";
    waitingForAck = true;
    currentRound++;
    delay(2000);
    sendJson(client, 200, body);
    return;
  }

  if (path == "/api/rundeOk") {
    waitingForAck = false;
    sendJson(client, 200, "{\"ok\":true,\"message\":\"runde_ok\"}");
    return;
  }

  if (path == "/api/mix") {
    String a = getQueryParam(query, "a");
    String b = getQueryParam(query, "b");
    String c = getQueryParam(query, "c");
    String d = getQueryParam(query, "d");

    delay(10000);
    String body = "{\"ok\":true,\"message\":\"mix_ok\",\"received\":\"mix_" + a + "_" + b + "_" + c + "_" + d + "\"}";
    sendJson(client, 200, body);
    return;
  }

  sendJson(client, 404, "{\"ok\":false,\"error\":\"not_found\"}");
}

void handleHttp() {
  WiFiClient client = server.available();
  if (!client) return;

  String reqLine = readRequestLine(client);
  if (reqLine.length() == 0) {
    client.stop();
    return;
  }

  int s1 = reqLine.indexOf(' ');
  int s2 = reqLine.indexOf(' ', s1 + 1);
  if (s1 < 0 || s2 < 0) {
    sendJson(client, 400, "{\"ok\":false,\"error\":\"bad_request\"}");
    client.stop();
    return;
  }

  String method = reqLine.substring(0, s1);
  String target = reqLine.substring(s1 + 1, s2);
  String path = target;
  String query = "";
  int q = target.indexOf('?');
  if (q >= 0) {
    path = target.substring(0, q);
    query = target.substring(q + 1);
  }

  handleRoute(client, method, path, query);

  delay(1);
  client.stop();
}

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 3000) {}

  while (WiFi.begin(ssid, pass) != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting...");
  }

  server.begin();
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  handleHttp();
}