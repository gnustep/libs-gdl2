/** 
   EOFetchSpecification.m <title>EOFetchSpecification</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
#include <Foundation/NSCoder.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOKeyValueArchiver.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EODebug.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EOQualifier.h>

#include <EOControl/EODeprecated.h>

NSString *EOPrefetchingRelationshipHintKey = @"EOPrefetchingRelationshipHintKey";
NSString *EOFetchLimitHintKey = @"EOFetchLimitHintKey";
NSString *EOPromptAfterFetchLimitHintKey = @"EOPromptAfterFetchLimitHintKey";


@interface NSObject (EOAccess)
 /* EOEntity.h */
- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)fetchSpecName;
 /* EOModelGroup */
- (id)entityNamed:(NSString *)entityName;
+ (id)defaultGroup;
@end

@implementation EOFetchSpecification

+ (void)initialize
{
  if (self == [EOFetchSpecification class])
    {
      Class cls = NSClassFromString(@"EODatabaseContext");

      if (cls != Nil)
	[cls class]; // Insure correct initialization.
    }
}


+ (EOFetchSpecification *)fetchSpecification
{
  return [[[self alloc] init] autorelease];
}

- (id) init
{
  if ((self = [super init]))
    {
      _flags.isDeep = YES;
    }

  return self;
}

- (void)dealloc
{
#ifdef DEBUG
//  NSDebugFLog(@"Dealloc EOFetchSpecification %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif

  DESTROY(_qualifier);
  DESTROY(_sortOrderings);
  DESTROY(_entityName);
  DESTROY(_hints);
  DESTROY(_prefetchingRelationshipKeys);
  DESTROY(_rawAttributeKeys);

  [super dealloc];

#ifdef DEBUG
//  NSDebugFLog(@"Stop Dealloc EOFetchSpecification %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif
}

- (id) initWithEntityName: (NSString *)entityName
		qualifier: (EOQualifier *)qualifier
	    sortOrderings: (NSArray *)sortOrderings
	     usesDistinct: (BOOL)usesDistinct
		   isDeep: (BOOL)isDeep
		    hints: (NSDictionary *)hints
{
  if ((self = [self init]))
    {
      ASSIGN(_entityName, entityName);
      ASSIGN(_qualifier, qualifier);
      ASSIGN(_sortOrderings, sortOrderings);

      [self setUsesDistinct: usesDistinct];
      [self setIsDeep: isDeep];
      [self setHints: hints];
    }

  return self;
}

- (EOFetchSpecification *)fetchSpecificationWithQualifierBindings: (NSDictionary *)bindings
{
  EOQualifier *qualifier;
  BOOL flag = [self requiresAllQualifierBindingVariables];

  qualifier = [[self qualifier] qualifierWithBindings: bindings
				requiresAllVariables: flag];
  [self setQualifier: qualifier];
  return self;
}

+ (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)name
                                      entityNamed: (NSString *)entityName
{
  Class modelGroupClass = GSClassFromName("EOModelGroup");
  if (modelGroupClass != Nil)
    {
      return [[[modelGroupClass defaultGroup] entityNamed: entityName] 
	       fetchSpecificationNamed: name];
    }
  return nil;
}

+ (EOFetchSpecification *)fetchSpecificationWithEntityName: (NSString *)name
                                                 qualifier: (EOQualifier *)qualifier
                                             sortOrderings: (NSArray *)sortOrderings
{
    return [[[EOFetchSpecification alloc]
	      initWithEntityName: name
	      qualifier: qualifier
	      sortOrderings: sortOrderings
	      usesDistinct: NO
	      isDeep: YES
	      hints: nil] autorelease];
}

+ (EOFetchSpecification *)fetchSpecificationWithEntityName: (NSString *)name
                                                 qualifier: (EOQualifier *)qualifier
                                             sortOrderings: (NSArray *)sortOrderings
                                              usesDistinct: (BOOL)usesDistinct
                                                    isDeep: (BOOL)isDeep
                                                     hints: (NSDictionary *)hints
{
    return [[[EOFetchSpecification alloc]
	      initWithEntityName: name
	      qualifier: qualifier
	      sortOrderings: sortOrderings
	      usesDistinct: usesDistinct
	      isDeep: isDeep
	      hints: hints] autorelease];
}


+ (EOFetchSpecification *)fetchSpecificationWithEntityName: (NSString *)name
                                                 qualifier: (EOQualifier *)qualifier
                                             sortOrderings: (NSArray *)sortOrderings
                                              usesDistinct: (BOOL)usesDistinct
{
    return [[[EOFetchSpecification alloc]
	      initWithEntityName: name
	      qualifier: qualifier
	      sortOrderings: sortOrderings
	      usesDistinct: usesDistinct
	      isDeep: YES
	      hints: nil] autorelease];
}

- (id) copyWithZone: (NSZone *)zone
{
  EOFetchSpecification *ret = [EOFetchSpecification allocWithZone:zone];
//order: hints, isdeep, usesDistinct,sortOrderings, qualifier,entityName
//and call nitWithEntityName:qualifier:sortOrderings:usesDistinct:isDeep:hints: 
//after:
/*   [fetch setLocksObjects:[_fetchSpecification locksObjects]];
  [fetch setRefreshesRefetchedObjects:[_fetchSpecification refreshesRefetchedObjects]];
  [fetch setPrefetchingRelationshipKeyPaths:[_fetchSpecification prefetchingRelationshipKeyPaths
  [fetch setRawRowKeyPaths:[_fetchSpecification rawRowKeyPaths
setFetchLimit:fetchLimit
setPromptsAfterFetchLimit: promptsAfterFetchLimit
setRequiresAllQualifierBindingVariables:requiresAllQualifierBindingVariables
*/
  //call setXX fn instead to have "willChange" ??
  ret->_qualifier = [(id <NSCopying>)_qualifier copyWithZone: zone];
  ret->_sortOrderings = [_sortOrderings copyWithZone: zone]; //mirko: ASSIGN(ret->_sortOrderings, _sortOrderings);
  ret->_entityName = [_entityName copyWithZone: zone];
  ret->_hints = [_hints copyWithZone: zone]; 
  ret->_prefetchingRelationshipKeys = [_prefetchingRelationshipKeys copyWithZone: zone];
  ret->_rawAttributeKeys = [_rawAttributeKeys copyWithZone: zone];
  ret->_fetchLimit = _fetchLimit;
  ret->_flags = _flags;

  return ret;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeObject: _qualifier];
  [coder encodeObject: _sortOrderings];
  [coder encodeObject: _entityName];
  [coder encodeObject: _hints];
  [coder encodeValueOfObjCType: @encode(unsigned int) at: &_fetchLimit];
  [coder encodeObject: _prefetchingRelationshipKeys];
  [coder encodeObject: _rawAttributeKeys];
  [coder encodeValueOfObjCType: @encode(unsigned int) at: &_flags];
}

- (id)initWithCoder: (NSCoder *)coder
{
  _qualifier = [[coder decodeObject] retain];
  _sortOrderings = [[coder decodeObject] retain];
  _entityName = [[coder decodeObject] retain];
  _hints = [[coder decodeObject] retain];
  [coder decodeValueOfObjCType: @encode(unsigned int) at: &_fetchLimit];
  _prefetchingRelationshipKeys = [[coder decodeObject] retain];
  _rawAttributeKeys = [[coder decodeObject] retain];
  [coder decodeValueOfObjCType: @encode(unsigned int) at: &_flags];

  return self;
}

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver*)unarchiver
{
  if ((self = [self init]))
    {
      ASSIGN(_hints, [unarchiver decodeObjectForKey: @"hints"]);
      ASSIGN(_qualifier, [unarchiver decodeObjectForKey: @"qualifier"]);
      ASSIGN(_sortOrderings, [unarchiver decodeObjectForKey: @"sortOrderings"]);
      ASSIGN(_entityName, [unarchiver decodeObjectForKey: @"entityName"]);
      ASSIGN(_prefetchingRelationshipKeys,
             [unarchiver decodeObjectForKey: @"prefetchingRelationshipKeyPaths"]);
      ASSIGN(_rawAttributeKeys, [unarchiver decodeObjectForKey: @"rawRowKeyPaths"]);

      _fetchLimit = [unarchiver decodeIntForKey: @"fetchLimit"];
      _flags.usesDistinct = [unarchiver decodeBoolForKey: @"usesDistinct"];
      _flags.isDeep = [unarchiver decodeBoolForKey: @"isDeep"];
      _flags.locksObjects = [unarchiver decodeBoolForKey: @"locksObjects"];
      _flags.refreshesRefetchedObjects = 
        [unarchiver decodeBoolForKey: @"refreshesRefetchedObjects"];
      _flags.promptsAfterFetchLimit = 
        [unarchiver decodeBoolForKey: @"promptsAfterFetchLimit"];
      _flags.requiresAllQualifierBindingVariables = 
        [unarchiver decodeBoolForKey: @"requiresAllQualifierBindingVariables"];
    }

  return self;
}

- (void) encodeWithKeyValueArchiver: (EOKeyValueArchiver*)archiver
{
  [archiver encodeObject:_hints
            forKey:@"hints"];
  [archiver encodeObject:_qualifier
            forKey:@"qualifier"];
  [archiver encodeObject:_sortOrderings
            forKey:@"sortOrderings"];
  [archiver encodeObject:_entityName
            forKey:@"entityName"];
  [archiver encodeObject:_sortOrderings
            forKey:@"sortOrderings"];
  [archiver encodeObject:_prefetchingRelationshipKeys
            forKey:@"prefetchingRelationshipKeyPaths"];
  [archiver encodeInt:_fetchLimit
            forKey:@"fetchLimit"];
  [archiver encodeBool:_flags.usesDistinct ? YES : NO
            forKey:@"usesDistinct"];
  [archiver encodeBool:_flags.isDeep ? YES : NO
            forKey:@"isDeep"];
  [archiver encodeBool:_flags.locksObjects ? YES : NO
            forKey:@"locksObjects"];
  [archiver encodeBool:_flags.refreshesRefetchedObjects ? YES : NO
            forKey:@"refreshesRefetchedObjects"];
  [archiver encodeBool:_flags.promptsAfterFetchLimit ? YES : NO
            forKey:@"promptsAfterFetchLimit"];
  [archiver encodeBool:_flags.refreshesRefetchedObjects ? YES : NO
            forKey:@"refreshesRefetchedObjects"];
  [archiver encodeBool:_flags.promptsAfterFetchLimit ? YES : NO
            forKey:@"promptsAfterFetchLimit"];
  [archiver encodeBool:_flags.requiresAllQualifierBindingVariables ? YES : NO
            forKey:@"requiresAllQualifierBindingVariables"];
}

- (NSString*)description
{
  NSMutableString *desc = [NSMutableString string];
  
  [desc appendString: @"{\n"];
  [desc appendString: [NSString stringWithFormat: @"hints = %@;\n", 
				[_hints description]]];
  [desc appendString: [NSString stringWithFormat: @"qualifier = %@;\n",
				_qualifier]];
  [desc appendString: [NSString stringWithFormat: @"sortOrderings = %@;\n",
				[_sortOrderings description]]];
  [desc appendString: [NSString stringWithFormat: @"entityName = %@;\n", 
				_entityName]];
  [desc appendString: [NSString stringWithFormat: @"prefetchingRelationshipKeyPaths = %@;\n", 
				[_prefetchingRelationshipKeys description]]];
  [desc appendString: [NSString stringWithFormat: @"rawRowKeyPaths = %@;\n", 
				[_rawAttributeKeys description]]];
  [desc appendString: [NSString stringWithFormat: @"fetchLimit = %d;\n", 
				_fetchLimit]];
  [desc appendString: [NSString stringWithFormat: @"usesDistinct = %s;\n", 
				_flags.usesDistinct ? "YES" : "NO"]];
  [desc appendString: [NSString stringWithFormat: @"isDeep = %s;\n", 
				_flags.isDeep ? "YES" : "NO"]];
  [desc appendString: [NSString stringWithFormat: @"locksObjects = %s;\n", 
				_flags.locksObjects ? "YES" : "NO"]];
  [desc appendString: [NSString stringWithFormat: @"refreshesRefetchedObjects = %s;\n", 
				_flags.refreshesRefetchedObjects ? "YES" : "NO"]];
  [desc appendString: [NSString stringWithFormat: @"promptsAfterFetchLimit = %s;\n", 
				_flags.promptsAfterFetchLimit ? "YES" : "NO"]];
  [desc appendString: [NSString stringWithFormat: @"requiresAllQualifierBindingVariables = %s;\n", 
				_flags.requiresAllQualifierBindingVariables ? "YES" : "NO"]];
  [desc appendString: @"}"];

  return desc;
}

- (void)setEntityName: (NSString *)entityName
{
  [self willChange];
  ASSIGN(_entityName, entityName);
}

- (NSString *)entityName
{
  return _entityName;
}

- (void)setSortOrderings: (NSArray *)sortOrderings
{
  ASSIGN(_sortOrderings, sortOrderings);
}

- (NSArray *)sortOrderings
{
  return _sortOrderings;
}

- (void)setQualifier: (EOQualifier *)qualifier
{
  [self willChange];
  ASSIGN(_qualifier, qualifier);
}

- (EOQualifier *)qualifier
{
  return _qualifier;
}

- (void)setUsesDistinct: (BOOL)flag
{
  [self willChange];
  _flags.usesDistinct = flag ? YES : NO;
}

- (BOOL)usesDistinct
{
  return _flags.usesDistinct;
}

- (void)setIsDeep: (BOOL)isDeep
{
  [self willChange];
  _flags.isDeep = isDeep ? YES : NO;
}

- (BOOL)isDeep
{
  return _flags.isDeep;
}

- (void)setLocksObjects: (BOOL)locksObjects
{
  [self willChange];  
  _flags.locksObjects = locksObjects ? YES : NO;
}

- (BOOL)locksObjects
{
  return _flags.locksObjects;
}

- (void)setRefreshesRefetchedObjects: (BOOL)refreshesRefetchedObjects
{
  [self willChange];  
  _flags.refreshesRefetchedObjects = refreshesRefetchedObjects ? YES : NO;
}

- (BOOL)refreshesRefetchedObjects
{
  return _flags.refreshesRefetchedObjects;
}

- (void)setFetchLimit: (unsigned)fetchLimit
{
  [self willChange];  
  _fetchLimit = fetchLimit;
}

- (unsigned)fetchLimit
{
  return _fetchLimit;
}

- (void)setPromptsAfterFetchLimit: (BOOL)promptsAfterFetchLimit
{
  [self willChange];  
  _flags.promptsAfterFetchLimit = promptsAfterFetchLimit ? YES : NO;
}

- (BOOL)promptsAfterFetchLimit
{
  return _flags.promptsAfterFetchLimit;
}

- (void)setRequiresAllQualifierBindingVariables: (BOOL)flag
{
  _flags.requiresAllQualifierBindingVariables = flag ? YES : NO;
}

- (BOOL)requiresAllQualifierBindingVariables
{
  return _flags.requiresAllQualifierBindingVariables;
}

- (void)setPrefetchingRelationshipKeyPaths: (NSArray *)prefetchingRelationshipKeys
{
  [self willChange];  
  ASSIGN(_prefetchingRelationshipKeys, prefetchingRelationshipKeys);
}

- (NSArray *)prefetchingRelationshipKeyPaths
{
  return _prefetchingRelationshipKeys;
}

- (void)setRawAttributeKeys: (NSArray *)rawAttributeKeys
{
  ASSIGN(_rawAttributeKeys, rawAttributeKeys);
}

- (NSArray *)rawAttributeKeys
{
  return _rawAttributeKeys;
}

- (void)setFetchesRawRows: (BOOL)fetchRawRows
{
  if (fetchRawRows)
    [self setRawRowKeyPaths: [NSArray array]];
  else
    [self setRawRowKeyPaths: nil];
}

- (BOOL)fetchesRawRows
{
  if ([self rawRowKeyPaths])
     return YES;
  else
    return NO;
}

- (void)setHints: (NSDictionary *)hints
{
  //TODO: set fetchLimit,... from hints ???
  [self willChange];
//even if nil: initWithDictionary:copyItems: 
//thedict objectForKey:EOPrefetchingRelationshipHintKey
//EOFetchLimitHintKey
//EOPromptAfterFetchLimitHintKey
  ASSIGN(_hints, hints);
}

- (NSDictionary *)_hints
{
  return _hints;
}

- (NSDictionary *)hints
{
  NSMutableDictionary *hints = (NSMutableDictionary *)_hints;
  BOOL promptsAfterFetchLimit;
  NSArray *prefetchingRelationshipKeyPaths;
  unsigned fetchLimit;

  fetchLimit = [self fetchLimit];
  promptsAfterFetchLimit = [self promptsAfterFetchLimit];
  prefetchingRelationshipKeyPaths = [self prefetchingRelationshipKeyPaths];
  
  if (fetchLimit != 0 || promptsAfterFetchLimit
      || [prefetchingRelationshipKeyPaths count] > 0)
    {
      NSMutableDictionary *mutableHints = [NSMutableDictionary
					    dictionaryWithDictionary: hints];

      hints = mutableHints;

      if (fetchLimit != 0)
        {
          [mutableHints setObject: [NSNumber numberWithInt: fetchLimit]
			forKey: EOFetchLimitHintKey];
        }

      if (promptsAfterFetchLimit)
        {
	  [mutableHints setObject: [NSNumber numberWithBool:
					       promptsAfterFetchLimit]
			forKey: EOPromptAfterFetchLimitHintKey];
        }

      if ([prefetchingRelationshipKeyPaths count] > 0)
        {
	  [mutableHints setObject: prefetchingRelationshipKeyPaths
			forKey: EOPrefetchingRelationshipHintKey];
        }
    }

  return hints;
}

- (NSArray *)rawRowKeyPaths
{
  return _rawAttributeKeys;
}

- (void)setRawRowKeyPaths: (NSArray *)rawRowKeyPaths
{
  [self willChange];  
  ASSIGN(_rawAttributeKeys, rawRowKeyPaths);
}

@end

@implementation EOFetchSpecification (deprecated)
- (BOOL)allVariablesRequiredFromBindings
{
  NSLog(@"DEPRECATED: Use requiresAllQualifierBindingVariables");
  return [self requiresAllQualifierBindingVariables];
}

- (void)setAllVariablesRequiredFromBindings: (BOOL)flag
{
  NSLog(@"DEPRECATED: Use setRequiresAllQualifierBindingVariables:");
  [self setRequiresAllQualifierBindingVariables: flag];
}

@end

