/** 
 EOCustomObject.m <title>EOCustomObject</title>
 
 Copyright (C) 2010 Free Software Foundation, Inc.
 
 Author: David Wetzel <dave@turbocat.de>
 Date: April 2010
 
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

RCS_ID("$Id: EOGenericRecord.m 30111 2010-04-09 10:09:41Z ayers $")

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSHashTable.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSError.h>
#include <Foundation/FoundationErrors.h>
#else
#include <Foundation/Foundation.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

#include "EOCustomObject.h"
#include "EOPrivate.h"


@implementation EOCustomObject


- (void) dealloc
{
  [EOEditingContext _objectDeallocated: self];
  
  [EOObserverCenter _forgetObject:self];
  
  [super dealloc];
}


// used to be EOInitialization

- (id)initWithEditingContext: (EOEditingContext *)editingContext
            classDescription: (EOClassDescription *)classDescription
                    globalID: (EOGlobalID *)globalID
{
  return [self init];
}

// -------
// from GDL2CDNSObject

- (EOClassDescription *)classDescription
{
  EOClassDescription *cd;
    
  cd = (EOClassDescription *)[EOClassDescription classDescriptionForClass:[self class]];
  
  return cd;
}

- (NSString *)entityName
{
  NSString *entityName;
  
  entityName = [[self classDescription] entityName];
    
  return entityName;
}

- (NSArray *)attributeKeys
{
  NSArray *attributeKeys;
    
  attributeKeys = [[self classDescription] attributeKeys];
  
  
  return attributeKeys;
}

- (NSArray *)toOneRelationshipKeys
{
  NSArray *toOneRelationshipKeys;
  
  
  toOneRelationshipKeys = [[self classDescription] toOneRelationshipKeys];
  
  
  return toOneRelationshipKeys;
}

- (NSArray *)toManyRelationshipKeys
{
  NSArray *toManyRelationshipKeys;
  
  
  toManyRelationshipKeys = [[self classDescription] toManyRelationshipKeys];
  
  
  return toManyRelationshipKeys;
}

- (NSString *)inverseForRelationshipKey: (NSString *)relationshipKey
{
  NSString *inverse;
  
  
  inverse = [[self classDescription]
             inverseForRelationshipKey: relationshipKey];
  
  
  return inverse;
}

- (EODeleteRule)deleteRuleForRelationshipKey: (NSString *)relationshipKey
{
  EODeleteRule rule;
  EOClassDescription *cd;
    
  cd = [self classDescription];
  
  rule = [cd deleteRuleForRelationshipKey: relationshipKey];
  
  
  return rule;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey: (NSString *)relationshipKey
{
  BOOL owns;
  
  
  owns = [[self classDescription]
          ownsDestinationObjectsForRelationshipKey: relationshipKey];
  
  
  return owns;
}

- (EOClassDescription *)classDescriptionForDestinationKey:(NSString *)detailKey
{
  EOClassDescription *cd;
    
  cd = [[self classDescription] classDescriptionForDestinationKey: detailKey];
  
  return cd;
}

- (NSString *)userPresentableDescription
{
  EOClassDescription * classDes = [self classDescription];

  if (classDes) {
    return [classDes userPresentableDescriptionForObject:self];
  }

  return nil;
}

- (NSException *)validateValue: (id *)valueP
                        forKey: (NSString *)key
{
  NSException *exception;
  EOClassDescription *selfClassDescription;
  
  
  NSAssert(valueP, @"No value pointer");
  
  selfClassDescription = [self classDescription];
  
  exception = [selfClassDescription validateValue: valueP
                                           forKey: key];
  if (exception)
  {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              self, EOValidatedObjectUserInfoKey,
                              key, EOValidatedPropertyUserInfoKey,
                              nil];
    
    exception = [NSException exceptionWithName: [exception name]
                                        reason: [exception reason]
                                      userInfo: userInfo];
  }
  
  if (exception == nil)
  {
    NSUInteger size = [key length];
    
    if (size < 1)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"storedValueForKey: ... empty key"];
    }
    else
    {
      SEL validateSelector;
      NSUInteger length = [key length];
      char buf[length + 10];
      
      strcpy(buf, "validate");
      [key getCString: &buf[8]];
      buf[8] = toupper((int)buf[8]);
      buf[length + 8] = ':';
      buf[length + 9] = 0;
      
      validateSelector = GSSelectorFromName(buf);
      if (validateSelector && [self respondsToSelector: validateSelector])
	    {
	      exception = [self performSelector: validateSelector
                               withObject: *valueP];
	    }
    }
  }
  
  
  return exception;
}

/**
 * returns YES if value is valid
 **/

- (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)outError
{
  NSException *ex;

  ex = [self validateValue:value forKey:key];
  
  if (ex) {
    NSDictionary * uInfo;
    NSString     * errorString = @"unknown reason";
    
    uInfo = [NSDictionary dictionaryWithObjectsAndKeys:
             (*value ? *value : (id)@"nil"), @"EOValidatedObjectUserInfoKey",
             key, @"EOValidatedPropertyUserInfoKey",
             nil];
    

    NSDictionary *userInfoDict =
    [NSDictionary dictionaryWithObject:[ex reason]
                                forKey:NSLocalizedDescriptionKey];
    NSError *error = [[[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                 code:NSKeyValueValidationError
                                             userInfo:uInfo] autorelease];
    *outError = error;
    
    
    return NO;
  }
  
  return YES;
}

/**
 * This method is called to validate and potentially coerce
 * VALUE for the receivers key path.  This method also assigns
 * the value if it is different from the current value.
 * This method will raise an EOValidationException
 * if validateValue:forKey: returns an exception.
 * This method returns new value.
 **/
- (id)validateTakeValue:(id)value forKeyPath:(NSString *)path
{
  id nval = value;
  id oval;
  NSRange	r = [path rangeOfString: @"."];
  
  if (r.length == 0)
  {
    NSException *e = [self validateValue:&nval forKey:path];
    
    if (e)
    {
      [e raise];
    }
    
    oval = [self valueForKey:path];
    if (nval != oval && 
        ((nval == nil || oval == nil) || [nval isEqual: oval] == NO))
    {
      [self takeValue:nval forKey: path];
    }
  }
  else
  {
    NSString	*key = [path substringToIndex: r.location];
    NSString	*kpath = [path substringFromIndex: NSMaxRange(r)];
    
    nval = [[self valueForKey: key] validateTakeValue: nval forKeyPath: kpath];
  }
  return nval;
}


- (NSException *)validateForSave
{
  NSMutableArray *expArray = nil;
  NSException* exception;
  int which;
  IMP selfVFK=NULL; // valueForKey:
  IMP selfVVFK=NULL; // validateValue:forKey:
  IMP selfTVFK=NULL; // takeValue:forKey:
  
  
  exception = [[self classDescription] validateObjectForSave: self];
  
  if (exception)
  {
    if (!expArray)
      expArray = [NSMutableArray array];
    [expArray  addObject:exception];
  }
  
  for (which = 0; which < 3; which++)
  {
    NSArray *keys;
    
    if (which == 0)
      keys = [self attributeKeys];
    else if (which == 1)
      keys = [self toOneRelationshipKeys];
    else
      keys = [self toManyRelationshipKeys];
    
    if (keys)
    {
      int keysCount = [keys count];
      int i;
      IMP oaiIMP=NULL;
      
      for (i = 0; i < keysCount; i++)
      {
        NSString *key = GDL2_ObjectAtIndexWithImpPtr(keys,&oaiIMP,i);
        id value = GDL2_ValueForKeyWithImpPtr(self,&selfVFK,key);
        id newValue = value;
        BOOL isEqual=NO;
        
        exception = GDL2_ValidateValueForKeyWithImpPtr(self,&selfVVFK,&newValue,key);
        if (exception)
        {
          if (!expArray)
            expArray = [NSMutableArray array];
          [expArray addObject: exception];
        }              
        if (newValue==value)
          isEqual = YES;
        else if (_isNilOrEONull(newValue))
          isEqual = _isNilOrEONull(value);
        else 
          isEqual = [newValue isEqual: value];
        
        if (isEqual == NO)
        {
          GDL2_TakeValueForKeyWithImpPtr(self,&selfTVFK,newValue,key);
        }
      }
    }
  }
  
  
  return [NSException aggregateExceptionWithExceptions: expArray];
}

- (NSException *)validateForDelete
{
  NSException *exception;
  
  
  exception = [[self classDescription] validateObjectForDelete: self];
  
  
  return exception;
}

- (void)awakeFromInsertionInEditingContext: (EOEditingContext *)editingContext
{
  
  [[self classDescription] awakeObject: self
			   fromInsertionInEditingContext: editingContext];
  
}

- (void)awakeFromFetchInEditingContext: (EOEditingContext *)editingContext
{
  
  [[self classDescription] awakeObject: self
             fromFetchInEditingContext: editingContext];
  
}



// -----------------------------------------------
// those used to be EOClassDescriptionPrimitives


// -----------------------------------------------

// those used to be NSObject EOKeyRelationshipManipulation

- (void)addObject: (id)object toPropertyWithKey: (NSString *)key
{
  NSUInteger size = [key length];
  
  if (size < 1)
  {
    [NSException raise: NSInvalidArgumentException
                format: @"addObject:toPropertyWithKey: ... empty key"];
  }
  else
  {
    char buf[size+7];
    GDL2IMP_BOOL rtsIMP=NULL;
    SEL sel=NULL;
    
    // Test addToKey:
    
    strcpy(buf, "addTo");
    [key getCString: &buf[5]];
    buf[5] = toupper(buf[5]);
    buf[size+5] = ':';
    buf[size+6] = '\0';
    
    
    sel = GSSelectorFromName(buf);
    
    if (sel && GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == YES)
    {      
      [self performSelector: sel
                 withObject: object];
    }
    else
    {
      id val = nil;
      
      if ([self isToManyKey: key] == YES)
      {
        
        val = [self valueForKey: key]; //should use storedValueForKey: ?
        
        if (![val containsObject: object])
        {          
          if ([val isKindOfClass: GDL2_NSMutableArrayClass])
          {
            [self willChange];
            [val addObject: object];
          }
          else
          {
            NSMutableArray *relArray;
            
            relArray = (val)
            ? AUTORELEASE([val mutableCopy])
            : AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 10]);
            
            [relArray addObject: object];
            
            [self takeValue: relArray
                     forKey: key];
          }
        }
      }
      else
      {
        
        [self takeValue: object
                 forKey: key];
      }
    }
  }
}

- (void)removeObject: (id)object fromPropertyWithKey: (NSString *)key
{
  NSUInteger size = [key length];
  
  if (size < 1)
  {
    [NSException raise: NSInvalidArgumentException
                format: @"removeObject:fromPropertyWithKey: ... empty key"];
  }
  else
  {
    char buf[size+12];
    GDL2IMP_BOOL rtsIMP=NULL;
    SEL sel=NULL;
    
    // Test removeFromKey:
    
    strcpy(buf, "removeFrom");
    [key getCString: &buf[10]];
    buf[10] = toupper(buf[10]);
    buf[size+10] = ':';
    buf[size+11] = '\0';
        
    sel = GSSelectorFromName(buf);
    
    if (sel && GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == YES)
    {
      [self performSelector: sel
                 withObject: object];
    }
    else
    {
      id val = nil;
            
      if ([self isToManyKey:key] == YES)
      {        
        val = [self valueForKey: key];
        
        if ([val isKindOfClass: GDL2_NSMutableArrayClass])
        {
          [self willChange];
          [val removeObject: object];
        }
        else
        {
          NSMutableArray *relArray = nil;
          
          if (val)
          {
            relArray = AUTORELEASE([val mutableCopy]);
            
            [relArray removeObject: object];
            [self takeValue: relArray
                     forKey: key];
          }
        }
      }
      else
      {
        [self takeValue: nil
                 forKey: key];
      }
    }
  }
}

- (void)_setObject: (id)object forBothSidesOfRelationshipWithKey: (NSString*)key
{
  
  id oldObject = [self valueForKey: key];
  
  if (object!=oldObject) // Don't put it again if it is already set
  {
    NSString *inverseKey = NULL;
    inverseKey = [self inverseForRelationshipKey:key];
    
    if (inverseKey)
    {
      if (oldObject==GDL2_EONull)
      {
        NSWarnMLog(@"Warning: oldObject is an EONull. self=%@ key=%@ object=%@",self,key,object);
      }
      else
      {
        [oldObject removeObject: self
            fromPropertyWithKey: inverseKey];
        [object addObject: self
        toPropertyWithKey: inverseKey];
      }
    }
    
    [self takeValue: object
             forKey: key];
  }
}

- (void)addObject: (id)object toBothSidesOfRelationshipWithKey: (NSString *)key
{
  // 2 differents cases: to-one and to-many relation
  if ([self isToManyKey:key]) // to-many
  {
    //See if there's an inverse relationship
    NSString *inverseKey = [self inverseForRelationshipKey: key];
    
    NSDebugMLLog(@"gsdb", @"self %p=%@,object %p=%@ key=%@ inverseKey=%@",
                 self,
                 self,
                 object,
                 object,
                 key,
                 inverseKey);
    
    // First add object to self relation array
    [self addObject: object toPropertyWithKey: key];
    
    if (inverseKey) //if no inverse relation do nothing 
    {
      if (object==GDL2_EONull)
      {
        NSWarnMLog(@"Warning: object is an EONull. self=%@ key=%@ object=%@",self,key,object);
      }
      else
      {
        // See if inverse relationship is to-many or to-one
        if ([object isToManyKey: inverseKey])
        {
          //TODO VERIFY
          [object addObject:self
          toPropertyWithKey:inverseKey];
        }
        else
        {
          // Previous value, if any
          id oldObject = [object valueForKey: inverseKey];
          
          // Don't put it again if it already set
          if (object!=oldObject)
          {
            if (oldObject)
            {
              //TODO VERIFY
              [object removeObject:oldObject
               fromPropertyWithKey:inverseKey];
            }
            
            // Just set self into object relationship property
            [object takeValue: self
                       forKey: inverseKey];
          };
        }
      }
    }
  }
  else
  {
    [self _setObject: object forBothSidesOfRelationshipWithKey: key];
  }
}

- (void)removeObject: (id)object fromBothSidesOfRelationshipWithKey: (NSString *)key
{
  NSString *inverseKey=nil;
  
  [self removeObject: object
 fromPropertyWithKey: key];
  
  if ((inverseKey = [self inverseForRelationshipKey: key]))
  {
    if (object==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: object is an EONull. self=%@ key=%@",self,key);
    }
    else
    {
      [object removeObject: self
       fromPropertyWithKey: inverseKey];
    }
  };
}

// -----------------------------------------------
// those used to be NSObject (_EOValueMerging)

- (void)mergeValue: (id)value
            forKey: (id)key
{
  [self notImplemented:_cmd];
  return;
}

- (void)mergeChangesFromDictionary: (NSDictionary *)changes
{
  [self notImplemented:_cmd];
  return;
}

- (NSDictionary *)changesFromSnapshot: (NSDictionary *)snapshot
{
  id propertiesList[2];
  NSArray *properties;
  int h, i, count;
  NSMutableArray *newKeys
  = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 16]);
  NSMutableArray *newVals
  = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 16]);
  NSString *key;
  IMP selfSVFK=NULL; // storedValueForKey:
  IMP snapshotSVFK=NULL; // storedValueForKey:
  IMP newKeysAO=NULL;
  IMP newValsAO=NULL;
  
  propertiesList[0] = [self attributeKeys];
  propertiesList[1] = [self toOneRelationshipKeys];
  
  for (h = 0; h < 2; h++)
  {
    id val, oldVal;
    IMP oaiIMP=NULL;
    
    properties = propertiesList[h];
    count = [properties count];
    
    for(i = 0; i < count; i++)
    {
      key = GDL2_ObjectAtIndexWithImpPtr(properties, &oaiIMP, i);
      val = GDL2_StoredValueForKeyWithImpPtr(self, &selfSVFK, key);
      oldVal = GDL2_StoredValueForKeyWithImpPtr(snapshot, &snapshotSVFK, key);
      
      if (val == oldVal || [val isEqual: oldVal] == YES)
        continue;
      
      GDL2_AddObjectWithImpPtr(newKeys,&newKeysAO,key);
      GDL2_AddObjectWithImpPtr(newVals,&newValsAO,val);
    };
  }
  
  properties = [self toManyRelationshipKeys];
  count = [properties count];
  
  if (count>0)
  {
    IMP oaiIMP=NULL;
    for(i = 0; i < count; i++)
    {
      NSMutableArray *array, *objects;
      NSArray *val, *oldVal;
      int valCount, oldValCount;
      
      key = GDL2_ObjectAtIndexWithImpPtr(properties, &oaiIMP, i);
      val = GDL2_StoredValueForKeyWithImpPtr(self, &selfSVFK, key);
      oldVal = GDL2_StoredValueForKeyWithImpPtr(snapshot, &snapshotSVFK, key);
      
      if ((id)val == GDL2_EONull)
        val = nil;
      
      if ((id)oldVal == GDL2_EONull)
        oldVal = nil;
      
      if (!val && !oldVal)
        continue;
      
      valCount = [val count];
      oldValCount = [oldVal count];
      
      if (valCount == 0 && oldValCount == 0)
        continue;
      
      array 
	    = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 2]);
      
      if (val && valCount>0)
      {
        objects 
        = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithArray: val]);
        [objects removeObjectsInArray: oldVal];
      }
      else
        objects 
	      = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 1]);
      
      [array addObject: objects];
      
      if (val && valCount > 0)
      {
        objects 
        = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithArray: oldVal]);
        [objects removeObjectsInArray: val];
      }
      else
        objects 
	      = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 1]);
      
      [array addObject: objects];
      
      GDL2_AddObjectWithImpPtr(newKeys,&newKeysAO,key);
      GDL2_AddObjectWithImpPtr(newVals,&newValsAO,array);
    }
  };
  
  return [NSDictionary dictionaryWithObjects: newVals forKeys: newKeys];
}

- (void)reapplyChangesFromSnapshot: (NSDictionary *)changes
{
  [self notImplemented: _cmd];
}

// -----------------------------------------------
// those used to be NSObject (EOClassDescriptionExtras)

- (NSDictionary *)snapshot
{
  //OK Can be Improved may be by using a dictionaryinitializer
  NSMutableDictionary *snapshot;
  NSArray *attributeKeys;
  NSArray *toOneRelationshipKeys;
  NSArray *toManyRelationshipKeys;
  
  unsigned attributeKeyCount;
  unsigned toOneRelationshipKeyCount;
  unsigned toManyRelationshipKeyCount;
  unsigned i;
  
    IMP selfSVFK=NULL; // storedValueForKey:
    IMP snapshotSOFK=NULL; // setObject:forKey:
    
    attributeKeys = [self attributeKeys];
    
    toOneRelationshipKeys = [self toOneRelationshipKeys];
    toManyRelationshipKeys = [self toManyRelationshipKeys];
    
    attributeKeyCount = [attributeKeys count];
    toOneRelationshipKeyCount = [toOneRelationshipKeys count];
    toManyRelationshipKeyCount = [toManyRelationshipKeys count];
    
    
    snapshot 
    = AUTORELEASE([GDL2_alloc(NSMutableDictionary) initWithCapacity:
                   (attributeKeyCount +
                    toOneRelationshipKeyCount +
                    toManyRelationshipKeyCount)]);
    
    if (attributeKeyCount>0)
    {
      IMP oaiIMP=NULL;
      
      for (i = 0; i < attributeKeyCount; i++)
      {
        id key = GDL2_ObjectAtIndexWithImpPtr(attributeKeys,&oaiIMP,i);
        id value = GDL2_StoredValueForKeyWithImpPtr(self,&selfSVFK,key);
        
        if (!value)
          value = GDL2_EONull;
        
        GDL2_SetObjectForKeyWithImpPtr(snapshot,&snapshotSOFK,value,key);
      }
    };
    
    if (toOneRelationshipKeyCount>0)
    {
      IMP oaiIMP=NULL;
      
      for (i = 0; i < toOneRelationshipKeyCount; i++)
      {
        id key = GDL2_ObjectAtIndexWithImpPtr(toOneRelationshipKeys,
                                              &oaiIMP,i);
        id value = GDL2_StoredValueForKeyWithImpPtr(self,&selfSVFK,key);
        
        if (!value)
          value = GDL2_EONull;
        
        GDL2_SetObjectForKeyWithImpPtr(snapshot,&snapshotSOFK,value,key);
      }
    };
    
    
    if (toManyRelationshipKeyCount>0)
    {
      IMP oaiIMP=NULL;
      
      for (i = 0; i < toManyRelationshipKeyCount; i++)
      {
        id key = GDL2_ObjectAtIndexWithImpPtr(toManyRelationshipKeys,
                                              &oaiIMP,i);
        id value = GDL2_StoredValueForKeyWithImpPtr(self,&selfSVFK,key);
        
        if (value)
        {
          
          value = AUTORELEASE([(NSArray *)value shallowCopy]);
          
          GDL2_SetObjectForKeyWithImpPtr(snapshot,&snapshotSOFK,
                                         value,key);
        }
        /*    //TODO-VERIFY or set it to eonull ?
         else
         value=GDL2_EONull;
         */
      }
    };
  
  return snapshot;
}

- (void)updateFromSnapshot: (NSDictionary *)snapshot
{
  NSEnumerator *snapshotEnum = [snapshot keyEnumerator];
  NSString *key;
  id val;
  IMP selfTSVFK=NULL; // takeStoredValue:forKey:
  IMP snapshotOFK=NULL;
  IMP enumNO=NULL; // nextObject
  
  while ((key = GDL2_NextObjectWithImpPtr(snapshotEnum,&enumNO)))
  {
    val = GDL2_ObjectForKeyWithImpPtr(snapshot,&snapshotOFK,key);
    
    if (val==GDL2_EONull)
      val = nil;
    
    if ([val isKindOfClass: GDL2_NSArrayClass])
      val = AUTORELEASE([val mutableCopy]);
    
    GDL2_TakeStoredValueForKeyWithImpPtr(self,&selfTSVFK,val,key);
  }
}

- (BOOL)isToManyKey: (NSString *)key
{
  NSArray *toMany = [self toManyRelationshipKeys];
  NSEnumerator *toManyEnum = [toMany objectEnumerator];
  NSString *relationship;
  IMP enumNO=NULL; // nextObject
  
  while ((relationship = GDL2_NextObjectWithImpPtr(toManyEnum,&enumNO)))
  {
    if ([relationship isEqualToString: key])
      return YES;
  }
  
  return NO;
}

- (NSException *)validateForInsert
{
  NSException *exception;
    
  exception = [self validateForSave];
    
  return exception;
}

- (NSException *)validateForUpdate
{
  NSException *exception;
    
  exception = [self validateForSave];
    
  return exception;
}

- (NSArray *)allPropertyKeys
{
  NSArray *toOne;
  NSArray *toMany;
  NSArray *attr;
  NSMutableArray *ret;
  
  attr = [self attributeKeys];
  toOne = [self toOneRelationshipKeys];
  toMany = [self toManyRelationshipKeys];
  
  ret = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity:
                     [attr count] + [toOne count] 
                     + [toMany count]]);
  
  [ret addObjectsFromArray: attr];
  [ret addObjectsFromArray: toOne];
  [ret addObjectsFromArray: toMany];
  
  return ret;
}

- (void)clearProperties
{
  NSArray *toOne = nil;
  NSArray *toMany = nil;
  NSEnumerator *relEnum = nil;
  NSString *key = nil;
  IMP selfTSVFK=NULL; // takeStoredValue:forKey:
  IMP enumNO=NULL; // nextObject
    
  toOne = [self toOneRelationshipKeys];
  toMany = [self toManyRelationshipKeys];
  
  relEnum = [toOne objectEnumerator];
  enumNO=NULL;
  
  while ((key = GDL2_NextObjectWithImpPtr(relEnum,&enumNO)))
    GDL2_TakeStoredValueForKeyWithImpPtr(self,&selfTSVFK,nil,key);
  
  
  relEnum = [toMany objectEnumerator];
  enumNO=NULL;
  
  while ((key = GDL2_NextObjectWithImpPtr(relEnum,&enumNO)))
    GDL2_TakeStoredValueForKeyWithImpPtr(self,&selfTSVFK,nil,key);

}

- (void)propagateDeleteWithEditingContext: (EOEditingContext *)editingContext
{  
  [[self classDescription] propagateDeleteForObject: self
                                     editingContext: editingContext];
}

- (NSString *)eoShallowDescription
{
  [self notImplemented: _cmd];
  return nil; //TODO
}

- (NSString *)eoDescription
{
  NSArray *attrArray = [self allPropertyKeys];
  NSEnumerator *attrEnum = [attrArray objectEnumerator];
  NSString *key;
  IMP attrEnumNO=NULL; // nextObject
  IMP retAS=NULL; // appendString:
  IMP selfVFK=NULL; // valueForKey:
  
  NSMutableString *ret = [NSMutableString
                          stringWithCapacity: 5 * [attrArray count]];
  
  GDL2_AppendStringWithImpPtr(ret,&retAS,
                              [NSString stringWithFormat:@"<%@ (%p)",
                               NSStringFromClass([self class]), self]);
  
  while ((key = GDL2_NextObjectWithImpPtr(attrEnum,&attrEnumNO)))
  {
    GDL2_AppendStringWithImpPtr(ret,&retAS,
                                [NSString stringWithFormat: @" %@=%@",
                                 key, 
                                 GDL2_ValueForKeyWithImpPtr(self,&selfVFK,key)]);
  }
  
  GDL2_AppendStringWithImpPtr(ret,&retAS,@">");
  
  return ret; //TODO
}

// -----------------------------------------------


@end
