/**
 EOMEDocument.m <title>EOMEDocument Class</title>
 
 Copyright (C) Free Software Foundation, Inc.
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
 <license>
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
 </license>
 **/

#import "EOMEDocument.h"
#import "EOMEEOAccessAdditions.h"
#import "TableViewController.h"
#import "SQLGenerator.h"
#import "AdaptorsPanel.h"
#import "CodeGenerator.h"
#import <EOModeler/EOMInspectorController.h>
#import "DataBrowser.h"

static NSString * entitiesItem = @"Entities";
static NSString * storedProceduresItem = @"Procedures";

/** Notification sent when beginning consistency checks.
 * The notifications object is the EOModelerDocument.
 * The receiver should call -appendConsistencyCheckErrorText:
 * on the notifications object for any consistency check failures */
NSString *EOMCheckConsistencyBeginNotification =
@"EOMCheckConsistencyBeginNotification";

/** Notification sent when ending consistency checks.
 * The notifications object is the EOModelerDocument.
 * The receiver should call -appendConsistencyCheckSuccessText:
 * on the notifications object for any consistency checks that passed. */
NSString *EOMCheckConsistencyEndNotification =
@"EOMCheckConsistencyEndNotification";

/** Notification sent when beginning EOModel consistency checks.
 * The notifications object is the EOModelerDocument.
 * The receiver should call -appendConsistencyCheckErrorText: 
 * on the notifications object for any consistency check failures
 * the userInfo dictionary contains an EOModel instance for the 
 * EOMConsistencyModelObjectKey key. */
NSString *EOMCheckConsistencyForModelNotification =
@"EOMCheckConsistencyForModelNotification";
NSString *EOMConsistencyModelObjectKey = @"EOMConsistencyModelObjectKey";

@implementation EOMEDocument

+ (void) initialize
{
//  [entitiesItem retain];
//  [storedProceduresItem retain];
}


- (void) dealloc
{
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  // stop observing
  [self setSelectedObjects:nil];
  
  DESTROY(_outlineSelection);
  DESTROY(_eomodel);
  DESTROY(_topTableViewController);
  DESTROY(_bottomTableViewController);
  DESTROY(_procTableViewController);
  DESTROY(_entityNames);
  DESTROY(_selectedObjects);
  
  [super dealloc];
}

- (EOModel*) eomodel
{
  return _eomodel;
}

- (void) setEomodel:(EOModel*) model
{
  ASSIGN(_eomodel, model);
}

- (NSString *)windowNibName 
{
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"EOMEDocument";
}

- (NSButtonCell*) _cellWithImageNamed:(NSString*) aName
{
  NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];
  [cell setButtonType:NSSwitchButton];
  [cell setImagePosition:NSImageOnly];
  [cell setBordered:NO];
  [cell setBezeled:NO];
  [cell setAlternateImage:[NSImage imageNamed:aName]];
  [cell setControlSize: NSSmallControlSize];
  [cell setEditable:NO];

  return AUTORELEASE(cell);
}

- (void) initTopColumns
{
  NSTableColumn * column;
  NSButtonCell  * cell;
  
  column = [_topTableView tableColumnWithIdentifier:@"isPrimaryKey"];
  if (column) {
    cell = [self _cellWithImageNamed:@"Key_On"];
    [column setEditable: NO];
    [column setDataCell:cell];

  }
  column = [_topTableView tableColumnWithIdentifier:@"isClassProperty"];
  if (column) {
    cell = [self _cellWithImageNamed:@"ClassProperty_On"];
    [column setEditable: NO];
    [column setDataCell:cell];
    
  }
  column = [_topTableView tableColumnWithIdentifier:@"allowNull"];
  if (column) {
    cell = [self _cellWithImageNamed:@"AllowsNull_On"];
    [column setEditable: NO];
    [column setDataCell:cell];
    
  }

  column = [_topTableView tableColumnWithIdentifier:@"isUsedForLocking"];
  if (column) {
    cell = [self _cellWithImageNamed:@"Locking_On"];
    [column setEditable: NO];
    [column setDataCell:cell];
    
  }
  
}

- (void) initBottomColumns
{
  NSTableColumn * column;
  NSButtonCell  * cell;
  
  column = [_bottomTableView tableColumnWithIdentifier:@"isToMany"];
  if (column) {
    cell = [self _cellWithImageNamed:@"toMany"];
    [cell setImage:[NSImage imageNamed:@"toOne"]];
    [cell setImageDimsWhenDisabled:NO];
    [cell setEnabled:NO];
    [column setEditable: NO];
    [column setDataCell:cell];
    
  }
  column = [_bottomTableView tableColumnWithIdentifier:@"isClassProperty"];
  if (column) {
    cell = [self _cellWithImageNamed:@"ClassProperty_On"];
    [column setEditable: NO];
    [column setDataCell:cell];
    
  }
}

- (void) initStoredProcedureColumns
{
  NSTableColumn * column;
  NSButtonCell  * cell;
  
  column = [_storedProcedureTableView tableColumnWithIdentifier:@"parameterDirection"];
  if (column) {
    cell = [_storedProcDirectionUp cell];
    [column setEditable: NO];
    [column setDataCell:cell];    
  }
}


- (void) updateItemsInPopUp:(NSPopUpButton*) popUpB forEOClass:(Class) eoclass tableView:(NSTableView*) tableView
{
  NSDictionary * columnDict = [eoclass allColumnNames];
  NSArray      * sortedTags = [[columnDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
  NSEnumerator * enumer = [sortedTags objectEnumerator];
  NSString     * currentKey = nil;
  NSDictionary * currentDict = nil;
  NSMenu       * menu = [popUpB menu];
  
  [popUpB removeAllItems];
  
  NSMenuItem * item = [NSMenuItem alloc];
  
  [item initWithTitle:@"" 
               action:NULL 
        keyEquivalent:@""];
  
  [item setTag:1000];
  [item setImage:[NSImage imageNamed:@"NSAddTemplate"]]; // @"gear"
  [menu addItem:item];
  [item release];

 // [[[NSImage imageNamed:@"NSAddTemplate"] TIFFRepresentation] writeToFile:@"/tmp/NSAddTemplate.tiff" atomically:NO];
  
  while ((currentKey = [enumer nextObject])) {
    currentDict = [columnDict objectForKey:currentKey];
    NSTableColumn * col = [tableView tableColumnWithIdentifier:[currentDict objectForKey:@"key"]];
                           
    item = [NSMenuItem alloc];
    
    [item initWithTitle:[currentDict objectForKey:@"name"] 
                 action:NULL 
          keyEquivalent:@""];
    
    [item setTag:[currentKey integerValue]];
    if ([col isHidden]) {
      [item setState:NSOffState];
    } else {
      [item setState:NSOnState];
    }
    
    [menu addItem:item];
    
    [item release];
    
  }

}

- (void) makeCornerViews
{
  NSView  * cornerView = [_topTableView cornerView];

  [[_topVisibleColumnsPopUp cell] setArrowPosition:NSPopUpNoArrow];
  [_topVisibleColumnsPopUp setFrame:[cornerView frame]];
  [_topVisibleColumnsPopUp setImagePosition:NSImageOnly];
  [_topVisibleColumnsPopUp setBezelStyle:NSShadowlessSquareBezelStyle];
  
  [_topTableView setCornerView:_topVisibleColumnsPopUp];
  
  // bottom table view
  
  cornerView = [_bottomTableView cornerView];
  
  [[_bottomVisibleColumnsPopUp cell] setArrowPosition:NSPopUpNoArrow];
  [_bottomVisibleColumnsPopUp setFrame:[cornerView frame]];
  [_bottomVisibleColumnsPopUp setImagePosition:NSImageOnly];
  [_bottomVisibleColumnsPopUp setBezelStyle:NSShadowlessSquareBezelStyle];
  
  [_bottomTableView setCornerView:_bottomVisibleColumnsPopUp];
  
  // stored proc table view

  cornerView = [_storedProcedureTableView cornerView];
  
  [[_storedProcVisibleColumnsPopUp cell] setArrowPosition:NSPopUpNoArrow];
  [_storedProcVisibleColumnsPopUp setFrame:[cornerView frame]];
  [_storedProcVisibleColumnsPopUp setImagePosition:NSImageOnly];
  [_storedProcVisibleColumnsPopUp setBezelStyle:NSShadowlessSquareBezelStyle];
  
  [_storedProcedureTableView setCornerView:_storedProcVisibleColumnsPopUp];
  
}

- (void) awakeFromGSMarkup
{
  //NSImage * smartImage = [NSImage imageNamed:@"gear"];
  
//  [[smartImage TIFFRepresentation] writeToFile:@"/tmp/NSSmartBadgeTemplate.tiff" atomically:NO];

  [_outlineView setHeaderView:nil];
  
  [self makeCornerViews];
  [self updateItemsInPopUp:_topVisibleColumnsPopUp
                forEOClass:[EOAttribute class]
                 tableView:_topTableView];

  [self updateItemsInPopUp:_bottomVisibleColumnsPopUp
                forEOClass:[EORelationship class]
                 tableView:_bottomTableView];
  
  [self updateItemsInPopUp:_storedProcVisibleColumnsPopUp
                forEOClass:[EOStoredProcedure class]
                 tableView:_storedProcedureTableView];
  
//  [_storedProcDirectionUp setBezelStyle: NSRegularSquareBezelStyle];
  [_storedProcDirectionUp setBordered: NO];

  
  [self initTopColumns];
  [self initBottomColumns];
  [self initStoredProcedureColumns];

  
  _topTableViewController = [TableViewController new];
  _bottomTableViewController = [TableViewController new];
  _procTableViewController = [TableViewController new];
  
  [_topTableView setDataSource:_topTableViewController];
  [_topTableView setDelegate:_topTableViewController];
  
  [_bottomTableView setDataSource:_bottomTableViewController];
  [_bottomTableView setDelegate:_bottomTableViewController];

  [_storedProcedureTableView setDataSource:_procTableViewController];
  [_storedProcedureTableView setDelegate:_procTableViewController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(outlineViewSelectionDidChange:) 
                                               name:NSOutlineViewSelectionDidChangeNotification 
                                             object:_outlineView];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(outlineViewItemWillCollapse:) 
                                               name:NSOutlineViewItemWillCollapseNotification 
                                             object:_outlineView];
  

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewSelectionDidChange:) 
                                               name:NSTableViewSelectionDidChangeNotification 
                                             object:_topTableView];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewSelectionDidChange:) 
                                               name:NSTableViewSelectionDidChangeNotification 
                                             object:_bottomTableView];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewSelectionDidChange:) 
                                               name:NSTableViewSelectionDidChangeNotification 
                                             object:_storedProcedureTableView];
  
}


- (void) setSelectedObjects:(NSArray*) aValue
{
  
  [self stopObserving];
      
  ASSIGN(_selectedObjects, aValue);
  
  [self startObserving];  
  
  // we will probably have the definition of EOModelerSelectionChanged somewhere else
  // so we just use a string for now
  [[NSNotificationCenter defaultCenter] postNotificationName:@"EOModelerSelectionChanged" 
                                                      object:self];  
}

- (NSArray*) selectedObjects
{
  return _selectedObjects;
}

- (void) startObserving
{
  if ((_selectedObjects) && ([_selectedObjects count])) {
    NSEnumerator * objEnumer = [_selectedObjects objectEnumerator];
    id currentObj = nil;
    
    while ((currentObj = [objEnumer nextObject])) {
      NSEnumerator * keyEnumer = [[currentObj observerKeys] objectEnumerator];
      NSString     * currentKey;
      while ((currentKey = [keyEnumer nextObject])) {
        [currentObj addObserver:self
                     forKeyPath:currentKey
                        options:(NSKeyValueObservingOptionNew |
                                 NSKeyValueObservingOptionOld)
                        context:NULL];
        
      }
    }
  }  
}

- (void) stopObserving
{
  if ((_selectedObjects) && ([_selectedObjects count])) {
    NSEnumerator * objEnumer = [_selectedObjects objectEnumerator];
    id currentObj = nil;
    
    while ((currentObj = [objEnumer nextObject])) {
      NSEnumerator * keyEnumer = [[currentObj observerKeys] objectEnumerator];
      NSString     * currentKey;
      while ((currentKey = [keyEnumer nextObject])) {
        [currentObj removeObserver:self
                        forKeyPath:currentKey];
        
      }
    }
  }  
}


- (void) setOutlineSelection:(id) aValue
{
  ASSIGN(_outlineSelection, aValue);
  
  if ([_outlineSelection class] == [EOStoredProcedure class]) {
    [_tabView selectTabViewItemAtIndex:1];
    
    [_procTableViewController setRepresentedObject:[(EOStoredProcedure*)_outlineSelection arguments]];
    NSLog(@"%s:%@",__PRETTY_FUNCTION__, [(EOStoredProcedure*)_outlineSelection arguments]);
    [_storedProcedureTableView reloadData];

  } else {
    [_tabView selectTabViewItemAtIndex:0];
    
    [_topTableViewController setRepresentedObject:[_outlineSelection attributes]];
    [_topTableView reloadData];
    
    [_bottomTableViewController setRepresentedObject:[_outlineSelection relationships]];
    [_bottomTableView reloadData];
  }
  
  if (!aValue) {
    [self setSelectedObjects:[NSArray arrayWithObject:_eomodel]];
  } else {
    [self setSelectedObjects:[NSArray arrayWithObject:aValue]];
  }
}

- (id) outlineSelection
{
  return _outlineSelection;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
  NSLog(@"%s:%@", __PRETTY_FUNCTION__, typeName);

  NS_DURING {
  
  [_eomodel writeToFile: [absoluteURL path]];
  
  } NS_HANDLER {
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[localException reason]
                                forKey:NSLocalizedDescriptionKey];

    *outError = [NSError errorWithDomain:@"EOModel"
                                    code:1
                                userInfo:userInfo];
    return NO;
  } NS_ENDHANDLER;
  
  return YES;
}


//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
//{
//  NSLog(@"%s:%@", __PRETTY_FUNCTION__, typeName);
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, 
  // ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or
  // -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems,
  // you should use the deprecated API -dataRepresentationOfType:.
  // In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

//    return nil;
//}

//- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
//{
//  NSLog(@"%s:%@", __PRETTY_FUNCTION__, typeName);
//
//  // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.
//
//    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
//    
//    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. 
//  // In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
//    
//    return YES;
//}


- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError 
{  
  ASSIGN(_eomodel, [EOModel modelWithContentsOfFile: [absoluteURL path]]);
  ASSIGN(_entityNames,[_eomodel entityNames]);
  
  return YES;  
}

#pragma mark -
#pragma mark Outline

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (!item) {
    // top level entities and storedProcedures
    return 2;
  }
  
  if ((item == entitiesItem)) {
    return [[_eomodel entityNames] count];
  }
  
  if ((item == storedProceduresItem)) {
    return [[_eomodel storedProcedureNames] count];
  }
  
  return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if (!item) {
    return YES;
  }
  if (((item == entitiesItem)) || ((item == storedProceduresItem))) {
    return YES;
  }
  
  return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  if (!item) {
    if ((index == 0)) {
      return entitiesItem;
    }
    if ((index == 1)) {
      return storedProceduresItem;
    }
  }
  
  if ((item == entitiesItem)) {
    return [[_eomodel entityNames] objectAtIndex:index];
  }
  
  if ((item == storedProceduresItem)) {
    return [[_eomodel storedProcedureNames] objectAtIndex:index];
  }
  
  
  return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  
  if (!item) {
    // top level entities and storedProcedures
//    return @"EOModel";
    return nil;  
  }
  if ((item == entitiesItem)) {
    return entitiesItem;
  }
  
  if ((item == storedProceduresItem)) {
    return storedProceduresItem;
  }
//  
//  NSLog(@"%s (%d)", __PRETTY_FUNCTION__, [outlineView rowForItem:item]);
//  
//  if ([item respondsToSelector:@selector(name)]) {
//    return [item name];
//  }
//  
 
  return item;
  
  
//  return nil;
}

#pragma mark -

- (NSString*) pathForOutlineSelection
{
  NSMutableArray * myArray = [NSMutableArray array];
  id parentItem = [_outlineView itemAtRow:[_outlineView selectedRow]];
  
  if ((parentItem)) {
    
    [myArray addObject:parentItem];
    
    while (YES) {
      parentItem = [_outlineView parentForItem:parentItem];
      if (parentItem) {
        [myArray insertObject:parentItem atIndex:0];
      } else {
        break;
      }
    }
  }
  
  return [myArray componentsJoinedByString:@"."];
}


/// KVC

- (id) eomObjectForKeyPath:(NSString*) path
{
  NSString * newPath = nil;
  
  if (([path hasPrefix:entitiesItem]) && ([path length] > ([entitiesItem length] + 1))) {
    newPath = [path substringFromIndex:[entitiesItem length]+1];    
    return [_eomodel entityNamed:newPath];
  } else if ((([path hasPrefix:storedProceduresItem]) && ([path length] > ([storedProceduresItem length] + 1)))) {
    newPath = [path substringFromIndex:[storedProceduresItem length]+1];
    return [_eomodel storedProcedureNamed:newPath];
  } 
  
  return nil;
}

#pragma mark -
#pragma mark delegates 

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  id newSelection = nil;
  
  newSelection = [self eomObjectForKeyPath:[self pathForOutlineSelection]];
  
  [self setOutlineSelection:newSelection];
  
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
  NSOutlineView * outlineView = [notification object];
  NSUInteger      index = 0;
  NSInteger       intIndex = 0;
  NSString      * collapseObj = [[notification userInfo] objectForKey:@"NSObject"];
  
  intIndex = [outlineView rowForItem:collapseObj];
  if (intIndex > -1) {
    index = intIndex;
  }
  
  [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex: index]
           byExtendingSelection:NO];
  
}

- (void)tableViewSelectionDidChange:(NSNotification *) notification
{
  NSArray * selectedObjects = nil;

  if (([notification object] == _topTableView)) {
    selectedObjects = [_topTableViewController selectedObjects];
    
    if ([selectedObjects count] > 0) {
      [self setSelectedObjects:selectedObjects];
      
      [_bottomTableView selectRowIndexes:[NSIndexSet indexSet] 
                    byExtendingSelection:NO];
    }
  }
  
  if (([notification object] == _bottomTableView)) {
    selectedObjects = [_bottomTableViewController selectedObjects];
    
    if ([selectedObjects count] > 0) {
      [self setSelectedObjects:selectedObjects];
      
      [_topTableView selectRowIndexes:[NSIndexSet indexSet] 
                 byExtendingSelection:NO];
    }
  }

  if (([notification object] == _storedProcedureTableView)) {
    selectedObjects = [_procTableViewController selectedObjects];
    
    if ([selectedObjects count] > 0) {
      [self setSelectedObjects:selectedObjects];      
    }
  }
  
}

- (IBAction) tableViewClicked:(NSTableView*) tv
{
 // NSLog(@"%s:%@",__PRETTY_FUNCTION__, tv);
}

#pragma mark -
#pragma mark Pop ups 

- (IBAction) visibleColumnsChanged:(id) sender
{
  NSMenuItem    * item = [sender selectedItem];
  NSDictionary  * dict = nil;
  NSString      * identifier = nil;  
  NSTableColumn * col = nil;
  
  if (sender == _topVisibleColumnsPopUp) {
    dict = [[EOAttribute allColumnNames] objectForKey:[NSNumber numberWithInteger:[item tag]]];
    identifier = [dict objectForKey:@"key"];
    col = [_topTableView tableColumnWithIdentifier:identifier];
  } 
  
  if (sender == _bottomVisibleColumnsPopUp) {
    dict = [[EORelationship allColumnNames] objectForKey:[NSNumber numberWithInteger:[item tag]]];
    identifier = [dict objectForKey:@"key"];
    col = [_bottomTableView tableColumnWithIdentifier:identifier];
  }

  if (sender == _storedProcVisibleColumnsPopUp) {
    dict = [[EOStoredProcedure allColumnNames] objectForKey:[NSNumber numberWithInteger:[item tag]]];
    identifier = [dict objectForKey:@"key"];
    col = [_storedProcedureTableView tableColumnWithIdentifier:identifier];
  }
  

  if (([item state] == NSOnState)) {
    [item setState:NSOffState];
    [col setHidden:YES];
  } else {
    [item setState:NSOnState];
    [col setHidden:NO];
  }
}

- (IBAction) directionChanged:(id) sender
{
  NSMenuItem    * item = [_storedProcDirectionUp selectedItem];
  NSLog(@"%s:%d", __PRETTY_FUNCTION__, [item tag]);
}

#pragma mark -
#pragma mark Menu Items
- (void) showInspector:(id)sender
{
  [EOMInspectorController showInspector];
}

- (void) generateSQL:(id)sender
{
  [[SQLGenerator sharedGenerator] openSQLGeneratorForDocument:self];
}


- (void) setAdaptor:(id)sender
{
  NSString *adaptorName;
  EOAdaptor *adaptor;
  AdaptorsPanel *adaptorsPanel = [[AdaptorsPanel alloc] init];
  
  adaptorName = [adaptorsPanel runAdaptorsPanel];
  RELEASE(adaptorsPanel);
  
  if (!adaptorName)
    return;
  
  [_eomodel setAdaptorName: adaptorName]; 
  adaptor = [EOAdaptor adaptorWithName: adaptorName];
  [_eomodel setConnectionDictionary:[adaptor runLoginPanel]];
  
}

- (void)createTemplates:(id)sender
{
  CodeGenerator * codeGen = [[CodeGenerator new] autorelease];
  
  [codeGen generate];
  
}

- (void)addAttribute:(id)sender
{
  EOAttribute       *attrb;
  EOEntity          *entity;
  EOStoredProcedure *sProc = nil;
  NSMutableArray    *attributes;
  NSUInteger         count;
  
  if ((!_outlineSelection) || 
      (([_outlineSelection class] != [EOEntity class]) && ([_outlineSelection class] != [EOStoredProcedure class]))) {
    return;
  }
  
  if (([_outlineSelection class] == [EOStoredProcedure class])) {
    sProc = (EOStoredProcedure*) _outlineSelection;
    attributes = (NSMutableArray*)[sProc arguments];
    if (!attributes) {
      attributes = [NSMutableArray array];
    } else {
      attributes = [NSMutableArray arrayWithArray:attributes];
    }

    NSLog(@"%s:%@",__PRETTY_FUNCTION__, attributes);
  } else {
    entity = (EOEntity*) _outlineSelection;
    attributes = (NSMutableArray*) [entity attributes];
  }

  count = [attributes count];
  
  attrb = [[EOAttribute alloc] init];   
  [attrb setName: [NSString stringWithFormat: @"Attribute%d", count]]; 
  [attrb setColumnName: [attrb name]]; 
  [attrb setValueClassName: @"NSString"]; 
  [attrb setExternalType: @""]; 
  
  if (sProc) {
    [attributes addObject:attrb];
    [sProc setArguments:attributes];
    [_procTableViewController setRepresentedObject:[sProc arguments]];
    [_storedProcedureTableView reloadData];
  }else {
    [entity addAttribute:attrb];
    [_topTableView reloadData];
  }

  RELEASE(attrb);
  
}

- (IBAction)addProcedure:(id)sender
{
  EOStoredProcedure * sProc;
  NSUInteger          count;
  count = [[_eomodel storedProcedureNames] count];
  
  sProc = [[EOStoredProcedure alloc] initWithName:[NSString stringWithFormat:@"Procedure%d", count]];

  [_eomodel addStoredProcedure:sProc];
  RELEASE(sProc);

  [_outlineView reloadData];
}

- (IBAction)addEntity:(id)sender
{
  EOEntity          * newEntity;
  NSUInteger          count;
  
  count = [[_eomodel entityNames] count];
  newEntity = [[EOEntity alloc] init]; 
  [newEntity setName:[NSString stringWithFormat:@"Entity%d", count]];
  [newEntity setClassName:@"EOGenericRecord"];
  
  [_eomodel addEntity:newEntity];
  RELEASE(newEntity);
  
  [_outlineView reloadData];
}

- (IBAction)addRelationship:(id)sender
{
  EORelationship    * newRel;
  EOEntity          * selectedEntity;
  NSUInteger          count = 0;

  selectedEntity = (EOEntity*) _outlineSelection;
  
  if ([selectedEntity relationships]) {
    count = [[selectedEntity relationships] count];
  }

  newRel = [[EORelationship alloc] init];
  
  [newRel setName:[NSString stringWithFormat:@"Relationship%d", count]];
  
  [selectedEntity addRelationship:newRel];
  
  RELEASE(newRel);
  
  [_bottomTableViewController setRepresentedObject:[selectedEntity relationships]];
  [_bottomTableView reloadData];
}

- (IBAction)dataBrowser:(id)sender
{
  EOEntity * entity = [self outlineSelection];
  
  if ((entity) && ([entity class] == [EOEntity class])) {
    DataBrowser * sharedBrowser = [DataBrowser sharedBrowser];
    
    [sharedBrowser setEntity:entity];

  }
  
}

- (IBAction)delete:(id)sender
{
}

#pragma mark -
#pragma mark key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([object isKindOfClass:[EOAttribute class]]) {
    // optimize this?
    [_topTableView reloadData];
    [_storedProcedureTableView reloadData];
  }

  if ([object isKindOfClass:[EORelationship class]]) {
    [_bottomTableView reloadData];
  }

  if ([object isKindOfClass:[EOEntity class]]) {
    [_outlineView reloadData];
  }

  if ([object isKindOfClass:[EOStoredProcedure class]]) {
    [_outlineView reloadData];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"EOModelerSelectionChanged" 
                                                      object:self];  

 // NSLog(@"%s: %@, %@, %@", __PRETTY_FUNCTION__, keyPath, object, change);
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
  
  SEL action = [anItem action];
  //NSLog(@"%s: %@", __PRETTY_FUNCTION__, anItem);


  if ((action == @selector(addAttribute:))) {    
      if ((!_outlineSelection) || 
          (([_outlineSelection class] != [EOEntity class]) && ([_outlineSelection class] != [EOStoredProcedure class]))) {
        return NO;
      }
  }

  if ((action == @selector(addRelationship:))) {    
    if ((!_outlineSelection) || 
        ([_outlineSelection class] != [EOEntity class])) {
      return NO;
    }
  }

  if ((action == @selector(delete:))) {    
    if (!_outlineSelection) {
      return NO;
    }
  }
  
  return [super validateUserInterfaceItem:anItem];
}

@end
