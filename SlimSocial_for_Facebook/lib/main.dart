import 'package:app_links/app_links.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:native_flutter_proxy/custom_proxy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slimsocial_for_facebook/controllers/fb_controller.dart';
import 'package:slimsocial_for_facebook/screens/home_page.dart';
import 'package:slimsocial_for_facebook/screens/settings_page.dart';
import 'package:slimsocial_for_facebook/style/color_schemes.g.dart';
import 'package:slimsocial_for_facebook/utils/css.dart';
import 'package:slimsocial_for_facebook/utils/utils.dart';

late SharedPreferences sp;

//riverpod state
final fbWebViewProvider =
    StateNotifierProvider<webViewUriState, Uri>(webViewUriState.new);
final messengerWebViewProvider =
    StateNotifierProvider<webViewUriState, Uri>(webViewUriState.new);

late PackageInfo packageInfo;

// Theme mode provider
final themeProvider = StateProvider<ThemeMode>((ref) {
  return CustomCss.darkThemeCss.isEnabled() ? ThemeMode.dark : ThemeMode.light;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  packageInfo = await PackageInfo.fromPlatform();
  sp = await SharedPreferences.getInstance();
  
  final container = ProviderContainer();

  if (sp.getBool("custom_proxy_enabled") ?? false) _setupProxy();

  final _appLinks = AppLinks();
  _appLinks.uriLinkStream.listen((uri) {
    print("Received uri: $uri");
    container.read(fbWebViewProvider.notifier).updateUrl(uri.toString());
  });

  runApp(
    ProviderScope(
      parent: container,
      child: EasyLocalization(
        supportedLocales: const [
          Locale('it', 'IT'),
          Locale('en', 'US'),
          Locale('fr', 'FR'),
          Locale('es', 'ES'),
          Locale('de', 'DE'),
          Locale('pt', 'PT'),
          Locale('nl', 'NL'),
          Locale('ru', 'RU'),
          Locale('pl', 'PL'),
          Locale('tr', 'TR'),
          Locale('zh', 'CN'),
          Locale('ja', 'JP'),
          Locale('ko', 'KR'),
          Locale('ar', 'AR'),
          Locale('hi', 'IN'),
          Locale('sv', 'SE'),
          Locale('no', 'NO'),
          Locale('fi', 'FI'),
          Locale('da', 'DK'),
          Locale('cs', 'CZ'),
          Locale('sk', 'SK'),
          Locale('hu', 'HU'),
          Locale('ro', 'RO'),
          Locale('uk', 'UA'),
          Locale('bg', 'BG'),
          Locale('hr', 'HR'),
          Locale('sr', 'SP'),
          Locale('sl', 'SI'),
          Locale('et', 'EE'),
          Locale('lv', 'LV'),
          Locale('lt', 'LT'),
          Locale('he', 'IL'),
          Locale('fa', 'IR'),
          Locale('ur', 'PK'),
          Locale('bn', 'IN'),
          Locale('ta', 'IN'),
          Locale('te', 'IN'),
          Locale('mr', 'IN'),
          Locale('ml', 'IN'),
          Locale('th', 'TH'),
          Locale('vi', 'VN'),
        ],
        path: 'assets/lang',
        fallbackLocale: const Locale('en', 'US'),
        child: const SlimSocialApp(),
      ),
    ),
  );
}

void _setupProxy() {
  final ip = sp.getString("custom_proxy_ip");
  final port = sp.getString("custom_proxy_port");
  if (ip == null || port == null) {
    showToast("error_proxy".tr());
    return;
  }

  try {
    final proxy = CustomProxy(ipAddress: ip, port: int.parse(port));
    proxy.enable();
    showToast("proxy_is_active".tr());
  } catch (e) {
    showToast("error_proxy with {}:{}".tr(args: [ip, port]));
  }
}


class SlimSocialApp extends ConsumerStatefulWidget {
  const SlimSocialApp({super.key});

  @override
  ConsumerState<SlimSocialApp> createState() => _SlimSocialAppState();
}

class _SlimSocialAppState extends ConsumerState<SlimSocialApp> {
  final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1877F2), // Facebook blue
    brightness: Brightness.light,
  );

  final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1877F2),
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic color if supported by the system
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Otherwise, use our default schemes
          lightScheme = _defaultLightColorScheme;
          darkScheme = _defaultDarkColorScheme;
        }

        return MaterialApp(
          title: 'SlimSocial for Facebook',
          debugShowCheckedModeBanner: false,
          
          // Light theme
          theme: FlexThemeData.light(
            scheme: FlexScheme.blue,
            colorScheme: lightScheme,
            useMaterial3: true,
            fontFamily: GoogleFonts.roboto().fontFamily,
            subThemesData: const FlexSubThemesData(
              interactionEffects: true,
              blendOnLevel: 20,
              blendOnColors: true,
              elevatedButtonRadius: 12,
              textButtonRadius: 8,
              outlinedButtonRadius: 12,
              inputDecoratorRadius: 8,
              cardRadius: 16,
              popupMenuRadius: 12,
              dialogRadius: 20,
              timePickerElementRadius: 12,
              appBarBackgroundSchemeColor: SchemeColor.surfaceVariant,
            ),
          ),
          
          // Dark theme
          darkTheme: FlexThemeData.dark(
            scheme: FlexScheme.blue,
            colorScheme: darkScheme,
            useMaterial3: true,
            fontFamily: GoogleFonts.roboto().fontFamily,
            subThemesData: const FlexSubThemesData(
              interactionEffects: true,
              blendOnLevel: 20,
              tintLevel: 12,
              elevatedButtonRadius: 12,
              textButtonRadius: 8,
              outlinedButtonRadius: 12,
              inputDecoratorRadius: 8,
              cardRadius: 16,
              popupMenuRadius: 12,
              dialogRadius: 20,
              timePickerElementRadius: 12,
              appBarBackgroundSchemeColor: SchemeColor.surfaceVariant,
            ),
          ),
          
          themeMode: themeMode,
          
          // Route animations
          builder: (context, child) {
            return Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => child!.animate().fadeIn(
                    duration: const Duration(milliseconds: 300),
                  ),
                );
              },
            );
          },
          
          home: const HomePage(),
          routes: {
            "/settings": (context) => SettingsPage(),
          },
          
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}

// Modern toast message
void showModernToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      dismissDirection: DismissDirection.horizontal,
      animation: CurvedAnimation(
        parent: const AlwaysStoppedAnimation(1),
        curve: Curves.easeOutCirc,
      ),
    ),
  );
}
