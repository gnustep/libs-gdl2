#ifndef __KVDataSource_H_
#define __KVDataSource_H_

/*
    KVDataSource.h
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Apr 2005

    This file is part of DBModeler.

    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/ 

#include <EOControl/EODataSource.h>

@interface KVDataSource : EODataSource <NSCoding>
{
  id _dataObject; 
  EOEditingContext *_context;
  EOClassDescription *_classDescription;
  NSString *_key; 
}

- (id) initWithClassDescription: (EOClassDescription *)classDescription
                 editingContext: (EOEditingContext *) context;
- (void) setDataObject: (id)object;
- (id) dataObject;
- (void) setKey:(NSString *)key;

/** result of [_dataObject -valueForKey:key] should be an array */
- (NSString *)key;

@end

#endif // __KVDataSource_H_
