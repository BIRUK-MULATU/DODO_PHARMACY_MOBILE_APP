//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<file_selector_ios/FileSelectorPlugin.h>)
#import <file_selector_ios/FileSelectorPlugin.h>
#else
@import file_selector_ios;
#endif

#if __has_include(<no_screenshot/NoScreenshotPlugin.h>)
#import <no_screenshot/NoScreenshotPlugin.h>
#else
@import no_screenshot;
#endif

#if __has_include(<pdfx/PdfxPlugin.h>)
#import <pdfx/PdfxPlugin.h>
#else
@import pdfx;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FileSelectorPlugin registerWithRegistrar:[registry registrarForPlugin:@"FileSelectorPlugin"]];
  [NoScreenshotPlugin registerWithRegistrar:[registry registrarForPlugin:@"NoScreenshotPlugin"]];
  [PdfxPlugin registerWithRegistrar:[registry registrarForPlugin:@"PdfxPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
