#include <InterfaceBuilder/IBInspector.h>
@class NSBrowser;
@class NSPopUpButton;
@class EOAssociation;

@interface GDL2ConnectionInspector : IBInspector
{
  NSBrowser *oaBrowser;
  NSBrowser *connectionsBrowser;
  NSPopUpButton *popUp;

  NSArray *_keys;
  NSArray *_signatures;
  NSMutableArray *_values;
  NSMutableArray *_connectors;
  
  NSNibConnector *_currentConnector;
  
  EOAssociation *_association;
}

- (void) updateKeys;
- (void) updateValues;
- (void) updateButtons;
- (void) selectedConnector;
- (void) selectedOutletOrAction;
@end


