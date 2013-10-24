library webrtcstreammanager;

import "dart:html";
import "dart:convert";
import "../lib/cachingusermediaretriever.dart";

class WebRtcStreamManager {
  WebSocket webSocket;
  var sendingRtcPeerConnections;
  var receivingRtcPeerConnections;
  var cachingUserMediaRetriever;
  var streamAddHandler;
  var streamRemoveHandler;
  
  WebRtcStreamManager() {
    sendingRtcPeerConnections = new Map();
    receivingRtcPeerConnections = new Map();
    
    cachingUserMediaRetriever = new CachingUserMediaRetriever();
    
    var uri = "ws://" + window.location.host + "/ws";
    log("Creating websocket to: '$uri'");
    webSocket = new WebSocket(uri);
    log("Waiting for websocket to open...");
    webSocket.onOpen.listen(handleOpen);
    webSocket.onClose.listen(handleClose);
    webSocket.onMessage.listen(handleMessage);
    webSocket.onError.listen(handleError); 
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
    log("Sending message: targetClientId='${message["targetClientId"]}' type='${message["type"]}'");
    webSocket.send(JSON.encode(message));  
  }

  void handleOpen(message) {
    log("Websocket opened");
  }

  void handleClose(closeEvent) {
    log("Websocket closed");
  }

  void handleMessage(message) {
    var parsedData = JSON.decode(message.data);
    var messageType = parsedData["type"];
    var originClientId = parsedData["originClientId"];
    var messageContent = parsedData["content"];
    
    log("Received message: originClientId='${originClientId}' messageType='${messageType}'");
    
    switch(messageType) {
      case "clientIds":
        handleCliendIds(messageContent);
        break;
      case "clientAdd":
        createSendingRtcPeerConnection(messageContent);
        break;
      case "clientRemove":
        handleClientRemove(messageContent);
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
    log("handleClientIds: clientIds='${clientIds}'");
    clientIds.forEach((id) {
      createSendingRtcPeerConnection(id);
    });
  }

  void createSendingRtcPeerConnection(id) {
    RtcPeerConnection sendingRtcPeerConnection = createRtcPeerConnection();; 
    sendingRtcPeerConnections[id] = sendingRtcPeerConnection;
    cachingUserMediaRetriever.get().then((MediaStream stream) {
      sendingRtcPeerConnection.addStream(stream);
      sendOffer(id, sendingRtcPeerConnection);    
    });
  }

  void handleClientRemove(id) {
    RtcPeerConnection receivingRtcPeerConnection = receivingRtcPeerConnections[id];
    receivingRtcPeerConnections.remove(id);
    notifyRemoveStream(id);
    
    RtcPeerConnection sendingRtcPeerConnection = sendingRtcPeerConnections[id];
    sendingRtcPeerConnections.remove(id);
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
    receivingRtcPeerConnection.onAddStream.listen((MediaStreamEvent event) {
      notifyAddStream(originClientId, event.stream);
    });
    receivingRtcPeerConnection.onIceConnectionStateChange.listen((Event event){
      if(receivingRtcPeerConnection.iceConnectionState == "disconnected" && receivingRtcPeerConnections.containsKey(originClientId)) 
        handleClientRemove(originClientId); 
    });
  }

  void notifyAddStream(originClientId, MediaStream stream) {
    if(streamAddHandler != null)
      streamAddHandler(originClientId, stream);
  }

  void notifyRemoveStream(originClientId) {
    if(streamRemoveHandler != null)
      streamRemoveHandler(originClientId);
  }

  void handleAnswer(originClientId, answer) {
    log("Got answer from ${originClientId}");
    var sendingRtcPeerConnection = sendingRtcPeerConnections[originClientId];
    sendingRtcPeerConnection.setRemoteDescription(new RtcSessionDescription(answer));
  }

  void handleReceiverCandidate(originClientId, candidate) {
    var rtcIceCandidate = new RtcIceCandidate({"sdpMLineIndex": candidate["sdpMLineIndex"], "candidate": candidate["candidate"]});
    log("handleReceiverCandidate: originClientId=${originClientId}");
    var sendingRtcPeerConnection = sendingRtcPeerConnections[originClientId];
    sendingRtcPeerConnection.addIceCandidate(rtcIceCandidate);
  }

  void handleSenderCandidate(originClientId, candidate) {
    var rtcIceCandidate = new RtcIceCandidate({"sdpMLineIndex": candidate["sdpMLineIndex"], "candidate": candidate["candidate"]});
    log("handleSenderCandidate: originClientId='${originClientId}'");
    var receivingRtcPeerConnection = receivingRtcPeerConnections[originClientId];
    receivingRtcPeerConnection.addIceCandidate(rtcIceCandidate);
  }
  
  void setStreamAddHandler(var handler) {
    streamAddHandler = handler;
  }
  
  void setStreamRemoveHandler(var handler) {
    streamRemoveHandler = handler;
  }
  
  void handleError(errorMessage) {
    log("Error: $errorMessage");
  }

  void log(message) {
    print(message);
  }
}