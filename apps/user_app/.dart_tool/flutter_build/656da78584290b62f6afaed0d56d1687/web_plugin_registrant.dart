// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:file_selector_web/file_selector_web.dart';
import 'package:no_screenshot/no_screenshot_web.dart';
import 'package:pdfx/src/renderer/web/pdfx_plugin.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  FileSelectorWeb.registerWith(registrar);
  NoScreenshotWeb.registerWith(registrar);
  PdfxPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
