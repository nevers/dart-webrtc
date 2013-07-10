import "dart:io";

class FileHandler {
  static final String DOCUMENT_ROOT = "www";

  void handleRequest(HttpRequest request) {
    String path = (request.uri.path.endsWith('/')) ? "${request.uri.path}index.html" : request.uri.path;
    path = DOCUMENT_ROOT + path;
    HttpResponse response = request.response;

    File file = new File(path);
    file.exists().then((bool exists) {
      if (exists) {
        var stream  = file.openRead();
        stream.pipe(response).catchError((e) => print(e));
      } else {
        response.statusCode = HttpStatus.NOT_FOUND;
        response.close();
      }
    });
  }
}
