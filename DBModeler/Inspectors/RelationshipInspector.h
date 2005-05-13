#include <EOModeler/EOMInspector.h>
#include <AppKit/AppKit.h>

@class EOModel;
@class EOEntity;
@interface RelationshipInspector : EOMInspector
{
  IBOutlet NSTextField		*name_textField;
  IBOutlet NSPopUpButton	*model_popup;
  IBOutlet NSMatrix		*joinCardinality_matrix;
  IBOutlet NSPopUpButton	*joinSemantic_popup;
  IBOutlet NSTableView		*destEntity_tableView;
  IBOutlet NSTableView		*srcAttrib_tableView;
  IBOutlet NSTableView		*destAttrib_tableView;
  IBOutlet NSButton		*connect_button;
}

- (IBAction) connectionChanged:(id)sender;
- (IBAction) nameChanged:(id)sender;
@end

