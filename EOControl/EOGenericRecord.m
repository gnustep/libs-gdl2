/** 
   EOGenericRecord.m <title>EOGenericRecord</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSObjCRuntime.h>

#import <EOAccess/EOEntity.h>
#import <EOAccess/EORelationship.h>

#import <EOControl/EOClassDescription.h>
#import <EOControl/EOGenericRecord.h>
#import <EOControl/EONull.h>
#import <EOControl/EOObserver.h>
#import <EOControl/EOFault.h>
#import <EOControl/EOMutableKnownKeyDictionary.h>
#import <EOControl/EODebug.h>



@interface NSObject (EOCalculateSize)
- (unsigned int)eoGetSize;
@end

@interface NSString (EOCalculateSize)
- (unsigned int)eoGetSize;
@end


@interface NSArray (EOCalculateSize)
- (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict;
@end

@interface NSDictionary (EOCalculateSize)
- (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict;
@end

@interface EOFault (EOCalculateSize)
+ (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
			   forFault: (id)object;
@end


static NSHashTable *allGenericRecords = NULL;
static NSRecursiveLock *allGenericRecordsLock = nil;  


@implementation EOGenericRecord

+ (void) initialize
{
  if ([[super superclass] initialize])
    {
      if (self == [EOGenericRecord class])
        {
          allGenericRecords = NSCreateHashTable(NSNonOwnedPointerHashCallBacks,
						1000);
          allGenericRecordsLock = [NSRecursiveLock new];
        }
    }
}

+ (void)addCreatedObject: (EOGenericRecord *)o
{
  [allGenericRecordsLock lock];
  NSHashInsertIfAbsent(allGenericRecords, o);
  [allGenericRecordsLock unlock];
}

+ (void)removeDestoyedObject: (EOGenericRecord *)o
{
  [allGenericRecordsLock lock];
  NSHashRemove(allGenericRecords, o);
  [allGenericRecordsLock unlock];
}

- (id) init
{
  if ((self = [super init]))
    {
      [[self class] addCreatedObject: self];
    }

  return self;
}

- (id) initWithEditingContext: (EOEditingContext *)context
             classDescription: (EOClassDescription *)classDesc
                     globalID: (EOGlobalID *)globalID;
{
  if ((self = [self init]))
    {
      EOEntity *entity = nil;
      EOMutableKnownKeyDictionary *entityMKKD = nil;

      if (!classDesc)
        {
          [NSException raise: NSInternalInconsistencyException
                       format: @"%@ -- %@ 0x%x: attempt to initialize object with nil classDescription",
                       NSStringFromSelector(_cmd),
                       NSStringFromClass([self class]),
                       self];

          [self autorelease];
          return nil;
        }

      ASSIGN(classDescription, classDesc);

      entity = [(EOEntityClassDescription*)classDesc entity];
      NSAssert(entity, @"No entity");

      entityMKKD = [entity _dictionaryForProperties];

      ASSIGN(dictionary,entityMKKD);
      EOFLOGObjectLevelArgs(@"EOGenericRecord", @"Record %p: dictionary=%@",
			    self, dictionary);
    }

  return self;
}

- (void)dealloc
{
  EOFLOGObjectLevelArgs(@"EOGenericRecord",
			@"Deallocate EOGenericRecord %p (dict=%p)",
			self, dictionary);

  [[self class] removeDestoyedObject: self];

  DESTROY(classDescription);
  DESTROY(dictionary);

  [super dealloc];
}

- (EOClassDescription*)classDescription
{
  return classDescription;
}

static const char _c_id[2] = { _C_ID, NULL };

//used to allow derived object implementation
- (BOOL)_infoForInstanceVariableNamed: (NSString*)name
                              retType: (const char**)type
                              retSize: (unsigned int*)size
                            retOffset: (int*)offset
{
  BOOL ok;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
/*  ok=[super _infoForInstanceVariableNamed:name
            retType:type
            retSize:size
            retOffset:offset];
*/
  ok = GSFindInstanceVariable(self, [name cString], type, size, offset);

  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Super InstanceVar named %@:%s",
			name, (ok ? "YES" : "NO"));

  if (!ok)
    {
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			    @"dictionary: %p eoMKKDInitializer: %p",
			    dictionary,
			    [dictionary eoMKKDInitializer]);
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"dictionary allkeys= %@",
			    [dictionary allKeys]);

      if ([dictionary hasKey: name])
        {
	  if (type)
	    *type = _c_id;
	  if (size)
	    *size = sizeof(id);
	  if (offset)
	    *offset = UINT_MAX; //Special Marker

          ok = YES;

          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"Self InstanceVar named %@:%s",
				name, (ok ? "YES" : "NO"));
        }
    }

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");

  return ok;
}

//used to allow derived object implementation
- (id)_getValueForKey: (NSString*)aKey
	     selector: (SEL)sel
		 type: (const char*)type
		 size: (unsigned)size
	       offset: (unsigned)offset
{
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Super InstanceVar named %@: offset=%u",
			aKey, offset);

  if (offset == UINT_MAX)
    {
      value = [dictionary objectForKey: aKey];

      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value %p (class=%@)",
			    value, [value class]);
    }
  else
    {
      /*    value=[super _getValueForKey:aKey
            selector:sel
            type:type
            size:size
            offset:offset];*/

      value = GSGetValue(self, aKey, sel, type, size, offset);
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value %p (class=%@)",
			    value, [value class]);
    }

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");

  return value;
}

//used to allow derived object implementation
- (void)_setValueForKey: (NSString *)aKey
		 object: (id)anObject
	       selector: (SEL)sel
		   type: (const char*)type
		   size: (unsigned)size
		 offset: (unsigned)offset
{
  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Super InstanceVar named %@: offset=%u",
			aKey, offset);

  [self willChange];

  if (offset == UINT_MAX)
    {
      if (anObject)
        [dictionary setObject: anObject
                    forKey: aKey];
      else
        [dictionary removeObjectForKey: aKey];
    }
  else
/*    [super _setValueForKey:aKey
           object:anObject
           selector:sel
           type:type
           size:size
           offset:offset];
*/
    GSSetValue(self, aKey, anObject, sel, type, size, offset);

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}

//used to allow derived object implementation
- (id) _handleQueryWithUnboundKey: (NSString*)aKey
{
  return nil;
}

//used to allow derived object implementation
- (void) _handleTakeValue: (id)anObject forUnboundKey: (NSString*)aKey
{
}

/*
- (void)takeStoredValue:(id)value
                 forKey:(NSString *)key
{
  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
  EOFLOGObjectLevelArgs(@"EOGenericRecord", @"key=%@", key);
  [super takeStoredValue: value
         forKey: key];
  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
}

- (void)takeValue:(id)value
           forKey:(NSString *)key
{
  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
  EOFLOGObjectLevelArgs(@"EOGenericRecord", @"key=%@", key);

  [self willChange];

  [super takeValue: value
         forKey: key];
  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
//
//  if(value == nil || value == [EONull null])
//    [dictionary removeObjectForKey:key];
//  else
//    {
//      NSArray *attrKeys, *toManyKeys, *toOneKeys;
//
//      attrKeys = [classDescription attributeKeys];
//      toManyKeys = [classDescription toManyRelationshipKeys];
//      toOneKeys = [classDescription toOneRelationshipKeys];
//      
//      if([attrKeys containsObject:key] == NO &&
//	 [toManyKeys containsObject:key] == NO &&
//	 [toOneKeys containsObject:key] == NO)
//	return;
//
//      [dictionary setObject:value forKey:key];
//    }
//
//  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
}

- (id)storedValueForKey:(NSString *)key
{
  id value=nil;
  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
  EOFLOGObjectLevelArgs(@"EOGenericRecord",@"key=%@",key);
  value=[super storedValueForKey: key];
  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
  return value;
}

- (id)valueForKey:(NSString *)key
{
  id value=nil;
  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
  EOFLOGObjectLevelArgs(@"EOGenericRecord", @"key=%@", key);
  value=[super valueForKey: key];
  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
  return value;
//  id value=nil;
//  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
//  EOFLOGObjectLevelArgs(@"EOGenericRecord", @"key=%@", key);
//  NSArray *attrKeys, *toManyKeys, *toOneKeys;
//
//  attrKeys = [classDescription attributeKeys];
//  toManyKeys = [classDescription toManyRelationshipKeys];
//  toOneKeys = [classDescription toOneRelationshipKeys];
//      
//  if([attrKeys containsObject:key] == NO &&
//     [toManyKeys containsObject:key] == NO &&
//     [toOneKeys containsObject:key] == NO)
//    return nil;
//
//  value=[dictionary objectForKey:key];
//  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
//  return value;
}
*/

- (id) storedValueForKey: (NSString*)aKey
{
  SEL		sel = 0;
  const char	*type = NULL;
  unsigned	size = 0;
  unsigned	off = 0;
  NSString	*name = nil;
  NSString	*cap = nil;
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  if ([[self class] useStoredAccessor] == NO)
    {
      value = [self valueForKey: aKey];
    }
  else
    {
      size = [aKey length];

      if (size < 1)
        {
          [NSException raise: NSInvalidArgumentException
                       format: @"storedValueForKey: ... empty key"];
        }

      cap = [[aKey substringToIndex: 1] uppercaseString];
      if (size > 1)
        {
          cap = [cap stringByAppendingString: [aKey substringFromIndex: 1]];
        }

      name = [NSString stringWithFormat: @"_get%@", cap];
      sel = NSSelectorFromString(name);

      if (sel == 0 || [self respondsToSelector: sel] == NO)
        {
          name = [NSString stringWithFormat: @"_%@", aKey];
          sel = NSSelectorFromString(name);

          if (sel == 0 || [self respondsToSelector: sel] == NO)
            {
              sel = 0;
            }
        }

      if (sel == 0)
        {
          if ([[self class] accessInstanceVariablesDirectly] == YES)
            {
              name = [NSString stringWithFormat: @"_%@", aKey];

              if ([self _infoForInstanceVariableNamed:name
                        retType: &type
                        retSize: &size
                        retOffset: &off]==NO)
                {
                  name = aKey;
                  [self _infoForInstanceVariableNamed:name
                        retType: &type
                        retSize: &size
                        retOffset: &off];
                }
            }

          if (type == NULL)
            {
              name = [NSString stringWithFormat: @"get%@", cap];
              sel = NSSelectorFromString(name);

              if (sel == 0 || [self respondsToSelector: sel] == NO)
                {
                  name = aKey;
                  sel = NSSelectorFromString(name);

                  if (sel == 0 || [self respondsToSelector: sel] == NO)
                    {
                      sel = 0;
                    }
                }
            }
        }

      value = [self _getValueForKey: aKey
                    selector: sel
                    type: type
                    size: size
                    offset: off];

    }

  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value=%@", value);
  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");

  return value;
}

- (void) takeStoredValue: (id)anObject
		  forKey: (NSString*)aKey
{
  SEL		sel = NULL;
  const char	*type = NULL;
  unsigned	size = 0;
  unsigned	off = 0;
  NSString	*cap = nil;
  NSString	*name = nil;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"anObject=%@", anObject);
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  if ([[self class] useStoredAccessor] == NO)
    {
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

      [self takeValue: anObject
	    forKey: aKey];
    }
  else
    {
      size = [aKey length];

      if (size < 1)
        {
          [NSException raise: NSInvalidArgumentException
                       format: @"takeStoredValue:forKey: ... empty key"];
        }

      cap = [[aKey substringToIndex: 1] uppercaseString];
      if (size > 1)
        {
          cap = [cap stringByAppendingString: [aKey substringFromIndex: 1]];
        }
      
      name = [NSString stringWithFormat: @"_set%@:", cap];
      type = NULL;
      sel = NSSelectorFromString(name);

      if (sel == 0 || [self respondsToSelector: sel] == NO)
        {
          sel = 0;

          if ([[self class] accessInstanceVariablesDirectly] == YES)
            {
              name = [NSString stringWithFormat: @"_%@", aKey];

              EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@ name=%@",
				    aKey, name);

              if ([self _infoForInstanceVariableNamed: name
                        retType: &type
                        retSize: &size
                        retOffset: &off]==NO)
                {
                  name = aKey;

                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"aKey=%@ name=%@", aKey, name);

                  [self _infoForInstanceVariableNamed: name
                        retType: &type
                        retSize: &size
                        retOffset: &off];
                }
            }

          if (type == NULL)
            {
              name = [NSString stringWithFormat: @"set%@:", cap];

              EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@ name=%@",
				    aKey, name);

              sel = NSSelectorFromString(name);

              if (sel == 0 || [self respondsToSelector: sel] == NO)
                {
                  sel = 0;
                }
            }
        }

      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			    @"class=%@ aKey=%@ sel=%p offset=%u",
			    [self class], aKey, sel, off);

      [self _setValueForKey: aKey
            object: anObject
            selector: sel
            type: type
            size: size
            offset: off];
    }

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}

/** if key is a bidirectional rel, use addObject:toBothSidesOfRelationship otherwise call  takeValue:forKey: **/
- (void)smartTakeValue: (id)anObject 
                forKey: (NSString *)aKey
{
  EORelationship *rel = [classDescription relationshipNamed: aKey];

  //NSDebugMLog(@"aKey=%@ rel=%@ anObject=%@", aKey, rel, anObject);
  //NSDebugMLog(@"[rel isBidirectional]=%d", [rel isBidirectional]);

  if (rel && [rel isBidirectional])
    {
      if (isNilOrEONull(anObject))
        {
          id oldObj = [self valueForKey: aKey];

          if (isNilOrEONull(oldObj))
            {
              if (![rel isToMany])
                [self takeValue: anObject
                      forKey: aKey];
            }
          else
            [self removeObject: anObject
                  fromBothSidesOfRelationshipWithKey: aKey];
        }
      else
        [self addObject: anObject
              toBothSidesOfRelationshipWithKey: aKey];
    }
  else
    [self takeValue: anObject
          forKey: aKey];
}

- (void) takeValue: (id)anObject forKey: (NSString*)aKey
{
  SEL		sel;
  const char	*type;
  unsigned	size;
  unsigned	off=0;
  NSString	*cap;
  NSString	*name;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"anObject=%@", anObject);
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  size = [aKey length];
  if (size < 1)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"takeValue:forKey: ... empty key"];
    }

  cap = [[aKey substringToIndex: 1] uppercaseString];
  if (size > 1)
    {
      cap = [cap stringByAppendingString: [aKey substringFromIndex: 1]];
    }

  name = [NSString stringWithFormat: @"set%@:", cap];
  type = NULL;
  sel = NSSelectorFromString(name);

  if (sel == 0 || [self respondsToSelector: sel] == NO)
    {
      name = [NSString stringWithFormat: @"_set%@:", cap];
      sel = NSSelectorFromString(name);

      if (sel == 0 || [self respondsToSelector: sel] == NO)
	{
	  sel = 0;

	  if ([[self class] accessInstanceVariablesDirectly] == YES)
	    {
	      name = [NSString stringWithFormat: @"_%@", aKey];

              if ([self _infoForInstanceVariableNamed: name
                        retType: &type
                        retSize: &size
                        retOffset: &off]==NO)
		{
		  name = aKey;

                  [self _infoForInstanceVariableNamed: name
                        retType: &type
                        retSize: &size
                        retOffset: &off];
		}
	    }
	}
    }

  [self _setValueForKey: aKey
        object: anObject
        selector: sel
        type: type
        size: size
        offset: off];

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}

- (id) valueForKey: (NSString*)aKey
{
  SEL		sel = 0;
  NSString	*cap;
  NSString	*name = nil;
  const char	*type = NULL;
  unsigned	size;
  unsigned	off = 0;
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  size = [aKey length];
  if (size < 1)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"valueForKey: ... empty key"];
    }

  cap = [[aKey substringToIndex: 1] uppercaseString];
  if (size > 1)
    {
      cap = [cap stringByAppendingString: [aKey substringFromIndex: 1]];
    }

  name = [@"get" stringByAppendingString: cap];
  sel = NSSelectorFromString(name);

  if (sel == 0 || [self respondsToSelector: sel] == NO)
    {
      name = aKey;
      sel = NSSelectorFromString(name);

      if (sel == 0 || [self respondsToSelector: sel] == NO)
	{
	  name = [@"_get" stringByAppendingString: cap];
	  sel = NSSelectorFromString(name);

	  if (sel == 0 || [self respondsToSelector: sel] == NO)
	    {
	      name = [NSString stringWithFormat: @"_%@", aKey];
	      sel = NSSelectorFromString(name);

	      if (sel == 0 || [self respondsToSelector: sel] == NO)
		{
		  sel = 0;
		}
	    }
	}
    }

  if (sel == 0 && [[self class] accessInstanceVariablesDirectly] == YES)
    {
      name = [NSString stringWithFormat: @"_%@", aKey];

      if ([self _infoForInstanceVariableNamed: name
                retType: &type
                retSize: &size
                retOffset: &off]==NO)
        {
          name = aKey;

          [self _infoForInstanceVariableNamed: name
		retType: &type
                retSize: &size
                retOffset: &off];
        }
    }

  value = [self _getValueForKey: aKey
		selector: sel
		type: type
		size: size
		offset: off];

  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value: %p (class=%@)",
			value, [value class]);
  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");

  return value;
}


/** used in -decription for self toOne or toMany objects to avoid
infinite loop in description **/
- (NSString *)_shortDescription
{
  NSArray *toManyKeys = nil;
  NSArray *toOneKeys = nil;
  NSEnumerator *enumerator = [dictionary keyEnumerator];
  NSMutableDictionary *dict;
  NSString *key = nil;
  id obj = nil;

  toManyKeys = [classDescription toManyRelationshipKeys];
  toOneKeys = [classDescription toOneRelationshipKeys];
  dict = [NSMutableDictionary dictionaryWithCapacity: [dictionary count]];

  while ((key = [enumerator nextObject]))
    {
      obj = [dictionary objectForKey: key];

      if (!obj)
        [dict setObject: @"(null)"
              forKey: key];
      else
        {
          // print out only simple values
          if ([toManyKeys containsObject: key] == NO
	      && [toOneKeys containsObject: key] == NO)
            {
              [dict setObject: obj
                    forKey: key];
            }
        }
    }

  return [NSString stringWithFormat: @"<%s %p : classDescription=%@\nvalues=%@>",
		   object_get_class_name(self),
		   (void*)self,
		   classDescription,
                   dict];
}

- (NSString *)description
{
  NSArray *toManyKeys = nil;
  NSArray *toOneKeys = nil;
  NSEnumerator *enumerator = [dictionary keyEnumerator];
  NSMutableDictionary *dict;
  NSString *key = nil;
  id obj = nil;

  toManyKeys = [classDescription toManyRelationshipKeys];
  toOneKeys = [classDescription toOneRelationshipKeys];

  dict = [NSMutableDictionary dictionaryWithCapacity: [dictionary count]];

  while ((key = [enumerator nextObject]))
    {
      obj = [dictionary objectForKey: key];

      if (!obj)
        [dict setObject: @"(null)"
              forKey: key];
      else
        {
          if ([toManyKeys containsObject: key] == NO
	      && [toOneKeys containsObject: key] == NO)
            {
              [dict setObject: obj
                    forKey: key];
            }
          else
            {
              if ([EOFault isFault: obj] == YES)
                {
                  [dict setObject: [obj description]
                        forKey: key];
                }
              else if ([toManyKeys containsObject: key] == YES)
                {
                  NSEnumerator *toManyEnum;
                  NSMutableArray *array;
                  id rel;

                  array = [NSMutableArray arrayWithCapacity: 8];
                  toManyEnum = [obj objectEnumerator];

                  while ((rel = [toManyEnum nextObject]))
                    {
                      NSString* relDescr;
                      // Avoid infinit loop
                      if ([rel respondsToSelector: @selector(_shortDescription)])
                        relDescr=[rel _shortDescription];
                      else
                        relDescr=[rel description];

                      [array addObject:
                               [NSString
                                 stringWithFormat: @"<%@ %p>",
                                 relDescr, NSStringFromClass([rel class])]];
                    }

                  [dict setObject: [NSString stringWithFormat:
					       @"<%p %@ : %@>",
					     obj, [obj class], array]
                        forKey: key];
                }
              else
                {
                  [dict setObject: [NSString
				     stringWithFormat: @"<%p %@: classDescription=%@>",
				     obj,
				     NSStringFromClass([obj class]),
				     [obj classDescription]]
                        forKey: key];
                }
            }
        }
    }

  return [NSString stringWithFormat: @"<%s %p : classDescription=%@\nvalues=%@>",
		   object_get_class_name(self),
		   (void*)self,
		   classDescription,
                   dict];
}

//debug only
- (NSString *)debugDictionaryDescription
{
  return [dictionary debugDescription];
}

/*dictionary has following entries:
  - NSMutableDictionary* processed: processed entries (key=object address, value=size)
  - NSMutableDictionary* summaryNb: objects by class name (key=class name, value=number of objects)
  - NSMutableDictionary* summarySize: objects by class name (key=class name, value=size)
  - NSMutableArray* unknownClasses: not calculated objects classes

  size are size of objects + size of elementary included objects
*/

+ (void)eoCalculateAllSizeWith: (NSMutableDictionary *)dict
{
  EOGenericRecord *record = nil;
  NSHashEnumerator hashEnum;

  EOFLOGClassFnStart();
  //NSDebugMLog(@"CALCULATE START");

  [allGenericRecordsLock lock];

  NS_DURING
    {
      hashEnum = NSEnumerateHashTable(allGenericRecords);
 
      while ((record = (EOGenericRecord*)NSNextHashEnumeratorItem(&hashEnum)))
        {
          [record eoCalculateSizeWith: dict];
        }

      NSEndHashTableEnumeration(&hashEnum);
    }
  NS_HANDLER
    {
      NSDebugMLog(@"%@ (%@)", localException, [localException reason]);

      [allGenericRecordsLock unlock];

      NSDebugMLog(@"CALCULATE STOPEXC");
      [localException raise];
    }
  NS_ENDHANDLER;

  [allGenericRecordsLock unlock];

  //NSDebugMLog(@"CALCULATE STOP");
  EOFLOGClassFnStop();
}

- (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
{
  NSMutableDictionary *processed;
  NSValue *selfP;

  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
  //NSDebugMLog(@"CALCULATE OBJ START %p", self);

  processed = [dict objectForKey: @"processed"];
  selfP = [NSValue valueWithPointer: self];

  if (![processed objectForKey: selfP])
    {
      NSMutableDictionary *summaryNb = nil;
      NSMutableDictionary *summarySize = nil;
      NSMutableArray *unknownClasses = nil;
      NSArray *props;
      NSString *selfClassName = NSStringFromClass([self class]);
      NSNumber *selfSummaryNb = nil;
      NSNumber *selfSummarySize = nil;
      unsigned int size = 0;
      int i, propCount;

      //NSDebugMLog(@"self=%@",self);

      if (!processed)
        {
          processed = (NSMutableDictionary *)[NSMutableDictionary dictionary];
          [dict setObject: processed
                forKey: @"processed"];
        }

      [processed setObject: [NSNumber numberWithUnsignedInt: 0]
                 forKey: selfP];

      //NSDebugMLog(@"classDescription=%@", classDescription);

      props = [[(EOEntityClassDescription *)classDescription entity]
		classPropertyNames];
      size += [self eoGetSize];
      size += [dictionary eoGetSize];

      //NSDebugMLog(@"props=%@",props);

      propCount = [props count];

      for (i = 0; i < propCount; i++)
        {
          NSString *propKey = [props objectAtIndex: i];
          id value = [self valueForKey: propKey];

          //NSDebugMLog(@"propKey=%@", propKey);
          //NSDebugMLog(@"value isFault=%s", ([EOFault isFault:value] ? "YES" : "NO"));
          //NSDebugMLog(@"value=%p class=%@", value, [value class]);

          if (value)
            {
              if ([EOFault isFault:value])
                size += [EOFault eoCalculateSizeWith: dict
				 forFault: value];
              else if ([value respondsToSelector: @selector(eoCalculateSizeWith:)])
                {
                  size += [value eoCalculateSizeWith: dict];
                }
              else if ([value respondsToSelector: @selector(eoGetSize)])
                size += [value eoGetSize];
              else
                {
                  NSString *className = NSStringFromClass([value class]);

                  if (!unknownClasses)
                    {
                      unknownClasses = [dict objectForKey: @"unknownClasses"];

                      if (!unknownClasses)
                        {
                          unknownClasses = [NSMutableArray array];
                          [dict setObject: unknownClasses
                                forKey: @"unknownClasses"];
                        }
                    }

                  if (![unknownClasses containsObject: className])
                    [unknownClasses addObject: className];
                }
            }
        }

      if (size > 0)
        [processed setObject: [NSNumber numberWithUnsignedInt: size]
                   forKey: selfP];

      summaryNb = [dict objectForKey: @"summaryNb"];

      if (!summaryNb)
        {
          summaryNb = (NSMutableDictionary *)[NSMutableDictionary dictionary];
          [dict setObject: summaryNb
                forKey: @"summaryNb"];
        }

      selfSummaryNb = [summaryNb objectForKey: selfClassName];
      selfSummaryNb = [NSNumber numberWithUnsignedInt: [selfSummaryNb
							 unsignedIntValue] + 1];
      [summaryNb setObject: selfSummaryNb
                 forKey: selfClassName];
      summarySize = [dict objectForKey: @"summarySize"];

      if (!summarySize)
        {
          summarySize = (NSMutableDictionary *)[NSMutableDictionary dictionary];
          [dict setObject: summarySize
                forKey: @"summarySize"];
        }

      selfSummarySize = [summarySize objectForKey: selfClassName];
      selfSummarySize = [NSNumber numberWithUnsignedInt:
				    [selfSummarySize unsignedIntValue] + size];

      [summarySize setObject: selfSummarySize
		   forKey: selfClassName];
    }

  //NSDebugMLog(@"CALCULATE OBJ STOP %p", self);
  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");

  return 0;
}

+ (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
			   forArray: (NSArray *)array
{
  NSMutableDictionary *processed;
  NSValue *selfP;

  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");
  //NSDebugMLog(@"CALCULATE ARRAY START %p", self);

  processed = [dict objectForKey: @"processed"];
  selfP = [NSValue valueWithPointer: array];

  if (![processed objectForKey: selfP])
    {
      int i, count;

      if (!processed)
        {
          processed = (NSMutableDictionary *)[NSMutableDictionary dictionary];
          [dict setObject: processed
                forKey: @"processed"];
        }

      [processed setObject: [NSNumber numberWithUnsignedInt: 0]
                 forKey: selfP];

      count = [array count];

      for (i = 0; i < count; i++)
        {
          id value = [array objectAtIndex: i];

          if (value)
            {
              if ([value respondsToSelector: @selector(eoCalculateSizeWith:)])
                [value eoCalculateSizeWith: dict];
            }
        }
    }

  //NSDebugMLog(@"CALCULATE ARRAY START %p", self);
  EOFLOGClassFnStop();

  return [array eoGetSize]; //return the base size
}

+ (NSString *)eoFormatSizeDictionary: (NSDictionary *)dict
{
  NSMutableString *dscr = [NSMutableString string];
  NSMutableDictionary *processed;
  NSMutableDictionary *summaryNb;
  NSMutableDictionary *summarySize;
  NSString *key;
  unsigned totalSize = 0;
  unsigned totalNb = 0;
  NSEnumerator *enumK;

  EOFLOGClassFnStart();

  processed = [dict objectForKey: @"processed"];
  summaryNb = [dict objectForKey: @"summaryNb"];
  summarySize = [dict objectForKey: @"summarySize"];
  enumK = [[[summaryNb allKeys] sortedArrayUsingSelector:
				  @selector(compare:)] objectEnumerator];

  while ((key = [enumK nextObject]))
    {
      NSNumber *size = [summarySize objectForKey: key];
      NSNumber *number = [summaryNb objectForKey: key];

      [dscr appendFormat: @"%@: totalSize=%@ bytes (%d Kb)/ objectsNb=%@ / meanSize=%d bytes (%d Kb)\n",
            key,
            size,
            [size unsignedIntValue]/1024,
            number,
            (int)([size unsignedIntValue] / [number unsignedIntValue]),
            (int)([size unsignedIntValue] / [number unsignedIntValue] / 1024)];

      totalSize += [size unsignedIntValue];
      totalNb += [number unsignedIntValue];
    }

  [dscr appendFormat: @"-------------\ntotalSize=%u bytes (%d Kb) / objectsNb=%u / meanSize=%d bytes (%d Kb)\n",
        totalSize,
        totalSize / 1024,
        totalNb,
        (int)(totalSize / totalNb),
        (int)(totalSize / totalNb / 1024)];

  EOFLOGClassFnStop();

  return dscr;
}

@end /* EOGenericRecord */


@implementation NSObject (EOCalculateSize)

- (unsigned int)eoGetSize
{
  unsigned int size = 0;
  Class selfClass = Nil;

//  EOFLOGObjectFnStartOrCond(@"EOGenericRecord");

  selfClass = [self class];
  size = selfClass->instance_size;

//  EOFLOGObjectFnStopOrCond(@"EOGenericRecord");

  return size;
}

@end

@implementation NSString (EOCalculateSize)

- (unsigned int)eoGetSize
{
  unsigned int size;
  //consider 2bytes string

  //EOFLOGObjectFnStartOrCond(@"EOGenericRecord");

  size = [super eoGetSize] + [self length] * 2;

  //EOFLOGObjectFnStopOrCond(@"EOGenericRecord");

  return size;
}

@end


@implementation NSArray (EOCalculateSize)

- (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
{
  unsigned int size;

  //NSDebugMLog(@"CALCULATE ARRAY START %p", self);

  size = [EOGenericRecord  eoCalculateSizeWith: dict
                           forArray: self];

  //NSDebugMLog(@"CALCULATE ARRAY STOP %p", self);

  return size;
}

@end

@implementation NSDictionary (EOCalculateSize)

- (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
{
  //EOFLOGObjectFnStartOrCond(@"EOGenericRecord");

  return [EOGenericRecord eoCalculateSizeWith: dict
			  forArray: [self allValues]];

  //EOFLOGObjectFnStopOrCond(@"EOGenericRecord");
}

@end

@implementation EOFault (EOCalculateSize)

+ (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
			   forFault: (id)object
{
  NSMutableDictionary *processed;
  unsigned int baseSize = 0;
  NSValue *objectP;

  EOFLOGClassFnStart();
  //NSDebugFLog(@"CALCULATE FAULT START %p",object);

  processed = [dict objectForKey: @"processed"];
  objectP = [NSValue valueWithPointer: object];

  if (![processed objectForKey: objectP])
    {
      NSString *objectClassName = [NSString stringWithFormat: @"%@ (Fault)",
					    NSStringFromClass([object class])];
      NSNumber *objectSummaryNb = 0;
      NSNumber *objectSummarySize = 0;
      Class objectClass = [object class];
      unsigned int size = 0;

      //NSDebugMLog(@"object=%p", object);

      if (!processed)
        {
          processed = (NSMutableDictionary *)[NSMutableDictionary dictionary];

          [dict setObject: processed
                forKey: @"processed"];
        }

      [processed setObject: [NSNumber numberWithUnsignedInt: 0]
                 forKey: objectP];
      size += objectClass->instance_size;

      if ([object isKindOfClass: [NSArray class]])
        baseSize += size;
      else
        {
          NSMutableDictionary *summaryNb = nil;
          NSMutableDictionary *summarySize = nil;

          if (size>0)
            [processed setObject: [NSNumber numberWithUnsignedInt: size]
                       forKey: objectP];

          summaryNb = [dict objectForKey: @"summaryNb"];
          if (!summaryNb)
            {
              summaryNb = (NSMutableDictionary *)[NSMutableDictionary
						   dictionary];

              [dict setObject: summaryNb
                    forKey: @"summaryNb"];
            }

          objectSummaryNb = [summaryNb objectForKey: objectClassName];
          objectSummaryNb = [NSNumber numberWithUnsignedInt:
					[objectSummaryNb unsignedIntValue] + 1];

          [summaryNb setObject: objectSummaryNb
                     forKey: objectClassName];
          summarySize = [dict objectForKey: @"summarySize"];

          if (!summarySize)
            {
              summarySize = (NSMutableDictionary *)[NSMutableDictionary
						     dictionary];

              [dict setObject: summarySize
                    forKey: @"summarySize"];
            }

          objectSummarySize = [summarySize objectForKey: objectClassName];
          objectSummarySize = [NSNumber numberWithUnsignedInt:
					  [objectSummarySize unsignedIntValue]
					+ size];

          [summarySize setObject: objectSummarySize
                       forKey: objectClassName];
        }
    }

  //NSDebugMLog(@"CALCULATE FAULT STOP %p", object);
  EOFLOGClassFnStop();

  return baseSize;
}

@end
