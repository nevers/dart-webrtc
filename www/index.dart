import "dart:html";
import "dart:convert";

WebSocket webSocket;
Set<RtcPeerConnection> sendingRtcPeerConnections;
Set<RtcPeerConnection> receivingRtcPeerConnections;

void main() {
  sendingRtcPeerConnections = new Set();
  receivingRtcPeerConnections = new Set();
  
  var uri = "ws://" + window.location.host + "/ws";
  log("Creating websocket to: '$uri'");
  webSocket = new WebSocket(uri);
  log("Waiting for websocket to open...");
  webSocket.onOpen.listen(handleOpen);
  webSocket.onClose.listen(handleClose);
  webSocket.onMessage.listen(handleMessage);
  webSocket.onError.listen(handleError);

  //var webcam = new DivElement();
  //webcam.classes.add("webcam");
  //webcam.text = "webcam content";

  //var webcams = query("#webcams");
  //webcams.children.add(webcam);
}

void subscribe() {
  sendMessage({"type": "subscribe", "id": webSocket});
}

RtcPeerConnection createRtcPeerConnection() {
  var rtcIceServers = {
    "iceServers": [{"url": "stun:stun.l.google.com:19302"}]
  };

  var mediaConstraints = {
    "optional": [{"RtpDataChannels": true}, {"DtlsSrtpKeyAgreement": true}]
  }; 

  return new RtcPeerConnection(rtcIceServers, mediaConstraints);
}


void sendMessage(message) {
  log("Sending message: '$message'");
  webSocket.send(message);  
}

void handleOpen(message) {
  log("Websocket opened");
}

void handleClose(closeEvent) {
  log("Websocket closed");
}

void handleMessage(message) {
  //log("Received message: ${message.data}");
  var parsedData = JSON.decode(message.data);
  var messageContent = parsedData["content"];
  var messageType = parsedData["type"];
  switch(messageType) {
    case "clientIds":
      handleCliendIds(messageContent);
      break;
    case "offer":
      var clientId = parsedData["clientId"];
      handleOffer(clientId, messageContent);
      break;
    case "answer":
      var clientId = parsedData["clientId"];
      handleAnswer(clientId, messageContent);
      break;
  }
}

void handleCliendIds(List clientIds) {
  clientIds.forEach((id) {
    var sendingRtcPeerConnection = createRtcPeerConnection();
    sendingRtcPeerConnections.add(sendingRtcPeerConnection);
    sendOffer(id, sendingRtcPeerConnection); 
  });
}

void handleOffer(clientId, offer) {
  var receivingRtcPeerConnection = createRtcPeerConnection();
  receivingRtcPeerConnections.add(receivingRtcPeerConnection);
  receivingRtcPeerConnection.setRemoteDescription(new RtcSessionDescription(offer));
  receivingRtcPeerConnection.createAnswer({}).then((RtcSessionDescription description) {
    receivingRtcPeerConnection.setLocalDescription(description);
    var data = {"type": "answer", "targetClientId": clientId, "content": {"sdp": description.sdp, "type": description.type}};
    sendMessage(JSON.encode(data));
  });
  log("Received offer: ${offer}");
}

void handleAnswer(clientId, answer) {
  log("Got answer from ${clientId}");
}

void sendOffer(clientId, sendingRtcPeerConnection) {
  sendingRtcPeerConnection.createOffer({}).then((RtcSessionDescription description) {
    sendingRtcPeerConnection.setLocalDescription(description); 
    var data = {"type": "offer", "targetClientId": clientId, "content":  {"sdp": description.sdp, "type": description.type}};
    sendMessage(JSON.encode(data));
  }); 
}

void handleError(errorMessage) {
  log("Error: $errorMessage");
}

void log(message) {
  print(message);
}
