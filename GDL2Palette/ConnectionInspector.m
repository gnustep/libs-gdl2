#include "ConnectionInspector.h"
#include "Foundation+Categories.h"

#include <EOAccess/EODatabaseDataSource.h>

#include <AppKit/NSBrowser.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSPopUpButton.h>

#include <EOInterface/EOAspectConnector.h>
#include <EOInterface/EOAssociation.h>
#include <EOInterface/EODisplayGroup.h>

#include <EOModeler/EOModelExtensions.h>

#include <Foundation/NSArray.h>

#include <GormCore/GormClassManager.h>
#include <GormCore/GormDocument.h>

#include <InterfaceBuilder/IBApplicationAdditions.h>
/* TODO get notifications for IB{Will,Did}RemoveConnectorNotification
 * and remove the object from the _objectToAssociation map table if
 * there are no more connectors for it */
static NSMapTable *_objectToAssociation;

@interface NSApplication(missingStuff)
- (GormClassManager *)classManager;
@end

@implementation GDL2ConnectionInspector
+ (void) initialize
{
  _objectToAssociation = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks,
		  				    NSObjectMapValueCallBacks,
		  	   			    0, [self zone]); 
}

- (NSButton *)okButton
{
  return nil;
}

- (id) init
{
  self = [super init];

  [NSBundle loadNibNamed:@"GDL2ConnectionInspector" owner:self];
  return self;
}

- (void) awakeFromNib
{
  [oaBrowser setMaxVisibleColumns:2];
  [oaBrowser setAllowsMultipleSelection:NO];
  [oaBrowser setHasHorizontalScroller:NO];
  [oaBrowser setTitled:NO];

  [connectionsBrowser setTitled:NO];
  [connectionsBrowser setHasHorizontalScroller:NO];
  [connectionsBrowser setMaxVisibleColumns:1];
  [connectionsBrowser setAllowsMultipleSelection:NO];
  
  [popUp removeAllItems];

}

- (void) setObject:(id)anObject
{
  NSArray *foo;
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

  DESTROY(_values);
  [self updateKeys];  
  [popUp removeAllItems];
  [popUp addItemWithTitle:@"Outlets"];
  
  foo = RETAIN([EOAssociation associationClassesForObject:anObject]);
  for (i = 0, c = [foo count]; i < c; i++)
    {
      Class assocSubclass = [foo objectAtIndex:i];
      NSString *title = [assocSubclass displayName];
      [popUp addItemWithTitle:title];
      [[popUp itemWithTitle:title] setRepresentedObject:assocSubclass];
    }
  RELEASE(foo);
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
      _keys = RETAIN([[NSApp classManager] allOutletsForObject:object]);
      _signatures = nil;
    }
  else
    {
      _keys = RETAIN([repObj aspects]);
      _signatures = RETAIN([repObj aspectSignatures]);
    }
}

- (void) updateValues
{
  id dest = [NSApp connectDestination];
  int selection = [oaBrowser selectedRowInColumn:0];
  NSString *sig = [_signatures objectAtIndex:selection];
  NSMutableArray *objs = [NSMutableArray new];
  EOEntity *ent = nil;
  
  sig = [sig uppercaseString];
  if ([dest isKindOfClass:[EODisplayGroup class]])
    ent = [(EODatabaseDataSource *)[(EODisplayGroup *)dest dataSource] entity];
  if ([sig length] && ent)
    {
      int i,c;
      for (i = 0, c = [sig length]; i < c; i++)
         {
           switch ([sig characterAtIndex:i])
             {
               case 'A':
                 [objs addObjectsFromArray: [ent classAttributes]];
                 break;
               case '1':
                 [objs addObjectsFromArray: [ent classToOneRelationships]];
                 break;
               case 'M':
		 [objs addObjectsFromArray: [ent classToManyRelationships]];
                 break;
             }
         }
     }
  RELEASE(_values);
  _values = objs;
             
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

  switch ([sender selectedColumn])
    {
      case 0:
	{
	  id dest;
	  
	  if ([[popUp selectedItem] representedObject]  == nil)
	    {
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
	          RELEASE(_values);
	          _values = RETAIN([[NSApp classManager] allActionsForObject: dest]);
	          if ([_values count] > 0)
	            {
	              conn = [NSNibControlConnector new];
		      [conn setSource: object];
		      [conn setDestination: [NSApp connectDestination]];
		      [conn setLabel: [_values objectAtIndex:0]];
		      AUTORELEASE(conn);
		    }
	          if (_currentConnector != conn)
		    ASSIGN(_currentConnector, conn);
	          [self _selectAction: [conn label]];
	        }
	      else
	        {
	          BOOL found = NO;
	          NSString *title = [[sender selectedCell] stringValue];
		  NSArray *outletConnectors;
		  
		  outletConnectors = [_connectors arrayWithObjectsRespondingYesToSelector:@selector(isKindOfClass:)
			  	withObject:[NSNibOutletConnector class]];
		  for (i = 0, c = [outletConnectors count]; i < c; i++)
		    {
		      conn = [outletConnectors objectAtIndex:i];
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
	}
	break;
      case 1:
      if ([[popUp selectedItem] representedObject]  == nil)
 	{
	  BOOL found = NO;
	  NSString *title = [[sender selectedCell] stringValue];
	  NSArray *controlConnectors;

	  controlConnectors = [_connectors arrayWithObjectsRespondingYesToSelector:@selector(isKindOfClass:)
			  	withObject:[NSNibControlConnector class]];
	   
	  for (i = 0, c = [controlConnectors count]; i < c; i++)
	    {
	      NSNibConnector *con = [controlConnectors objectAtIndex:i];
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
	  NSString *key = [[sender selectedCell] stringValue];
	  NSString *label = [NSString stringWithFormat:@"%@ - %@", aspectName, key];
	  NSArray *aspectConnectors;

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
	      EOAssociation *assoc;

	      assoc = NSMapGet(_objectToAssociation, object);
	      
	      if (!assoc)
	        {
  		  Class assocClass = [[popUp selectedItem] representedObject];
		  assoc = [[assocClass alloc] initWithObject:object];
		  NSMapInsert(_objectToAssociation, object, assoc);
		}
	      
	      [assoc bindAspect:aspectName
		   displayGroup:[NSApp connectDestination]
		   	    key:key];

	      RELEASE(_currentConnector);
	      _currentConnector = [[EOAspectConnector alloc] 
		      			initWithAssociation:assoc
						 aspectName:aspectName];
	      [_currentConnector setSource:object];
	      [_currentConnector setDestination: [NSApp connectDestination]];
	      [_currentConnector setLabel:label];
	    }
	}
	break;
    }
  [self updateButtons];
}

- (void) selectedOutletOrAction
{
  NSString *path;
  NSString *name = [[(id <IB>)NSApp activeDocument] nameForObject:[_currentConnector destination]];
  path = [@"/" stringByAppendingString:[_currentConnector label]];
  path = [path stringByAppendingFormat:@" (%@)", name];
  [connectionsBrowser setPath:path];
}

- (void) updateButtons
{
  
  if (!_currentConnector)
    {
      [okButton setState: NSOffState];
    }
  else
    {
      id src, dest;
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
  BOOL found;

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
	      NSString *path;
	      
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

  path = [@"/" stringByAppendingString:[_currentConnector label]];
  if ([_currentConnector isKindOfClass: [NSNibControlConnector class]])
    {
      path = [@"/target" stringByAppendingString:path];
    }
  [oaBrowser setPath:path];
  [NSApp displayConnectionBetween:object and:[_currentConnector destination]];
}

- (int) browser:(NSBrowser *)browser
numberOfRowsInColumn:(int)column
{
  id repObj = [[popUp selectedItem] representedObject];
  if (browser == oaBrowser)
    switch(column)
      {
        case 0:
	  return [_keys count];
          break;
        case 1:
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
	      return [_values count];
	    }
	  break;
        default:
	  [[NSException exceptionWithName:NSInternalInconsistencyException
		  		reason:@"uhhhhh should be column 0 or 1...."
				userInfo: nil] raise];
  	  return 0;
	  break;
      }
  else if (browser == connectionsBrowser)
    return [_connectors count];
}

- (void) browser:(NSBrowser *)sender
willDisplayCell:(id)cell atRow:(int)row column:(int)column
{
  id repObj = [[popUp selectedItem] representedObject];
  if (sender == oaBrowser)
    switch (column)
      {
        case 0:
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
	  break;
	case 1:
	  if (repObj == nil)
	    {
              if ([[[sender selectedCellInColumn:0] stringValue] isEqual:@"target"])
	        {
		  [cell setLeaf:YES];
		  [cell setStringValue: [_values objectAtIndex:row]];
		  [cell setEnabled:YES];
	        }
	    }
	  else
	    {
		[cell setLeaf:YES]; // TODO relationships should be NO...
	        [cell setStringValue: [(EOAttribute *)[_values objectAtIndex:row] name]];
		[cell setEnabled:YES];
	    }
	  break;
      }
  else if (sender == connectionsBrowser)
    {
      int i, c;
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
//      [_currentConnector setDestination:nil];
//      [_currentConnector setLabel:nil];
      [_connectors removeObject:_currentConnector];
      [connectionsBrowser loadColumnZero];
    }
  else
    {
      NSString *path;
      id dest;
     
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

