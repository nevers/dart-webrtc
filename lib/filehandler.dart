library filehandler;

import "dart:io";

//TODO Add headers depending on the file extension
class FileHandler {
  static final String DOCUMENT_ROOT = "../web";

  void handleRequest(HttpRequest request) {
    String path = (request.uri.path.endsWith('/')) ? "${request.uri.path}index.html" : request.uri.path;
    path = DOCUMENT_ROOT + path;
    HttpResponse response = request.response;
    response.headers.contentType = getContentType(path);

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
  
  ContentType getContentType(String path) {
    if(hasValidExtension(path))
      return getContentTypeFromExtension(getExtension(path));
    else
      return ContentType.parse("text/plain");
  }
  
  ContentType getContentTypeFromExtension(String extension) {
    switch(extension) {
      case ".html":
        return ContentType.parse("text/html; charset=UTF-8");
      case ".css":
        return ContentType.parse("text/css; charset=UTF-8");
      case ".js":
        return ContentType.parse("application/javascript; charset=UTF-8");
      case ".ico":
        return ContentType.parse("image/ico");
      default:
        return ContentType.parse("text/plain");
    }
  }
 
  bool hasValidExtension(String path) {
    return path.indexOf('.') != -1 && path.length > 1;
  }
  
  String getExtension(String path) {
    String trimmedPath = path.trim().toLowerCase();
    int start = trimmedPath.lastIndexOf('.');
    int stop = trimmedPath.length;
    return trimmedPath.substring(start, stop);
  }
}
