import "dart:html";
import "dart:json" as JSON;

WebSocket webSocket;
var  sendingRtcPeerConnections;
var  receivingRtcPeerConnections;

void main() {
  sendingRtcPeerConnections = new Map();
  receivingRtcPeerConnections = new Map();
  
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
  webSocket.send(JSON.stringify(message));  
}

void handleOpen(message) {
  log("Websocket opened");
}

void handleClose(closeEvent) {
  log("Websocket closed");
}

void handleMessage(message) {
  log("Received message: ${message.data}");
  var parsedData = JSON.parse(message.data);
  var messageContent = parsedData["content"];
  var messageType = parsedData["type"];
  var originClientId = parsedData["originClientId"];
  switch(messageType) {
    case "clientIds":
      handleCliendIds(messageContent);
      break;
    case "offer":
      handleOffer(originClientId, messageContent);
      break;
    case "answer":
      handleAnswer(originClientId, messageContent);
      break;
    case "receiverCandidate":
      handleReceiverCandidate(originClientId, messageContent); 
      break;
    case "senderCandidate":
      handleSenderCandidate(originClientId, messageContent);
      break;
  }
}

void handleCliendIds(List clientIds) {
  clientIds.forEach((id) {
    var sendingRtcPeerConnection = createRtcPeerConnection();
    sendingRtcPeerConnections[id] = sendingRtcPeerConnection;
    sendOffer(id, sendingRtcPeerConnection); 
  });
}

void sendOffer(originClientId, sendingRtcPeerConnection) {
  sendingRtcPeerConnection.createOffer({}).then((RtcSessionDescription description) {
    sendingRtcPeerConnection.setLocalDescription(description); 
    sendMessage({"type": "offer", "targetClientId": originClientId, "content":  {"sdp": description.sdp, "type": description.type}});
    sendingRtcPeerConnection.onIceCandidate.listen((RtcIceCandidateEvent event) {
      if(event.candidate != null)
        sendMessage({"type": "senderCandidate", "targetClientId": originClientId, "content": {"sdpMLineIndex": event.candidate.sdpMLineIndex, "candidate": event.candidate.candidate}});
    });
  }); 
}

void handleOffer(originClientId, offer) {
  var receivingRtcPeerConnection = createRtcPeerConnection();
  receivingRtcPeerConnections[originClientId] = receivingRtcPeerConnection;
  receivingRtcPeerConnection.setRemoteDescription(new RtcSessionDescription(offer));
  receivingRtcPeerConnection.createAnswer({}).then((RtcSessionDescription description) {
    receivingRtcPeerConnection.setLocalDescription(description);
    sendMessage({"type": "answer", "targetClientId": originClientId, "content": {"sdp": description.sdp, "type": description.type}});
  });
  receivingRtcPeerConnection.onIceCandidate.listen((RtcIceCandidateEvent event) {
    if(event.candidate != null)
      sendMessage({"type": "receiverCandidate", "targetClientId": originClientId, "content": {"sdpMLineIndex": event.candidate.sdpMLineIndex, "candidate": event.candidate.candidate}});
  });
}

void handleAnswer(originClientId, answer) {
  log("Got answer from ${originClientId}");
  var sendingRtcPeerConnection = sendingRtcPeerConnections[originClientId];
  sendingRtcPeerConnection.setRemoteDescription(new RtcSessionDescription(answer));
}

void handleReceiverCandidate(originClientId, candidate) {
  //var candidate = new RtcIceCandidate({"sdpMLineIndex": candidate.sdpMLineIndex, "candidate": candidate.candidate});
  log("handleReceiverCandidate: ${originClientId}");
}

void handleSenderCandidate(originClientId, candidate) {
  log("handleSenderCandidate: ${originClientId}");
}

void handleError(errorMessage) {
  log("Error: $errorMessage");
}

void log(message) {
  print(message);
}
