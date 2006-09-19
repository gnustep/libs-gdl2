#include <InterfaceBuilder/IBInspector.h>
#include <AppKit/NSNibDeclarations.h>

@class NSButton;
@class NSTableView;
@class NSMutableArray;

@interface GDL2DisplayGroupInspector : IBInspector
{
  IBOutlet NSButton	*_fetchesOnLoad;
  IBOutlet NSButton	*_refresh;
  IBOutlet NSButton	*_validate;
 
  IBOutlet NSTableView	*_localKeysTable;
  IBOutlet NSButton	*_addKey;
  IBOutlet NSButton	*_removeKey;
  
  NSMutableArray *_localKeys;
}
-(IBAction) setValidatesImmediately:(id)sender;
-(IBAction) setRefreshesAll:(id)sender;
-(IBAction) setFetchesOnLoad:(id)sender;
@end

