/** 
   EOGenericRecord.m <title>EOGenericRecord</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSHashTable.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <GNUstepBase/GSLock.h>

#include <EOControl/EOClassDescription.h>
#include <EOControl/EOGenericRecord.h>
#include <EOControl/EONull.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EOFault.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EODebug.h>
#include <EOControl/EOKeyValueCoding.h>

#ifndef GNU_RUNTIME
#include <objc/objc-class.h>
#endif

#include <limits.h>

#include "EOPrivate.h"

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

@interface EOGenericRecord(EOCalculateSize)
+ (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
                           forArray: (NSArray *)array;
@end


static NSHashTable *allGenericRecords = NULL;
static NSRecursiveLock *allGenericRecordsLock = nil;  


@implementation EOGenericRecord

+ (void) initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_PrivateInit();

      allGenericRecords = NSCreateHashTable(NSNonOwnedPointerHashCallBacks,
					    1000);
      allGenericRecordsLock = [GSLazyRecursiveLock new];
    }
}

+ (void)addCreatedObject: (EOGenericRecord *)o
{
  [allGenericRecordsLock lock];
  NSHashInsertIfAbsent(allGenericRecords, o);
  [allGenericRecordsLock unlock];
}

+ (void)removeDestroyedObject: (EOGenericRecord *)o
{
  [allGenericRecordsLock lock];
  NSHashRemove(allGenericRecords, o);
  [allGenericRecordsLock unlock];
}

-(void)_createDictionaryForInstanceProperties
{
  // Ayers: Review
  // We use entity dictionaryForProperties to avoid creation 
  //of new EOMKKDInitializer
  ASSIGN(dictionary,[classDescription dictionaryForInstanceProperties]);
  EOFLOGObjectLevelArgs(@"EOGenericRecord", @"Record %p: dictionary=%@",
                        self, dictionary);
};

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
                     globalID: (EOGlobalID *)globalID
{
  if ((self = [self init]))
    {
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

      [self _createDictionaryForInstanceProperties];
    }

  return self;
}

- (void)dealloc
{
  EOFLOGObjectLevelArgs(@"EOGenericRecord",
			@"Deallocate EOGenericRecord %p (dict=%p)",
			self, dictionary);

  [[self class] removeDestroyedObject: self];

  DESTROY(classDescription);
  DESTROY(dictionary);

  [super dealloc];
}

- (EOClassDescription*)classDescription
{
  return classDescription;
}

//MG #if !FOUNDATION_HAS_KVC

static const char _c_id[2] = { _C_ID, 0 };

//used to allow derived object implementation
- (BOOL)_infoForInstanceVariableNamed: (const char*)cStringName
                           stringName: (NSString*)stringName
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
  ok = GSObjCFindVariable(self, cStringName, type, size, offset);

  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Super InstanceVar named %s:%s",
			cStringName, (ok ? "YES" : "NO"));

  if (!ok)
    {
      NSString* name=(stringName ? stringName : GDL2_StringWithCString(cStringName));

      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			    @"dictionary: %p eoMKKDInitializer: %p",
			    dictionary,
			    [dictionary eoMKKDInitializer]);
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"dictionary allkeys= %@",
			    [dictionary allKeys]);
      
      if (EOMKKD_hasKeyWithImpPtr(dictionary,NULL,name))
        {
	  if (type)
	    *type = _c_id;
	  if (size)
	    *size = sizeof(id);
	  if (offset)
	    *offset = INT_MAX; //Special Marker

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
	       offset: (int)offset
{
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Super InstanceVar named %@: sel=%@ type=%s size=%u offset=%u",
			aKey,NSStringFromSelector(sel),type,size,offset);

  if (offset == INT_MAX)
    {
      value = EOMKKD_objectForKeyWithImpPtr(dictionary,NULL,aKey);

      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value %p (class=%@)",
			    value, [value class]);
    }
  else
    {
      value = GSObjCGetVal(self, [aKey UTF8String], sel, type, size, offset);
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
		 offset: (int)offset
{
  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Super InstanceVar named %@: offset=%u",
			aKey, offset);

  if (offset == INT_MAX)
    {
      if (anObject)
        EOMKKD_setObjectForKeyWithImpPtr(dictionary,NULL,anObject,aKey);
      else
        EOMKKD_removeObjectForKeyWithImpPtr(dictionary,NULL,aKey);
    }
  else
    GSObjCSetVal(self, [aKey UTF8String], anObject, sel, type, size, offset);

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
//  if(value == nil || value == GDL2_EONull)
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

inline BOOL infoForInstanceVariableWithImpPtr(id object,GDL2IMP_BOOL* impPtr,
                                              const char* cStringName,NSString* stringName,
                                              const char** type,unsigned int* size,
                                              int* offset)
{
  SEL sel=@selector(_infoForInstanceVariableNamed:stringName:retType:retSize:retOffset:);
  if (!*impPtr)
    *impPtr=(GDL2IMP_BOOL)[object methodForSelector:sel];
  return (**impPtr)(object,sel,cStringName,stringName,type,size,offset);
};

- (id) storedValueForKey: (NSString*)aKey
{
  SEL		sel = 0;
  const char	*type = NULL;
  unsigned	size = 0;
  int		off = 0;
  id value = nil;
  Class 	selfClass=[self class];

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  if ([selfClass useStoredAccessor] == NO)
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
      else
        {
          char buf[size+5];
          char lo;
          char hi;
          GDL2IMP_BOOL rtsIMP=NULL;
          GDL2IMP_BOOL infoVarIMP=NULL;
          
          strcpy(buf, "_get");
          [aKey getCString: &buf[4]];
          lo = buf[4];
          hi = toupper(lo);
          buf[4] = hi;

          // test _getKey
          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"A aKey=%@ Method [_getKey] name=%s",
                                aKey, buf);
          sel = GSSelectorFromName(buf);

          if (sel == 0 || 
	      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
            {
              // test _key
              buf[3]='_';
              buf[4]=lo;

              EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				    @"B aKey=%@ Method [_key] name=%s",
                                    aKey, &buf[3]);
              sel = GSSelectorFromName(&buf[3]);
              
              if (sel == 0 ||
		  GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
                {
                  sel = 0;
                }
            }
          
          if (sel == 0)
            {
              if ([selfClass accessInstanceVariablesDirectly] == YES)
                {
                  // test _key
                  buf[3]='_';
                  buf[4]=lo;

                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"C aKey=%@ Instance [_key] name=%s",
                                        aKey, &buf[3]);
                  /*if ([self _infoForInstanceVariableNamed:&buf[3]
                            stringName: nil
                            retType: &type
                            retSize: &size
                            retOffset: &off]==NO)*/
                  if (infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                        &buf[3], // name
                                                        nil,     // stringName
                                                        &type,   // retType
                                                        &size,   // retSize
                                                        &off)==NO) // retOffset
                    {
                      // key
                      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					    @"C aKey=%@ Instance [key] name=%s",
                                            aKey, &buf[4]);
                      /*[self _infoForInstanceVariableNamed:&buf[4]
                            stringName: aKey
                            retType: &type
                            retSize: &size
                            retOffset: &off];*/
                      infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                        &buf[4], // name
                                                        aKey,     // stringName
                                                        &type,   // retType
                                                        &size,   // retSize
                                                        &off); // retOffset
                    }
                }
              
              if (type == NULL)
                {
                  //test getKey
                  buf[3]='t';
                  buf[4]=hi;
                  
                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"E aKey=%@ Method [getKey] name=%s",
                                        aKey, &buf[1]);
                  sel = GSSelectorFromName(&buf[1]);
                  if (sel == 0 || 
		      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
                    {
                      // test key
                      buf[4]=lo;

                      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					    @"F aKey=%@ Method [key] name=%s",
                                            aKey, &buf[4]);
                      sel = GSSelectorFromName(&buf[4]);
                      
                      if (sel == 0 ||
			  GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
                        {
                          sel = 0;
                        }
                    }
                }
            }

          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
                                @"class=%@ aKey=%@ sel=%@ offset=%u",
                                selfClass, aKey, NSStringFromSelector(sel), off);

          value = [self _getValueForKey: aKey
                        selector: sel
                        type: type
                        size: size
                        offset: off];
        };
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
  int		off = 0;
  Class 	selfClass=[self class];

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"anObject=%@", anObject);
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  if ([selfClass useStoredAccessor] == NO)
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
      else
        {
          char buf[size+6];
          char		lo;
          char		hi;
          GDL2IMP_BOOL rtsIMP=NULL;
          GDL2IMP_BOOL infoVarIMP=NULL;

          strcpy(buf, "_set");
          [aKey getCString: &buf[4]];
          lo = buf[4];
          hi = toupper(lo);
          buf[4] = hi;
          buf[size+4] = ':';
          buf[size+5] = '\0';

          // test _setKey:          
          type = NULL;

          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"A aKey=%@ Method [_setKey] name=%s",
                                aKey, buf);

          sel = GSSelectorFromName(buf);

          if (sel == 0 || 
	      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
            {
              sel = 0;
              
              if ([selfClass accessInstanceVariablesDirectly] == YES)
                {
                  // test _key
                  buf[3] = '_';
                  buf[4] = lo;
                  buf[size+4] = '\0';

                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"B aKey=%@ Instance [_key] name=%s",
                                        aKey, &buf[3]);
                  
                  /*if ([self _infoForInstanceVariableNamed:&buf[3]
                            stringName: nil
                            retType: &type
                            retSize: &size
                            retOffset: &off]==NO)
                  */
                  if (infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                        &buf[3], // name
                                                        nil,     // stringName
                                                        &type,   // retType
                                                        &size,   // retSize
                                                        &off)==NO) // retOffset
                    {
                      // Test key
                      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
                                            @"C aKey=%@ Instance [_key] name=%s",
					    aKey, &buf[4]);
                      
                      /*[self _infoForInstanceVariableNamed: &buf[4]
                            stringName: aKey
                            retType: &type
                            retSize: &size
                            retOffset: &off];*/
                      infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                        &buf[4], // name
                                                        aKey,     // stringName
                                                        &type,   // retType
                                                        &size,   // retSize
                                                        &off); // retOffset
                    }
                }
              
              if (type == NULL)
                {
                  // Test setKey:
                  buf[3] = 't';
                  buf[4] = hi;
                  buf[size+4] = ':';

                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"D aKey=%@ Method [setKey:] name=%s",
                                        aKey, &buf[1]);
                  
                  sel = GSSelectorFromName(&buf[1]);
                  
                  if (sel == 0 || 
		      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
                    {
                      sel = 0;
                    }
                }
            }
          
          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
                                @"class=%@ aKey=%@ sel=%@ offset=%u",
                                selfClass, aKey, NSStringFromSelector(sel),
				off);
          
          [self _setValueForKey: aKey
                object: anObject
                selector: sel
                type: type
                size: size
                offset: off];
        }
    };

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}
//#endif /* !FOUNDATION_HAS_KVC */

/** if key is a bidirectional rel, use addObject:toBothSidesOfRelationship otherwise call  takeValue:forKey: **/
- (void)smartTakeValue: (id)anObject 
                forKey: (NSString *)aKey
{
  BOOL	isToMany = NO;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");

  isToMany=[[classDescription toManyRelationshipKeys]
             containsObject: aKey];

  //NSDebugMLog(@"aKey=%@ rel=%@ anObject=%@", aKey, rel, anObject);
  //NSDebugMLog(@"[rel isBidirectional]=%d", [rel isBidirectional]);

    if ((isToMany
	 || [[classDescription toOneRelationshipKeys] containsObject: aKey])
	&& [classDescription inverseForRelationshipKey: aKey] != nil)
    {
      if (_isNilOrEONull(anObject))
        {
          id oldObj = [self valueForKey: aKey];

          if (_isNilOrEONull(oldObj))
            {
              if (!isToMany)
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

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}

//MG#if !FOUNDATION_HAS_KVC
- (void) takeValue: (id)anObject forKey: (NSString*)aKey
{
  SEL		sel;
  const char	*type;
  unsigned	size;
  int		off=0;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"anObject=%@", anObject);
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  size = [aKey length];
  if (size < 1)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"takeValue:forKey: ... empty key"];
    }
  else
    {
      char		buf[size+6];
      char		lo;
      char		hi;
      GDL2IMP_BOOL rtsIMP=NULL;
      GDL2IMP_BOOL infoVarIMP=NULL;

      // We'll call willChange if we modify ivar directly or call a _setMethod
      // otherwise, the setMethod should do it
      BOOL shouldCallWillChange=NO; //OXYMIUM

      strcpy(buf, "_set");
      [aKey getCString: &buf[4]];
      lo = buf[4];
      hi = toupper(lo);
      buf[4] = hi;
      buf[size+4] = ':';
      buf[size+5] = '\0';

      type = NULL;

      //Try setKey:
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			    @"A aKey=%@ Method [setKey:] name=%s",
                            aKey, &buf[1]);
      sel = GSSelectorFromName(&buf[1]);

      if (sel == 0 || GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
        {
          // Try _setKey:
          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"B aKey=%@ Method [_setKey:] name=%s",
                                aKey, buf);
	  sel = GSSelectorFromName(buf);

          if (sel != 0 &&
	      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == YES)
            {
              shouldCallWillChange=YES;
            }
          else
            {
              sel = 0;

              if ([[self class] accessInstanceVariablesDirectly] == YES)
                {
                  // test _key
		  buf[size+4] = '\0';
		  buf[3] = '_';
		  buf[4] = lo;
                  
                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"C aKey=%@ Instance [_key] name=%s",
                                        aKey, &buf[3]);
                  /*if ([self _infoForInstanceVariableNamed: &buf[3]
                            stringName: nil
                            retType: &type
                            retSize: &size
                            retOffset: &off]==NO)*/
                  if (infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                        &buf[3], // name
                                                        nil,     // stringName
                                                        &type,   // retType
                                                        &size,   // retSize
                                                        &off)==YES) // retOffset
                    {
                      // We'll call willChange
                      shouldCallWillChange=YES;
                    }
                  else
                    {
                      // Test key                      
                      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					    @"D aKey=%@ Instance [key] name=%s",
                                            aKey, &buf[4]);
                      /*[self _infoForInstanceVariableNamed: &buf[4]
                            stringName: aKey
                            retType: &type
                            retSize: &size
                            retOffset: &off];*/
                      infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                        &buf[4], // name
                                                        aKey,     // stringName
                                                        &type,   // retType
                                                        &size,   // retSize
                                                        &off); // retOffset
                      // We'll call willChange
                      shouldCallWillChange=YES;
                    }
                }
            }
        }
      
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
                            @"aKey=%@ sel=%@ offset=%u shouldCallWillChange=%d",
                            aKey, NSStringFromSelector(sel), off,
                            shouldCallWillChange);

      if (shouldCallWillChange)
        [self willChange];

      [self _setValueForKey: aKey
            object: anObject
            selector: sel
            type: type
            size: size
            offset: off];
    };

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}

- (id) valueForKey: (NSString*)aKey
{
  SEL		sel = 0;
  const char	*type = NULL;
  unsigned	size;
  int		off = 0;
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"aKey=%@", aKey);

  size = [aKey length];
  if (size < 1)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"valueForKey: ... empty key"];
    }
  else
    {
      char		buf[size+5];
      char		lo;
      char		hi;
      GDL2IMP_BOOL rtsIMP=NULL;
      GDL2IMP_BOOL infoVarIMP=NULL;

      strcpy(buf, "_get");
      [aKey getCString: &buf[4]];
      lo = buf[4];
      hi = toupper(lo);
      buf[4] = hi;

      // Test getKey
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"A aKey=%@ Method [getKey] name=%s",
                            aKey, &buf[1]);
      sel = GSSelectorFromName(&buf[1]);

      if (sel == 0 || 
	  GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
        {
          //Test key
	  buf[4] = lo;

          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"B aKey=%@ Method [key] name=%s",
                                aKey, &buf[4]);
	  sel = GSSelectorFromName(&buf[4]);

          if (sel == 0 ||
	      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
            {
              //Test _getKey
	      buf[4] = hi;

              EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				    @"C aKey=%@ Method [_getKey] name=%s",
                                    aKey, buf);
	      sel = GSSelectorFromName(buf);
              
              if (sel == 0 ||
		  GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
                {
                  // Test _key
		  buf[3] = '_';
		  buf[4] = lo;

                  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
					@"C aKey=%@ Method [_key] name=%s",
                                        aKey, &buf[3]);
                  sel = GSSelectorFromName(&buf[3]);

                  if (sel == 0 ||
		      GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == NO)
                    {
                      sel = 0;
                    }
                }
            }
        }

      if (sel == 0 && [[self class] accessInstanceVariablesDirectly] == YES)
        {
          // Test _key
          buf[3] = '_';
          buf[4] = lo;
          
          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"D aKey=%@ Instance [_key] name=%s",
                                aKey, &buf[3]);
          /*if ([self _infoForInstanceVariableNamed: &buf[3]
                    stringName: nil
                    retType: &type
                    retSize: &size
                    retOffset: &off]==NO)*/
          if (infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                &buf[3], // name
                                                nil,     // stringName
                                                &type,   // retType
                                                &size,   // retSize
                                                &off)==NO) // retOffset
            {
              // Test key
              
              EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				    @"E aKey=%@ Instance [key] name=%s",
                                    aKey, &buf[4]);
              /*[self _infoForInstanceVariableNamed:  &buf[4]
                    stringName: aKey
                    retType: &type
                    retSize: &size
                    retOffset: &off];*/
              infoForInstanceVariableWithImpPtr(self,&infoVarIMP,
                                                &buf[4], // name
                                                aKey,     // stringName
                                                &type,   // retType
                                                &size,   // retSize
                                                &off); // retOffset
            }
        }
      
      EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
                            @"aKey=%@ sel=%@ offset=%u",
                            aKey, NSStringFromSelector(sel), off);
      
      value = [self _getValueForKey: aKey
                    selector: sel
                    type: type
                    size: size
                    offset: off];
    };
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value: %p (class=%@)",
			value, [value class]);
  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");

  return value;
}

//MG#else /* FOUNDATION_HAS_KVC */
/*
- (id) handleQueryWithUnboundKey: (NSString *)key
{
  id value;

  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Unbound key named %@",
			key);

  if (![dictionary hasKey: key])
    return [super handleQueryWithUnboundKey: key];

  value = [dictionary objectForKey: key];

  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC", @"value %p (class=%@)",
			value, [value class]);
  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");

  return value;
}

- (void) handleTakeValue: (id)value forUnboundKey: (NSString *)key
{
  EOFLOGObjectFnStartCond(@"EOGenericRecordKVC");
  EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
			@"Unbound key named %@",
			key);

  [self willChange];

  if (![dictionary hasKey:key])
    [super handleTakeValue:value forUnboundKey: key];

  if (value)
    [dictionary setObject: value
		forKey: key];
  else
//        [dictionary setObject: GDL2_EONull
//                       forKey: key];
    [dictionary removeObjectForKey: key];

  EOFLOGObjectFnStopCond(@"EOGenericRecordKVC");
}
*/
//MG#endif /* FOUNDATION_HAS_KVC */


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
  IMP ofkIMP=NULL;
  IMP enumNO=NULL;
  IMP dictSOFK=NULL;

  toManyKeys = [classDescription toManyRelationshipKeys];
  toOneKeys = [classDescription toOneRelationshipKeys];
  dict = [NSMutableDictionary dictionaryWithCapacity: [dictionary count]];

  while ((key = GDL2_NextObjectWithImpPtr(enumerator,&enumNO)))
    {
      obj = EOMKKD_objectForKeyWithImpPtr(dictionary,&ofkIMP,key);
      if (!obj)
        GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,@"(null)",key);
      else
        {
          // print out only simple values
          if ([toManyKeys containsObject: key] == NO
	      && [toOneKeys containsObject: key] == NO)
            {
              GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,obj,key);
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
  IMP ofkIMP=NULL;
  IMP enumNO=NULL;
  IMP dictSOFK=NULL;

  toManyKeys = [classDescription toManyRelationshipKeys];
  toOneKeys = [classDescription toOneRelationshipKeys];

  dict = [NSMutableDictionary dictionaryWithCapacity: [dictionary count]];

  while ((key = GDL2_NextObjectWithImpPtr(enumerator,&enumNO)))
    {
      obj = EOMKKD_objectForKeyWithImpPtr(dictionary,&ofkIMP,key);

      if (!obj)
        GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,@"(null)",key);
      else if (_isFault(obj) == YES)
        {
          GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,
                                        [obj description],key);
        }
      else if (obj==GDL2_EONull)
        {
          GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,@"(null)",key);
        }
      else
        {
          if ([toManyKeys containsObject: key] != NO)
            {
              NSEnumerator *toManyEnum;
              NSMutableArray *array;
              id rel;
              IMP toManyEnumNO=NULL;
              IMP arrayAO=NULL;
              
              array = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 8]);
              toManyEnum = [obj objectEnumerator];
              
              while ((rel = GDL2_NextObjectWithImpPtr(toManyEnum,&toManyEnumNO)))
                {
                  NSString* relDescr=nil;
                  // Avoid infinit loop
                  if ([rel respondsToSelector: @selector(_shortDescription)])
                    relDescr=[rel _shortDescription];
                  else
                    relDescr=[rel description];
                  
                  GDL2_AddObjectWithImpPtr(array,&arrayAO,
                                          [NSString
                                            stringWithFormat: @"<%@ %p>",
                                            relDescr, NSStringFromClass([rel class])]);
                }
              
              GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,
                                            [NSString stringWithFormat:
                                                        @"<%p %@ : %@>",
                                                      obj, [obj class], array],
                                            key);
            }
          else if ([toOneKeys containsObject: key] != NO)
            {
              GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,
                                            [NSString
                                              stringWithFormat: @"<%p %@: classDescription=%@>",
                                              obj,
                                              NSStringFromClass([obj class]),
                                              [(EOGenericRecord *)obj classDescription]],
                                            key);
            }
          else
            {
              GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,obj,key);
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

/** should returns an array of property names to exclude from entity 
instanceDictionaryInitializer.
You can override this to exclude properties manually handled by derived object **/
+ (NSArray *)_instanceDictionaryInitializerExcludedPropertyNames
{
  //Ayers: Review (There is also an NSObject category making kind of redundant)
  // default implementation returns nil
  return nil;
};

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
  NSAutoreleasePool *arp;

  EOFLOGClassFnStart();
  //NSDebugMLog(@"CALCULATE START");

  [allGenericRecordsLock lock];

  NS_DURING
    {
      arp = [NSAutoreleasePool new];
      hashEnum = NSEnumerateHashTable(allGenericRecords);
 
      while ((record = (EOGenericRecord*)NSNextHashEnumeratorItem(&hashEnum)))
        {
          if (_isFault(record))
            [EOFault eoCalculateSizeWith: dict
                     forFault: record];
          else
            [record eoCalculateSizeWith: dict];
        }

      NSEndHashTableEnumeration(&hashEnum);
    }
  NS_HANDLER
    {
      NSDebugMLog(@"%@ (%@)", localException, [localException reason]);

      RETAIN(localException);
      DESTROY(arp);
      AUTORELEASE(localException);

      [allGenericRecordsLock unlock];

      NSDebugMLog(@"CALCULATE STOPEXC", "");
      [localException raise];
    }
  NS_ENDHANDLER;

  DESTROY(arp);

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

      // Get class properties (attributes + relationships)
      props = [NSMutableArray arrayWithArray: [classDescription attributeKeys]];
      [(NSMutableArray *)props addObjectsFromArray:
			   [classDescription toOneRelationshipKeys]];
      [(NSMutableArray *)props addObjectsFromArray:
			   [classDescription toManyRelationshipKeys]];
      size += [self eoGetSize];
      size += [dictionary eoGetSize];

      //NSDebugMLog(@"props=%@",props);

      propCount = [props count];

      for (i = 0; i < propCount; i++)
        {
          NSString *propKey = [props objectAtIndex: i];
          id value = [self valueForKey: propKey];

          //NSDebugMLog(@"propKey=%@", propKey);
          //NSDebugMLog(@"value isFault=%s", (_isFault(value) ? "YES" : "NO"));
          //NSDebugMLog(@"value=%p class=%@", value, [value class]);

          if (value)
            {
              if (_isFault(value))
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
        (int)(totalNb!=0 ? (totalSize / totalNb) : 0),
        (int)(totalNb!=0 ? (totalSize / totalNb / 1024) : 0)];

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
