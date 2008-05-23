/**
    KVDataSource.m
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: Apr 2005

    This file is part of DBModeler.
    
    <license>
    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>

#include <EOControl/EOClassDescription.h>
#include <EOControl/EOEditingContext.h>

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#endif

#include "KVDataSource.h"

#include <GNUstepBase/GNUstep.h>

@implementation KVDataSource

- (id) initWithClassDescription: (EOClassDescription *)classDescription
                 editingContext: (EOEditingContext *)context
{
   if ((self = [super init]))
     {
       _classDescription = RETAIN(classDescription);
       _context = RETAIN(context);
       _dataObject = nil;
       _key = nil;
     }
   return self;
}

- (void) dealloc
{
  DESTROY(_classDescription);
  DESTROY(_context);
  DESTROY(_dataObject);
  DESTROY(_key);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)encoder
{

}

- (id) initWithCoder: (NSCoder *)decoder
{
return self;
}
- (id) createObject
{
/*  id object;
  EOEditingContext *edCtxt;

  if ([_key isEqual:@"entities"])
    object = [EOEntity new];
  if ([_key isEqual:@"attributes"])
    object = [EOAttribute new];
  
  if (object && (edCtxt = [self editingContext]))
    [edCtxt insertObject:object];

  return AUTORELEASE(object);
*/ 
  [[NSException exceptionWithName:NSInternalInconsistencyException
                           reason: [NSString stringWithFormat:@"%@ not supported by %@", NSStringFromSelector(_cmd), NSStringFromClass([self class])]
                        userInfo:nil] raise];
  return nil;
}
- (void) insertObject:(id)object
{
/* 
 if ([object isKindOfClass:[EOEntity class]])
   {
     [_dataObject addEntity:object];
   }
 else if ([object isKindOfClass:[EOAttribute class]])
   {
     [_dataObject addAttribute:object];
   } 
*/
  [[NSException exceptionWithName:NSInternalInconsistencyException
                           reason: [NSString stringWithFormat:@"%@ not supported by %@", NSStringFromSelector(_cmd), NSStringFromClass([self class])]
                        userInfo:nil] raise];
}

- (void) deleteObject:(id)object
{
  // TODO
}

- (NSArray *)fetchObjects
{
  return [_dataObject valueForKey:_key];
}

- (EOEditingContext *)editingContext
{
  return _context;
}

- (void) qualifyWithRelationshipKey:(NSString *)key ofObject:(id) sourceObject
{
  // FIXME 
}

- (EODataSource *) dataSourceQualifiedByKey: (NSString *)key
{
  // FIXME
  return nil;
}

- (EOClassDescription *)classDescriptionForObjects
{
  return _classDescription;
}

- (NSArray *)qualifierBindingKeys
{
  // FIXME
  return nil;
}

- (void) setQualifierBindings:(NSDictionary *)bindings
{

}

- (NSDictionary *)qualifierBindings
{
  return nil;
}

- (void) setDataObject:(id)object
{
  ASSIGN(_dataObject,object);
}

- (id) dataObject
{
  return _dataObject;
}

- (void) setKey:(NSString *)key
{
  ASSIGN(_key,key);
}

- (NSString *) key
{
  return _key;
}
@end

