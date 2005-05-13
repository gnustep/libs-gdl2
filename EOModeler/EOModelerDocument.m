/**
  EOModelerDocument.m <title>EOModelerDocument Class</title>
  
  Copyright (C) 2005 Free Software Foundation, Inc.
 
  Author: Matt Rice <ratmice@yahoo.com>
  Date: April 2005
  
  This file is part of the GNUstep Database Library.
  
  <license>
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.
 
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
 
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
  </license>
**/

#include <AppKit/NSOpenPanel.h>

#include <EOInterface/EODisplayGroup.h>

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EORelationship.h>

#include <EOControl/EOEditingContext.h>

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSException.h>

#include "EOModeler/EODefines.h"
#include "EOModeler/EOModelerDocument.h"
#include "EOModeler/EOModelerEditor.h"
#include "EOModeler/EOModelerApp.h"

static Class      _defaultEditorClass;
static EOModelerEditor *_currentEditorForDocument;

@interface EOModelerApp (PrivateStuff)
- (void) _setActiveDocument:(EOModelerDocument *)newDocument;
@end

@interface NSArray (EOMAdditions)
- (id) firstSelectionOfClass:(Class)aClass;
@end
@implementation NSArray (EOMAdditions)
- (id) firstSelectionOfClass:(Class)aClass
{
  int i, c;
  id obj;
  for (i = 0, c = [self count]; i < c; i++)
    {
      obj = [self objectAtIndex:i];
      if ([obj isKindOfClass:aClass])
        {
          break;
        }

      if ([obj isKindOfClass:[NSArray class]])
        {
          int j, d;
          for (j = 0, d = [obj count]; j < d; j++)
            {
              id obj2 = [obj objectAtIndex:j];

              if ([obj2 isKindOfClass:aClass])
                {
                  obj = obj2;
                  break;
                }
            }
        }
    }
  if (![obj isKindOfClass:aClass])
    {
      NSLog(@"blah:");
      for (i = 0; c < [self count]; i++)
	 NSLog(@"## %@", [self objectAtIndex:i]);
 /*     [[NSException exceptionWithName:NSInternalInconsistencyException
                               reason:[NSString stringWithFormat:@"Couldn't find a selected %@", aClass]
                             userInfo:[NSDictionary dictionaryWithObject:self forKey:@"array"]] raise];*/
      return nil;
    }
  
  return obj;
}
@end

@implementation EOModelerDocument 

- (id)initWithModel:(EOModel*)model
{
  if (self = [super init])
    {
      _model = RETAIN(model);
      _userInfo = nil;
      _editors = [[NSMutableArray alloc] init];
      _editingContext = [[EOEditingContext alloc] init];
      [_editingContext insertObject:model];
    }
  return self;
}

- (EOAdaptor *)adaptor
{
  NS_DURING
    return [EOAdaptor adaptorWithModel:_model];
  NS_HANDLER
    return nil;
  NS_ENDHANDLER
}

- (EOModel *)model;
{
  return _model;
}

- (EOEditingContext *)editingContext
{
  return _editingContext;
}

- (BOOL) isDirty
{

}

- (BOOL) prepareToSave
{

}

- (NSString *)documentPath
{
  return [[[EOMApp activeDocument] model] path];
}

- (BOOL)saveToPath:(NSString *)path
{
  if (![[path pathExtension] isEqual:@"eomodeld"])
    path = [path stringByAppendingPathExtension:@"eomodeld"];
  NS_DURING
    [_model writeToFile: path];
    return YES;
  NS_HANDLER
       NSRunAlertPanel(@"Error",@"Save failed: %@",@"Ok",NULL,NULL,[localException reason]);
    return NO;
  NS_ENDHANDLER
}

- (BOOL)checkCloseDocument
{

}

- (void)activate
{
  [EOMApp _setActiveDocument: self];
  [[_editors objectAtIndex:0] activate];

  //[[EOMApp currentEditor] activate];
 // int i,count=[_editors count];
 /* should we really activate the _defaultEditorClass or have some _currentEditor private variable? */
 /* for (i = 0; i < count; i++)
    { 
      EOModelerEditor *anEditor = [_editors objectAtIndex:i];
      if ([anEditor isKindOfClass: _defaultEditorClass])
        {
           [anEditor activate];
        }
    }
 */
}

/* Editors stuff */

- (NSArray *)editors
{
  return [NSArray arrayWithArray:_editors];
}

- (void)addEditor:(EOModelerEditor *)editor
{
  /* check if we already have an editor object? */
  [_editors addObject:editor];
}

- (void) closeEditor:(EOModelerEditor *)editor
{

}

- (BOOL)checkCloseEditor:(EOModelerEditor *)editor
{

}

- (EOModelerEditor *) addDefaultEditor
{
  EOModelerEditor *defaultEditor = [[_defaultEditorClass alloc] initWithDocument:self];
  [self addEditor: defaultEditor];
  _currentEditorForDocument = defaultEditor;
  RELEASE(defaultEditor);
  return defaultEditor;
}

- (void)addEntity:(id)sender
{
  EOAttribute *attrb;
  int entityCount = [[_model entities] count];
  EOEntity *newEntity = [[EOEntity alloc] init];
  
  if (![_editors containsObject:[EOMApp currentEditor]])
    {
      [[NSException  exceptionWithName:NSInternalInconsistencyException reason:@"currentEditor not in edited document exception" userInfo:nil] raise]; 
      return; 
    }
  
  
  [newEntity setName: entityCount ? [NSString stringWithFormat: @"Entity%i",entityCount + 1] : @"Entity"];
  [newEntity setClassName:@"EOGenericRecord"];
  attrb = [EOAttribute new];
  [attrb setName:@"Attribute"];
  [newEntity addAttribute:attrb];
  [_editingContext insertObject:newEntity];
  [_model addEntity:AUTORELEASE(newEntity)];
  [(EOModelerCompoundEditor *)[EOMApp currentEditor] viewSelectedObject];
}

- (void)addAttribute:(id)sender
{
  EOAttribute *attrb;
  EOModelerEditor *currEd = [EOMApp currentEditor];
  int attributeCount;
  EOEntity *entityObject;

  /* the currentEditor must be in this document */
  if (![_editors containsObject:currEd])
    {
      [[NSException  exceptionWithName:NSInternalInconsistencyException reason:@"currentEditor not in edited document exception" userInfo:nil] raise]; 
      return; 
    }
 
  entityObject = [[currEd selectionPath] firstSelectionOfClass:[EOEntity class]];
  attributeCount = [[entityObject attributes] count];
   
  attrb = [[EOAttribute alloc] init];   
  [attrb setName: attributeCount ? [NSString stringWithFormat: @"Attribute%i", attributeCount + 1] : @"Attribute"];
  [entityObject addAttribute:attrb];
  [_editingContext insertObject:attrb];
  //[[(EOModelerCompoundEditor *)[EOMApp currentEditor] activeEditor] setSelectionWithinViewedObject:[NSArray arrayWithObject: entityObject]];
  [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow:0.001]];
  [(EOModelerCompoundEditor *)[EOMApp currentEditor] viewSelectedObject];
}

- (void)addRelationship:(id)sender
{
  EORelationship *newRel;
  EOEntity *srcEntity;
  EOModelerEditor *currentEditor = [EOMApp currentEditor];
  int count;

  if (![_editors containsObject:currentEditor])
    {
      [[NSException  exceptionWithName:NSInternalInconsistencyException reason:@"currentEditor not in edited document exception" userInfo:nil] raise];
      return;
    }
  
  srcEntity = [[currentEditor selectionPath] firstSelectionOfClass:[EOEntity class]];
  count = [[srcEntity relationships] count];
  newRel = [[EORelationship alloc] init];  
  [newRel setName: count ? [NSString stringWithFormat:@"Relationship%i", count + 1] : @"Relationship"];
  [srcEntity addRelationship:newRel];
  [_editingContext insertObject:newRel];
  //[[(EOModelerCompoundEditor *)[EOMApp currentEditor] activeEditor] setSelectionWithinViewedObject:[NSArray arrayWithObject: srcEntity]];
  [(EOModelerCompoundEditor *)[EOMApp currentEditor] viewSelectedObject];
}

- (void)addFetchSpecification:(id)sender
{

}

- (void)addStoredProcedure:(id)sender
{

}

- (void)addArgument:(id)sender
{

}

- (BOOL)canFlattenSelectedAttribute;
{
  // no idea
}

- (void)flattenAttribute:(id)sender
{
  // likewise
}

- (void)save:(id)sender
{
  NSString *path;
  path = [_model path];
  if (!path)
    [self saveAs:self];
  else
    [self saveToPath:path];
}

- (void)saveAs:(id)sender
{
  NSString *path = [_model path];
  if (!path)
    {
      id savePanel = [NSSavePanel savePanel];
      int result = [savePanel runModal];

      if (result == NSOKButton)
	{
	  path = [savePanel filename];
	}
    }
  [self saveToPath: path];
}

- (void)revertToSaved:(id)sender
{

}

-(void)close:(id)sender
{

}

- (void)undo:(id)sender
{

}

- (void)redo:(id)sender
{

}

/* consitency checking stuff */
- (void) appendConcistencyCheckErrorText: (NSAttributedString *)errorText
{

}
- (void) appendConcistencyCheckSuccessText: (NSAttributedString *)successText
{

}

+ (void)setDefaultEditorClass:(Class)editorClass
{
  _defaultEditorClass = editorClass;
}

+ (Class)defaultEditorClass
{
  return _defaultEditorClass;
}

- (void)setUserInfo:(NSDictionary*)dictionary
{
  ASSIGN(_userInfo,dictionary); //just a guess
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (void) windowDidBecomeKey:(NSNotification *)notif
{
  [self activate];
}

@end

