dart-webrtc
===========
A clean and simple proof of concept for webrtc in dart.

How to get started:

0. Install dart from https://www.dartlang.org/ and make sure the dart binaries are available in $PATH.
1. Checkout the project and go to the newly created folder.
2. Compile the client dart code using pub:
> ```
> $ pub build
> Your pubspec has changed, so we need to update your lockfile:
> Resolving dependencies...
> + browser 0.10.0+2
> + logging 0.9.2
> Changed 2 dependencies!
> Loading source assets...
> Building dart_webrtc...
> [Info from Dart2JS]:
> Compiling dart_webrtc|web/index.dart...
> [Info from Dart2JS]:
> Took 0:00:08.410037 to compile dart_webrtc|web/index.dart.
> Built 9 files to "build".
> ```

3. Start the server:
> ```
> $ cd bin
> bin$ dart server.dart
> Starting server
> Listening for connections at 0.0.0.0:1337
> ```

4. Browse to http://localhost:1337 and you should see the following page:
> ![Screenshot](screenshot.png)
