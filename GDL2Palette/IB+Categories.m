#include <Foundation/Foundation.h>

#include <EOInterface/EODisplayGroup.h>
@interface EODisplayGroup (PaletteStuff)
- (NSString *)connectInspectorClassName;
@end

@implementation EODisplayGroup (PaletteStuff)
- (NSString *)connectInspectorClassName
{
  return @"GDL2ConnectionInspector";
}
@end

#include <AppKit/NSView.h>
@interface NSView (PaletteStuff)
- (NSString *)connectInspectorClassName;
@end

@implementation NSView (PaletteStuff)
- (NSString *)connectInspectorClassName
{
  return @"GDL2ConnectionInspector";
}
@end

#include <AppKit/NSTableColumn.h>

@interface NSTableColumn (PaletteStuff)
- (NSString *)connectInspectorClassName;
@end

@implementation NSTableColumn (PaletteStuff)
- (NSString *)connectInspectorClassName
{
  return @"GDL2ConnectionInspector";
}

@end

