import "dart:io";
import "dart:async";

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
    socket.listen((MessageEvent event) {
          broadcastMessage(socket, event);          
        }, onDone: () {
          sockets.remove(socket);
        }, onError: (error) {
          sockets.remove(socket);
        });
    sockets.add(socket);
  }

  void broadcastMessage(WebSocket currentSocket, message) {
    print("Got message: ${message}");
    sockets.forEach((socket) {
      if(currentSocket == socket)
        return;
      // Send a message on the event loop at the next opportunity
      new Future.delayed(Duration.ZERO, () => socket.add(message));
    });
  }
}
