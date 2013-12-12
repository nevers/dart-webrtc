import "dart:html";
import "dart:async";
import "../lib/webrtcstreammanager.dart";

var receivingVideoElements = new Map();

void main() {
  WebRtcStreamManager webRtcStreamManager = new WebRtcStreamManager();
  webRtcStreamManager.setStreamAddHandler((clientId, MediaStream stream) {
    hideTitle(() {
      addVideo(clientId, stream);
    });
  });
  
  webRtcStreamManager.setStreamRemoveHandler((clientId) {
    removeVideo(clientId);
  });
}

void hideTitle(Function onAnimationEnd) {
  var cssClassFadeOutDown = "animated fadeOutDown";
  var cssClassFadeOutUp = "animated fadeOutUp";
  bool isCalledback = false;
  var title = querySelector("#title");
  var subtitle = querySelector("#subtitle");

  if(title.className == cssClassFadeOutUp || subtitle.className == cssClassFadeOutDown)
    onAnimationEnd();

  title.className = cssClassFadeOutUp;
  subtitle.className = cssClassFadeOutDown;
  window.onAnimationEnd.listen((AnimationEvent event) {
    if(!isCalledback && (event.target == title || event.target == subtitle)) {
      onAnimationEnd();
      isCalledback = true;
    }
  });
}

void addVideo(String clientId, MediaStream stream) {
  print("Adding webcam: stream='${stream}'");
  var video = new VideoElement();
  video.classes.add("video");
  video.classes.add("animated flipInY");
  video.src = Url.createObjectUrl(stream);
  video.onLoadedData.listen((Event event) {
    video.play();
  });
  querySelector("#videos").children.add(video);
  receivingVideoElements[clientId] = video;
}

void removeVideo(String clientId) {
  if(!receivingVideoElements.containsKey(clientId))
    return;
  VideoElement video = receivingVideoElements[clientId];
  video.pause();
  video.remove();
}
