/** 
   EOModel.m <title>EOModel Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
           Manuel Guesdon <mguesdon@orange-concept.com>
   Date: February 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSBundle.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <GNUstepBase/GSObjCRuntime.h>

#include <EOControl/EOGenericRecord.h>
#include <EOControl/EOFault.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOEntityPriv.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOAccessFault.h>
#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAttribute.h>

#define DEFAULT_MODEL_VERSION 2

NSString *EOEntityLoadedNotification = @"EOEntityLoadedNotification";

@interface EOModel (EOModelPrivate)

+ (NSString *) _formatModelPath: (NSString *)path checkFileSystem: (BOOL)chkFS;

- (void) setCreateMutableObjects: (BOOL)flag;
- (BOOL) createsMutableObjects;
- (EOEntity *) _verifyBuiltEntityObject: (id)entity
                                  named: (NSString *)name;

@end /* EOModel (EOModelPrivate) */


@implementation EOModel

+ (EOModel*) model
{
  return AUTORELEASE([[self alloc] init]);
}

+ (NSString*) findPathForModelNamed: (NSString *)modelName
{
  NSString *modelPath = nil;
  NSString *tmpModelName = nil;
  NSString *tmpPath = nil;
  NSBundle *bundle = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory, NSAllDomainsMask, YES);

  tmpModelName = [modelName lastPathComponent];
  EOFLOGClassLevelArgs(@"gsdb", @"modelName=%@ tmpModelName=%@",
		       modelName, tmpModelName);

  tmpPath = [[modelName stringByStandardizingPath]
              stringByDeletingLastPathComponent]; 
  EOFLOGClassLevelArgs(@"gsdb", @"modelName=%@ tmpPath=%@",
			modelName, tmpPath);

  bundle = [NSBundle mainBundle];
  modelPath = [bundle pathForResource: modelName
                      ofType: @"eomodel"];

  EOFLOGClassLevelArgs(@"gsdb", @"modelName=%@ modelPath=%@",
			modelName, modelPath);

  if (!modelPath)
    {
      modelPath = [bundle pathForResource: modelName
                          ofType: @"eomodeld"];

      EOFLOGClassLevelArgs(@"gsdb", @"modelName=%@ modelPath=%@",
			    modelName, modelPath);

      if (!modelPath)
        {
          if ([tmpPath length] == 0)
            {
              tmpPath = @"./";
              tmpPath = [tmpPath stringByStandardizingPath];
            }

          if ([[tmpModelName pathExtension] length] != 0)
            tmpModelName = [tmpModelName stringByDeletingPathExtension]; 
          
          EOFLOGClassLevelArgs(@"gsdb",
				@"modelName=%@ tmpPath=%@ tmpModelName=%@",
				modelName, tmpPath, tmpModelName);

          bundle = [NSBundle bundleWithPath: tmpPath];
          
          modelPath = [bundle pathForResource: tmpModelName
                              ofType: @"eomodel"];

          EOFLOGClassLevelArgs(@"gsdb", @"modelName=%@ modelPath=%@",
				modelName, modelPath);

          if (!modelPath)
            {          
              modelPath = [bundle pathForResource: tmpModelName
                                  ofType: @"eomodeld"];
              EOFLOGClassLevelArgs(@"gsdb", @"modelName=%@ modelPath=%@",
				    modelName, modelPath);

              if (!modelPath)
                {
                  int i, pathCount = [paths count];

                  for (i = 0; !modelPath && pathCount < i; i++)
                    {
                      EOFLOGClassLevelArgs(@"gsdb", @"Trying path:%@",
					    [paths objectAtIndex:i]);

                      bundle = [NSBundle bundleWithPath: [paths objectAtIndex:i]];
                      
                      modelPath = [bundle pathForResource: modelName
                                          ofType: @"eomodel"];

                      EOFLOGClassLevelArgs(@"gsdb",
					    @"modelName=%@ modelPath=%@",
					    modelName, modelPath);

                      if (!modelPath)
                        {
                          modelPath = [bundle pathForResource: modelName
                                              ofType: @"eomodeld"];

                          EOFLOGClassLevelArgs(@"gsdb",
						@"modelName=%@ modelPath=%@",
						modelName, modelPath);
                        }
                    }
                }
            }
        }
    }

   return modelPath;
}

- (id) init
{
  EOFLOGObjectFnStart();

  if ((self = [super init]))
    {
      // Turbocat
      _version = DEFAULT_MODEL_VERSION;
      _flags.createsMutableObjects = YES;
      
      _entitiesByName = [GCMutableDictionary new];
      _entitiesByClass = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks, 
						  NSObjectMapValueCallBacks,
						  8,
						  [self zone]);
  
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_classDescriptionNeeded:)
        name: EOClassDescriptionNeededNotification
        object: nil];

      //No ?
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_classDescriptionNeeded:)
        name: EOClassDescriptionNeededForClassNotification
        object: nil];

      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_classDescriptionNeeded:)
        name: EOClassDescriptionNeededForEntityNameNotification
        object: nil];

      [EOClassDescription invalidateClassDescriptionCache];
    }

  EOFLOGObjectFnStop();

  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  if (_entitiesByClass)
    {
      NSFreeMapTable(_entitiesByClass);
      _entitiesByClass = NULL;
    }

  DESTROY(_name);
  DESTROY(_path);
  DESTROY(_adaptorName);
  DESTROY(_connectionDictionary);
  DESTROY(_userInfo);
  DESTROY(_internalInfo);
  DESTROY(_docComment);

  [super dealloc];
}

- (void) gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  [(id)_group gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"entities gcDecrementRefCount");

  [(id)_entities gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"entitiesByName gcDecrementRefCount");

  [(id)_entitiesByName gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"storedProcedures gcDecrementRefCount");

  [(id)_storedProcedures gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"subEntitiesCache gcDecrementRefCount");

  [(id)_subEntitiesCache gcDecrementRefCount];

  EOFLOGObjectFnStop();
}

- (BOOL) gcIncrementRefCountOfContainedObjects
{
  if (![super gcIncrementRefCountOfContainedObjects])
    return NO;

  [(id)_group gcIncrementRefCount];
  [(id)_entities gcIncrementRefCount];
  [(id)_entitiesByName gcIncrementRefCount];
  [(id)_storedProcedures gcIncrementRefCount];
  [(id)_subEntitiesCache gcIncrementRefCount];

  [(id)_group gcIncrementRefCountOfContainedObjects];
  [(id)_entities gcIncrementRefCountOfContainedObjects];
  [(id)_entitiesByName gcIncrementRefCountOfContainedObjects];
  [(id)_storedProcedures gcIncrementRefCountOfContainedObjects];
  [(id)_subEntitiesCache gcIncrementRefCountOfContainedObjects];

  return YES;
}

- (NSString*) path
{
  return _path;
}

- (NSString*) name
{
  return _name;
}

- (NSString*) adaptorName
{
  return _adaptorName;
}

- (NSString*) adaptorClassName
{
  return _adaptorClassName;
}

- (EOEntity*) entityNamed: (NSString *)name
{
  EOEntity *entity = nil;

  NSAssert(name,@"No entityt name");

  entity = [_entitiesByName objectForKey: name];
  if (entity != nil)
    {
      entity = [self _verifyBuiltEntityObject: entity
					named: name];
    }

  return entity;
}

- (NSArray*) entities
{
  //TODO revoir ?
  if (!_entities)
    {
      NSArray *entityNames = [self entityNames];

      ASSIGN(_entities,
	[self resultsOfPerformingSelector: @selector(entityNamed:)
	  withEachObjectInArray: entityNames]);
    }

  return _entities;
}

- (NSArray*) entityNames
{
  return [[_entitiesByName allKeys]
	   sortedArrayUsingSelector: @selector(compare:)];
}

- (NSArray*) storedProcedureNames
{

  NSEnumerator *stEnum;
  EOStoredProcedure *st;
  NSMutableArray *stNames = [NSMutableArray arrayWithCapacity:
					      [_storedProcedures count]];

  stEnum = [_storedProcedures objectEnumerator];
  while ((st = [stEnum nextObject]))
    [stNames addObject: st];

  return stNames;
}

- (EOStoredProcedure*) storedProcedureNamed: (NSString *)name
{
  NSEnumerator *stEnum;
  EOStoredProcedure *st;

  stEnum = [_storedProcedures objectEnumerator];
  while ((st = [stEnum nextObject]))
    {
      if ([[st name] isEqual:name])
	return st;
    }

  return nil;
}

- (NSArray*) storedProcedures
{
  //TODO revoir ?
  if (!_storedProcedures)
    {
      NSArray *storedProcedures = nil;
      NSArray *storedProcedureNames = [self storedProcedureNames];

      EOFLOGObjectLevelArgs(@"gsdb", @"storedProcedureNames=%@",
			    storedProcedureNames);

      storedProcedures = [self resultsOfPerformingSelector:
				 @selector(storedProcedureNamed:)
			       withEachObjectInArray: storedProcedureNames];

      EOFLOGObjectLevelArgs(@"gsdb", @"storedProcedures=%@", storedProcedures);

      ASSIGN(_storedProcedures, [GCArray arrayWithArray:storedProcedures]);
/*      [self performSelector:@selector(storedProcedureNamed:)
            withEachObjectInArray:storedProcedureNames];
*/
    }

  return _storedProcedures;
}

- (EOEntity*) entityForObject: (id)object
{
  EOEntity *entity = nil;
  NSString *entityName = nil;

  if ([EOFault isFault: object])
    {
      EOFaultHandler *handler = [EOFault handlerForFault: object];

      if ([handler respondsToSelector: @selector(globalID)] == YES)
        entityName = [[(EOAccessFaultHandler *)handler globalID]
		       entityName];
    }
  else
    {
      //  if ([object isKindOfClass:[EOGenericRecord class]])
      //    return [object entity];      
      entityName = [object entityName];
    }

  if (entityName)
    entity = [self entityNamed:entityName];

  return entity;
}

- (NSDictionary*) connectionDictionary
{
  return _connectionDictionary;
}

- (NSDictionary*) userInfo
{
  return _userInfo;
}

- (NSString*) description
{
  NSMutableDictionary *descdict;
  id obj;

  descdict = [NSMutableDictionary dictionaryWithCapacity: 6];
  obj = [self name];
  if (obj) [descdict setObject: obj forKey: @"name"];
  obj = [self adaptorName];
  if (obj) [descdict setObject: obj forKey: @"adaptorName"];
  obj = [self connectionDictionary];
  if (obj) [descdict setObject: obj forKey: @"connectionDictionary"];
  obj = [self userInfo];
  if (obj) [descdict setObject: obj forKey: @"userInfo"];
  obj = [self entities];
  if (obj) [descdict setObject: obj forKey: @"entities"];
  obj = [self storedProcedures];
  if (obj) [descdict setObject: obj forKey: @"storedProcedures"];

  obj = [descdict description];
  return obj;
}

- (NSString*) docComment
{
  return _docComment;
}

- (EOModelGroup*) modelGroup
{
  return _group;
}

- (EOAttribute *)prototypeAttributeNamed: (NSString *)attributeName
{
  NSString *entityName;
  EOEntity *entity;
  NSArray *attributes;
  EOAttribute *attribute = nil;
  int i, count;

  EOFLOGObjectFnStart();
  EOFLOGObjectLevelArgs(@"gsdb", @"attrName=%@", attributeName);

  entityName = [NSString stringWithFormat: @"EO%@Prototypes", _adaptorName];

  EOFLOGObjectLevelArgs(@"gsdb", @"entityName=%@", entityName);

  entity = [self entityNamed: entityName];

  if (!entity)
    entity = [_group entityNamed: entityName];

  if (!entity)
    entity = [_group entityNamed: @"EOPrototypes"];

  if (!entity && _adaptorName && [_adaptorName length] > 0)
    {
      EOAdaptor *adaptor;

      adaptor = [EOAdaptor adaptorWithName: _adaptorName];
      attributes = [adaptor prototypeAttributes];
    }
  else
    attributes = [entity attributes];

  EOFLOGObjectLevelArgs(@"gsdb", @"entity=%@ - attributes=%@",
			entity, attributes);

  if (attributes)
    {
      count = [attributes count];

      for (i = 0; i < count; i++)
	{
	  attribute = [attributes objectAtIndex: i];

	  if ([[attribute name]
		isEqualToString: attributeName])
	    break;
	}
    }

  EOFLOGObjectLevelArgs(@"gsdb", @"attribute=%@", attribute);
  EOFLOGObjectFnStop();

  return attribute;
}

@end


@implementation EOModel (EOModelFileAccess)

+ (EOModel*) modelWithContentsOfFile: (NSString *)path
{
  return AUTORELEASE([[self alloc] initWithContentsOfFile: path]);
}

- (id) initWithContentsOfFile: (NSString *)path
{
  NS_DURING
    {
      NSString *name = nil;
      NSString *modelPath = nil;
      NSString *indexPath = nil;
      NSString *fileContents = nil;
      NSDictionary *propList = nil;

      path = [path stringByStandardizingPath];
      modelPath = [isa _formatModelPath: path checkFileSystem: YES];
      NSAssert1(modelPath!=nil, @"Model does not exist at path %@",
                path );
      name = [[modelPath lastPathComponent] stringByDeletingPathExtension];
      [self setName: name];

      if ([[modelPath pathExtension] isEqualToString: @"eomodeld"])
        {
          indexPath =
              [modelPath stringByAppendingPathComponent: @"index.eomodeld"];
        }
      else
        {
          indexPath = modelPath;
        }

      fileContents = [NSString stringWithContentsOfFile: indexPath];
      propList = [fileContents propertyList];
      EOFLOGObjectLevelArgs(@"gsdb", @"propList=%@", propList);
      NSAssert1(propList!=nil, @"Model at path %@ is invalid", indexPath);

      self = [self initWithTableOfContentsPropertyList: propList
                   path: modelPath];
      NSAssert2(self!=nil,@"Failed to initialize with path %@ and plist %@",
                modelPath,
                propList);
    }
  NS_HANDLER
    {
      NSLog(@"exception in EOModel initWithContentsOfFile:");
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  return self;
}

/**
 * Writes the receivers plist representation into an
 * .eomodeld file wrapper located at path.  
 * Depending on the the path extension .eomodeld or .eomodel
 * the corresponding format will be used.
 * If the path has neither .eomodeld nor .eomodel path
 * extension, .eomodeld will be used.
 * If the file located at path already exists, a back is created
 * by appending a '~' character to file name.
 * If a backup file already exists, when trying to create a backup,
 * the old backup will be deleted.
 * If any of the file operations fail, an NSInvalidArgumentException
 * will be raised.
 */
- (void) writeToFile: (NSString *)path
{
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSMutableDictionary	*pList;
  NSDictionary		*attributes;
  NSDictionary		*entityPList;
  NSEnumerator		*entityEnum;
  NSString              *fileName;
  NSString              *extension;
  BOOL writeSingleFile;

  path = [path stringByStandardizingPath];
  extension = [path pathExtension];

  if ([extension isEqualToString: @"eomodeld"] == NO
      && [extension isEqualToString: @"eomodel"] == NO)
    {
      path = [path stringByAppendingPathExtension: @"eomodeld"];
      extension = [path pathExtension];
    }
  
  writeSingleFile = [extension isEqualToString: @"eomodel"] ? YES : NO;

  [self _setPath: path];

  if ([mgr fileExistsAtPath: path])
    {
      NSString *backupPath;
      backupPath = [path stringByAppendingString: @"~"];

      if ([mgr fileExistsAtPath: backupPath])
	{
	  if ([mgr removeFileAtPath: backupPath handler: nil] == NO)
	    {
	      NSString *fmt;
	      fmt = [NSString stringWithFormat: @"Could not remove %@",
			      backupPath];
	      [NSException raise: NSInvalidArgumentException
			   format: fmt];
	    }
	}

      if ([mgr movePath: path toPath: backupPath handler: nil] == NO)
	{
	  NSString *fmt;
	  fmt = [NSString stringWithFormat: @"Could not move %@ to %@",
			  path, backupPath];
	  [NSException raise: NSInvalidArgumentException
		       format: fmt];
	}
    }

  pList = [NSMutableDictionary dictionaryWithCapacity: 10];

  [self encodeIntoPropertyList: pList];

  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithUnsignedLong: 0777], NSFilePosixPermissions,
    nil];

  if (writeSingleFile == NO
      && [mgr createDirectoryAtPath: path attributes: attributes] == NO)
    {
      NSString *fmt;
      fmt = [NSString stringWithFormat: @"Could not create directory: %@",
		      path];
      [NSException raise: NSInvalidArgumentException
		   format: fmt];
    }

  entityEnum = [[pList objectForKey: @"entities"] objectEnumerator];
  while (writeSingleFile == NO
	 && (entityPList = [entityEnum nextObject]))
    {
      NSString *fileName;

      fileName = [path stringByAppendingPathComponent:
			 [NSString stringWithFormat: @"%@.plist",
				   [entityPList objectForKey: @"name"]]];
      if ([entityPList writeToFile: fileName atomically: YES] == NO)
	{
	  NSString *fmt;
	  fmt = [NSString stringWithFormat: @"Could not create file: %@",
			  fileName];
	  [NSException raise: NSInvalidArgumentException
		       format: fmt];
	}
    }

  if (writeSingleFile == NO)
    {
      fileName = [path stringByAppendingPathComponent: @"index.eomodeld"];
      [pList removeAllObjects];
      [self encodeTableOfContentsIntoPropertyList: pList];
    }
  else
    {
      fileName = path;
    }

  if ([pList writeToFile: fileName atomically: YES] == NO)
    {
      NSString *fmt;
      fmt = [NSString stringWithFormat: @"Could not create file: %@",
		      fileName];
      [NSException raise: NSInvalidArgumentException
		   format: fmt];
    }
}

@end

@implementation EOModel (EOModelPropertyList)

- (id) initWithTableOfContentsPropertyList: (NSDictionary *)tableOfContents
                                      path: (NSString *)path
{
  //OK
  NS_DURING
    {
      if ((self = [self init]))
        {
          NSString *versionString = nil;
          NSArray  *entities = nil;
          int i, count = 0;

          EOFLOGObjectLevelArgs(@"gsdb", @"tableOfContents=%@",
				tableOfContents);

	  /* The call to _setPath: also sets the name implicitly. */
          [self _setPath: [isa _formatModelPath: path checkFileSystem: YES]];
          EOFLOGObjectLevelArgs(@"gsdb", @"name=%@ path=%@", _name, _path);

          versionString = [tableOfContents objectForKey: @"EOModelVersion"];
          if (versionString)
            _version = [versionString floatValue];
          else
            _version = 0; // dayers: is this correct?

          ASSIGN(_connectionDictionary,
                 [tableOfContents objectForKey: @"connectionDictionary"]);
          ASSIGN(_adaptorName, [tableOfContents objectForKey: @"adaptorName"]);
          ASSIGN(_userInfo, [tableOfContents objectForKey: @"userInfo"]);

          if (!_userInfo)
            {
              ASSIGN(_userInfo,
                     [tableOfContents objectForKey:@"userDictionary"]);
            }

          ASSIGN(_internalInfo,
                 [tableOfContents objectForKey: @"internalInfo"]);
          ASSIGN(_docComment,[tableOfContents objectForKey:@"docComment"]);

          //VERIFY
          if (_version >= 2)
            {
              NSMutableDictionary *markSP = [NSMutableDictionary dictionary];
              NSArray *storedProcedures = [tableOfContents
                                           objectForKey: @"storedProcedures"];
              EOStoredProcedure *sp = nil;
              NSEnumerator *enumerator = nil;

              count = [storedProcedures count];

              for (i = 0; i < count; i++)
                {
                  EOStoredProcedure *st;
                  NSDictionary *plist;
                  NSString *fileName;

                  fileName = [NSString stringWithFormat: @"%@.storedProcedure",
                                       [[storedProcedures objectAtIndex: i]
                                         objectForKey: @"name"]];	  
                  plist = [[NSString stringWithContentsOfFile:
                                       [_name stringByAppendingPathComponent:
                                                fileName]]
                            propertyList];	  

                  [markSP setObject: plist
                          forKey: [plist objectForKey: @"name"]];

                  st = [EOStoredProcedure storedProcedureWithPropertyList: plist
                                           owner: self];
                  [self addStoredProcedure: st];
                }

              enumerator = [_storedProcedures objectEnumerator];
              while ((sp = [enumerator nextObject]))
                [sp awakeWithPropertyList: [markSP objectForKey: [sp name]]];
            }
        
          entities = [tableOfContents objectForKey: @"entities"];
          count = [entities count];

          for (i = 0; i < count; i++)
            {
              [self _addFakeEntityWithPropertyList:
                      [entities objectAtIndex: i]];
            }
        }
    }
  NS_HANDLER
    {
      NSLog(@"exception in EOModel initWithTableOfContentsPropertyList:path:");
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  return self;
}

- (void) encodeTableOfContentsIntoPropertyList:
  (NSMutableDictionary *)propertyList
{
  int i, count;
  NSMutableArray *entitiesArray;

  [propertyList setObject:
    [[NSNumber numberWithFloat: DEFAULT_MODEL_VERSION] stringValue]
		forKey: @"EOModelVersion"];

  if (_adaptorName)
    [propertyList setObject: _adaptorName
		  forKey: @"adaptorName"];

  if (_connectionDictionary)
    [propertyList setObject: _connectionDictionary
		  forKey: @"connectionDictionary"];

  if (_userInfo)
    [propertyList setObject: _userInfo
		  forKey: @"userInfo"];

  if (_docComment)
    [propertyList setObject: _docComment forKey: @"docComment"];

  /* Do not access _entities until cache is triggered */
  count = [[self entities] count];
  entitiesArray = [NSMutableArray arrayWithCapacity: count];
  [propertyList setObject: entitiesArray forKey: @"entities"];

  for (i = 0; i < count; i++)
    {
      NSMutableDictionary *entityPList;
      EOEntity *entity;

      entity = [_entities objectAtIndex: i];
      entityPList = [NSMutableDictionary dictionaryWithCapacity: 2];

      [entityPList setObject: [entity className] forKey: @"className"];
      [entityPList setObject: [entity name] forKey: @"name"];

      [entitiesArray addObject: entityPList];
    }
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
                      owner: (id)owner
{
  NS_DURING
    {
      if (!propertyList)
        [NSException raise: NSInvalidArgumentException
                     format: @"%@ -- %@ 0x%x: must not be the nil object",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self];

      if (![propertyList isKindOfClass: [NSDictionary class]])
        [NSException raise: NSInvalidArgumentException
	  format: @"%@ -- %@ 0x%x: must not be kind of NSDictionary class",
	  NSStringFromSelector(_cmd),
	  NSStringFromClass([self class]),
	  self];

      if ((self = [self init]))
        {
          int i, count;
          NSArray *propListEntities, *propListSt;
          NSMutableDictionary *markEntities =
            [NSMutableDictionary dictionaryWithCapacity: 10];
          NSMutableDictionary *markSP =
            [NSMutableDictionary dictionaryWithCapacity: 10];
          NSEnumerator *enumerator;
          EOEntity *entity;
          EOStoredProcedure *sp;
      
          _version = [[propertyList objectForKey: @"EOModelVersion"]
		       floatValue];
          _adaptorName = RETAIN([propertyList objectForKey: @"adaptorName"]);
          _connectionDictionary = RETAIN([propertyList objectForKey:
						   @"connectionDictionary"]);
          _userInfo = RETAIN([propertyList objectForKey: @"userInfo"]);
          _docComment = RETAIN([propertyList objectForKey: @"docComment"]);

          propListEntities = [propertyList objectForKey: @"entities"];
          propListSt = [propertyList objectForKey: @"storedProcedures"];
      
          _flags.errors = NO;
          [self setCreateMutableObjects: YES];
      
          count = [propListEntities count];
          for (i = 0; i < count; i++)
            {
              EOEntity *entity;
              NSDictionary *plist;
          
              plist = [propListEntities objectAtIndex: i];
              EOFLOGObjectLevelArgs(@"gsdb", @"plist=%@ [%@]",
				    plist, [plist class]);
          
              if (_version >= 2)
                {
                  NSString *fileName = [NSString stringWithFormat: @"%@.plist",
                                                 [plist objectForKey: @"name"]];
              
                  plist = [[NSString stringWithContentsOfFile:
                                       [_name stringByAppendingPathComponent:
						fileName]]
                            propertyList];
                }
          
              [markEntities setObject: plist
                            forKey: [plist objectForKey: @"name"]];
          
              entity = [EOEntity entityWithPropertyList: plist
				 owner: self];
              [self addEntity: entity];
            }

          /* Do not access _entities until cache is triggered */
          enumerator = [[self entities] objectEnumerator];
          while ((entity = [enumerator nextObject]))
            {
              NS_DURING
                {
                  [entity awakeWithPropertyList:
			    [markEntities objectForKey: [entity name]]];
                }
              NS_HANDLER
                {
                  [NSException raise: NSInvalidArgumentException
                               format: @"%@ -- %@ 0x%x: exception in model '%@' during awakeWithPropertyList: of entity '%@': %@",
                               NSStringFromSelector(_cmd),
                               NSStringFromClass([self class]),
                               self,
                               [self name],
                               [entity name],
                               [localException reason]];
                } 
              NS_ENDHANDLER;
            }
      
          if (_version >= 2)
            {
              count = [propListSt count];
              for (i = 0; i < count; i++)
                {
                  EOStoredProcedure *st;
                  NSDictionary *plist;
                  NSString *fileName;
              
                  fileName = [NSString stringWithFormat: @"%@.storedProcedure",
                                       [[propListSt objectAtIndex: i]
					 objectForKey: @"name"]];

                  plist = [[NSString stringWithContentsOfFile:
                                       [_name stringByAppendingPathComponent:
						fileName]]
                            propertyList];

                  [markSP setObject: plist
			  forKey: [plist objectForKey: @"name"]];

                  st = [EOStoredProcedure storedProcedureWithPropertyList: plist
                                          owner: self];
                  [self addStoredProcedure: st];
                }
          
              enumerator = [_storedProcedures objectEnumerator];
              while ((sp = [enumerator nextObject]))
                [sp awakeWithPropertyList: [markSP objectForKey: [sp name]]];
            }
  
          [self setCreateMutableObjects: NO];
        }
    }
  NS_HANDLER
    {
      NSLog(@"exception in EOModel initWithPropertyList:owner:");
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;
  
  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList
{
}

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList
{
  int i, count;

  [propertyList setObject: 
		  [[NSNumber numberWithFloat: DEFAULT_MODEL_VERSION]
			     stringValue]
		forKey: @"EOModelVersion"];

  if (_name)
    [propertyList setObject: _name forKey: @"name"];
  if (_adaptorName)
    [propertyList setObject: _adaptorName forKey: @"adaptorName"];
  if (_adaptorClassName) 
    [propertyList setObject: _adaptorClassName forKey: @"adaptorClassName"];
  if (_connectionDictionary)
    [propertyList setObject: _connectionDictionary
		  forKey: @"connectionDictionary"];
  if (_userInfo)
    [propertyList setObject: _userInfo forKey: @"userInfo"];
  if (_internalInfo)
    [propertyList setObject: _internalInfo forKey: @"internalInfo"];
  if (_docComment)
    [propertyList setObject: _docComment forKey: @"docComment"];

  /* Do not access _entities until cache is triggered */
  count = [[self entities] count];

  if (count > 0)
    {
      NSMutableArray *entitiesArray = [NSMutableArray arrayWithCapacity: count];

      [propertyList setObject: entitiesArray forKey: @"entities"];

      for (i = 0; i < count; i++)
        {
	  NSMutableDictionary *entityPList = [NSMutableDictionary dictionary];
	  
	  [[_entities objectAtIndex: i] encodeIntoPropertyList: entityPList];
	  [entitiesArray addObject: entityPList];
        }
    }

  count = [_storedProcedures count];
  if (count > 0)
    {
      NSMutableArray *stArray = [NSMutableArray arrayWithCapacity: count];

      [propertyList setObject: stArray forKey: @"entities"];
      for (i = 0; i < count; i++)
        {
	  NSMutableDictionary *stPList = [NSMutableDictionary dictionary];

	  [[_storedProcedures objectAtIndex: i]
	    encodeIntoPropertyList: stPList];
	  [stArray addObject: stPList];
        }
    }
}

@end

@implementation EOModel (EOModelHidden)

-(void) _classDescriptionNeeded: (NSNotification *)notification
{
  //TODO
  NSString *notificationName = nil;

  EOFLOGObjectFnStart();

  notificationName = [notification name];

  EOFLOGObjectLevelArgs(@"gsdb", @"notificationName=%@", notificationName);

  if ([notificationName
	isEqualToString: EOClassDescriptionNeededForClassNotification])
    {
      Class aClass = [notification object];
      EOClassDescription *classDescription = nil;
      EOEntity *entity = nil;
      NSString *entityClassName = nil;

      EOFLOGObjectLevelArgs(@"gsdb", @"notification=%@ aClass=%@",
			    notification, aClass);
      NSAssert(aClass, @"No class");

      entity = [self _entityForClass: aClass];

      if (!entity)
        {
          NSAssert1((!GSObjCIsKindOf(aClass, [EOGenericRecord class])),
                    @"No entity for class %@", aClass);
        }
      else
        {
          Class entityClass=Nil;
          classDescription = [entity classDescriptionForInstances];
          EOFLOGObjectLevelArgs(@"gsdb", @"classDescription=%@",
				classDescription);

          entityClassName = [entity className];
          EOFLOGObjectLevelArgs(@"gsdb",@"entityClassName=%@",entityClassName);

          entityClass=NSClassFromString(entityClassName);
          NSAssert1(entityClass,@"No entity class named '%@'",entityClassName);

          [EOClassDescription registerClassDescription: classDescription
                              forClass: entityClass];

          /*      classDescription = [[EOClassDescription new] autorelease];
                  EOFLOGObjectLevelArgs(@"gsdb",
		                        @"classDescription=%@ aClass=%@",
					classDescription, aClass);
                  [EOClassDescription registerClassDescription: classDescription
                  forClass: aClass];
          */
        }
    }
  else if ([notificationName
	     isEqualToString: EOClassDescriptionNeededForEntityNameNotification])
    {
      //OK
      EOClassDescription *classDescription;
      NSString *entityName = [notification object];
      EOEntity *entity = nil;
      NSString *entityClassName = nil;
      Class entityClass = Nil;

      EOFLOGObjectLevelArgs(@"gsdb", @"notification=%@", notification);
      EOFLOGObjectLevelArgs(@"gsdb", @"entityName=%@", entityName);

      NSAssert(entityName, @"No entity name");//??

      entity = [self entityNamed: entityName];
      NSAssert1(entity, @"No entity named %@", entityName);//??

      classDescription = [entity classDescriptionForInstances];
      EOFLOGObjectLevelArgs(@"gsdb", @"classDescription=%@", classDescription);

      entityClassName = [entity className];
      EOFLOGObjectLevelArgs(@"gsdb", @"entityClassName=%@", entityClassName);

      entityClass=NSClassFromString(entityClassName);
      NSAssert1(entityClass,@"No entity class named '%@'",entityClassName);

      [EOClassDescription registerClassDescription: classDescription
                          forClass:entityClass];//??
    }
  else if ([notificationName
	     isEqualToString: EOClassDescriptionNeededNotification])
    {
      //TODO
    }
  else
    {
      //TODO
    }

  EOFLOGObjectFnStop();
}

- (void) _resetPrototypeCache
{
  // TODO
  [self notImplemented: _cmd];
}

- (BOOL) isPrototypesEntity: (id)param0
{
  // TODO
  [self notImplemented: _cmd];
  return NO;
}

- (id) _instantiatedEntities
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

- (void) _setPath: (NSString*)path
{
  //OK
  [self loadAllModelObjects];
  [self willChange];
  ASSIGN(_path, path);
  [self setName: [[path lastPathComponent] stringByDeletingPathExtension]];
}

- (EOEntity*) _entityForClass: (Class)aClass
{
  NSString *className;
  EOEntity *entity;

  EOFLOGObjectFnStart();

  NSAssert(aClass, @"No class");
  NSAssert(_entitiesByClass, @"No _entitiesByClass");

  className = NSStringFromClass(aClass);
  EOFLOGObjectLevelArgs(@"gsdb", @"className=%@", className);

  entity = NSMapGet(_entitiesByClass, className);
  EOFLOGObjectLevelArgs(@"gsdb", @"entity class=%@", [entity class]);

  if (entity)
    {
      entity = [self _verifyBuiltEntityObject: entity
                     named: nil];
      EOFLOGObjectLevelArgs(@"gsdb", @"entity=%@", entity);
    }
  else
    {
      EOFLOGObjectLevelArgs(@"gsdb", @"entity for class named=%@ not found",
			    className);
      EOFLOGObjectLevelArgs(@"gsdb", @"entities class names=%@",
			    NSAllMapTableKeys(_entitiesByClass));
      EOFLOGObjectLevelArgs(@"gsdb", @"entities entities names=%@",
			    NSAllMapTableValues(_entitiesByClass));
      EOFLOGObjectLevelArgs(@"gsdb", @"entities map=%@",
			    NSStringFromMapTable(_entitiesByClass));
    }

  EOFLOGObjectFnStop();

  return entity;
}

- (id) _childrenForEntityNamed: (id)param0
{
  // TODO [self notImplemented:_cmd];
  return nil;
}

- (void) _registerChild: (id)param0
             forParent: (id)param1
{
  // TODO [self notImplemented:_cmd];
}

- (void) _setInheritanceLinks: (id)param0
{
  // TODO
  [self notImplemented: _cmd];
}

- (void) _removeEntity: (id)entity
{
  //should be ok
  NSString *entityName = nil;
  NSString *entityClassName = nil;

  if ([entity isKindOfClass: [EOEntity class]])
    {
      entityName = [(EOEntity*)entity name];
      entityClassName = [entity className];
    }
  else
    {
      entityName = [entity objectForKey: @"name"];
      entityClassName = [entity  objectForKey: @"className"];
    }

  [_entitiesByName removeObjectForKey: entityName];

  if (_entitiesByClass)
    NSMapRemove(_entitiesByClass, entityClassName);

  DESTROY(_entities);
}

- (EOEntity*) _addEntityWithPropertyList: (NSDictionary*)propertyList
{
  //OK
  id children = nil;
  EOEntity *entity = nil;

  NSAssert(propertyList, @"no propertyList");
  EOFLOGObjectLevelArgs(@"gsdb", @"propertyList=%@", propertyList);

  entity = [EOEntity entityWithPropertyList: propertyList
		     owner: self];

  NSAssert2([entity className], @"Entity %p named %@ has no class name",
	    entity, [entity name]);
  entity = [self _addEntity: entity];

  children = [self _childrenForEntityNamed: [entity name]];

  if (children)
    {
      [self notImplemented: _cmd];//TODO
      //may be: self  _registerChild:(id)param0
      //             forParent:entity...
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"EOEntityLoadedNotification"
    object: entity];

  return entity;
}

- (void) _addFakeEntityWithPropertyList: (NSDictionary*)propertyList
{
  //OK
  NSString *entityName;
  NSString *className;

  NSAssert(propertyList, @"no propertyList");

  entityName = [propertyList objectForKey: @"name"];
  className = [propertyList objectForKey: @"className"];

  NSAssert1(entityName, @"No entity name in %@", propertyList);
  NSAssert1(className, @"No class name in %@", propertyList);

  [self _setEntity: propertyList
        forEntityName: entityName
        className: className];

  DESTROY(_entities); //To force rebuild
}

- (id) _addEntity: (EOEntity*)entity
{
  //Seems OK
  NSString *entityClassName;

  NSAssert(entity, @"No entity to add");
  EOFLOGObjectLevelArgs(@"gsdb", @"model _addEntity=%@", [entity name]);

  entityClassName = [entity className];
  NSAssert2(entityClassName, @"Entity %p named %@ has no class name",
	    entity, [entity name]);

  //May be returning a previous entity of that name if any ?
  [self _setEntity: entity
        forEntityName: [entity name]
        className: entityClassName];
  [entity _setModel: self];

  return entity;
}

//entity can be a EOEntity or an entity PList
- (void) _setEntity: (id)entity
      forEntityName: (NSString*)entityName
	  className: (NSString*)className
{
  NSAssert(entityName, @"No entity name");
  NSAssert(className, @"No class name");

  //Seems OK
  [_entitiesByName setObject: entity
                   forKey: entityName];

  NSAssert(_entitiesByClass, @"No entities by class");

  if (NSMapGet(_entitiesByClass, className))
    NSMapRemove(_entitiesByClass, className);

  NSMapInsertIfAbsent(_entitiesByClass, className, entity);
}

@end

@implementation EOModel (EOModelEditing)

- (void) setName: (NSString *)name
{
  if (![name isEqualToString: _name])
    {
      //TODO
/*
      //???
      self retain;
      self modelGroup;
      //todo if modelgroup;
*/
      ASSIGN(_name, name);
/*
      self modelGroup;
      self release;
*/
    }
}

- (void) setAdaptorName: (NSString *)adaptorName
{
  ASSIGN(_adaptorName, adaptorName);
}

- (void) setConnectionDictionary: (NSDictionary *)connectionDictionary
{
  ASSIGN(_connectionDictionary, connectionDictionary);
}

- (void) setUserInfo: (NSDictionary *)userInfo
{
  [self willChange];
  ASSIGN(_userInfo, userInfo);
}

- (void) setDocComment: (NSString *)docComment
{
  [self willChange];
  ASSIGN(_docComment, docComment);
}

- (void) addEntity: (EOEntity *)entity
{
  NSString *entityName = [entity name];
//  void *entitiesClass;
//  int count;
  NSString *className = nil;

  if ([self entityNamed: [entity name]])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: \"%@\" already registered as entity name ",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 entityName];

  /* Do not access _entities until cache is triggered */
  if ([self createsMutableObjects])
    [(GCMutableArray *)[self entities] addObject: entity];
  else
    {
      id e = [GCMutableArray arrayWithArray: [self entities]];

      [e addObject: entity];
      ASSIGNCOPY(_entities, e);
    }

  NSAssert(_entitiesByClass, @"No _entitiesByClass");

  className = [entity className];
  NSAssert1(className, @"No className in %@", entity);

  if (NSMapGet(_entitiesByClass, className))
    NSMapRemove(_entitiesByClass, className);

  NSMapInsertIfAbsent(_entitiesByClass, className, entity);

  [_entitiesByName setObject: entity 
                   forKey: entityName];
  [entity setModel: self];
}

- (void) removeEntity: (EOEntity *)entity
{
  NSString *className = nil;

  [entity setModel: nil];
  [_entitiesByName removeObjectForKey: [entity name]];

  NSAssert(_entitiesByClass, @"No _entitiesByClass");

  className = [entity className];
  NSAssert1(className, @"No className in %@", entity);
  NSMapRemove(_entitiesByClass, className);

  /* Do not access _entities until cache is triggered */
  if ([self createsMutableObjects])
    [(GCMutableArray *)[self entities] removeObject: entity];
  else
    {
      id e = [GCMutableArray arrayWithArray: [self entities]];

      [e removeObject: entity];
      ASSIGNCOPY(_entities, e);
    }
}

- (void) removeEntityAndReferences: (EOEntity *)entity;
{
  [self removeEntity: entity];
  // TODO;
}

- (void) addStoredProcedure: (EOStoredProcedure *)storedProcedure
{
  if ([self storedProcedureNamed: [storedProcedure name]])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: \"%@\" already registered as stored procedure name ",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 [storedProcedure name]];
  
  if ([self createsMutableObjects])
    [(GCMutableArray *)_storedProcedures addObject: storedProcedure];
  else
    {
      _storedProcedures = [[[GCMutableArray alloc] initWithArray:[_storedProcedures autorelease] copyItems:NO]
			    autorelease];
      [(GCMutableArray *)_storedProcedures addObject: storedProcedure];
      _storedProcedures = [[GCArray alloc] initWithArray:_storedProcedures copyItems:NO];
    }
}

- (void) removeStoredProcedure: (EOStoredProcedure *)storedProcedure
{
  if ([self createsMutableObjects])
    [(GCMutableArray *)_storedProcedures removeObject: storedProcedure];
  else
    {
      _storedProcedures = [[_storedProcedures autorelease] mutableCopy];
      [(GCMutableArray *)_storedProcedures removeObject: storedProcedure];
      _storedProcedures = [[GCArray alloc] initWithArray:[_storedProcedures autorelease] copyItems:NO];
    }
}

- (void) setModelGroup: (EOModelGroup *)group
{
  EOFLOGObjectFnStart();

//call group _addSubEntitiesCache:
  _group = group;

  EOFLOGObjectFnStop();
}

- (void) loadAllModelObjects
{
  //Ayers: Review
  //NSArray *storedProcedures = [self storedProcedures];
  //TODO something if storedProcedures ?
  //NSArray *entities = [self entities];

  //TODO something if entities ?
  [self willChange];
}

- (NSArray *) referencesToProperty: property
{
  // TODO
  [self notImplemented: _cmd];

  return nil;
}

- (NSArray *) externalModelsReferenced
{
  // TODO;
  [self notImplemented: _cmd];

  return nil;
}

@end


@implementation EOModel (EOModelBeautifier)

- (void) beautifyNames
{
  NSArray  *listItems;
  NSString *newString = [NSString string];
  int	    anz, i, count;
 
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOModel");
  
  /* Makes the receiver's name conform to a standard convention. 
     Names that conform to this style are all lower-case except 
     for the initial letter of each embedded word other than the 
     first, which is upper case. Thus, "NAME" becomes "name", and 
     "FIRST_NAME" becomes "firstName". */
  
  if ((_name) && ([_name length] > 0))
    {
      listItems = [_name componentsSeparatedByString: @"_"];
      newString = [newString stringByAppendingString:
			       [(NSString *)[listItems objectAtIndex: 0]
					    lowercaseString]];
      anz = [listItems count];

      for (i = 1; i < anz; i++)
	{
	  newString = [newString stringByAppendingString:
				   [(NSString *)[listItems objectAtIndex: i]
						capitalizedString]];
	}

      // Exception abfangen
      NS_DURING
	{
	  // Model Name
	  [self setName: newString];

	  // Entites
	  /* Do not access _entities until cache is triggered */
	  if ([self entities] && (count = [_entities count]))
	    {
	      for (i = 0; i < count; i++)
		[(EOEntity *)[_entities objectAtIndex:i] beautifyName];
	    }
	}
      NS_HANDLER
	NSLog(@"%@ in Class: EOEntity , Method: beautifyName >> error : %@",
	      [localException name], [localException reason]);
      NS_ENDHANDLER;
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOModel");
}

@end

@implementation EOModel (EOModelPrivate)
/**
 * Returns a string that can be uses as a model path to load or save
 * the model.  If chkFS is YES, then the path is searched.  If path
 * does not include a path extension then first .eomodeld checked.  If that
 * fails then .eomodel is searched.  Call this method to format the path
 * provided before saving the model with chkFS NO.  Call this method to
 * format the path provided before loading a model with chkFS YES.
 */
+ (NSString *) _formatModelPath: (NSString *)path checkFileSystem: (BOOL)chkFS
{
  NSFileManager *fileManager;
  NSString *lastPathComponent = nil;
  NSString *pathExtension = nil;
  NSString *searchPath = path;
  NSString *returnPath = path;

  lastPathComponent = [path lastPathComponent];
  pathExtension = [lastPathComponent pathExtension];

  if ([lastPathComponent isEqualToString: @"index.eomodeld"] == NO)
    {
      if ([pathExtension isEqualToString: @"eomodeld"] == NO)
	{
	  searchPath =
	      [searchPath stringByAppendingPathExtension: @"eomodeld"];
	}
      searchPath =
	  [searchPath stringByAppendingPathComponent: @"index.eomodeld"];
    }
        
  searchPath = [searchPath stringByStandardizingPath];

  if (chkFS==YES)
    {
      fileManager = [NSFileManager defaultManager];

      if ([fileManager fileExistsAtPath: searchPath] == YES)
        {
          returnPath = searchPath;
	}
      else
        {
	  searchPath = path;
          if ([pathExtension isEqualToString: @"eomodel"] == NO)
	    {
	      searchPath =
		  [searchPath stringByAppendingPathComponent: @"eomodel"];
	    }
	  searchPath = [searchPath stringByStandardizingPath];
	  if ([fileManager fileExistsAtPath: searchPath] == YES)
	    {
	      returnPath = searchPath;
	    }
	}
      NSAssert1(returnPath!=nil,@"No valid Model found at path:%@", path);
    }
  else 
    {
      returnPath = searchPath;
    }

  lastPathComponent = [returnPath lastPathComponent];
  if ([lastPathComponent isEqualToString: @"index.eomodeld"] == YES)
    {
      returnPath = [returnPath stringByDeletingLastPathComponent];
    }

  return returnPath;
}

- (void) setCreateMutableObjects: (BOOL)flag
{
  if (_flags.createsMutableObjects != flag)
    {
      _flags.createsMutableObjects = flag;
      
      /* Do not access _entities until cache is triggered */
      if (_flags.createsMutableObjects)
	_entities = [[GCMutableArray alloc] initWithArray:[[self entities] autorelease] copyItems:NO];
      else
	_entities = [[GCArray alloc] initWithArray:[[self entities] autorelease] copyItems:NO];
    }
}

- (BOOL) createsMutableObjects
{
  return _flags.createsMutableObjects;
}

- (EOEntity *) _verifyBuiltEntityObject: (id)entity
				  named: (NSString*)name
{
  if ([entity isKindOfClass: [EOEntity class]] == NO)
    {
      [EOObserverCenter suppressObserverNotification];

      NS_DURING
        {
          NSString *basePath = nil;
          NSString *plistPathName = nil;
          NSDictionary *propList = nil;

          EOFLOGObjectLevelArgs(@"gsdb", @"name=%@", name);

          if (!name && [entity isKindOfClass: [NSDictionary class]])
            name = [entity objectForKey: @"name"];

          EOFLOGObjectLevelArgs(@"gsdb", @"name=%@", name);
          NSAssert1(name, @"No name for entity %@", entity);
          EOFLOGObjectLevelArgs(@"gsdb", @"[self path]=%@", [self path]);

          basePath = [self path]; 
          [RETAIN(entity) autorelease]; //so it won't be lost in _removeEntity

          EOFLOGObjectLevelArgs(@"gsdb", @"basePath =%@", basePath);

	  if ([basePath hasSuffix: @"eomodel"])
	    {
	      propList = entity;
	    }
	  else
	    {
	      plistPathName = [[basePath stringByAppendingPathComponent: name]
				stringByAppendingPathExtension: @"plist"];

	      EOFLOGObjectLevelArgs(@"gsdb", @"entity plistPathName =%@",
				    plistPathName);

	      propList 
		= [NSDictionary dictionaryWithContentsOfFile: plistPathName];
	      EOFLOGObjectLevelArgs(@"gsdb", @"entity propList=%@", propList);

	      if (!propList)
		{
		  if ([[NSFileManager defaultManager]
			fileExistsAtPath: plistPathName])
		    {
		      NSAssert1(NO,
				@"%@ is not a dictionary or is not readable.",
				plistPathName);
		    }
		  else
		    {
		      propList = entity;
		      NSWarnLog(@"%@ doesn't exists. Using %@",
				plistPathName, propList);
		    }
		}
	    }

          [self _removeEntity: entity];
          EOFLOGObjectLevelArgs(@"gsdb", @"entity propList=%@", propList);

          entity = [self _addEntityWithPropertyList: propList];
        }
      NS_HANDLER
        {
          [EOObserverCenter enableObserverNotification];
          [localException raise];
        }
      NS_ENDHANDLER;
      [EOObserverCenter enableObserverNotification];
    }

  return entity;
}

@end /* EOModel (EOModelPrivate) */
