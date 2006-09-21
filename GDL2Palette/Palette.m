#include "Palette.h"
#include "ResourceManager.h"
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSBundle.h>

static NSConstantString *GDL2PaletteBundles = @"GDL2PaletteBundles";
@implementation GDL2Palette

+(void) initialize
{
//  NSLog(@"GDL2Palette initialize");
  NSArray *bundles;
  int i, c;

  [IBResourceManager registerResourceManagerClass:[GDL2ResourceManager class]];
  bundles = [[NSUserDefaults standardUserDefaults] arrayForKey:GDL2PaletteBundles];
  for (i = 0, c = [bundles count]; i < c; i++) 
    [[NSBundle bundleWithPath:[bundles objectAtIndex:i]] load];
}

@end
