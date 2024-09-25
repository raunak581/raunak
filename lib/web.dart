// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'dart:io'; // Import for Platform checking

// class WebViewExample extends StatefulWidget {
//   final String url;

//   WebViewExample({required this.url});

//   @override
//   _WebViewExampleState createState() => _WebViewExampleState();
// }

// class _WebViewExampleState extends State<WebViewExample> {
//   late WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();
//     // Android specific initialization
//     if (Platform.isAndroid) {
//       WebView.platform = SurfaceAndroidWebView();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('WebView'),
//       ),
//       body: WebView(
//         initialUrl: widget.url,
//         javascriptMode: JavascriptMode.unrestricted,
//         onWebViewCreated: (WebViewController webViewController) {
//           _controller = webViewController;
//         },
//       ),
//     );
//   }
// }
