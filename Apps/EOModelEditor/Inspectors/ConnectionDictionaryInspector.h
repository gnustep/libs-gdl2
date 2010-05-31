
/*
 ConnectionDictionaryInspector.h
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
 EOModelEditor is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 EOModelEditor is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with EOModelEditor; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <EOModeler/EOMInspector.h>

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/AppKit.h>
#endif

@class EOAttribute;
@class TableViewController;

@interface ConnectionDictionaryInspector : EOMInspector
{
  IBOutlet NSTableView          *_tableView;
  IBOutlet NSTextView           *_textView;
  NSMutableArray                *_dataArray;
  TableViewController           *_tableViewController;
  NSMutableDictionary           *_selectedDict;
}

- (void) commitChanges;

@end

