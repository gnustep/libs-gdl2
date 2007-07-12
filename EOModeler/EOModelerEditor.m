/**
  EOModelerEditor.m <title>EOModelerEditor Classes</title>
  
  Copyright (C) 2005 Free Software Foundation, Inc.
 
  Author: Matt Rice <ratmice@gmail.com>
  Date: April 2005
  
  This file is part of the GNUstep Database Library.
  
  <license>
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 3 of the License, or (at your option) any later version.
 
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
 
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
  </license>
**/


#include "EOModeler/EOModelerEditor.h"
#include "EOModeler/EOModelerDocument.h"
#include "EOModeler/EOModelerApp.h"

#include <EOControl/EOObserver.h>

#include <AppKit/NSView.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSRunLoop.h>

@implementation EOModelerEditor
- (void) dealloc
{
  [super dealloc];
}

- (id)initWithDocument:(EOModelerDocument *)document
{
  if ((self = [super init]))
    {
      _document = document;
      _selectionWithinViewedObject = [NSArray new];
    }
  return self;
}

- (EOModelerDocument *)document
{
  return _document; 
}

/** Subclassses should implement, by default throws an exception */
- (void)setSelectionPath:(NSArray *)newSelection
{
  [self subclassResponsibility: _cmd];
}

/** Subclassses should implement, by default throws an exception */
- (NSArray *)selectionPath
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/** Subclassses should implement, by default throws an exception */
- (void)activate
{
  [self subclassResponsibility: _cmd];
}

/** Subclassses should implement, by default throws an exception */
- (NSArray *)selectionWithinViewedObject
{
  [self subclassResponsibility: _cmd];
  return [NSArray array];
}

/** Subclassses should implement, by default throws an exception */
- (void)setSelectionWithinViewedObject:(NSArray *)newSelection
{
  [self subclassResponsibility: _cmd];
}

/** Subclassses should implement, by default throws an exception */
- (void)setViewedObjectPath:(NSArray *)newPath
{
  [self subclassResponsibility: _cmd];
}

/** Subclassses should implement, by default throws an exception */
- (NSArray *)viewedObjectPath
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (void) debugSelectionPath
{
  int i,j;
  NSArray *_selectionPath = [self selectionPath];
  for (i = 0; i < [_selectionPath count]; i++)
    {
      id obj = [_selectionPath objectAtIndex:i];

      if (![obj isKindOfClass:[NSArray class]])
      NSLog(@"%i %@(%@)", i, [obj class], [obj name]);
      else
    	{
	  for (j = 0; j < [obj count]; j++)
	     {
		id obj2 = [obj objectAtIndex:j];
		NSLog(@"* %i %@(%@)", j, [obj2 class], [obj2 name]);
	     }
	}
    }
  printf("\n\n");
}
@end

@implementation EOModelerCompoundEditor 
- (void) dealloc
{
  RELEASE(_editors);
  RELEASE(_viewedObjectPath);
  RELEASE(_selectionWithinViewedObject);
  [super dealloc];
}
- (id) initWithDocument:(id)doc
{
  self = [super initWithDocument:doc];
  _editors = [[NSMutableArray alloc] init];
  _activeEditor = nil;
  _viewedObjectPath = [[NSArray alloc] initWithObjects:[doc model], nil];
  return self;
}

- (void) selectionDidChange
{
  [[NSNotificationCenter defaultCenter]
	 postNotificationName:EOMSelectionChangedNotification
                       object:_document];
}

- (EOModelerEmbedibleEditor *)activeEditor
{
  return _activeEditor;
}

- (void)activateEditorWithClass:(Class)embedibleEditorClass
{
  int i, count = [_editors count];
  for (i = 0; i < count; i++)
    {
      EOModelerEmbedibleEditor *anEditor = [_editors objectAtIndex:i];
      if ([anEditor isKindOfClass: embedibleEditorClass])
        {
          [anEditor activate];
          _activeEditor = anEditor;
        }
    }   
}

- (void)activateEmbeddedEditor:(EOModelerEmbedibleEditor *)editor
{
  unsigned int index = [_editors indexOfObjectIdenticalTo: editor];
  if (index == NSNotFound)
    {
      [_editors addObject: editor];
    }
  [editor activate];
  _activeEditor = editor;
}

- (EOModelerEmbedibleEditor *)embedibleEditorOfClass:(Class)editorClass
{
  int i, count = [_editors count];
  for (i = 0; i < count; i++)
    {
      EOModelerEmbedibleEditor *anEditor = [_editors objectAtIndex:i];
      if ([anEditor isKindOfClass: editorClass])
        {
	   return anEditor;
	}
    }
 {
   EOModelerEmbedibleEditor *newEditor = [[editorClass alloc] initWithParentEditor:self]; 
   [self registerEmbedibleEditor: newEditor];
   RELEASE(newEditor);
   return newEditor;
 }
}


- (void)registerEmbedibleEditor:(EOModelerEmbedibleEditor *)editor
{
  [_editors addObject:editor];
}


/* getting the selection */
- (NSArray *)selectionPath
{
  return [_viewedObjectPath arrayByAddingObject:_selectionWithinViewedObject];
}

- (NSArray *) viewedObjectPath
{
  return _viewedObjectPath;
}
- (NSArray *)selectionWithinViewedObject
{
  return _selectionWithinViewedObject;
}


/** <p>Compound editors subclass this to send an EOMSelectionChangeNotification and manage
    the selection arrays.</p> */
- (void)setSelectionPath:(NSArray *)newSelection
{
  unsigned int indexOfLast = [newSelection indexOfObject:[newSelection lastObject]];
  NSRange allButLastElement;
/* 
  int i,j;

  printf("%@\n",NSStringFromSelector(_cmd));  
  for (i = 0; i < [newSelection count]; i++)
    {
      id foo = [newSelection objectAtIndex:i];
      if ([foo isKindOfClass:[NSArray class]])
	{
	  printf("\t");
          for (j = 0; j < [foo count]; j++)
             printf("%@", [[foo objectAtIndex:j] class]);
	  printf("\n");
	}
      else 
        printf("%@\n", [[newSelection objectAtIndex:i] class]);
      
    }
 */
  
  if (indexOfLast == NSNotFound)
    {
      ASSIGN(_viewedObjectPath, [NSArray array]);
      ASSIGN(_selectionWithinViewedObject, [NSArray array]); 
    }
  else 
    {
      allButLastElement.location = 0;
      allButLastElement.length = indexOfLast;
      
      ASSIGN(_viewedObjectPath, [newSelection subarrayWithRange:allButLastElement]);
      ASSIGN(_selectionWithinViewedObject, [newSelection lastObject]);
    }

  [self selectionDidChange];
}

/** <p>Compound editors subclass this to send an EOMSelectionChangeNotification and manage
    the selection arrays.</p> */
- (void) setSelectionWithinViewedObject:(NSArray *) newSelection
{
/* 
  int i,j;
  printf("%@\n",NSStringFromSelector(_cmd));  
  for (i = 0; i < [newSelection count]; i++)
    {
      id foo = [newSelection objectAtIndex:i];
      if ([foo isKindOfClass:[NSArray class]])
	{
	  printf("\t");
          for (j = 0; j < [foo count]; j++)
             printf("%@", [[foo objectAtIndex:j] class]);
	  printf("\n");
	}
      else 
        printf("%@\n", [[newSelection objectAtIndex:i] class]);
    } 
 */ 
  ASSIGN(_selectionWithinViewedObject, newSelection);
  [self selectionDidChange];
}

/** <p>Compound editors subclass this to send an EOMSelectionChangeNotification and manage
    the selection arrays.</p> */
- (void) setViewedObjectPath:(NSArray *)newPath
{
 /* 
  int i,j;

  printf("%@\n",NSStringFromSelector(_cmd));  
  for (i = 0; i < [newPath count]; i++)
    {
      id foo = [newPath objectAtIndex:i];
      if ([foo isKindOfClass:[NSArray class]])
	{
	  printf("\t");
          for (j = 0; j < [foo count]; j++)
             printf("%@", [[foo objectAtIndex:j] class]);
	  printf("\n");
	}
      else 
        printf("%@\n", [[newPath objectAtIndex:i] class]);
    }
 */ 
  ASSIGN(_viewedObjectPath, newPath);
  [self selectionDidChange];
}

- (void)setStoredProceduresSelected:(BOOL)selected
{
  _storedProceduresSelected = selected;
}

- (BOOL)storedProceduresSelected
{
  if ([[_viewedObjectPath lastObject] isKindOfClass: NSClassFromString(@"EOModel")])
    {
      return _storedProceduresSelected;
    }
  return NO;
}

/* viewing the selection */

- (void)viewSelectedObject
{
  if (![_selectionWithinViewedObject count])
    return;

  {
    id object = [_selectionWithinViewedObject objectAtIndex:0];
    [self setSelectionPath: [[_viewedObjectPath arrayByAddingObject: object]
	    				arrayByAddingObject:[NSArray array]]];
  }
}

- (void) activate
{
  [EOMApp setCurrentEditor:self];
}

@end

@implementation EOModelerEmbedibleEditor 
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}
- (id) initWithParentEditor:(EOModelerCompoundEditor *)parentEditor
{
  if ((self = [super initWithDocument: [parentEditor document]]))
  {
    _parentEditor = parentEditor;
    [[NSNotificationCenter defaultCenter]
	    addObserver:self
	    selector:@selector(selectionDidChange:)
	    name:EOMSelectionChangedNotification
	    object:[self document]];
  }
  return self;
}

- (EOModelerCompoundEditor *)parentEditor
{
  return _parentEditor;
}

- (void)selectionDidChange:(NSNotification *)notification
{
  if (self == [_parentEditor activeEditor])
    {
      [self activate];
    }
}
/** subclasses should return YES if they can edit the current selection (should return NO if there is no selection */
- (BOOL)canSupportCurrentSelection
{
  return NO;
}

/* subclasses should implement */
- (NSArray *)friendEditorClasses
{
  return nil;
}

/* subclasses should implement */
- (NSView *)mainView
{
  return nil;
}

- (NSString *)pathViewPreferenceHint
{
  [self subclassResponsibility: _cmd];
  return nil; 
}

- (void)print
{
  [self subclassResponsibility: _cmd];
}

/** Returns the selection path from the parent editor */
- (NSArray *)selectionPath
{
  return [[self parentEditor] selectionPath]; 
}

/** Returns the viewed object path from the parent editor */
- (NSArray *) viewedObjectPath
{
  return [[self parentEditor] viewedObjectPath];
}

/** Returns the selection within the viewed object from the parent editor */
- (NSArray *)selectionWithinViewedObject
{
  return [[self parentEditor] selectionWithinViewedObject];
}

/** Forwarded to the parent editor.
  * This method is not called by the parent editor.
  * to update the selection when its changed in the parent editor,
  * register for EOMSelectionDidChangeNotification.
  */
- (void)setSelectionPath:(NSArray *)newSelection
{
  [[self parentEditor] setSelectionPath: newSelection];
}

/** Forwarded to the parent editor.
  * This method is not called by the parent editor.
  * to update the selection when its changed in the parent editor,
  * register for EOMSelectionDidChangeNotification.
  */
- (void) setSelectionWithinViewedObject:(NSArray *) newSelection
{
  [[self parentEditor] setSelectionWithinViewedObject: newSelection];
}

/** Forwarded to the parent editor.
  * This method is not called by the parent editor.
  * to update the selection when its changed in the parent editor,
  * register for EOMSelectionDidChangeNotification.
  */
- (void) setViewedObjectPath:(NSArray *)newPath
{
  [[self parentEditor] setViewedObjectPath: newPath];
}

@end

