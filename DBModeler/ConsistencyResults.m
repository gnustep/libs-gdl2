/**
    ConsistencyResults.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Jul 2005

    This file is part of DBModeler.
    
    <license>
    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/


#include <ConsistencyResults.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSTextStorage.h>

static ConsistencyResults *_sharedResults;

@implementation ConsistencyResults
+ (id) sharedConsistencyPanel;
{
  if (!_sharedResults)
    _sharedResults = [[self allocWithZone:NSDefaultMallocZone()] init];

  return _sharedResults;
}

- (id) init
{
  self = [super init];
  [NSBundle loadNibNamed:@"ConsistencyResults" owner:self];
  successful = YES;
  return self;
}

- (int) showConsistencyCheckResults:(id)sender cancelButton:(BOOL)useCancel
showOnSuccess:(BOOL)flag
{
  int foo = NSRunStoppedResponse;

  [cancelButton setEnabled:useCancel];
  if (!flag && successful)
    {
    }
  else
    {
      foo = [NSApp runModalForWindow:_panel];
    }
  /* reset this.. */ 
  successful = YES;
  return foo;
}

- (void) appendConsistencyCheckErrorText:(NSAttributedString *)errorText
{
  successful = NO;
  [[results textStorage] appendAttributedString:errorText];
}

- (void) appendConsistencyCheckSuccessText:(NSAttributedString *)successText
{
  [[results textStorage] appendAttributedString:successText];
}

- (void) cancel:(id)sender
{
  [NSApp abortModal];
  [_panel orderOut:self];
  [results setString:@""];
}

- (void) ok:(id)sender
{
  [NSApp stopModal];
  [_panel orderOut:self];
  [results setString:@""];
}

@end
