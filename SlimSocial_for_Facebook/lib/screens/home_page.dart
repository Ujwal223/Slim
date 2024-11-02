import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slimsocial_for_facebook/consts.dart';
import 'package:slimsocial_for_facebook/controllers/fb_controller.dart';
import 'package:slimsocial_for_facebook/main.dart';
import 'package:slimsocial_for_facebook/screens/messenger_page.dart';
import 'package:slimsocial_for_facebook/screens/settings_page.dart';
import 'package:slimsocial_for_facebook/style/color_schemes.g.dart';
import 'package:slimsocial_for_facebook/utils/css.dart';
import 'package:slimsocial_for_facebook/utils/js.dart';
import 'package:slimsocial_for_facebook/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late WebViewController _controller;
  bool isLoading = false;
  bool isScontentUrl = false;

  @override
  void initState() {
    super.initState();

    _controller = _initWebViewController();
  }

  WebViewController _initWebViewController() {
    final homepage = PrefController.getHomePage();
    final controller = (WebViewController())
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(FacebookColors.darkBlue)
      ..setUserAgent(PrefController.getUserAgent())
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: onNavigationRequest,
          onPageStarted: (String url) async {
            setState(() {
              isScontentUrl = Uri.parse(url).host.contains("scontent");
            });

            //inject the css as soon as the DOM is loaded
            await injectCss();
          },
          onPageFinished: (String url) async {
            await runJs();
            if (kDebugMode) print(url);
          },
          onProgress: (int progress) {
            setState(() {
              isLoading = progress < 100;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(homepage));

    if (Platform.isAndroid) {
      (controller.platform as AndroidWebViewController)
        ..setCustomWidgetCallbacks(
          onShowCustomWidget:
              (Widget widget, OnHideCustomWidgetCallback callback) {
            // Handle the full screen videos
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => widget,
                fullscreenDialog: true,
              ),
            );
          },
          onHideCustomWidget: () {
            // Handle the full screen videos
            Navigator.of(context).pop();
          },
        )
        ..setOnShowFileSelector(
          (FileSelectorParams params) async {
            final photosPermission = sp.getBool("photos_permission") ?? false;

            if (photosPermission) {
              final result = await FilePicker.platform.pickFiles();

              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                return [file.uri.toString()];
              }
            } else {
              // Handle the case when the permission is not granted
              showToast("check_permission".tr());
            }
            return [];
          },
        )
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            final gpsPermission = sp.getBool("gps_permission") ?? false;

            if (gpsPermission) {
              // request location permission
              final locationPermissionStatus =
                  await Permission.locationWhenInUse.request();

              // return the response
              return GeolocationPermissionsResponse(
                allow: locationPermissionStatus == PermissionStatus.granted,
                retain: false,
              );
            } else {
              // return the response denying the permission
              return const GeolocationPermissionsResponse(
                allow: false,
                retain: false,
              );
            }
          },
          onHidePrompt: () => print("Geolocation permission prompt hidden"),
        );
    }
    return controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<NavigationDecision> onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.parse(request.url);
    print("onNavigationRequest: ${request.url}");

    for (final other in kPermittedHostnamesFb)
      if (uri.host.endsWith(other)) {
        return NavigationDecision.navigate;
      }

    for (final other in kPermittedHostnamesMessenger) {
      if (uri.host.endsWith(other)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessengerPage(initialUrl: uri.toString()),
          ),
        );
        return NavigationDecision.prevent;
      }
    }

    // open on webview
    print("Launching external url: ${request.url}");
    launchInAppUrl(context, request.url);
    return NavigationDecision.prevent;
  }

  @override
  Widget build(BuildContext context) {
    //refresh the page whenever a new state (url) comes
    ref.listen<Uri>(
      fbWebViewProvider,
      (previous, next) async {
        final currentUrl = await _controller.currentUrl();
        final colorScheme = Theme.of(context).colorScheme;
        if (currentUrl != null) {
          final currentUri = Uri.parse(currentUrl);
          if (currentUri.toString() == next.toString()) {
            print("refreshing keeping the y index...");
            //if I'm refreshing the page, I need to save the current scroll position
            final position = await _controller.getScrollPosition();
            final x = position.dx;
            final y = position.dy;

            //refresh
            await _controller.reload();

            //go back to the previous location
            if (y > 0 || x > 0) {
              await Future.delayed(const Duration(milliseconds: 1500));
              print("restoring  $x, $y");
              await _controller.scrollTo(x.toInt(), y.toInt());
            }
            return;
          }
        }

        await _controller.loadRequest(next);
      },
    );
 @override
  Widget build(BuildContext context) {
    // Get color scheme based on current theme
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      // Modern gradient app bar with frosted glass effect
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDarkMode
                    ? colorScheme.primaryContainer.withOpacity(0.8)
                    : colorScheme.primary.withOpacity(0.9),
                isDarkMode
                    ? colorScheme.primary.withOpacity(0.7)
                    : colorScheme.primaryContainer.withOpacity(0.8),
              ],
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            ref
                .read(fbWebViewProvider.notifier)
                .updateUrl(PrefController.getHomePage());
          },
          icon: Icon(
            Icons.home_rounded,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        title: GestureDetector(
          onTap: () => _controller.scrollTo(0, 0),
          child: Text(
            'SlimSocial',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          ),
        ),
        actions: [
          if (isScontentUrl) ...[
            IconButton(
              onPressed: () async {
                final url = await _controller.currentUrl();
                if (url != null) {
                  showModernToast(context, "downloading".tr());
                  final path = await downloadImage(url);
                  if (path != null) OpenFile.open(path);
                }
              },
              icon: Icon(
                Icons.save_rounded,
                color: colorScheme.onPrimary,
              ),
            ),
            IconButton(
              onPressed: () async {
                final url = await _controller.currentUrl();
                if (url != null) {
                  final path = await downloadImage(url);
                  if (path != null) Share.shareXFiles([XFile(path)]);
                }
              },
              icon: Icon(
                Icons.share_rounded,
                color: colorScheme.onPrimary,
              ),
            ),
          ],
          if (sp.getBool("enable_messenger") ?? true)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MessengerPage(),
                    ),
                  );
                },
                icon: Image.asset('assets/icons/ic_messenger.png',
                    height: 22, color: colorScheme.onPrimary),
              ),
            ),
          _buildModernPopupMenu(colorScheme),
        ],
      ),
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDarkMode
                      ? colorScheme.background
                      : colorScheme.background.withOpacity(0.95),
                  isDarkMode
                      ? colorScheme.surface
                      : colorScheme.surface.withOpacity(0.98),
                ],
              ),
            ),
            child: WebViewWidget(controller: _controller),
          ),
          if (isLoading)
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              backgroundColor: Colors.transparent,
            ),
        ],
      ),
    );
  }

  Widget _buildModernPopupMenu(ColorScheme colorScheme) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          color: colorScheme.onPrimary,
        ),
        onSelected: (item) async {
          switch (item) {
            case "share_url":
              final url = await _controller.currentUrl();
              if (url != null) Share.share(url);
              break;
            case "refresh":
              _controller.reload();
              break;
            case "settings":
              Navigator.of(context).pushNamed("/settings");
              break;
            case "top":
              _controller.scrollTo(0, 0);
              break;
            case "support":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(productId: "donation_1"),
                ),
              );
              break;
            case "reset":
              await _controller.clearCache();
              await _controller.clearLocalStorage();
              _controller = _initWebViewController();
              break;
          }
        },
        itemBuilder: (context) => [
          _buildPopupMenuItem("top", Icons.vertical_align_top_rounded, "top"),
          _buildPopupMenuItem("refresh", Icons.refresh_rounded, "refresh"),
          _buildPopupMenuItem("share_url", Icons.share_rounded, "share_url"),
          _buildPopupMenuItem("settings", Icons.settings_rounded, "settings"),
          _buildPopupMenuItem("support", Icons.favorite_rounded, "support",
              iconColor: Colors.red),
          _buildPopupMenuItem("reset", Icons.restore_rounded, "reset"),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String textKey,
      {Color? iconColor}) {
    return PopupMenuItem<String>(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: iconColor),
        title: Text(
          textKey.tr().capitalize(),
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void showModernToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
    );
  }
} 

  Future<void> injectCss() async {
    var cssList = "";
    for (final css in CustomCss.cssList) {
      if (css.isEnabled()) cssList += css.code;
    }

    //create the function that will be called later
    await _controller.runJavaScript(CustomJs.removeAdsFunc);

    //it's important to remove the \n
    final code = """
                    document.addEventListener("DOMContentLoaded", function() {
                        ${CustomJs.injectCssFunc(CustomCss.removeMessengerDownloadCss.code)}
                        ${CustomJs.injectCssFunc(CustomCss.removeBrowserNotSupportedCss.code)}
                        ${CustomJs.injectCssFunc(cssList)}
                         ${(sp.getBool('hide_ads') ?? true) ? "removeAds();" : ""}
                    });"""
        .replaceAll("\n", " ");
    await _controller.runJavaScript(code);
  }

  Future<void> runJs() async {
    if (sp.getBool('hide_ads') ?? true) {
      //setup the observer to run on page updates
      await _controller.runJavaScript(CustomJs.removeAdsObserver);
    }

    final userCustomJs = PrefController.getUserCustomJs();
    if (userCustomJs?.isNotEmpty ?? false) {
      await _controller.runJavaScript(userCustomJs!);
    }
  }

/*  JavascriptChannel _setupJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'Toaster',
      onMessageReceived: (JavascriptMessage message) {
        // ignore: deprecated_member_use
        print('Message received: ${message.message}');
      },
    );
  }*/
}
