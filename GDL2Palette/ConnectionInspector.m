/**
    ConnectInspector.m

    Author: Matt Rice <ratmice@yahoo.com>
    Date: 2005, 2006

    This file is part of GDL2Palette.

    <license>
    GDL2Palette is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    GDL2Palette is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with GDL2Palette; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/
#include "ConnectionInspector.h"
#include "Foundation+Categories.h"

#include <EOAccess/EODatabaseDataSource.h>

#include <EOControl/EODetailDataSource.h>
#include <EOControl/EOClassDescription.h>

#include <AppKit/NSBrowser.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSPopUpButton.h>

#include <EOInterface/EOAspectConnector.h>
#include <EOInterface/EOAssociation.h>
#include <EOInterface/EODisplayGroup.h>

#include <EOModeler/EOModelExtensions.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSCharacterSet.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormDocument.h>

#include <InterfaceBuilder/IBApplicationAdditions.h>

#include "KeyWrapper.h"

@interface GDL2ConnectionInspector (Private)
- (NSArray *) _associationClassesUsableWithObject:(id)anObject;
@end

@interface NSApplication(missingStuff)
- (GormClassManager *)classManager;
@end

@implementation GDL2ConnectionInspector

- (NSButton *)okButton
{
  return nil;
}

- (id) init
{
  self = [super init];
  _values = [[NSMutableArray alloc] init];
  [NSBundle loadNibNamed:@"GDL2ConnectionInspector" owner:self];
  return self;
}

- (void) awakeFromNib
{
  [oaBrowser setMaxVisibleColumns:2];
  [oaBrowser setAllowsMultipleSelection:NO];
  [oaBrowser setTitled:NO];
  [oaBrowser setPathSeparator:@"."];

  [connectionsBrowser setTitled:NO];
  [connectionsBrowser setHasHorizontalScroller:NO];
  [connectionsBrowser setMaxVisibleColumns:1];
  [connectionsBrowser setAllowsMultipleSelection:NO];
  /* doubt if this is neccessary but why not */
  [connectionsBrowser setPathSeparator:@"."];
  
  [popUp removeAllItems];
}

/* for populating the associations pop-up */
- (NSArray *) _associationClassesUsableWithObject:(id)anObject
{
  NSMutableArray *usable;
  NSMutableSet *superseded;
  NSArray *allSuperseded;
  int i,c; 
  
  usable = [[NSMutableArray alloc] init];
  superseded = [[NSMutableSet alloc] init];
  [usable addObjectsFromArray:[EOAssociation
	  	associationClassesForObject:anObject]];
  /* get all supserseded associations */
  for (i = 0, c = [usable count]; i < c; i++)
    {
      id assocClass = [usable objectAtIndex:i];
      [superseded addObjectsFromArray:
	      	[assocClass associationClassesSuperseded]];
    }
  /* remove all superseded (even superseded associations superseded ones) */ 
  allSuperseded = [superseded allObjects];
  for (i = 0, c = [allSuperseded count]; i < c; i++)
    {
      id assocClass = [allSuperseded objectAtIndex:i];
      [usable removeObject:assocClass];
    }
  RELEASE(superseded);

  return AUTORELEASE(usable);
}

- (void) setObject:(id)anObject
{
  id associationClasses;
  int i,c; 
   
  [super setObject:anObject];

  if (!object) return;

  RELEASE(_connectors);
  _connectors = [NSMutableArray new];
  
  [_connectors addObjectsFromArray:[[[(id<IB>)NSApp activeDocument]
      connectorsForSource:object]
      	arrayWithObjectsRespondingYesToSelector:@selector(isKindOfClasses:)
	  withObject:[NSArray arrayWithObjects:[NSNibControlConnector class],
	  				      [NSNibOutletConnector class],
					      [EOAspectConnector class],
					      nil]]];

  [_values removeAllObjects];
  [self updateKeys];  
  [popUp removeAllItems];
  [popUp addItemWithTitle:@"Outlets"];
  associationClasses = [self _associationClassesUsableWithObject:anObject];
  for (i = 0, c = [associationClasses count]; i < c; i++)
    {
      Class assocSubclass = [associationClasses objectAtIndex:i];
      NSString *title = [assocSubclass displayName];
      [popUp addItemWithTitle:title];
      [[popUp itemWithTitle:title] setRepresentedObject:assocSubclass];
    }
  [connectionsBrowser reloadColumn:0];
  [oaBrowser loadColumnZero];
  [self updateButtons];
}

- (void) _popUpAction:(id)sender
{
  [self updateKeys];
  [oaBrowser reloadColumn:0];
  [oaBrowser reloadColumn:1];
  [connectionsBrowser reloadColumn:0];
}

- (void) updateKeys
{
  Class repObj = [[popUp selectedItem] representedObject];
  RELEASE(_keys);
  RELEASE(_signatures);

  /* outlets.. */
  if (repObj == nil)
    {
      /* gorm specific... but couldn't find a public standard api replacement */
      /* see bug #17822 */
      _keys = RETAIN([[NSApp classManager] allOutletsForObject:object]);
      _signatures = nil;
    }
  else
    {
      _keys = RETAIN([repObj aspects]);
      _signatures = RETAIN([repObj aspectSignatures]);
    }
}

- (NSArray *)_keysFromClassDescription:(EOClassDescription *)classDesc
{
  NSMutableArray *ret = [[NSMutableArray alloc] init];
  unsigned i, c, j;
  
  for (i = 0; i < 3; i++)
    {
      int type;
      NSArray *tmp;

      switch(i)
        {
	  case 0:
	    tmp  = [classDesc attributeKeys];
            type = AttributeType;
  	  break;
	  case 1:
            type = ToManyRelationshipType;
            tmp = [classDesc toManyRelationshipKeys];
	  break;
	  case 2:
            type = ToOneRelationshipType;
            tmp = [classDesc toOneRelationshipKeys];
	  break;
        }
      
      for (j = 0, c = [tmp count]; j < c; j++)
        {
          id obj = [tmp objectAtIndex:j];
          id key = [KeyWrapper wrapperWithKey:obj type:type];
	  [ret addObject:key];
        }
    }
  return AUTORELEASE(ret);
}

- (NSArray *) _localKeysFromDisplayGroup:(EODisplayGroup *)dg
{
  NSMutableArray *ret = [[NSMutableArray alloc] init];
  NSArray *local = [dg localKeys];
  int i,c;
  
  for (i = 0, c = [local count]; i < c; i++)
    {
      id obj = [local objectAtIndex:i];
      id key = [KeyWrapper wrapperWithKey:obj type:LocalType];

      [ret addObject:key];
    }

  return AUTORELEASE(ret);
}

/* for normal outlets/actions */
- (NSArray *) _keysFromArray:(NSArray *)arr
{
  NSMutableArray *ret = [[NSMutableArray alloc] init];
  int i, c;
  for (i = 0, c = [arr count]; i < c; i++)
     [ret addObject:[KeyWrapper wrapperWithKey:[arr objectAtIndex:i]
	     				  type:OtherType]];	 
  return AUTORELEASE(ret);
}
	
- (void) updateValues
{
  EODisplayGroup *dest = (EODisplayGroup *)[NSApp connectDestination];
  EODataSource *ds = [dest dataSource];
  
  [_values removeAllObjects];  
  if ([dest isKindOfClass:[EODisplayGroup class]])
    {
      if ([ds isKindOfClass:[EODataSource class]])
        {
	  id cd = [ds classDescriptionForObjects];
	  [_values addObjectsFromArray:[self _keysFromClassDescription:cd]];
        }
      [_values addObjectsFromArray:[self _localKeysFromDisplayGroup:dest]];
    }
}

- (void) _selectAction:(NSString*)label
{
  [oaBrowser reloadColumn:1];
  if (label != nil)
    [oaBrowser selectRow:[_values indexOfObject:label] inColumn:1];
}

- (void) _oaBrowserAction:(id)sender
{
  unsigned i,c;
  NSNibConnector *conn;

  if ([sender selectedColumn] == 0)
    {
	  id dest;
	  /* not an association */	  
	  if ([[popUp selectedItem] representedObject]  == nil)
	    {
	      /* browsing actions */
	      if ([[[sender selectedCell] stringValue] isEqual:@"target"])
	        {
		  NSArray *controlConnectors;
		  controlConnectors = [_connectors arrayWithObjectsRespondingYesToSelector:@selector(isKindOfClass:)
			  	withObject:[NSNibControlConnector class]];
	          c = [controlConnectors count];
	          conn = c ? [controlConnectors objectAtIndex:0]
	 	 	   : nil;
	          dest = c ? [conn destination]
			   : [NSApp connectDestination];
		  
		  [_values removeAllObjects];
		  
	          /* gorm specific...
		   * but couldn't find a public standard api replacement
		   * for allActionsForObject
		   */
	          [_values addObjectsFromArray:[self _keysFromArray:[[NSApp classManager]
			  			   allActionsForObject: dest]]];
	          if ([_values count] > 0)
	            {
	              conn = [NSNibControlConnector new];
		      [conn setSource: object];
		      [conn setDestination: [NSApp connectDestination]];
		      [conn setLabel: [[_values objectAtIndex:0] key]];
		      AUTORELEASE(conn);
		    }
	          if (_currentConnector != conn)
		    ASSIGN(_currentConnector, conn);
	          [self _selectAction: [conn label]];
	        }
	      else /* browsing outlets */
	        {
	          BOOL found = NO;
	          NSString *title = [[sender selectedCell] stringValue];
		  NSArray *oConns;
		  
		  oConns = [_connectors
				arrayWithObjectsRespondingYesToSelector:
						       @selector(isKindOfClass:)
			  	withObject:[NSNibOutletConnector class]];
		  
		  for (i = 0, c = [oConns count]; i < c; i++)
		    {
		      conn = [oConns objectAtIndex:i];
		      if ([conn label] == nil || [[conn label] isEqual:title])
		        {
		          found = YES;
		          ASSIGN(_currentConnector, conn);
		          break;
		        }
	            }
	      
	          if (!found)
	 	    {
		      RELEASE(_currentConnector); 
		      _currentConnector = [NSNibOutletConnector new];
		      [_currentConnector setSource:object];
		      [_currentConnector setDestination:[NSApp connectDestination]];
		      [_currentConnector setLabel:title];
		    }
	        }
	      [connectionsBrowser loadColumnZero];
	      [self selectedOutletOrAction];
	    }
	  else /* association connector */
	    {
	      [self updateValues];
	      [oaBrowser reloadColumn:1];
	    }
	  [okButton setEnabled:YES];
    }
  else
    {
      if ([[popUp selectedItem] representedObject]  == nil)
 	{
	  BOOL found = NO;
	  NSString *title = [[sender selectedCell] stringValue];
	  NSArray *cConns;

	  cConns = [_connectors 
		  	arrayWithObjectsRespondingYesToSelector:
						@selector(isKindOfClass:)
			  	withObject:[NSNibControlConnector class]];
	   
	  for (i = 0, c = [cConns count]; i < c; i++)
	    {
	      NSNibConnector *con = [cConns objectAtIndex:i];
	      NSString *action = [con label];
	      if ([action isEqual:title])
		{
		  ASSIGN(_currentConnector, con);
		  found = YES;
		  break;
		}
	    }
	  if (!found)
	    {
	      RELEASE(_currentConnector);
	      _currentConnector = [NSNibControlConnector new];
	      [_currentConnector setSource:object];
	      [_currentConnector setDestination:[NSApp connectDestination]];
	      [_currentConnector setLabel:title];
	      [connectionsBrowser loadColumnZero];
	    }
	  [self selectedOutletOrAction];
	}
      else
	{
	  BOOL found = NO;
	  NSString *aspectName = [[sender selectedCellInColumn:0] stringValue];
	  NSString *key;
	  NSCharacterSet *dotCharSet;
	  NSString *prefix = [NSString stringWithFormat:@"%@.", aspectName];
	  NSString *label;
	  NSArray *aspectConnectors;
	  
	  /* turn ".aspectName.foo.bar.baz." into "foo.bar.baz" */
	  dotCharSet = [NSCharacterSet characterSetWithCharactersInString:@"."];
	  key = [[[sender path] stringByTrimmingCharactersInSet:dotCharSet]
		   stringByDeletingPrefix:prefix];
	  /* "aspectName - foo.bar.baz" */
	  label = [NSString stringWithFormat:@"%@ - %@", aspectName, key];
	
	  aspectConnectors = [_connectors arrayWithObjectsRespondingYesToSelector:@selector(isKindOfClass:)
			  	withObject:[EOAspectConnector class]];
	  for (i = 0, c = [aspectConnectors count]; i < c; i++)
	     {
	       NSNibConnector *con = [aspectConnectors objectAtIndex:i];
	       if ([con source] == object && [[con label] isEqual: label])
	         {
		   ASSIGN(_currentConnector, con);
		   found = YES;
		   break;
		 }
	     }

	  if (!found)
	    {
	      NSArray *aConns = [[(id<IB>)NSApp activeDocument] connectorsForSource:object ofClass:[EOAspectConnector class]];
	      Class assocClass = [[popUp selectedItem] representedObject];
	      
	      _association = nil;

	      for (i = 0; i < c; i++)
	        {
		  EOAspectConnector *aConn = [aConns objectAtIndex:i];
		  EOAssociation *assoc = [aConn association];
		  if ([[assoc class] isEqual: assocClass])
		    {
		      ASSIGN(_association, assoc);
		    }
	        }

	      if (!_association)
	        {
		  _association = [[assocClass alloc] initWithObject:object];
	          /* this shouldn't happen until ok:. */
		}
	      
	      [_association bindAspect:aspectName
		   displayGroup:[NSApp connectDestination]
		   	    key:key];

	      RELEASE(_currentConnector);
	      _currentConnector = [[EOAspectConnector alloc] 
		      			initWithAssociation:_association
						 aspectName:aspectName];
	      [_currentConnector setSource:object];
	      [_currentConnector setDestination: [NSApp connectDestination]];
	      [_currentConnector setLabel:label];
	    }
	  /* fixme {'s and identation */
	    {
              int i;
              NSArray *vals = _values;
              EODisplayGroup *dest;
              EODataSource *ds;
              EOClassDescription *classDesc;
              id val;
              KeyType type;
              int wantsTypes = 0;
	      int column = [oaBrowser selectedColumn];
	      int row = [oaBrowser selectedRowInColumn:column];
	      int zeroRow = [oaBrowser selectedRowInColumn:0];
              NSString *sig = [[_signatures objectAtIndex:zeroRow]
                                                  uppercaseString];
              dest = (EODisplayGroup *)[NSApp connectDestination];
              ds = [dest dataSource];
              classDesc = [ds classDescriptionForObjects];


              for (i = 1; i < column; i++)
                {
                  int aRow = [sender selectedRowInColumn:i];

                  val = [vals objectAtIndex:aRow];
		  type = [val keyType]; 
		  
                  if (type == ToManyRelationshipType
		      || type == ToOneRelationshipType)
                    {
                      classDesc =
                      [classDesc classDescriptionForDestinationKey:[val key]];
                      vals = [self _keysFromClassDescription:classDesc];
                    }
                }
                val = [vals objectAtIndex:row];
                type = [val keyType];
                for (i = 0; i < [sig length]; i++)
                  {
                    switch ([sig characterAtIndex:i])
                      {
                        case 'A': wantsTypes |= AttributeType; break;
                        case '1': wantsTypes |= ToOneRelationshipType; break;
                        case 'M': wantsTypes |= ToManyRelationshipType; break;
                      }
                  }
		[okButton setEnabled:(wantsTypes & type)
				     || (type == LocalType)];
	    }
	}
    }
  [self updateButtons];
}

- (void) selectedOutletOrAction
{
  NSString *path;
  NSString *name = [[(id <IB>)NSApp activeDocument] nameForObject:[_currentConnector destination]];
  path = [@"." stringByAppendingString:[_currentConnector label]];
  path = [path stringByAppendingFormat:@" (%@)", name];
  [connectionsBrowser setPath:path];
}

- (void) updateButtons
{
  /* FIXME enable/disable okButton based off signature */ 
  if (!_currentConnector)
    {
      [okButton setState: NSOffState];
    }
  else
    {
      id src, dest;
      /* FIXME i wonder why this is not [self object]; */
      id firstResponder = [(GormDocument *)[(id<IB>)NSApp activeDocument] firstResponder];
      
      src = [_currentConnector source];
      dest = [_currentConnector destination];
      if (src && src != firstResponder
	  && ((dest && dest != firstResponder)
	      || ![_currentConnector isKindOfClass:[NSNibOutletConnector class]]))
        {
	  BOOL flag;
	  
	  flag = [_connectors containsObject:_currentConnector];
	  [okButton setState: flag ? NSOnState : NSOffState];
	}
      else
	{
	  [okButton setState: NSOnState];
	}
    }
}

- (void) _connectionsBrowserAction:(id)sender
{
  int i,c;
  NSNibConnector *con;
  NSString *title = [[sender selectedCell] stringValue];

  for (i = 0, c = [_connectors count]; i < c; i++)
    {
      NSString *label;
      
      con = [_connectors objectAtIndex:i];
       
      label = [con label];
      if (label == nil || [title hasPrefix:label])
	{
	  NSString *name;
	  id dest;

	  dest = [con destination];
	  name = [[(id <IB>)NSApp activeDocument] nameForObject:dest];
	  name = [label stringByAppendingFormat: @" (%@)", name];
	  if ([title isEqual:name])
	    {
	      ASSIGN(_currentConnector, con);
	      [self selectedConnector];
              break;
	    }
	}
    }
  [self updateButtons];
}

- (void) selectedConnector
{
  NSString *path; 

  path = [@"." stringByAppendingString:[_currentConnector label]];
  if ([_currentConnector isKindOfClass: [NSNibControlConnector class]])
    {
      path = [@".target" stringByAppendingString:path];
    }
  [oaBrowser setPath:path];
  [NSApp displayConnectionBetween:object and:[_currentConnector destination]];
}

- (int) browser:(NSBrowser *)browser
numberOfRowsInColumn:(int)column
{
  id repObj = [[popUp selectedItem] representedObject];
  if (browser == oaBrowser)
    {
      if (column == 0)
	{
          return [_keys count];
	}
      else
	{
          if (repObj == nil)
	    {
              if ([[[browser selectedCellInColumn:0] stringValue] isEqual:@"target"])
	        {
	          return [_values count];
	        }
	      else return 0;
	    }
          else
  	    {
	      int i;
	      NSArray *vals = _values;
  	      EODisplayGroup *dest;
	      EODataSource *ds;
	      EOClassDescription *classDesc;
	      
	      dest = (EODisplayGroup *)[NSApp connectDestination];
	      ds = [dest dataSource];
	      classDesc = [ds classDescriptionForObjects];
	      
	      for (i = 1; i < column; i++)
	        {
		  int row = [browser selectedRowInColumn:i];
		  id val = [vals objectAtIndex:row];
		  
		  if ([val keyType] != AttributeType)
		    {
		      classDesc =
		      [classDesc classDescriptionForDestinationKey: [val key]];
		      vals = [self _keysFromClassDescription:classDesc];
		    }
	        }
	      return [vals count];
	    }
        }
    }
  else if (browser == connectionsBrowser)
    {
      return [_connectors count];
    }
  return 0;
}

- (void) browser:(NSBrowser *)sender
willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
  id repObj = [[popUp selectedItem] representedObject];
  // FIXME -objectKeysTaken
  if (sender == oaBrowser)
    if (column == 0)
      {
	  if (repObj == nil)
	    {
	      NSString *name;
	      name = [_keys objectAtIndex:row];
	      [cell setStringValue:name];
	      [cell setLeaf: [name isEqual:@"target" ] ? NO : YES];
	      [cell setEnabled:YES];
	    }
	  else
	    {
	      [cell setStringValue: [_keys objectAtIndex:row]];
	      [cell setLeaf:[[_signatures objectAtIndex:row]  length] == 0];
	    }
      }
    else
      {
	  if (repObj == nil)
	    {
              if ([[[sender selectedCellInColumn:0] stringValue] isEqual:@"target"])
	        {
		  id val = [[_values objectAtIndex:row] key];
		  [cell setLeaf:YES];
		  [cell setStringValue: val];
		  [cell setEnabled:YES]; 
	        }
	    }
	  else
            {
              int i;
              NSArray *vals = _values;
              EODisplayGroup *dest;
              EODataSource *ds;
              EOClassDescription *classDesc;
	      id val;
	      KeyType type;
	      int wantsTypes = 0;
	      int zeroRow = [oaBrowser selectedRowInColumn:0];
	      NSString *sig = [[_signatures objectAtIndex:zeroRow]
		      					uppercaseString];
              
	      dest = (EODisplayGroup *)[NSApp connectDestination];
              ds = [dest dataSource];
              classDesc = [ds classDescriptionForObjects];
	      

              for (i = 1; i < column; i++)
                {
                  int aRow = [sender selectedRowInColumn:i];
                  val = [vals objectAtIndex:aRow];
		  type = [val keyType];

                  if (type != AttributeType || type != OtherType)
                    {
                      classDesc =
                      [classDesc classDescriptionForDestinationKey:[val key]];
		      vals = [self _keysFromClassDescription:classDesc];
                    }
                }
		val = [vals objectAtIndex:row];
		type = [val keyType];
		for (i = 0; i < [sig length]; i++)
		  {
		    switch ([sig characterAtIndex:i]) 
		      {
			case 'A': wantsTypes |= AttributeType; break; 
			case '1': wantsTypes |= ToOneRelationshipType; break;
			case 'M': wantsTypes |= ToManyRelationshipType; break;
		      }
		  }
		[cell setLeaf: (type == AttributeType
			        || type == LocalType)];
		// TODO relationships should be NO...
	        [cell setStringValue: [val key]];
		[cell setEnabled:(wantsTypes & type)
				 || (wantsTypes & AttributeType)
				 || (type == LocalType)];
            }
      }
  else if (sender == connectionsBrowser)
    {
      NSNibConnector *conn;
      NSString *name, *dest, *label;
      
      if (row < 0 || column != 0) return;
      
      conn = [_connectors objectAtIndex:row]; 
      label = [conn label];
      dest = [conn destination];
      name = [[(id<IB>)NSApp activeDocument] nameForObject: dest];
      [cell setStringValue: [label stringByAppendingFormat:@" (%@)", name]];
      [cell setEnabled:YES];
      [cell setLeaf:YES];
    }
}

- (void) ok:(id)sender
{
  if ([_currentConnector destination] == nil ||
     [_currentConnector source] == nil)
    {
      NSRunAlertPanel(_(@"Problem making connection"),
                      _(@"Please select a valid destination."),
                      _(@"OK"), nil, nil, nil);
    }
  else if ([_connectors containsObject:_currentConnector] == YES)
    {
      [[(id<IB>)NSApp activeDocument] removeConnector: _currentConnector];
      [_connectors removeObject:_currentConnector];
      [connectionsBrowser loadColumnZero];
    }
  else
    {
      if ([_currentConnector isKindOfClass:[NSNibControlConnector class]])
        {
	  int i, c;
	  NSArray *controlConnectors;

	  controlConnectors = [_connectors arrayWithObjectsRespondingYesToSelector:@selector(isKindOfClass:)
                                withObject:[NSNibControlConnector class]];
	   
	  for (i = 0, c = [controlConnectors count]; i < c; i++)
	    {
	      NSNibConnector *con = [controlConnectors objectAtIndex:i];
	      [[(id<IB>)NSApp activeDocument] removeConnector: con];
	      [_connectors removeObject:con];
	    }
	  [_connectors addObject:_currentConnector];
	}
     else if ([_currentConnector isKindOfClass:[NSNibOutletConnector class]])
       {
	 [_connectors addObject:_currentConnector];
       }
     else if ([_currentConnector isKindOfClass:[EOAspectConnector class]])
       {
	 [_connectors addObject:_currentConnector];
     	 [[(id<IB>)NSApp activeDocument]
	  		attachObject:_association toParent:object];
       }
     
     [self _selectAction:[_currentConnector label]];
     [[(id<IB>)NSApp activeDocument] addConnector: _currentConnector];
     [connectionsBrowser loadColumnZero];
     [self selectedConnector];
   }
  
  [[(id<IB>)NSApp activeDocument] touch];
  [self updateButtons];
}
@end

