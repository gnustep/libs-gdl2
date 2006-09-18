#include <InterfaceBuilder/IBInspector.h>
#include <AppKit/NSNibDeclarations.h>
#include <AppKit/NSButton.h>

@interface GDL2DisplayGroupInspector : IBInspector
{
  IBOutlet NSButton	*_fetchesOnLoad;
  IBOutlet NSButton	*_refresh;
  IBOutlet NSButton	*_validate;
}
-(IBAction) setValidatesImmediately:(id)sender;
-(IBAction) setRefreshesAll:(id)sender;
-(IBAction) setFetchesOnLoad:(id)sender;
@end

