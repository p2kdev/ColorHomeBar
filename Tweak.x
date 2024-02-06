#import "Tweak.h"

static bool isBlackOrWhite(UIColor *color) {
  CGFloat r, g, b;
  [color getRed:&r green:&g blue:&b alpha:NULL];
  r = round(r * 255.0);
  g = round(g * 255.0);
  b = round(b * 255.0);
  return (r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23);
}

static NSMutableDictionary *cachedPillColors;

%hook MTLumaDodgePillView

  - (void)_updateStyle {
    %orig;

    if ([(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication])
      self.style = 0;
  }

  - (void)layoutSubviews {
    %orig;

    //NSLog(@"CHBDict is %@", cachedPillColors);

    if (!cachedPillColors)
      cachedPillColors = [[NSMutableDictionary alloc] init];

    SBApplication *app = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    if (!app) return;

    __block NSString *appIdentifier = app.bundleIdentifier;

    if (![cachedPillColors objectForKey:appIdentifier])
    {
      NSArray<SBLeafIcon *> *icons =
          ((SBIconController *)[%c(SBIconController) sharedInstanceIfExists])
              .model.leafIcons.allObjects;

      NSUInteger iconIdx =
          [icons indexOfObjectPassingTest:^BOOL(SBLeafIcon *icon, NSUInteger idx, BOOL *stop) {
            if ([[icon applicationBundleID] isEqualToString:appIdentifier]) {
              *stop = YES;
              return YES;
            }
            return NO;
          }];

      if (iconIdx == NSNotFound) return;

      SBLeafIcon *icon = icons[iconIdx];

      UIImage *iconImage;
      if ([icon respondsToSelector:@selector(generateIconImage:)]) {
        iconImage = [icon generateIconImage:2];
      } else {
        struct SBIconImageInfo imageInfo;
        imageInfo.size = CGSizeMake(60, 60);
        imageInfo.scale = [UIScreen mainScreen].scale;
        imageInfo.continuousCornerRadius = 12;
        iconImage = [icon generateIconImageWithInfo:imageInfo];
      }

      [[[MPArtworkColorAnalyzer alloc] initWithImage:iconImage algorithm:0]
          analyzeWithCompletionHandler:^(MPArtworkColorAnalyzer *analyzer,
                                        MPMutableArtworkColorAnalysis *analysis) {
            UIColor *bgColor = analysis.backgroundColor;                  
            CCColorCube *colorCube = [[CCColorCube alloc] init];
            NSArray *ccColors = [colorCube extractColorsFromImage:iconImage
                                                            flags:CCAvoidWhite | CCAvoidBlack avoidColor:bgColor]; 

            if (isBlackOrWhite(bgColor) && ccColors.count != 0)
              bgColor = ccColors[0];  

            [cachedPillColors setObject:bgColor forKey:appIdentifier];           

        }];                   
    }
    else
      self.backgroundColor = [cachedPillColors objectForKey:appIdentifier];     
  }
%end