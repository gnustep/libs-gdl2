#include "DisplayGroupInspector.h"
#include <EOInterface/EODisplayGroup.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTableView.h>
#include <Foundation/NSArray.h>

@implementation GDL2DisplayGroupInspector 
- (id) init
{
  self = [super init];
  [NSBundle loadNibNamed:@"GDL2DisplayGroupInspector" owner:self];
  _localKeys = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(_localKeys);
}

-(IBAction) setValidatesImmediately:(id)sender;
{
  [(EODisplayGroup *)[self object]
	  setValidatesChangesImmediately:[sender intValue]];
}

-(IBAction) setRefreshesAll:(id)sender;
{
  [(EODisplayGroup *)[self object]
	  setUsesOptimisticRefresh:([sender intValue] ? NO : YES)]; 
}

-(IBAction) setFetchesOnLoad:(id)sender;
{
  [(EODisplayGroup *)[self object]
	  setFetchesOnLoad:[sender intValue]];
}

- (void) revert:(id)sender
{
  if (object == nil)
    return;

  [_fetchesOnLoad setIntValue:[object fetchesOnLoad]];
  [_validate setIntValue:[object validatesChangesImmediately]];
  [_refresh setIntValue:[object usesOptimisticRefresh] ? NO : YES];
}

- (void) addKey:(id)sender
{
  [_localKeys addObject:@""];
  [_localKeysTable reloadData];
  [_localKeysTable selectRow:([_localKeys count] - 1) byExtendingSelection:NO];
}

- (void) removeKey:(id)sender
{
  int selRow = [_localKeysTable selectedRow];
  if (selRow != NSNotFound && selRow > 0 && selRow < [_localKeys count])
    {
      [_localKeys removeObjectAtIndex:[_localKeysTable selectedRow]];
      [_localKeysTable reloadData];
    }
}

- (int) numberOfRowsInTableView:(NSTableView *)tv
{
  return [_localKeys count];
}

- (id) tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc
row:(int)row
{
  return [_localKeys objectAtIndex:row];
}

- (void) tableView:(NSTableView *)tv setObjectValue:(id)newValue forTableColumn:(NSTableColumn *)tc row:(int) row;
{
  [_localKeys replaceObjectAtIndex:row withObject:newValue];
  [object setLocalKeys:_localKeys];
}

@end


