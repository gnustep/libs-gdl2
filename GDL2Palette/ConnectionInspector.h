#include <InterfaceBuilder/IBInspector.h>
@class NSBrowser;
@class NSPopUpButton;

@interface GDL2ConnectionInspector : IBInspector
{
  NSBrowser *oaBrowser;
  NSBrowser *connectionsBrowser;
  NSPopUpButton *popUp;

  NSArray *_keys;
  NSArray *_signatures;
  NSArray *_values;
  NSMutableArray *_connectors;
  
  NSNibConnector *_currentConnector;

}

- (void) updateKeys;
- (void) updateValues;
- (void) updateButtons;
- (void) selectedConnector;
- (void) selectedOutletOrAction;
@end


