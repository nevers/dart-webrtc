import "dart:html";
import "dart:async";
import "packages/dart_webrtc/webrtcstreammanager.dart";

var cssClassFadeOutUp = "animated fadeOutUp";
var cssClassFadeOutDown = "animated fadeOutDown";
var cssClassFadeInUp = "animated fadeInUp";
var cssClassFadeInDown = "animated fadeInDown";
var cssClassAddVideo = "animated flipInY";
var cssClassRemoveVideo = "animated bounceOutDown";

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
  bool isCalledback = false;
  var title = querySelector("#title");
  var subtitle = querySelector("#subtitle");

  if(title.className == cssClassFadeOutUp || subtitle.className == cssClassFadeOutDown) {
    onAnimationEnd();
    return;
  }

  title.className = cssClassFadeOutUp;
  subtitle.className = cssClassFadeOutDown;
  window.onAnimationEnd.listen((AnimationEvent event) {
    if(!isCalledback && (event.target == title || event.target == subtitle)) {
      onAnimationEnd();
      isCalledback = true;
    }
  });
}

void addVideo(int clientId, MediaStream stream) {
  print("Adding webcam: stream='${stream}'");
  var video = new VideoElement();
  video.src = Url.createObjectUrl(stream);
  video.onLoadedData.listen((Event event) {
    video.play();
    querySelector("#videos").children.add(video);
    video.classes.add("video");
    video.classes.add(cssClassAddVideo);
  });
  receivingVideoElements[clientId] = video;
}

void removeVideo(int clientId) {
  //FIXME This should be handled in webRtcStreamManager!
  if(!receivingVideoElements.containsKey(clientId))
    return;
  VideoElement video = receivingVideoElements[clientId];
  video.className = cssClassRemoveVideo;
  window.onAnimationEnd.listen((AnimationEvent event) {
      if(event.target != video) return;
      video.pause();
      video.remove();
      receivingVideoElements.remove(clientId);
      if(receivingVideoElements.isEmpty)
        showTitle();
  });
}

void showTitle() {
  var title = querySelector("#title");
  var subtitle = querySelector("#subtitle");
  title.className = cssClassFadeInDown;
  subtitle.className = cssClassFadeInUp;
}
