import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restart_app/restart_app.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slimsocial_for_facebook/consts.dart';
import 'package:slimsocial_for_facebook/controllers/fb_controller.dart';
import 'package:slimsocial_for_facebook/main.dart';
import 'package:slimsocial_for_facebook/utils/css.dart';
import 'package:slimsocial_for_facebook/utils/js.dart';
import 'package:slimsocial_for_facebook/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerStatefulWidget {
  SettingsPage({this.productId, super.key});
  //this is used to make a shortcut for donations
  String? productId;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  StreamSubscription<List<PurchaseDetails>>? _paymentSubscription;
  bool isDev = false;

  final Map<String, Permission> permissions = const {
    "gps_permission": Permission.locationWhenInUse,
    "camera_permission": Permission.camera,
    "photos_permission": Permission.photos,
  };

  @override
  void initState() {
    _updatePermissionsToggle();

    if (!widget.productId.isNullOrEmpty()) {
      Future.delayed(const Duration(milliseconds: 1), () {
        buildPaymentWidget(widget.productId!);
      });
    }

    _checkDev();

    super.initState();
  }

  _checkDev() async {
    final _isDev = await FlutterJailbreakDetection.developerMode;
    setState(() {
      isDev = _isDev;
    });
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings'.tr().capitalize(),
          style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.9),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            'SlimSocial'.tr(),
            [
              _buildPrivacyTile(),
            ],
          ),
          _buildSection(
            'Facebook'.tr(),
            [
              _buildMessengerTile(),
              _buildHideAdsTile(),
              _buildRecentFirstTile(),
              _buildMBasicTile(),
            ],
          ),
        ].animate(interval: 50.ms).fadeIn(duration: 200.ms).slideX(),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildPrivacyTile() {
    return ListTile(
      leading: Icon(
        Icons.privacy_tip,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'privacy'.tr().capitalize(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text("disclaimer_privacy".tr()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).animate()
      .fadeIn(delay: 100.ms)
      .slideX(begin: 0.2, curve: Curves.easeOutQuad);
  }

  Widget _buildMessengerTile() {
    return SwitchListTile(
      secondary: Icon(
        Icons.messenger,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'enable_messenger'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      value: sp.getBool("enable_messenger") ?? true,
      onChanged: (value) {
        setState(() {
          sp.setBool("enable_messenger", value);
        });
      },
    );
  }

  Widget _buildHideAdsTile() {
    return SwitchListTile(
      secondary: Icon(
        Icons.hide_source,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'hide_ads'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      value: sp.getBool("hide_ads") ?? true,
      onChanged: (value) {
        setState(() {
          sp.setBool("hide_ads", value);
        });
        ref.refresh(fbWebViewProvider);
      },
    );
  }

  Widget _buildRecentFirstTile() {
    return SwitchListTile(
      secondary: Icon(
        Icons.rss_feed,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'recent_first'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      value: sp.getBool("recent_first") ?? false,
      onChanged: (value) {
        setState(() {
          sp.setBool("recent_first", value);
        });
        ref.read(fbWebViewProvider.notifier).updateUrl(PrefController.getHomePage());
      },
    );
  }

  Widget _buildMBasicTile() {
    return SwitchListTile(
      secondary: Icon(
        Icons.abc,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        'use_mbasic'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('use_mbasic_desc'.tr()),
      value: sp.getBool("use_mbasic") ?? false,
      onChanged: (value) {
        setState(() {
          sp.setBool("use_mbasic", value);
        });
        ref.read(fbWebViewProvider.notifier).updateUrl(PrefController.getHomePage());
        Restart.restartApp();
      },
    );
  }
}

  Future<bool> handlePermission(bool isTurningOn, Permission permission) async {
    final status = await permission.status;
    if (isTurningOn) {
      //going from off to on
      switch (status) {
        case PermissionStatus.restricted:
        case PermissionStatus.limited:
        case PermissionStatus.denied:
          await permission.request();
          break;
        case PermissionStatus.granted:
          break;
        case PermissionStatus.permanentlyDenied:
          await openAppSettings();
          break;
      }
    } else {
      //going from on to off
      switch (status) {
        case PermissionStatus.permanentlyDenied:
        case PermissionStatus.restricted:
        case PermissionStatus.limited:
        case PermissionStatus.denied:
          break;
        case PermissionStatus.granted:
          await openAppSettings();
          print("revoke_permission".tr());
          break;
      }
    }
    return permission.status.isGranted;
  }

  Future buildPaymentWidget(String idItem) async {
    //get the product
    final response = await InAppPurchase.instance.queryProductDetails({idItem});
    if (response.notFoundIDs.isNotEmpty) {
      print("Product not found");
      showToast("error_trylater".tr());
      return;
    }

    //set the listener
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;

    _paymentSubscription ??= purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        // handle  purchaseDetailsList
        purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
          if (purchaseDetails.status == PurchaseStatus.pending) {
          } else {
            if (purchaseDetails.status == PurchaseStatus.error) {
              showToast("error_trylater".tr());
            } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                purchaseDetails.status == PurchaseStatus.restored) {
              showToast("${"thankyou".tr()} ❤️");
            }
            if (purchaseDetails.pendingCompletePurchase) {
              await InAppPurchase.instance.completePurchase(purchaseDetails);
            }
          }
        });
      },
      onDone: () {
        showToast("${"thankyou".tr()} ❤️");
        print("Close subscription");
      },
      onError: (error) {
        print("Payment error: $error");
        showToast("error_trylater".tr());
      },
    );

    //show the dialog
    final products = response.productDetails;
    final product = products.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);

    return;
  }

  Future showTextInputDialog({required String spKey, String? hint}) async {
    final spKeyEnabled = "${spKey}_enabled";

    final _textEditingController = TextEditingController();
    _textEditingController.text = sp.getString(spKey) ?? "";

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (context, StateSetter _setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('enabled'.tr().capitalize()),
                    value: sp.getBool(spKeyEnabled) ?? false,
                    onChanged: (value) {
                      _setState(() {
                        sp.setBool(spKeyEnabled, value);
                      });
                      if (value)
                        showToast("default value will be overwritten".tr());
                    },
                  ),
                  TextField(
                    minLines: 4,
                    maxLines: 10,
                    controller: _textEditingController,
                    decoration: InputDecoration(hintText: hint),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('delete'.tr().capitalize()),
              onPressed: () {
                sp.remove(spKey);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('cancel'.tr().capitalize()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('save'.tr().capitalize()),
              onPressed: () {
                setState(() {
                  sp.setString(spKey, _textEditingController.text.trim());
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showSendCodeToDev() {
    var sendCss = true;
    var sendJs = true;
    var sendUserAgent = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (context, StateSetter _setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('send_useragent'.tr()),
                    value: sendUserAgent,
                    onChanged: (value) {
                      _setState(() => sendUserAgent = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('send_css'.tr()),
                    value: sendCss,
                    onChanged: (value) {
                      _setState(() => sendCss = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('send_js'.tr()),
                    value: sendJs,
                    onChanged: (value) {
                      _setState(() => sendJs = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('compose email'.tr()),
              onPressed: () {
                String myCss;
                String myJs;
                String myUserAgent;
                myCss = myJs = myUserAgent = "";

                if (sendCss)
                  myCss = Uri.encodeFull(sp.getString("custom_css") ?? "");

                if (sendJs)
                  myJs = Uri.encodeFull(sp.getString("custom_js") ?? "");

                if (sendUserAgent)
                  myUserAgent =
                      Uri.encodeFull(sp.getString("custom_useragent") ?? "");

                final link =
                    "mailto:$kDevEmail?subject=SlimSocial%3A%20new%20code%20suggestion&body=Hi%20Leo%2C%0A%0Athis%20code%20is%20good%20for%20these%20reasons%3A%0A-%20...%0A-%20...%0A%0AMy%20CSS%3A%20%0A$myCss%0A%0A-----%0A%0AMy%20js%3A%20%0A$myJs%0A%0A---%0A%0AMy%20user%20agent%3A%20%0A$myUserAgent%0A";

                launchUrl(Uri.parse(link));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePermissionsToggle() async {
    for (final entry in permissions.entries) {
      final permission = entry.value;
      final spKey = entry.key;

      final permissionValue = await permission.isGranted;
      setState(() {
        sp.setBool(spKey, permissionValue);
      });
    }
  }

  Future showProxyDialog() async {
    const spKey = "custom_proxy";
    const spKeyEnabled = "${spKey}_enabled";
    const spKeyIp = "${spKey}_ip";
    const spKeyPort = "${spKey}_port";

    final _ipController = TextEditingController();
    _ipController.text = sp.getString(spKeyIp) ?? "";
    final _portController = TextEditingController();
    _portController.text = sp.getString(spKeyPort) ?? "";

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StatefulBuilder(
            builder: (context, StateSetter _setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('enabled'.tr().capitalize()),
                    value: sp.getBool(spKeyEnabled) ?? false,
                    onChanged: (value) {
                      _setState(() {
                        sp.setBool(spKeyEnabled, value);
                      });
                      if (value)
                        showToast("default value will be overwritten".tr());
                    },
                  ),
                  Row(
                    children: [
                      Flexible(
                        flex: 4,
                        child: TextField(
                          minLines: 1,
                          controller: _ipController,
                          decoration:
                              const InputDecoration(hintText: "localhost"),
                        ),
                      ),
                      const Text(" : "),
                      Flexible(
                        flex: 2,
                        child: TextField(
                          minLines: 1,
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: "8888"),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('delete'.tr().capitalize()),
              onPressed: () {
                sp.remove(spKey);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('cancel'.tr().capitalize()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('save'.tr().capitalize()),
              onPressed: () {
                final port = _portController.text.trim();
                final ip = _ipController.text.trim();

                if (port.isNullOrEmpty() || port.isNullOrEmpty()) {
                  Navigator.of(context).pop();
                  return;
                }

                setState(() {
                  sp.setString(spKeyPort, port);
                  sp.setString(spKeyIp, ip);
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
