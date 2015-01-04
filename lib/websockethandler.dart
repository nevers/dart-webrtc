library websockethandler;

import "dart:io";
import "dart:async";
import "dart:convert";

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
          sendClientRemove(socket);
        }, onError: (error) {
          sendClientRemove(socket);
    });
    sockets.add(socket);
    sendClientIds(socket);
    sendClientAdd(socket);
  }

  void sendClientIds(WebSocket socket) {
    var clientIds = getClientIdsExcl(socket);
    var data = JSON.encode({"type": "clientIds", "content": clientIds}); 
    sendMessage(socket, data);
  }
  
  void sendClientAdd(WebSocket socket) {
    var data = JSON.encode({"type": "clientAdd", "content": getClientId(socket)});
    broadcastMessageExcl(socket, data);
  }
  
  void sendClientRemove(WebSocket socket) {
    var data = JSON.encode({"type": "clientRemove", "content": getClientId(socket)});
    broadcastMessage(data); 
    sockets.remove(socket);
  }

  void handleData(WebSocket socket, String data) {
    var parsedData = JSON.decode(data);
    var targetClientId = parsedData["targetClientId"];
    if(!isClientAvailable(targetClientId)) return;
    parsedData["originClientId"] = getClientId(socket);
    var targetSocket = getSocketFromClientId(targetClientId);
    sendMessage(targetSocket, JSON.encode(parsedData));
  }

  bool isClientAvailable(clientId) {
    try {
      sockets.firstWhere((socket) => getClientId(socket) == clientId);
      return true;
    } catch (e) {
      return false;
    }
  }
  WebSocket getSocketFromClientId(clientId) {
    return sockets.firstWhere((socket) => getClientId(socket) == clientId);
  }

  int getClientId(socket) {
    return socket.hashCode;
  }
  
  List getClientIdsExcl(excludedSocket) {
    return sockets.where((socket) => socket != excludedSocket).map((socket) => getClientId(socket)).toList();
  }
  
  void broadcastMessage(message) {
    broadcastMessageExcl(null, message);
  }
  
  void broadcastMessageExcl(WebSocket excludedSocket, message) {
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
