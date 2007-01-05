#ifndef __ModelerEntityEditor_H_
#define __ModelerEntityEditor_H_

/*
    ModelerEntityEditor.h
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: Apr 2005

    This file is part of DBModeler.

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
*/ 

#include "ModelerTableEmbedibleEditor.h"

#include <EOControl/EOObserver.h>

@class NSBox;
@class NSWindow;
@class NSTableView;
@class NSSplitView;
@class EODisplayGroup;
@class PlusMinusView;

@interface ModelerEntityEditor : ModelerTableEmbedibleEditor <EOObserving>
{
  NSTableView *_topTable;
  NSTableView *_bottomTable;
  NSSplitView *_splitView;
  NSWindow    *_window;
  NSBox	      *_box;
  EODisplayGroup *dg;
}


-(void)objectWillChange:(id)anObject;

@end

#endif // __ModelerEntityEditor_H_

