/**
    ModelerTableEmbedibleEditor.m
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006

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


#include "ModelerTableEmbedibleEditor.h"

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSImage.h>
#endif

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>
#endif
  
#include <EOInterface/EODisplayGroup.h>
#include <EOInterface/EOAssociation.h>
#include "EOModeler/EOModelerApp.h"

#include <GNUstepBase/GNUstep.h>

/* base class with some methods shared among default embedible editors */
@implementation ModelerTableEmbedibleEditor : EOModelerEmbedibleEditor
- (void) setupCornerView:(NSPopUpButton *)cornerView
               tableView:(NSTableView *)tableView
            displayGroup:(EODisplayGroup *)dg
                forClass:(Class)aClass
{
  NSArray *columnNames = [EOMApp columnNamesForClass:aClass];
  int i, c;
  [cornerView setTarget:self];
  [cornerView setAction:@selector(_cornerAction:)];
  [[cornerView cell] setRepresentedObject: aClass];

  for (i = 0, c = [columnNames count]; i < c; i++)
    {
      NSString *columnName = [columnNames objectAtIndex:i];
      NSMenuItem <NSMenuItem> *item;

      [cornerView addItemWithTitle:columnName];
      item = (NSMenuItem *)[cornerView itemWithTitle:columnName];
      [item setOnStateImage:[NSImage imageNamed:@"common_2DCheckMark"]];
      [item setState:NSOffState];
    }
}

/* attempts to find column names from the defaults.
 * subclasses should call supers, and return their default columns.
 * if it returns nil or an array of count 0 */
- (NSArray *)defaultColumnNamesForClass:(Class)aClass
{
   return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:NSStringFromClass(aClass)] objectForKey:@"Columns"];
}

- (void) addDefaultTableColumnsForTableView:(NSTableView *)tv
                               displayGroup:(EODisplayGroup *)dg
{
  Class aClass = [[(NSPopUpButton*)[tv cornerView] cell] representedObject];
  NSArray *columnNames = [self defaultColumnNamesForClass:aClass];
  int i, c; 
  for (i = 0, c = [columnNames count]; i < c; i++)
    {
      NSString *columnName = [columnNames objectAtIndex:i];
      NSPopUpButton *cv = (id)[tv cornerView];
      NSMenuItem <NSMenuItem>*item;
      id <EOMColumnProvider>provider;
      NSTableColumn *tc = [[NSTableColumn alloc] initWithIdentifier:nil];

      provider = [EOMApp providerForName: columnName class:aClass]; 
      
      /*
       * THIS *MUST* be before initColumn:class:name:displayGroup:document calls       */
      [tv addTableColumn:tc];
      RELEASE(tc);
      
      [provider initColumn:tc class:aClass name:columnName
              displayGroup:dg document:[self document]]; 
      item = (NSMenuItem *)[cv itemWithTitle:columnName];
      [item setRepresentedObject:tc];
      [item setState:NSOnState];
    }
  [tv tile];
}

- (void) addTableColumnForItem:(NSMenuItem *)item
          tableView:(NSTableView *)tv
{
  NSString *columnName = [item title];
  Class aClass = [[(NSPopUpButton *)[tv cornerView] cell] representedObject];
  id <EOMColumnProvider>provider = [EOMApp providerForName:columnName class:aClass];
  NSTableColumn *tc = [[NSTableColumn alloc] initWithIdentifier:nil]; // can't rely on ident.
  
  [item setState:NSOnState];
  [item setRepresentedObject:tc];
  
  /* THIS *MUST* be before initColumn:class:name:displayGroup:document calls */
  [tv addTableColumn:tc];
  RELEASE(tc);  
  /* this requires that the table at least have 1 table column in it...
   * so we have to have another method to setup the default table columns */
  [provider initColumn:tc
          class:aClass
           name:columnName
   displayGroup:[[tv delegate] displayGroupForAspect:@"source"] // <-+-^
       document:[self document]];
  [tc sizeToFit]; 
  [tv tile];
}
          
- (void) removeTableColumnForItem:(NSMenuItem *)item
          tableView:(NSTableView *)tv
{
  [tv removeTableColumn:[item representedObject]];
  [item setRepresentedObject:nil];
  [item setState:NSOffState];
}

- (void) _cornerAction:(id)sender
{
  NSMenuItem *item = (NSMenuItem*)[sender selectedItem];
  NSTableView *tv = [[sender enclosingScrollView] documentView];
  if ([item state] == NSOnState)
    {
      [self removeTableColumnForItem:item tableView:tv];
    }
  else
    {
      [self addTableColumnForItem:item tableView:tv];
    }
}

- (void) displayGroup:(EODisplayGroup *)dg didSetValue:(id)value
            forObject:(id)obj key:(NSString *)key
{
  [[NSNotificationCenter defaultCenter]
          postNotificationName:EOMSelectionChangedNotification
          object:nil];
}

@end

