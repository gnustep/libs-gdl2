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

#import <Foundation/NSBundle.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDebug.h>

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

                  for (i = 0; !modelPath && paths[i]; i++)
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
      _version = 2;
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

- (float) version
{
  return _version;
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
  return [_entitiesByName allKeys];
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

  descdict = [[NSMutableDictionary alloc] initWithCapacity: 6];
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
  RELEASE(descdict);
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

+ (float) version
{
  return 2;
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
      NSDebugMLLog(@"gsdb", @"propList=%@", propList);
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

- (void) writeToFile: (NSString *)path
{
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSMutableDictionary	*pList;
  NSDictionary		*attributes;
  NSDictionary		*entityPList;
  NSEnumerator		*entityEnum;

  path = [path stringByStandardizingPath];
  path = [[path stringByDeletingPathExtension]
    stringByAppendingPathExtension: @"eomodeld"];

  pList = [NSMutableDictionary dictionaryWithCapacity: 10];

  [self encodeIntoPropertyList: pList];

  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithUnsignedLong: 0777], NSFilePosixPermissions,
    nil];
  [mgr createDirectoryAtPath: path attributes: attributes];

  entityEnum = [[pList objectForKey: @"entities"] objectEnumerator];
  while ((entityPList = [entityEnum nextObject]))
    {
      NSString *fileName;

      fileName = [path stringByAppendingPathComponent:
			 [NSString stringWithFormat: @"%@.plist",
				   [entityPList objectForKey: @"name"]]];
      [entityPList writeToFile: fileName atomically: YES];
    }

  {
    NSString *fileName;

    fileName = [path stringByAppendingPathComponent: @"index.eomodeld"];

    [pList removeAllObjects];
    [self encodeTableOfContentsIntoPropertyList: pList];
    [pList writeToFile: fileName atomically: YES];
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
          NSString *name;
          NSString *versionString = nil;
          NSArray  *entities = nil;
          int i, count = 0;

          NSDebugMLLog(@"gsdb", @"tableOfContents=%@", tableOfContents);

	  /* The call to _setPath: also sets the name implicitly. */
          [self _setPath: [isa _formatModelPath: path checkFileSystem: YES]];
          NSDebugMLLog(@"gsdb", @"name=%@ path=%@", _name, _path);

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
    [[NSNumber numberWithFloat: [isa version]] stringValue]
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

  if ([self createsMutableObjects])
    [(GCMutableArray *)_entities addObject: entity];
  else
    {
      id	e = [[GCMutableArray alloc] initWithArray: _entities];

      [e addObject: entity];
      ASSIGNCOPY(_entities, e);
      RELEASE(e);
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

  if ([self createsMutableObjects])
    [(GCMutableArray *)_entities removeObject: entity];
  else
    {
      id	e = [[GCMutableArray alloc] initWithArray: _entities];

      [e removeObject: entity];
      ASSIGNCOPY(_entities, e);
      RELEASE(e);
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
      _storedProcedures = [[[_storedProcedures autorelease] mutableCopy]
			    autorelease];
      [(GCMutableArray *)_storedProcedures addObject: storedProcedure];
      _storedProcedures = [_storedProcedures copy];
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
      _storedProcedures = [[_storedProcedures autorelease] copy];
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
  NSArray *storedProcedures = [self storedProcedures];
  //TODO something if storedProcedures ?
  NSArray *entities = [self entities];

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
      
      if (_flags.createsMutableObjects)
        _entities = [[_entities autorelease] mutableCopy];
      else
        _entities = [[_entities autorelease] copy];
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

          NSDebugMLLog(@"gsdb", @"name=%@", name);

          if (!name && [entity isKindOfClass: [NSDictionary class]])
            name = [entity objectForKey: @"name"];

          NSDebugMLLog(@"gsdb", @"name=%@", name);
          NSAssert1(name, @"No name for entity %@", entity);
          NSDebugMLLog(@"gsdb", @"[self path]=%@", [self path]);

          basePath = [self path]; 
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
