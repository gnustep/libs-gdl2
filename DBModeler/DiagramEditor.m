/**
    DiagramEditor.m

    Author: Matt Rice <ratmice@gmail.com>
    Date: Oct 2006

    This file is part of DBModeler.

    <license>
    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
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

#include "DiagramEditor.h"
#include "DiagramView.h"
#include <EOModeler/EOModelerDocument.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSScrollView.h>
#include <AppKit/NSClipView.h>
#endif

#include <GNUstepBase/GNUstep.h>

@implementation DiagramEditor
- (void) dealloc
{
  RELEASE(_mainView);
  [super dealloc];
}

- (id) initWithParentEditor:(id)parent
{
  DiagramView *dv;
  NSClipView *cv;
  self = [super initWithParentEditor:parent];
  _mainView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,1,1)];
  cv = [[NSClipView alloc] initWithFrame:NSMakeRect(0,0,1,1)];
  [_mainView setHasVerticalScroller:YES]; 
  [_mainView setHasHorizontalScroller:YES]; 
  [_mainView setContentView:cv];
  RELEASE(cv);
  dv = [[DiagramView alloc] initWithFrame:NSMakeRect(0,0,1,1)];
  [_mainView setDocumentView:dv];
  RELEASE(dv);
  [dv setModel:[[self document] model]];
  return self;
}

- (NSView *)mainView
{
  return _mainView;
}

- (void) activate
{
  EOModel *model = [[self document] model];
  NSArray *entities = [model entities];
  int i, c;
  NSSize s = [_mainView contentSize];
  id docView = [_mainView documentView];

  [docView setFrameSize:s];
  for (i = 0, c = [entities count]; i < c; i++)
    {
      EOEntity *ent = [entities objectAtIndex:i];
      NSString *name = [ent name];

      [docView showEntity:name];
    }
}

- (BOOL) canSupportCurrentSelection
{
  return YES;
}

@end

