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

static char rcsId[] = "$Id$";

#import <Foundation/Foundation.h>

#import <Foundation/NSBundle.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSObjCRuntime.h>

#import <Foundation/NSException.h>

#import <EOAccess/EOModel.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EOEntityPriv.h>
#import <EOAccess/EOStoredProcedure.h>
#import <EOAccess/EOModelGroup.h>
#import <EOAccess/EOAccessFault.h>

#import <EOControl/EOGenericRecord.h>
#import <EOControl/EOFault.h>
#import <EOControl/EOKeyGlobalID.h>
#import <EOControl/EOClassDescription.h>
#import <EOControl/EOObserver.h>
#import <EOControl/EONSAddOns.h>
#import <EOControl/EODebug.h>

#include <sys/stat.h>


NSString *EOEntityLoadedNotification = @"EOEntityLoadedNotification";


@implementation EOModel

+ (EOModel *)model
{
  return [[[self alloc] init] autorelease];
}

+ (NSString *)findPathForModelNamed: (NSString *)modelName
{
  NSString *modelPath = nil;
  NSString *tmpModelName = nil;
  NSString *tmpPath = nil;
  NSBundle *bundle = nil;
  NSString *paths[] = { @"~/Library/Models",
			@"/LocalLibrary/Models",
			@"/NextLibrary/Models",
			nil };

  tmpModelName = [modelName lastPathComponent];
  NSDebugMLLog(@"gsdb", @"modelName=%@ tmpModelName=%@",
	       modelName, tmpModelName);

  tmpPath = [[modelName stringByStandardizingPath]
              stringByDeletingLastPathComponent]; 
  NSDebugMLLog(@"gsdb", @"modelName=%@ tmpPath=%@", modelName, tmpPath);

  bundle = [NSBundle mainBundle];
  modelPath = [bundle pathForResource: modelName
                      ofType: @"eomodel"];

  NSDebugMLLog(@"gsdb", @"modelName=%@ modelPath=%@", modelName, modelPath);

  if (!modelPath)
    {
      modelPath = [bundle pathForResource: modelName
                          ofType: @"eomodeld"];

      NSDebugMLLog(@"gsdb", @"modelName=%@ modelPath=%@",
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
          
          NSDebugMLLog(@"gsdb", @"modelName=%@ tmpPath=%@ tmpModelName=%@",
		       modelName, tmpPath, tmpModelName);

          bundle = [NSBundle bundleWithPath: tmpPath];
          
          modelPath = [bundle pathForResource: tmpModelName
                              ofType: @"eomodel"];

          NSDebugMLLog(@"gsdb", @"modelName=%@ modelPath=%@",
		       modelName, modelPath);

          if (!modelPath)
            {          
              modelPath = [bundle pathForResource: tmpModelName
                                  ofType: @"eomodeld"];
              NSDebugMLLog(@"gsdb", @"modelName=%@ modelPath=%@",
			   modelName, modelPath);

              if (!modelPath)
                {
                  int i;

                  for(i = 0; !modelPath && paths[i]; i++)
                    {
                      NSDebugMLLog(@"gsdb", @"Trying path:%@", paths[i]);

                      bundle = [NSBundle bundleWithPath: paths[i]];
                      
                      modelPath = [bundle pathForResource: modelName
                                          ofType: @"eomodel"];

                      NSDebugMLLog(@"gsdb", @"modelName=%@ modelPath=%@",
				   modelName, modelPath);

                      if (!modelPath)
                        {
                          modelPath = [bundle pathForResource: modelName
                                              ofType: @"eomodeld"];

                          NSDebugMLLog(@"gsdb", @"modelName=%@ modelPath=%@",
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

- (void)dealloc
{
  [NSNotificationCenter removeObserver: self];

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

- (void)gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  [(id)_group gcDecrementRefCount];
  NSDebugMLLog(@"gsdb", @"entities gcDecrementRefCount");

  [(id)_entities gcDecrementRefCount];
  NSDebugMLLog(@"gsdb", @"entitiesByName gcDecrementRefCount");

  [(id)_entitiesByName gcDecrementRefCount];
  NSDebugMLLog(@"gsdb", @"storedProcedures gcDecrementRefCount");

  [(id)_storedProcedures gcDecrementRefCount];
  NSDebugMLLog(@"gsdb", @"subEntitiesCache gcDecrementRefCount");

  [(id)_subEntitiesCache gcDecrementRefCount];

  EOFLOGObjectFnStop();
}

- (BOOL)gcIncrementRefCountOfContainedObjects
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

/*Mirko:
- (void)_registerClassDescForClass:(NSNotification *)notification
{
  EOEntityClassDescription *classDesc = nil;
  Class aClass = [notification object];
  int i;

  if (_entitiesByClass == NULL)
    return;

  for (i = 0; ((Class *)_entitiesByClass)[i]; i = i + 2)
    {
      if(aClass == ((Class *)_entitiesByClass)[i])
	{
          classDesc = [EOEntityClassDescription entityClassDescriptionWithEntity: ((EOEntity **)_entitiesByClass)[i+1]];

	  [EOClassDescription registerClassDescription:classDesc
			      forClass:aClass];

	  return;
	}
    }
}

- (void)_registerClassDescForEntityName:(NSNotification *)notification
{
  EOEntityClassDescription *classDesc;
  NSString *entityName = [notification object];
  EOEntity *entity;

  entity = [self entityNamed:entityName];

  if (entity)
    {
      classDesc = [EOEntityClassDescription entityClassDescriptionWithEntity: entity];

      [EOClassDescription registerClassDescription: classDesc
			  forClass: NSClassFromString([entity className])];
    }
}
*/

- (NSString *)path
{
  return _path;
}

- (NSString *)name
{
  return _name;
}

- (NSString *)adaptorName
{
  return _adaptorName;
}

- (NSString *)adaptorClassName
{
  return _adaptorClassName;
}

- (float)version
{
  return _version;
}

- (EOEntity *)entityNamed:(NSString *)name
{
  EOEntity *entity = nil;

  NSAssert(name,@"No entityt name");

  entity = [_entitiesByName objectForKey: name];
  entity = [self _verifyBuiltEntityObject: entity
                 named: name];

  return entity;
}

- (NSArray*)entities
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

- (NSArray *)entityNames
{
  return [_entitiesByName allKeys];
}

- (NSArray *)storedProcedureNames
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

- (EOStoredProcedure *)storedProcedureNamed: (NSString *)name
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

- (NSArray *)storedProcedures
{
  //TODO revoir ?
  if (!_storedProcedures)
    {
      NSArray *storedProcedures = nil;
      NSArray *storedProcedureNames = [self storedProcedureNames];

      NSDebugMLLog(@"gsdb", @"storedProcedureNames=%@", storedProcedureNames);

      storedProcedures = [self resultsOfPerformingSelector:
				 @selector(storedProcedureNamed:)
			       withEachObjectInArray: storedProcedureNames];

      NSDebugMLLog(@"gsdb", @"storedProcedures=%@", storedProcedures);

      ASSIGN(_storedProcedures, [GCArray arrayWithArray:storedProcedures]);
/*      [self performSelector:@selector(storedProcedureNamed:)
            withEachObjectInArray:storedProcedureNames];
*/
    }

  return _storedProcedures;
}

- (EOEntity *)entityForObject: object
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
      //  if([object isKindOfClass:[EOGenericRecord class]])
      //    return [object entity];      
      entityName = [object entityName];
    }

  if (entityName)
    entity = [self entityNamed:entityName];

  return entity;
}

- (NSDictionary *)connectionDictionary
{
  return _connectionDictionary;
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (NSString *)docComment
{
  return _docComment;
}

- (EOModelGroup *)modelGroup
{
  return _group;
}

+ (float)version
{
  return 2;
}

@end


@implementation EOModel (EOModelFileAccess)

+ (EOModel *)modelWithContentsOfFile: (NSString *)path
{
  return [[[self alloc] initWithContentsOfFile: path] autorelease];
}

- (id) initWithContentsOfFile: (NSString *)path
{
  NS_DURING
    {
      NSDictionary *propList = nil;
      NSString *completePath = [[self class] findPathForModelNamed: path];
      NSString *indexPath = nil;

      NSDebugMLLog(@"gsdb", @"path=%@", path);
      NSDebugMLLog(@"gsdb", @"completePath=%@", completePath);

      if ([[completePath pathExtension] isEqualToString: @"eomodeld"])
        indexPath = [completePath stringByAppendingPathComponent:
				    @"index.eomodeld"];
      else
        indexPath = completePath;

      NSDebugMLLog(@"gsdb", @"path=%@ completePath=%@ indexPath=%@",
		   path, completePath, indexPath);

      propList = [[NSString stringWithContentsOfFile: indexPath] propertyList];
      NSDebugMLLog(@"gsdb", @"propList=%@", propList);

      if (!propList)
        {
          NSLog(@"Loading model (path=%@ \n index path=%@) failed",
                path,
                indexPath);

          //Try loading directly from path
          if ([[path pathExtension] isEqualToString: @"eomodeld"])
            indexPath = [path stringByAppendingPathComponent:
				@"index.eomodeld"];
          else
            indexPath = path;

          NSDebugMLLog(@"gsdb", @"path=%@ completePath=%@ indexPath=%@",
		       path, completePath, indexPath);

          propList = [[NSString stringWithContentsOfFile: indexPath] propertyList];

          NSDebugMLLog(@"gsdb", @"propList=%@", propList);
        }

      //TODO test it
      NSAssert2(propList, @"Loading model (path=%@ \n index path=%@) failed",
                path,
                indexPath);

      //what to do if it fail ?
      if ((self = [self initWithTableOfContentsPropertyList: propList
			path: path]))
        {
        }
      else
        {
          NSEmitTODO();  
          return [self notImplemented: _cmd]; //TODO
        }
    }
  NS_HANDLER
    {
      NSLog(@"exception in EOModel initWithContentsOfFile:");
      NSLog(@"exception=%@", localException);
/*      localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                              @"In EOModel initWithContentsOfFile:");*/
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  return self;
}

- (void)writeToFile: (NSString *)path
{
  NSMutableDictionary *pList;
  NSDictionary *entityPList;
  NSEnumerator *entityEnum;

  path = [path stringByStandardizingPath];
  path = [[path stringByDeletingPathExtension]
	   stringByAppendingPathExtension: @"eomodeld"];

  pList = [NSMutableDictionary dictionaryWithCapacity: 10];

  [self encodeIntoPropertyList: pList];

  mkdir([path cString], S_IRWXU | S_IRWXG | S_IRWXO);

  entityEnum = [[pList objectForKey:@"entities"] objectEnumerator];
  while ((entityPList = [entityEnum nextObject]))
    {
      NSString *fileName;
      NSArray *entityArray;

      fileName = [path stringByAppendingPathComponent:
			 [NSString stringWithFormat: @"%@.plist",
				   [entityPList objectForKey: @"name"]]];
      entityArray = [NSArray arrayWithObject: entityPList];
      [entityArray writeToFile: fileName atomically: YES];
    }

  {
    NSString *fileName;

    fileName = [path stringByAppendingPathComponent: @"index.eomodeld"];

    [pList removeAllObjects];
    [self encodeTableOfContentsInfoPropertyList: pList];
    [pList writeToFile:fileName atomically: YES];
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
          NSArray *entities = nil;
          int i, count = 0;

          [self _setPath: path];
          _name = [[EOModel findPathForModelNamed: _path] retain];

          NSDebugMLLog(@"gsdb", @"tableOfContents=%@", tableOfContents);
          NSAssert1(_name, @"No name for model (path=%@)", path);          

          [self setName: _name];//??
          versionString = [tableOfContents objectForKey: @"EOModelVersion"];

          if (versionString)
            _version = [versionString floatValue];

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
/*      localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                              @"In EOModel initWithTableOfContentsPropertyList:path:");*/
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  return self;
}

- (void)encodeTableOfContentsInfoPropertyList: (NSMutableDictionary *)propertyList
{
  int i, count;
  NSMutableArray *entitiesArray;

  [propertyList setObject: [[NSNumber numberWithFloat: [isa version]] stringValue]
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

  count = [_entities count];
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
          _adaptorName = [[propertyList objectForKey: @"adaptorName"] retain];
          _connectionDictionary = [[propertyList objectForKey:
						   @"connectionDictionary"]
                                    retain];
          _userInfo = [[propertyList objectForKey: @"userInfo"] retain];
          _docComment = [[propertyList objectForKey: @"docComment"] retain];

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
              NSDebugMLLog(@"gsdb", @"plist=%@ [%@]", plist, [plist class]);
          
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

          enumerator = [_entities objectEnumerator];
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
/*      localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                              @"In EOModel initWithPropertyList:owner:");
*/
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

  [propertyList setObject: [[NSNumber numberWithFloat: [isa version]]
			     stringValue]
		forKey: @"EOModelVersion"];

  if(_name)
    [propertyList setObject: _name forKey: @"name"];
  if(_adaptorName)
    [propertyList setObject: _adaptorName forKey: @"adaptorName"];
  if (_adaptorClassName) 
    [propertyList setObject: _adaptorClassName forKey: @"adaptorClassName"];
  if(_connectionDictionary)
    [propertyList setObject: _connectionDictionary
		  forKey: @"connectionDictionary"];
  if(_userInfo)
    [propertyList setObject: _userInfo forKey: @"userInfo"];
  if(_internalInfo)
    [propertyList setObject: _internalInfo forKey: @"internalInfo"];
  if(_docComment)
    [propertyList setObject: _docComment forKey: @"docComment"];

  count = [_entities count];

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

  NSDebugMLLog(@"gsdb", @"notificationName=%@", notificationName);

  if ([notificationName
	isEqualToString: EOClassDescriptionNeededForClassNotification])
    {
      Class aClass = [notification object];
      EOClassDescription *classDescription = nil;
      EOEntity *entity = nil;
      NSString *entityClassName = nil;

      NSDebugMLLog(@"gsdb", @"notification=%@ aClass=%@", notification, aClass);
      NSAssert(aClass, @"No class");

      entity = [self _entityForClass: aClass];

      if (!entity)
        {
          NSAssert1((!GSObjCIsKindOf(aClass, [EOGenericRecord class])),
                    @"No entity for class %@", aClass);
        }
      else
        {
          classDescription = [entity classDescriptionForInstances];
          NSDebugMLLog(@"gsdb", @"classDescription=%@", classDescription);

          entityClassName = [entity className];
          NSDebugMLLog(@"gsdb",@"entityClassName=%@",entityClassName);

          [EOClassDescription registerClassDescription: classDescription
                              forClass: NSClassFromString(entityClassName)];

          /*      classDescription = [[EOClassDescription new] autorelease];
                  NSDebugMLLog(@"gsdb", @"classDescription=%@ aClass=%@", classDescription, aClass);
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
      EOEntity *entity;
      NSString *entityClassName;

      NSDebugMLLog(@"gsdb", @"notification=%@", notification);
      NSDebugMLLog(@"gsdb", @"entityName=%@", entityName);

      NSAssert(entityName, @"No entity name");//??

      entity = [self entityNamed: entityName];
      NSAssert1(entity, @"No entity named %@", entityName);//??

      classDescription = [entity classDescriptionForInstances];
      NSDebugMLLog(@"gsdb", @"classDescription=%@", classDescription);

      entityClassName = [entity className];
      NSDebugMLLog(@"gsdb", @"entityClassName=%@", entityClassName);

      [EOClassDescription registerClassDescription: classDescription
                          forClass: NSClassFromString(entityClassName)];//??
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

- (void)_resetPrototypeCache
{
  // TODO
  [self notImplemented: _cmd];
}

- (BOOL)isPrototypesEntity: (id)param0
{
  // TODO
  [self notImplemented: _cmd];
  return NO;
}

- (id)_instantiatedEntities
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}


- (void)_setPath: (NSString*)path
{
  //OK
  [self loadAllModelObjects];
  [self willChange];
  ASSIGN(_path,path);
  [self setName: [path stringByDeletingPathExtension]];//VERIFY
}

- (EOEntity*)_entityForClass: (Class)aClass
{
  NSString *className;
  EOEntity *entity;

  EOFLOGObjectFnStart();

  NSAssert(aClass, @"No class");
  NSAssert(_entitiesByClass, @"No _entitiesByClass");

  className = NSStringFromClass(aClass);
  NSDebugMLLog(@"gsdb", @"className=%@", className);

  entity = NSMapGet(_entitiesByClass, className);
  NSDebugMLLog(@"gsdb", @"entity class=%@", [entity class]);

  if (entity)
    {
      entity = [self _verifyBuiltEntityObject: entity
                     named: nil];
      NSDebugMLLog(@"gsdb", @"entity=%@", entity);
    }
  else
    {
      NSDebugMLLog(@"gsdb", @"entity for class named=%@ not found", className);
      NSDebugMLLog(@"gsdb", @"entities class names=%@",
		   NSAllMapTableKeys(_entitiesByClass));
      NSDebugMLLog(@"gsdb", @"entities entities names=%@",
		   NSAllMapTableValues(_entitiesByClass));
      NSDebugMLLog(@"gsdb", @"entities map=%@",
		   NSStringFromMapTable(_entitiesByClass));
    }

  EOFLOGObjectFnStop();

  return entity;
}

- (id)_childrenForEntityNamed: (id)param0
{
  // TODO [self notImplemented:_cmd];
  return nil;
}

- (void)_registerChild: (id)param0
             forParent: (id)param1
{
  // TODO [self notImplemented:_cmd];
}

- (void)_setInheritanceLinks: (id)param0
{
  // TODO
  [self notImplemented: _cmd];
}

- (void)_removeEntity: (id)entity
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

- (EOEntity*)_addEntityWithPropertyList: (NSDictionary*)propertyList
{
  //OK
  id children = nil;
  EOEntity *entity = nil;

  NSAssert(propertyList, @"no propertyList");
  NSDebugMLLog(@"gsdb", @"propertyList=%@", propertyList);

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

- (void)_addFakeEntityWithPropertyList: (NSDictionary*)propertyList
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

- (id)_addEntity: (EOEntity*)entity
{
  //Seems OK
  NSString *entityClassName;

  NSAssert(entity, @"No entity to add");
  NSDebugMLLog(@"gsdb", @"model _addEntity=%@", [entity name]);

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
- (void)_setEntity: (id)entity
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

- (void)setName: (NSString *)name
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

- (void)setAdaptorName: (NSString *)adaptorName
{
  ASSIGN(_adaptorName, adaptorName);
}

- (void)setConnectionDictionary: (NSDictionary *)connectionDictionary
{
  ASSIGN(_connectionDictionary, connectionDictionary);
}

- (void)setUserInfo: (NSDictionary *)userInfo
{
  [self willChange];
  ASSIGN(_userInfo, userInfo);
}

- (void)setDocComment: (NSString *)docComment
{
  [self willChange];
  ASSIGN(_docComment, docComment);
}

- (void)addEntity: (EOEntity *)entity
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

  if ([self createsMutableObjects])
    [(GCMutableArray *)_entities addObject: entity];
  else
    {
      _entities = [[[_entities autorelease] mutableCopy] autorelease];
      [(GCMutableArray *)_entities addObject: entity];
      _entities = [_entities copy];
    }

/*
  count = [_entities count];

  entitiesClass = calloc(count, sizeof(id));
  memcpy(entitiesClass, _entitiesByClass, sizeof(Class)*(count-1));
  ((Class *)entitiesClass)[count-1] = [entity class];
  free(_entitiesByClass);
  _entitiesByClass = entitiesClass;
*/
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

- (void)removeEntity: (EOEntity *)entity
{
//  unsigned int entityIndex = [_entities indexOfObject:entity];
  NSString *className = nil;
//  void *entitiesClass=NULL;
//  int count;

  [entity setModel: nil];
  [_entitiesByName removeObjectForKey: [entity name]];

/*  count = [_entities count]-1;
  if(count)
    {
      entitiesClass = calloc(count, sizeof(id));
      if(entityIndex)
	memcpy(entitiesClass, _entitiesByClass, sizeof(id)*entityIndex);
      if(count > entityIndex)
	memcpy(&((int *)entitiesClass)[entityIndex],
	       &((int *)_entitiesByClass)[entityIndex+1],
	       sizeof(id)*(count-entityIndex));
    }
  free(_entitiesByClass);
  _entitiesByClass = entitiesClass;
*/
  NSAssert(_entitiesByClass, @"No _entitiesByClass");

  className = [entity className];
  NSAssert1(className, @"No className in %@", entity);
  NSMapRemove(_entitiesByClass, className);

  if ([self createsMutableObjects])
    [(GCMutableArray *)_entities removeObject: entity];
  else
    {
      _entities = [[_entities autorelease] mutableCopy];
      [(GCMutableArray *)_entities removeObject: entity];
      _entities = [[_entities autorelease] copy];
    }
}

- (void)removeEntityAndReferences: (EOEntity *)entity;
{
  [self removeEntity: entity];
  // TODO;
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
  
  if ([self createsMutableObjects])
    [(GCMutableArray *)_storedProcedures addObject: storedProcedure];
  else
    {
      _storedProcedures = [[[_storedProcedures autorelease] mutableCopy]
			    autorelease];
      [(GCMutableArray *)_storedProcedures addObject: storedProcedure];
      _storedProcedures = [_storedProcedures copy];
    }
}

- (void)removeStoredProcedure: (EOStoredProcedure *)storedProcedure
{
  if([self createsMutableObjects])
    [(GCMutableArray *)_storedProcedures removeObject: storedProcedure];
  else
    {
      _storedProcedures = [[_storedProcedures autorelease] mutableCopy];
      [(GCMutableArray *)_storedProcedures removeObject: storedProcedure];
      _storedProcedures = [[_storedProcedures autorelease] copy];
    }
}

- (void)setModelGroup: (EOModelGroup *)group
{
  EOFLOGObjectFnStart();

//call group _addSubEntitiesCache:
  _group = group;

  EOFLOGObjectFnStop();
}

- (void)loadAllModelObjects
{
  NSArray *storedProcedures = [self storedProcedures];
  //TODO something if storedProcedures ?
  NSArray *entities = [self entities];

  //TODO something if entities ?
  [self willChange];
}

- (NSArray *)referencesToProperty: property
{
  // TODO
  [self notImplemented: _cmd];

  return nil;
}

- (NSArray *)externalModelsReferenced
{
  // TODO;
  [self notImplemented: _cmd];

  return nil;
}

@end


@implementation EOModel (EOModelBeautifier)

- (void)beautifyNames
{
  NSArray  *listItems;
  NSString *newString = [NSString string];
  int	    anz, i, count;
 
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOModel");
  
  /* Makes the receiver's name conform to a standard convention. 
Names that conform to this style are all lower-case except for the initial 
letter of each embedded word other than the first, which is upper case. Thus, 
"NAME" becomes "name", and "FIRST_NAME" becomes "firstName". */
  
  NSLog(@"EOModel : beautifyNames is called");
  
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
	  if (_entities && (count = [_entities count]))
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

- (void)setCreateMutableObjects: (BOOL)flag
{
  if (_flags.createsMutableObjects != flag)
    {
      _flags.createsMutableObjects = flag;
      
      if (_flags.createsMutableObjects)
        _entities = [[_entities autorelease] mutableCopy];
      else
        _entities = [[_entities autorelease] copy];
    }
}

- (BOOL)createsMutableObjects
{
  return _flags.createsMutableObjects;
}

- (EOEntity *)_verifyBuiltEntityObject: (id)entity
                                 named: (NSString*)name
{
  if (![entity isKindOfClass: [EOEntity class]])
    {
      [EOObserverCenter suppressObserverNotification];

      NS_DURING
        {
          NSString *basePath = nil;
          NSString *plistPathName = nil;
          NSDictionary *propList = nil;

          NSDebugMLLog(@"gsdb", @"name=%@", name);

          if (!name && [entity isKindOfClass: [NSDictionary class]])
            name = [entity objectForKey: @"name"];

          NSDebugMLLog(@"gsdb", @"name=%@", name);
          NSAssert1(name, @"No name for entity %@", entity);
          NSDebugMLLog(@"gsdb", @"[self path]=%@", [self path]);

          basePath = [[self class] findPathForModelNamed: [self path]]; 
          [[entity retain] autorelease]; //so it won't be lost in _removeEntity

          NSDebugMLLog(@"gsdb", @"basePath =%@", basePath);

          plistPathName = [[basePath stringByAppendingPathComponent: name]
			    stringByAppendingPathExtension: @"plist"];

          NSDebugMLLog(@"gsdb", @"entity plistPathName =%@", plistPathName);

          propList = [NSDictionary dictionaryWithContentsOfFile: plistPathName];
          NSDebugMLLog(@"gsdb", @"entity propList=%@", propList);

          if (!propList)
            {
              if ([[NSFileManager defaultManager]
		    fileExistsAtPath: plistPathName])
                {
                  NSAssert1(NO, @"%@ is not a dictionary or is not readable.",
			    plistPathName);
                }
              else
                {
                  propList = entity;
                  NSWarnLog(@"%@ doesn't exists. Using %@",
			    plistPathName, propList);
                }
            }

          [self _removeEntity: entity];
          NSDebugMLLog(@"gsdb", @"entity propList=%@", propList);

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
