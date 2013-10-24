import "dart:html";
import "../lib/webrtcstreammanager.dart";

var receivingVideoElements = new Map();

void main() {
  
  WebRtcStreamManager webRtcStreamManager = new WebRtcStreamManager();
  webRtcStreamManager.setStreamAddHandler((originClientId, MediaStream stream) {
    print("Adding webcam: stream='${stream}'");
    var video = new VideoElement();
    video.classes.add("video");
    video.src = Url.createObjectUrl(stream);
    video.onLoadedData.listen((Event event) {
      video.play();
    });
    querySelector("#videos").children.add(video);
    receivingVideoElements[originClientId] = video;
  });
  
  webRtcStreamManager.setStreamRemoveHandler((originClientId) {
    if(!receivingVideoElements.containsKey(originClientId))
      return;
    VideoElement video = receivingVideoElements[originClientId];
    video.pause();
    video.remove();
  });
}