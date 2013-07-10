import "dart:html";

WebSocket webSocket;
void main() {
  var uri = "ws://" + window.location.host + "/ws";
  log("Creating websocket to: '$uri'");
  webSocket = new WebSocket(uri);
  log("Waiting for socket to open...");
  webSocket.onOpen.listen((Event event) => sendMessage("Je moeder!"));
  webSocket.onMessage.listen(handleMessage);
  log(window.location.host);
}

void sendMessage(message) {
  log("Sending message: '$message'");
  webSocket.send(message);  
}

void handleMessage(MessageEvent message) {
  log("Received message: ${message.data}");
}

void log(message) {
  var paragraph = new ParagraphElement();
  paragraph.text = message;

  var log = query("#log");
  log.children.add(paragraph);
}
