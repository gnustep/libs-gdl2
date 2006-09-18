#include "DisplayGroupInspector.h"
#include <EOInterface/EODisplayGroup.h>
#include <AppKit/NSNibLoading.h>

@implementation GDL2DisplayGroupInspector 
- (id) init
{
  self = [super init];
  [NSBundle loadNibNamed:@"GDL2DisplayGroupInspector" owner:self];
  return self;
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

@end


