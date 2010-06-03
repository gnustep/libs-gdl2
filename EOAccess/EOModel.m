/** 
   EOModel.m <title>EOModel Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSBundle.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#endif


#include <GNUstepBase/GSObjCRuntime.h>

#include <EOControl/EOGenericRecord.h>
#include <EOControl/EOFault.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOAccessFault.h>
#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>

#include "EOEntityPriv.h"
#include "EOPrivate.h"
#include "EOAttributePriv.h"

#define DEFAULT_MODEL_VERSION 2

NSString *EOEntityLoadedNotification = @"EOEntityLoadedNotification";

@interface EOModel (EOModelPrivate)

+ (NSString *) _formatModelPath: (NSString *)path checkFileSystem: (BOOL)chkFS;

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

- (id)init
{


  if ((self = [super init]))
    {
      // Turbocat
      _version = DEFAULT_MODEL_VERSION;
      
      _entitiesByName = [NSMutableDictionary new];
      _entitiesByClass = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks, 
						  NSObjectMapValueCallBacks,
						  8,
						  [self zone]);
      _storedProcedures = [NSMutableArray new];
  
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



  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [[self entities] makeObjectsPerformSelector:@selector(_setModel:)
	  			withObject:nil];
  if (_entitiesByClass)
    {
      NSFreeMapTable(_entitiesByClass);
      _entitiesByClass = NULL;
    }
  DESTROY(_storedProcedures);
  DESTROY(_entitiesByName);
  DESTROY(_entities);
  DESTROY(_name);
  DESTROY(_path);
  DESTROY(_adaptorName);
  DESTROY(_connectionDictionary);
  DESTROY(_userInfo);
  DESTROY(_internalInfo);
  DESTROY(_docComment);

  [super dealloc];
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

  NSAssert(name,@"No entity name");

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
  if (!_entities)
  {
    NSArray *entityNames = [self entityNames];
    
    // we need an mutable array here, otherwise we cannot remove entities from it. -- dw
    ASSIGN(_entities,[NSMutableArray arrayWithArray:[self resultsOfPerformingSelector: @selector(entityNamed:)
                       withEachObjectInArray: entityNames]]);
  }
  
  return _entities;
}

- (NSArray*) entityNames
{
  return [[_entitiesByName allKeys]
	   sortedArrayUsingSelector: @selector(compare:)];
}

- (NSArray *)storedProcedureNames
{
  /* We do not load procedures lazy 
     so we can rely on the instance variable.  */
  return [_storedProcedures valueForKey: @"name"];
}

- (EOStoredProcedure*)storedProcedureNamed: (NSString *)name
{
  EOStoredProcedure *proc;
  NSString *procName;
  unsigned i,n;

  n = [_storedProcedures count];
  for (i=0; i<n; i++)
    {
      proc = [_storedProcedures objectAtIndex: i];
      procName = [proc name];
      if ([procName isEqual: name])
	{
	  return proc;
	}
    }

  return nil;
}

- (NSArray*)storedProcedures
{
  /* We do not load procedures lazy 
     so we can rely on the instance variable.  */
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
      NSAssert1(fileContents!=nil, @"File %@ could not be read.", indexPath);
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
 * <p>Writes the receivers plist representation into an
 * .eomodeld file wrapper located at path.  </p>
 * <p>Depending on the the path extension .eomodeld or .eomodel
 * the corresponding format will be used.
 * If the path has neither .eomodeld nor .eomodel path
 * extension, .eomodeld will be used.</p>
 * <p>If the file located at path already exists, a back is created
 * by appending a '~' character to file name.
 * If a backup file already exists, when trying to create a backup,
 * the old backup will be deleted.</p>
 * <p>If any of the file operations fail, an NSInvalidArgumentException
 * will be raised.</p>
 * <p>This method as the side effeect of setting the receivers path and
 * name.  The this change can happen even if the write operation fails
 * with an exception.</p>
 */
- (void)writeToFile: (NSString *)path
{
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSMutableDictionary	*pList;
  NSDictionary		*entityPList;
  NSDictionary		*stProcPList;
  NSEnumerator		*entityEnum;
  NSEnumerator		*stProcEnum;
  NSString              *fileName;
  NSString              *extension;
  BOOL writeSingleFile;

  [self loadAllModelObjects];

  path = [path stringByStandardizingPath];
  extension = [path pathExtension];

  if ([extension isEqualToString: @"eomodeld"] == NO
      && [extension isEqualToString: @"eomodel"] == NO)
    {
      path = [path stringByAppendingPathExtension: @"eomodeld"];
      extension = [path pathExtension];
    }
  
  writeSingleFile = [extension isEqualToString: @"eomodel"] ? YES : NO;

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

  [self _setPath: path];

  pList = [NSMutableDictionary dictionaryWithCapacity: 10];

  [self encodeIntoPropertyList: pList];

  if (writeSingleFile == NO
      && [mgr createDirectoryAtPath: path attributes: nil] == NO)
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

  stProcEnum = [[pList objectForKey: @"storedProcedures"] objectEnumerator];
  while (writeSingleFile == NO
	 && (stProcPList = [stProcEnum nextObject]))
    {
      NSString *fileName;

      fileName = [stProcPList objectForKey: @"name"];
      fileName = [fileName stringByAppendingPathExtension: @"storedProcedure"];
      fileName = [path stringByAppendingPathComponent: fileName];
      if ([stProcPList writeToFile: fileName atomically: YES] == NO)
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

- (id)initWithTableOfContentsPropertyList: (NSDictionary *)tableOfContents
                                     path: (NSString *)path
{
  //OK
  NS_DURING
    {
      if ((self = [self init]))
        {
	  NSString *modelPath;
          NSString *versionString = nil;
          NSArray  *entities = nil;
          int i, count = 0;

          EOFLOGObjectLevelArgs(@"gsdb", @"tableOfContents=%@",
				tableOfContents);

	  /* The call to _setPath: also sets the name implicitly. */
	  modelPath = [isa _formatModelPath: path checkFileSystem: YES];
	  [self _setPath: modelPath];
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
              NSArray *storedProcedures 
		= [tableOfContents objectForKey: @"storedProcedures"];

              count = [storedProcedures count];
              for (i = 0; i < count; i++)
                {
                  EOStoredProcedure *proc;
                  NSDictionary *plist;
                  NSString *fileName;
		  NSString *procName;
		  NSString *fullPath;

		  procName = [storedProcedures objectAtIndex: i];

                  fileName = [procName stringByAppendingPathExtension:
					 @"storedProcedure"];

		  fullPath = [_path stringByAppendingPathComponent: fileName];
                  plist 
		    = [NSDictionary dictionaryWithContentsOfFile: fullPath];

		  NSAssert2([procName isEqual: [plist objectForKey: @"name"]],
			    @"Name mismatch: index.plist: %@"
			    @" *.storedProcedure: %@", procName,
			    [plist objectForKey: @"name"]);
                  [markSP setObject: plist forKey: procName];

                  proc
		    = [EOStoredProcedure storedProcedureWithPropertyList: plist
					 owner: self];
                  [self addStoredProcedure: proc];
                }

              count = [_storedProcedures count];
              for (i = 0; i < count; i++)
                {
		  EOStoredProcedure *proc;
		  NSString *name;
		  NSDictionary *plist;

		  proc = [_storedProcedures objectAtIndex: i];
		  name = [proc name];
		  plist = [markSP objectForKey: name];

		  if (plist)
		    {
		      [proc awakeWithPropertyList: plist];
		    }
		}
            }
        
          entities = [tableOfContents objectForKey: @"entities"];
          count = [entities count];

          for (i=0; i<count; i++)
            {
	      NSDictionary *entityPList = [entities objectAtIndex: i];
              [self _addFakeEntityWithPropertyList: entityPList];
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

- (void)encodeTableOfContentsIntoPropertyList:
  (NSMutableDictionary *)propertyList
{
  int i, count;
  NSMutableArray *entitiesArray;
  NSMutableArray *stProcArray;

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
      EOEntity *parent;

      entity = [_entities objectAtIndex: i];
      entityPList = [NSMutableDictionary dictionaryWithCapacity: 2];

      [entityPList setObject: [entity className] forKey: @"className"];
      [entityPList setObject: [entity name] forKey: @"name"];

      parent = [entity parentEntity];
      if (parent)
        [entityPList setObject: [parent name] forKey: @"parent"];

      [entitiesArray addObject: entityPList];
    }

  stProcArray = [_storedProcedures valueForKey: @"name"];
  [propertyList setObject: stProcArray forKey: @"storedProcedures"];
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
          
              entity 
		= AUTORELEASE([[EOEntity alloc] initWithPropertyList: plist
						owner: self]);
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
  return;
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
	  EOEntity *entity = [_entities objectAtIndex: i];
	  
	  [entity encodeIntoPropertyList: entityPList];
	  [entitiesArray addObject: entityPList];
        }
    }

  count = [_storedProcedures count];
  if (count > 0)
    {
      NSMutableArray *stArray = [NSMutableArray arrayWithCapacity: count];

      [propertyList setObject: stArray forKey: @"storedProcedures"];
      for (i = 0; i < count; i++)
        {
	  NSMutableDictionary *stPList = [NSMutableDictionary dictionary];
	  EOStoredProcedure *proc = [_storedProcedures objectAtIndex: i];

	  [proc encodeIntoPropertyList: stPList];
	  [stArray addObject: stPList];
        }
    }
}

@end

@implementation EOModel (EOModelHidden)

- (NSMutableDictionary *) _loadFetchSpecificationDictionaryForEntityNamed:(NSString *) entName
{
  NSEmitTODO();
  
  return nil;
}

-(void) _classDescriptionNeeded: (NSNotification *)notification
{
  //TODO
  NSString *notificationName = nil;



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
  return;
}

- (void) _setInheritanceLinks: (id)param0
{
  // TODO
  [self notImplemented: _cmd];
  return;
}

/**
 * Before removing attributes we need to remove all references
 */

- (void) _removePropertiesReferencingProperty:(id) property
{
  NSUInteger refCount, refIdx = 0;
  NSArray * references = nil;

  references = [self referencesToProperty:property];
    
  refCount = [references count];
  
  for (; refIdx < refCount; refIdx++) {
    id refObj = [references objectAtIndex:refIdx];
    
    if ([refObj class] == [EOAttribute class])
    {
      [[(EOAttribute*) refObj entity] removeAttribute:refObj];
    } else {
      [[(EORelationship*) refObj entity] removeRelationship:refObj];
    }
  }
    
}

/**
 * Before removing entities we need to remove all references
 */

- (void) _removePropertiesReferencingEntity:(EOEntity*) entity
{
  int i;
  
  for (i = 0; i < 2; i++) 
  {
    NSArray        * attrsOrRels;
    NSArray        * names = nil;
    NSUInteger index = 0;
    NSUInteger count = 0;
    
    if ((i == 0))
    {
      attrsOrRels = [entity attributes];
    } else {
      attrsOrRels = [entity relationships];
    }
    // get name from the array
    names = [attrsOrRels resultsOfPerformingSelector:@selector(name)];
    
    for (count = [names count]; index < count; index++) 
    {
      id attrOrRel = nil;
      
      if (i == 0) {
        attrOrRel = [entity attributeNamed:[names objectAtIndex:index]];
      } else {
        attrOrRel = [entity relationshipNamed:[names objectAtIndex:index]];
      }
      
      if (attrOrRel) {
        [self _removePropertiesReferencingProperty:attrOrRel];
      }
      
    }
    
  }
  
}

- (void) _removeEntity: (EOEntity *)entity
{
  //should be ok
  NSString *entityName = nil;
  NSString *entityClassName = nil;

  if ([entity isKindOfClass: [EOEntity class]])
    {
      entityName = [entity name];
      entityClassName = [entity className];
    }
  else
    {
      entityName = [(NSDictionary *)entity objectForKey: @"name"];
      entityClassName = [(NSDictionary *)entity  objectForKey: @"className"];
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

  entity = AUTORELEASE([[EOEntity alloc] initWithPropertyList: propertyList
					 owner: self]);

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
  [entity awakeWithPropertyList:propertyList];

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

  NSAssert1([_entitiesByName objectForKey: entityName] == nil,
	    @"Entity '%@' is already registered with this model",
	    entityName);
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
      EOModelGroup *group;

      AUTORELEASE(RETAIN(self));

      group = [self modelGroup];
      if (group)
	{
	  [group removeModel: self];
	}

      [self willChange];
      ASSIGNCOPY(_name, name);

      if (group)
	{
	  [group addModel: self];
	}
    }
}

- (void) setAdaptorName: (NSString *)adaptorName
{
  [self willChange];
  ASSIGNCOPY(_adaptorName, adaptorName);
}

- (void) setConnectionDictionary: (NSDictionary *)connectionDictionary
{
  [self willChange];
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
  ASSIGNCOPY(_docComment, docComment);
}

- (void) addEntity: (EOEntity *)entity
{
  NSString *entityName = [entity name];
//  void *entitiesClass;
//  int count;
  NSString *className = nil;

  NSAssert1([self entityNamed: [entity name]] == nil,
	    @"Entity '%@' is already registered with this model",
	    entityName);

  NSAssert2([entity model]==nil,
	    @"Entity '%@' is already owned by model '%@'.",
	    [entity name], [[entity model] name]);

  [self willChange];
  
  /* _entities is sorted. we want a new one! */
  if (_entities) {
    DESTROY(_entities);
  }

  NSAssert(_entitiesByClass, @"No _entitiesByClass");

  className = [entity className];
  NSAssert1(className, @"No className in %@", entity);

  if (NSMapGet(_entitiesByClass, className))
    NSMapRemove(_entitiesByClass, className);

  NSMapInsertIfAbsent(_entitiesByClass, className, entity);

  [_entitiesByName setObject: entity 
                   forKey: entityName];
  [entity _setModel: self];
}

/**
 * Removes the entity without performing any referential integrity checking.
 */
- (void) removeEntity: (EOEntity *)entity
{
  // TODO: find out why removeEntity: and _removeEntity: exists
  [self _removeEntity:entity];
}

- (void) removeEntityAndReferences: (EOEntity *)entity
{
  NSArray      * subEntities;
  NSEnumerator * subEnumer;
  EOEntity     * subEntity;
  
  [self _removePropertiesReferencingEntity:entity];
  subEntities = [NSArray arrayWithArray:[entity subEntities]];
  subEnumer = [subEntities objectEnumerator];
                 
                 
  while ((subEntity = [subEnumer nextObject])) {
    [entity removeSubEntity:subEntity];
  }
    
  [self removeEntity: entity];
}

- (void)addStoredProcedure: (EOStoredProcedure *)storedProcedure
{
  if ([self storedProcedureNamed: [storedProcedure name]])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: \"%@\" already registered as stored procedure name ",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 [storedProcedure name]];
  NSAssert(_storedProcedures, @"Uninitialised _storedProcedures!");
  [self willChange];
  [(NSMutableArray *)_storedProcedures addObject: storedProcedure];
}

- (void)removeStoredProcedure: (EOStoredProcedure *)storedProcedure
{
  NSAssert(_storedProcedures, @"Uninitialised _storedProcedures!");

  [self willChange];
  [(NSMutableArray *)_storedProcedures removeObject: storedProcedure];
}

- (void) setModelGroup: (EOModelGroup *)group
{


//call group _addSubEntitiesCache:
  _group = group;


}

- (void)loadAllModelObjects
{
  NSArray *entityNames = [_entitiesByName allKeys];
  NSUInteger i,n = [entityNames count];
  
  [self storedProcedures];
  
  for (i=0; i<n; i++)
  {
    NSString *name = [entityNames objectAtIndex: i];
    id entity = [_entitiesByName objectForKey: name];
    
    // the reference imp does not do verify here.
    [self _verifyBuiltEntityObject: entity
                             named: name];
    
    [entity _loadEntity];
  }
}

/**
 * Returns an array of flattened attributes and relationships in the receiver's
 * entities that reference property, or nil if nothing references it.
 */
- (NSArray *) referencesToProperty: (id)property
{
  // TODO test
  NSEnumerator *entityEnumerator = [[self entities] objectEnumerator];
  IMP enumNO=NULL;
  EOEntity *ent;
  NSMutableArray *refProps = [NSMutableArray array];
  
  while ((ent = GDL2_NextObjectWithImpPtr(entityEnumerator,&enumNO)))
  {
    NSEnumerator *propEnumerator = [[ent attributes] objectEnumerator];
    EOAttribute *attr;
    EORelationship *rel;
    IMP propEnumNO=NULL;
    
    while ((attr = GDL2_NextObjectWithImpPtr(propEnumerator,&propEnumNO)))
    {
      if ([attr referencesProperty:property])
	    {
        NSArray * newArray;
	      [refProps addObject:attr];
        
        newArray = [self referencesToProperty:attr];
        if ([newArray count] > 0) {
          [refProps addObjectsFromArray:newArray];
        }
	    }
    }
    
    propEnumerator = [[ent relationships] objectEnumerator];
    propEnumNO = NULL;
    while ((rel = GDL2_NextObjectWithImpPtr(propEnumerator, &propEnumNO)))
    {
      if ([rel referencesProperty:property])
	    {
        NSArray * newArray;
	      [refProps addObject:rel];
        
        newArray = [self referencesToProperty:rel];
        if ([newArray count] > 0) {
          [refProps addObjectsFromArray:newArray];
        }
	    }
    }
  }	
  
  return [refProps count] ? [NSArray arrayWithArray:refProps] : nil;
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
          AUTORELEASE(RETAIN(entity)); //so it won't be lost in _removeEntity

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

/*
  This method rebuilds the caches:
  _entitiesByName, _subEntitiesCache, _entitiesByClass
  from _entities.  Insure this works for real entities and dictionaries
  which could be contained in _entities.  Also note that className need
  not be unique.
*/
- (void)_updateCache
{
  NSArray  *names;
  EOEntity *entity;
  NSString *className;
  unsigned int i,c;

  DESTROY(_subEntitiesCache);
  NSResetMapTable(_entitiesByClass);

  names = [_entities valueForKey: @"name"];
  DESTROY(_entitiesByName);
  _entitiesByName = [[NSMutableDictionary alloc] initWithObjects: _entities
						 forKeys: names];
  for (i = 0, c = [_entities count]; i < c; i++)
    {
      entity = [_entities objectAtIndex: i]; /* entity or dictionary */
      className = [entity valueForKey: @"className"];
      NSMapInsertIfAbsent(_entitiesByClass, className, entity);
    }
}
@end /* EOModel (EOModelPrivate) */

