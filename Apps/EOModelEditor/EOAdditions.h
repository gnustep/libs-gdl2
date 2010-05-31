#ifndef __EOAdditions_H_
#define __EOAdditions_H_

/*
    EOAdditions.h
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: Apr 2005

    This file is part of DBModeler.

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
*/ 

#include <EOAccess/EOAttribute.h>
/* these use NSNumbers because they are used in key value coding. */
@interface EOAttribute (ModelerAdditions)
- (NSNumber *) isPrimaryKey;
- (void) setIsPrimaryKey:(NSNumber *)flag;
- (NSNumber *) isClassProperty;
- (void) setIsClassProperty:(NSNumber *)flag;
@end

#endif // __EOAdditions_H_
