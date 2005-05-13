#include "Palette.h"
#include "ResourceManager.h"


@implementation GDL2Palette

+(void) initialize
{
//  NSLog(@"GDL2Palette initialize");
  [IBResourceManager registerResourceManagerClass:[GDL2ResourceManager class]];
}

@end
