/**
  EOModelerApp.m <title>EOModelerApp Class</title>
  
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

#include "EOModeler/EODefines.h"
#include "EOModeler/EOModelerApp.h"
#include "EOModeler/EOModelerDocument.h"

#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>

EOModelerApp *EOMApp;
NSString *EOMSelectionChangedNotification = @"EOModelerSelectionChanged";
NSString *EOMPropertyPboardType = @"EOModelProperty";

static EOModelerDocument *_activeDocument;

@interface EOModel (Private)
- (void) setCreateMutableObjects:(BOOL)flag;
@end

@implementation EOModelerApp : NSApplication

- (id) init
{
  if ((self = [super init]))
    {
      EOMApp = (EOModelerApp*)NSApp;
      _documents = [[NSMutableArray alloc] init];
      _columnsByClass = [[NSMutableDictionary alloc] init];
    }

   return self;
}

- (NSArray *)allPasteboardTypes
{
  return [NSArray arrayWithObject:EOMPropertyPboardType];
}

- (EOModelerEditor *)currentEditor;
{
  return _currentEditor;
}

- (void) setCurrentEditor:(EOModelerEditor *)newEditor
{
  _currentEditor = newEditor;
}

- (void)addDocument:(EOModelerDocument *)document
{
  [_documents addObject: document];
}

- (void)removeDocument:(EOModelerDocument *)document
{
  if (_activeDocument == document)
    _activeDocument = nil;
  [_documents removeObject: document];
}

- (NSArray *)documents
{
  return [NSArray arrayWithArray: _documents];
}

- (EOModelerDocument *)activeDocument
{
   //TODO 
  return _activeDocument;
}

- (EOModelerDocument *)loadDocumentAtPath:(NSString *)path
{
  EOModel *loadedModel = [[EOModel alloc] initWithContentsOfFile:path];
  [loadedModel setCreateMutableObjects:YES];
  [[EOModelGroup defaultGroup] addModel:loadedModel];
  EOModelerDocument *loadedDocument = [[EOModelerDocument alloc] initWithModel: loadedModel];
  [self addDocument: loadedDocument];
  RELEASE(loadedDocument);
  return loadedDocument;
}

- (EOModelerDocument *)documentWithPath:(NSString *)path
{
  unsigned i = 0;
  for (i=0; i < [_documents count]; i++)
     {
       if ([[[_documents objectAtIndex:i] documentPath] isEqual: path])
           return [_documents objectAtIndex:i];
     }
  return nil;
}

- (void)registerColumnName:(NSString *)name 
                  forClass:(Class)class
		  provider:(id <EOMColumnProvider>)provider
{
  NSMutableDictionary *classDict = [_columnsByClass objectForKey: class];
  if (!classDict)
    {
      classDict = [[NSMutableDictionary alloc] init];
      [_columnsByClass setObject:classDict forKey:class];
      RELEASE(classDict);
    }
  [classDict setObject:provider forKey:name];
}

- (void)registerColumnNames:(NSArray *)names
                   forClass:(Class)class
		   provider:(id <EOMColumnProvider>)provider
{
  unsigned i,count = [names count];
  NSMutableDictionary *classDict = [_columnsByClass objectForKey: class];
  
  if (!classDict)
    {
      classDict = [[NSMutableDictionary alloc] init];
      [_columnsByClass setObject:classDict forKey:class];
      RELEASE(classDict);
    }

  for (i = 0; i < count; i++)
    {
      [classDict setObject:provider forKey:[names objectAtIndex:i]]; 
    }
}

- (NSArray *)columnNamesForClass:(Class)class
{
  return [[_columnsByClass objectForKey:class] allKeys];
}

- (id <EOMColumnProvider>)providerForName:(NSString *)name class:(Class)class
{
  return [[_columnsByClass objectForKey:class] objectForKey:name];
}

+ (EOModel *)modelWithPath:(NSString *)path
{
  id _eom = [[EOModel alloc] initWithContentsOfFile:path];
  [_eom setCreateMutableObjects:YES];
  [[EOModelGroup defaultGroup] addModel: _eom];
  return _eom;
}

+ (EOModel *)modelContainingFetchSpecification:(EOFetchSpecification *)fs
{
  /* TODO */
  return nil;
}

+ (NSString *)nameForFetchSpecification:(EOFetchSpecification *)fs
{
  /* TODO */
  return nil;
}

-(void)_setActiveDocument:(EOModelerDocument*)ad
{
  _activeDocument = ad;
}

@end
