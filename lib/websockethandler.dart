library websockethandler;

import "dart:io";
import "dart:async";
import "dart:json" as JSON;

class WebSocketHandler {
  StreamController streamController;
  Set<WebSocket> sockets;

  WebSocketHandler() {
    sockets = new Set<WebSocket>();
    streamController = new StreamController(); 
    streamController.stream.transform(new WebSocketTransformer()).listen(handleWebSocketConnection);
  }

  void handleRequest(HttpRequest request) {
    streamController.add(request);
  }

  void handleWebSocketConnection(WebSocket socket) {
    socket.listen((data) {
          handleData(socket, data);          
        }, onDone: () {
          sockets.remove(socket);
        }, onError: (error) {
          sockets.remove(socket);
    });
    sockets.add(socket);
    sendClientIds();
  }

  void sendClientIds() {
    sockets.forEach((socket) {
      var clientIds = getClientIds(socket);
      var data = JSON.stringify({"type": "clientIds", "content": clientIds}); 
      sendMessage(socket, data);
    });
  } 

  void getClientIds(excludedSocket) {
    return sockets.where((socket) => socket != excludedSocket).map((socket) => socket.hashCode).toList();
  }

  void getSocketFromClientId(clientId) {
    return sockets.firstWhere((socket) => socket.hashCode == clientId);
  }

  void handleData(WebSocket socket, String data) {
    print("Received data: ${data}");
    var parsedData = JSON.parse(data);
    //var messageType = parsedData["type"];
    var targetClientId = parsedData["targetClientId"];
    parsedData["originClientId"] = socket.hashCode;
    //var messageContent = parsedData["content"];
    //switch(messageType) {
    //  case "offer":
    //    handleOffer(clientId, messageContent);
    //    break;
    //}
    var targetSocket = getSocketFromClientId(targetClientId);
    sendMessage(targetSocket, JSON.stringify(parsedData));
  }

  void handleOffer(clientId, messageContent) {
    var socket = getSocketFromClientId(clientId);
    var data = {"type": "offer", "clientId": clientId, "content": messageContent};
    sendMessage(socket, JSON.stringify(data));
  }

  void broadcastMessage(WebSocket excludedSocket, message) {
    print("Broadcasting message: ${message}");
    sockets.forEach((socket) {
      if(excludedSocket == socket)
        return;
      sendMessage(socket, message);   
    });
  }

  void sendMessage(socket, message) {
    // Send a message on the event loop at the next opportunity
    new Future.delayed(Duration.ZERO, () => socket.add(message));
  }
}
