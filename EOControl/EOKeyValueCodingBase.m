/** 
   EOKeyValueCodingBase.m

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: November 1996

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

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSException.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>

#include <objc/objc-api.h>

#if !FOUNDATION_HAS_KVC

#import <EOControl/EOControl.h>
#import <EOControl/EOKeyValueCoding.h>


/*
 *  EOKeyValueCoding implementation
 */

NSString *EOUnknownKeyException = @"EOUnknownKeyException";
NSString *EOTargetObjectUserInfoKey = @"EOTargetObjectUserInfoKey";
NSString *EOUnknownUserInfoKey = @"EOUnknownUserInfoKey";

@implementation NSObject (EOKVCPAdditions)

/*
 *  Accessor functions
 */

/* ACCESS to keys of id type. */

static id idMethodGetFunc(void *info1, void *info2, id self)
{
  id (*fptr)(id, SEL) = (id(*)(id, SEL))info1;
  id val = fptr(self, (SEL)info2);

  return val;
}

static id idIvarGetFunc(void *info1, void *info2, id self)
{
  id *ptr = (id*)((char*)self + (int)info2);

  return *ptr;
}

static void idMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, id) = (void(*)(id, SEL, id))info1;

  fptr(self, (SEL)info2, val);
}

static void idIvarSetFunc(void *info1, void *info2, id self, id val)
{
  id *ptr = (id*)((char*)self + (int)info2);

  [*ptr autorelease];
  *ptr = [val retain];
}

/* ACCESS to keys of char type. */

static id charMethodGetFunc(void *info1, void *info2, id self)
{
  char (*fptr)(id, SEL) = (char(*)(id, SEL))info1;
  char val = fptr(self, (SEL)info2);

  return [NSNumber numberWithChar: val];
}

static id charIvarGetFunc(void *info1, void *info2, id self)
{
  char *ptr = (char*)((char*)self + (int)info2);

  return [NSNumber numberWithChar: *ptr];
}

static void charMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, char) = (void(*)(id, SEL, char))info1;

  fptr(self, (SEL)info2, [val charValue]);
}

static void charIvarSetFunc(void *info1, void *info2, id self, id val)
{
  char *ptr = (char*)((char*)self + (int)info2);

  *ptr = [val charValue];
}


/* ACCESS to keys of unsigned char type. */

static id unsignedCharMethodGetFunc(void *info1, void *info2, id self)
{
  unsigned char (*fptr)(id, SEL) = (unsigned char(*)(id, SEL))info1;
  unsigned char val = fptr(self, (SEL)info2);

  return [NSNumber numberWithUnsignedChar: val];
}

static id unsignedCharIvarGetFunc(void *info1, void *info2, id self)
{
  unsigned char *ptr = (unsigned char*)((char*)self + (int)info2);

  return [NSNumber numberWithUnsignedChar: *ptr];
}

static void unsignedCharMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, unsigned char) = (void(*)(id, SEL, unsigned char))info1;

  fptr(self, (SEL)info2, [val unsignedCharValue]);
}

static void unsignedCharIvarSetFunc(void *info1, void *info2, id self, id val)
{
  unsigned char *ptr = (unsigned char*)((char*)self + (int)info2);

  *ptr = [val unsignedCharValue];
}


/* ACCESS to keys of short type. */

static id shortMethodGetFunc(void *info1, void *info2, id self)
{
  short (*fptr)(id, SEL) = (short(*)(id, SEL))info1;
  short val = fptr(self, (SEL)info2);

  return [NSNumber numberWithShort: val];
}

static id shortIvarGetFunc(void *info1, void *info2, id self)
{
  short *ptr = (short*)((char*)self + (int)info2);

  return [NSNumber numberWithShort: *ptr];
}

static void shortMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, short) = (void(*)(id, SEL, short))info1;

  fptr(self, (SEL)info2, [val shortValue]);
}

static void shortIvarSetFunc(void *info1, void *info2, id self, id val)
{
  short* ptr = (short*)((char*)self + (int)info2);

  *ptr = [val shortValue];
}


/* ACCESS to keys of unsigned short type. */

static id unsignedShortMethodGetFunc(void *info1, void *info2, id self)
{
  unsigned short (*fptr)(id, SEL) = (unsigned short(*)(id, SEL))info1;
  unsigned short val = fptr(self, (SEL)info2);

  return [NSNumber numberWithUnsignedShort: val];
}

static id unsignedShortIvarGetFunc(void *info1, void *info2, id self)
{
  unsigned short *ptr = (unsigned short*)((char*)self + (int)info2);

  return [NSNumber numberWithUnsignedShort: *ptr];
}

static void unsignedShortMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, unsigned short) = (void(*)(id, SEL, unsigned short))info1;

  fptr(self, (SEL)info2, [val unsignedShortValue]);
}

static void unsignedShortIvarSetFunc(void *info1, void *info2, id self, id val)
{
  unsigned short *ptr = (unsigned short*)((char*)self + (int)info2);

  *ptr = [val unsignedShortValue];
}


/* ACCESS to keys of int type. */

static id intMethodGetFunc(void *info1, void *info2, id self)
{
  int (*fptr)(id, SEL) = (int(*)(id, SEL))info1;
  int val = fptr(self, (SEL)info2);

  return [NSNumber numberWithInt: val];
}

static id intIvarGetFunc(void *info1, void *info2, id self)
{
  int *ptr = (int*)((char*)self + (int)info2);

  return [NSNumber numberWithInt: *ptr];
}

static void intMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, int) = (void(*)(id, SEL, int))info1;

  fptr(self, (SEL)info2, [val intValue]);
}

static void intIvarSetFunc(void *info1, void *info2, id self, id val)
{
  int *ptr = (int*)((char*)self + (int)info2);

  *ptr = [val intValue];
}


/* ACCESS to keys of unsigned int type. */

static id unsignedIntMethodGetFunc(void *info1, void *info2, id self)
{
  unsigned int (*fptr)(id, SEL) = (unsigned int(*)(id, SEL))info1;
  unsigned int val = fptr(self, (SEL)info2);

  return [NSNumber numberWithUnsignedInt: val];
}

static id unsignedIntIvarGetFunc(void *info1, void *info2, id self)
{
  unsigned int *ptr = (unsigned int*)((char*)self + (int)info2);

  return [NSNumber numberWithUnsignedInt: *ptr];
}

static void unsignedIntMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, unsigned int) = (void(*)(id, SEL, unsigned int))info1;

  fptr(self, (SEL)info2, [val unsignedIntValue]);
}

static void unsignedIntIvarSetFunc(void *info1, void *info2, id self, id val)
{
  unsigned int* ptr = (unsigned int*)((char*)self + (int)info2);

  *ptr = [val unsignedIntValue];
}


/* ACCESS to keys of long type. */

static id longMethodGetFunc(void *info1, void *info2, id self)
{
  long (*fptr)(id, SEL) = (long(*)(id, SEL))info1;
  long val = fptr(self, (SEL)info2);

  return [NSNumber numberWithLong: val];
}

static id longIvarGetFunc(void *info1, void *info2, id self)
{
  long *ptr = (long*)((char*)self + (int)info2);

  return [NSNumber numberWithLong: *ptr];
}

static void longMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, long) = (void(*)(id, SEL, long))info1;

  fptr(self, (SEL)info2, [val longValue]);
}

static void longIvarSetFunc(void *info1, void *info2, id self, id val)
{
  long *ptr = (long*)((char*)self + (int)info2);

  *ptr = [val longValue];
}


/* ACCESS to keys of unsigned long type. */

static id unsignedLongMethodGetFunc(void *info1, void *info2, id self)
{
  unsigned long (*fptr)(id, SEL) = (unsigned long(*)(id, SEL))info1;
  unsigned long val = fptr(self, (SEL)info2);

  return [NSNumber numberWithUnsignedLong: val];
}

static id unsignedLongIvarGetFunc(void *info1, void *info2, id self)
{
  unsigned long *ptr = (unsigned long*)((char*)self + (int)info2);

  return [NSNumber numberWithUnsignedLong: *ptr];
}

static void unsignedLongMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, unsigned long) = (void(*)(id, SEL, unsigned long))info1;

  fptr(self, (SEL)info2, [val unsignedLongValue]);
}

static void unsignedLongIvarSetFunc(void *info1, void *info2, id self, id val)
{
  unsigned long *ptr = (unsigned long*)((char*)self + (int)info2);

  *ptr = [val unsignedLongValue];
}


/* ACCESS to keys of long long type. */

static id longLongMethodGetFunc(void *info1, void *info2, id self)
{
  long long (*fptr)(id, SEL) = (long long(*)(id, SEL))info1;
  long long val = fptr(self, (SEL)info2);

  return [NSNumber numberWithLongLong: val];
}

static id longLongIvarGetFunc(void *info1, void *info2, id self)
{
  long long *ptr = (long long*)((char*)self + (int)info2);

  return [NSNumber numberWithLongLong: *ptr];
}

static void longLongMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, long long) = (void(*)(id, SEL, long long))info1;

  fptr(self, (SEL)info2, [val longLongValue]);
}

static void longLongIvarSetFunc(void *info1, void *info2, id self, id val)
{
  long long *ptr = (long long*)((char*)self + (int)info2);

  *ptr = [val longLongValue];
}


/* ACCESS to keys of unsigned long long type. */

static id unsignedLongLongMethodGetFunc(void *info1, void *info2, id self)
{
  unsigned long long (*fptr)(id, SEL) = (unsigned long long(*)(id, SEL))info1;
  unsigned long long val = fptr(self, (SEL)info2);

  return [NSNumber numberWithUnsignedLongLong: val];
}

static id unsignedLongLongIvarGetFunc(void *info1, void *info2, id self)
{
  unsigned long long *ptr = (unsigned long long*)((char*)self + (int)info2);

  return [NSNumber numberWithUnsignedLongLong: *ptr];
}

static void unsignedLongLongMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, unsigned long long) = (void(*)(id, SEL, unsigned long long))info1;

  fptr(self, (SEL)info2, [val unsignedLongLongValue]);
}

static void unsignedLongLongIvarSetFunc(void *info1, void *info2, id self, id val)
{
  unsigned long long *ptr = (unsigned long long*)((char*)self + (int)info2);

  *ptr = [val unsignedLongLongValue];
}


/* ACCESS to keys of float type. */

static id floatMethodGetFunc(void *info1, void *info2, id self)
{
  float (*fptr)(id, SEL) = (float(*)(id, SEL))info1;
  float val = fptr(self, (SEL)info2);

  return [NSNumber numberWithFloat: val];
}

static id floatIvarGetFunc(void *info1, void *info2, id self)
{
  float *ptr = (float*)((char*)self + (int)info2);

  return [NSNumber numberWithFloat: *ptr];
}

static void floatMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, float) = (void(*)(id, SEL, float))info1;

  fptr(self, (SEL)info2, [val floatValue]);
}

static void floatIvarSetFunc(void *info1, void *info2, id self, id val)
{
  float *ptr = (float*)((char*)self + (int)info2);

  *ptr = [val floatValue];
}


/* ACCESS to keys of double type. */

static id doubleMethodGetFunc(void *info1, void *info2, id self)
{
  double (*fptr)(id, SEL) = (double(*)(id, SEL))info1;
  double val = fptr(self, (SEL)info2);

  return [NSNumber numberWithDouble: val];
}

static id doubleIvarGetFunc(void *info1, void *info2, id self)
{
  double *ptr = (double*)((char*)self + (int)info2);

  return [NSNumber numberWithDouble: *ptr];
}

static void doubleMethodSetFunc(void *info1, void *info2, id self, id val)
{
  void (*fptr)(id, SEL, double) = (void(*)(id, SEL, double))info1;

  fptr(self, (SEL)info2, [val doubleValue]);
}

static void doubleIvarSetFunc(void *info1, void *info2, id self, id val)
{
  double *ptr = (double*)((char*)self + (int)info2);

  *ptr = [val doubleValue];
}

/*
 *  Types
 */

typedef struct _KeyValueMethod
{
  NSString *key;
  Class	class;
} KeyValueMethod;

typedef struct _GetKeyValueBinding
{
  id (*access)(void*, void*, id);
  void *info1;
  void *info2;
} GetKeyValueBinding;

typedef struct _SetKeyValueBinding
{
  void (*access)(void*, void*, id, id);
  void *info1;
  void *info2;
} SetKeyValueBinding;

/*
 * Globals
 */

static NSMapTable *getValueBindings = NULL;
static NSMapTable *setValueBindings = NULL;
static NSMapTable *getStoredValueBindings = NULL;
static NSMapTable *setStoredValueBindings = NULL;
static BOOL keyValueDebug = NO;
static BOOL keyValueInit  = NO;

/*
 *  KeyValueMapping
 */

static GetKeyValueBinding *newGetBinding(NSString *key, id instance)
{
  GetKeyValueBinding *ret = NULL;
  void *info1 = NULL;
  void *info2 = NULL;
  BOOL accessInstanceVariables;
  id (*fptr)(void*, void*, id) = NULL;
  int count;

  Class class = [instance class];
  MetaClass mclass = class_get_meta_class(class);
  const char *ckey = [key cString];
  char iname[strlen(ckey) + 4];
  SEL sel;
  struct objc_method *mth;

  accessInstanceVariables = [NSObject accessInstanceVariablesDirectly];

  // Lookup method name [- (type)key]
  // Lookup method name [- (type)getKey]
  count = 2;

  while (!fptr && count--)
    {
      if (count == 1)
	{
	  strcpy(iname, ckey);
	}
      else
	{
	  strcpy(iname, "get");
	  strcat(iname, ckey);
	  iname[3] = islower(iname[3]) ? toupper(iname[3]) : iname[3];
	}

      sel = sel_get_any_uid(iname);

      if (sel && ((mth = class_get_instance_method(class, sel))
		  || (mth = class_get_class_method(mclass, sel)))
	  && method_get_number_of_arguments(mth) == 2)
	{
	  switch (*objc_skip_type_qualifiers(mth->method_types))
	    {
	    case _C_CLASS:
	      fptr = (id (*)(void*, void*, id))idMethodGetFunc;
	      break;
	    case _C_ID:
	      fptr = (id (*)(void*, void*, id))idMethodGetFunc;
	      break;
	    case _C_CHR:
	      fptr = (id (*)(void*, void*, id))charMethodGetFunc;
	      break;
	    case _C_UCHR:
	      fptr = (id (*)(void*, void*, id))unsignedCharMethodGetFunc;
	      break;
	    case _C_SHT:
	      fptr = (id (*)(void*, void*, id))shortMethodGetFunc;
	      break;
	    case _C_USHT:
	      fptr = (id (*)(void*, void*, id))unsignedShortMethodGetFunc;
	      break;
	    case _C_INT:
	      fptr = (id (*)(void*, void*, id))intMethodGetFunc;
	      break;
	    case _C_UINT:
	      fptr = (id (*)(void*, void*, id))unsignedIntMethodGetFunc;
	      break;
	    case _C_LNG:
	      fptr = (id (*)(void*, void*, id))longMethodGetFunc;
	      break;
	    case _C_ULNG:
	      fptr = (id (*)(void*, void*, id))unsignedLongMethodGetFunc;
	      break;
	    case 'q':
	      fptr = (id (*)(void*, void*, id))longLongMethodGetFunc;
	      break;
	    case 'Q':
	      fptr = (id (*)(void*, void*, id))unsignedLongLongMethodGetFunc;
	      break;
	    case _C_FLT:
	      fptr = (id (*)(void*, void*, id))floatMethodGetFunc;
	      break;
	    case _C_DBL:
	      fptr = (id (*)(void*, void*, id))doubleMethodGetFunc;
	      break;
	    }

	  if (fptr)
	    {
	      info1 = (void*)(mth->method_imp);
	      info2 = (void*)(mth->method_name);
	    }
	}
    }

//  NSDebugFLog(@"accessInstanceVariables=%d",accessInstanceVariables);
  // Lookup ivar name

  if (!fptr && accessInstanceVariables == YES)
    {
      int keyType=0;

      for (keyType = 0; !fptr && keyType < 2; keyType++)
	{
	  const char *testKey = ckey;
	  char *testKeyDup = NULL;

	  if (keyType==1)
	    {
	      int len=strlen(testKey);

	      testKeyDup = malloc(len + 2);

	      testKeyDup[0] = '_';
	      strcpy(testKeyDup + 1,testKey);

	      testKey = testKeyDup;
	    }

	  class = [instance class];
	  //        NSDebugFLog(@"testKey=%s",testKey);

	  while (!fptr && class)
	    {
	      int i;

	      //          NSDebugFLog(@"class=%@",NSStringFromClass(class));
	      for (i = 0;!fptr &&  class->ivars && i < class->ivars->ivar_count; i++)
		{
		  if (!strcmp(testKey, class->ivars->ivar_list[i].ivar_name))
		    {
		      //              NSDebugFLog(@"Found");    
		      switch (*objc_skip_type_qualifiers(class->ivars->ivar_list[i].ivar_type))
			{
			case _C_ID:
			  fptr = (id (*)(void*, void*, id))idIvarGetFunc;
			  break;
			case _C_CHR:
			  fptr = (id (*)(void*, void*, id))charIvarGetFunc;
			  break;
			case _C_UCHR:
			  fptr = (id (*)(void*, void*, id))unsignedCharIvarGetFunc;
			  break;
			case _C_SHT:
			  fptr = (id (*)(void*, void*, id))shortIvarGetFunc;
			  break;
			case _C_USHT:
			  fptr = (id (*)(void*, void*, id))unsignedShortIvarGetFunc;
			  break;
			case _C_INT:
			  fptr = (id (*)(void*, void*, id))intIvarGetFunc;
			  break;
			case _C_UINT:
			  fptr = (id (*)(void*, void*, id))unsignedIntIvarGetFunc;
			  break;
			case _C_LNG:
			  fptr = (id (*)(void*, void*, id))longIvarGetFunc;
			  break;
			case _C_ULNG:
			  fptr = (id (*)(void*, void*, id))unsignedLongIvarGetFunc;
			  break;
			case 'q':
			  fptr = (id (*)(void*, void*, id))longLongIvarGetFunc;
			  break;
			case 'Q':
			  fptr = (id (*)(void*, void*, id))unsignedLongLongIvarGetFunc;
			  break;
			case _C_FLT:
			  fptr = (id (*)(void*, void*, id))floatIvarGetFunc;
			  break;
			case _C_DBL:
			  fptr = (id (*)(void*, void*, id))doubleIvarGetFunc;
			  break;
			}

		      if (fptr)
			{
			  info2 = (void*)(class->ivars->ivar_list[i].ivar_offset);
			}
		    }
		}

	      class = class->super_class;
	    }

	  if (testKeyDup)
	    {
	      free(testKeyDup);
	      testKeyDup=NULL;
	    }
	}
    }

//  NSDebugFLog(@"fptr=%p",fptr);    
  
  // Make binding and insert into map

  if (fptr)
    {
      KeyValueMethod* mkey = NSZoneMalloc(NSDefaultMallocZone(), sizeof(KeyValueMethod));
      GetKeyValueBinding* bin = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GetKeyValueBinding));

      mkey->key = [key copy];
      mkey->class = [instance class];

      bin->access = fptr;
      bin->info1 = info1;
      bin->info2 = info2;

      NSMapInsert(getValueBindings, mkey, bin);
      ret = bin;
    }
  
  // If no way to access value warn
  if (!ret && keyValueDebug)
    NSLog(@"cannnot get key `%@' for instance of class `%@'",
	  key, NSStringFromClass([instance class]));

  return ret;
}

static GetKeyValueBinding *newGetStoredBinding(NSString *key, id instance)
{
  GetKeyValueBinding *ret = NULL;
  void *info1 = NULL;
  void *info2 = NULL;
  BOOL accessInstanceVariables;
  id (*fptr)(void*, void*, id) = NULL;
  int count;

  Class class = [instance class];
  MetaClass mclass = class_get_meta_class(class);
  const char *ckey = [key cString];
  char iname[strlen(ckey) + 5];
  SEL sel;
  struct objc_method *mth;

  accessInstanceVariables = [NSObject accessInstanceVariablesDirectly];

  // Lookup method name [- (type)_key]
  // Lookup method name [- (type)_getKey]
  count = 2;

  while (!fptr && count--)
    {
      if(count == 1)
	{
	  strcpy(iname, "_");
	  strcat(iname, ckey);
	}
      else
	{
	  strcpy(iname, "_get");
	  strcat(iname, ckey);
	  iname[4] = islower(iname[4]) ? toupper(iname[4]) : iname[4];
	}

      sel = sel_get_any_uid(iname);

      if (sel && ((mth = class_get_instance_method(class, sel))
		  || (mth = class_get_class_method(mclass, sel)))
	  && method_get_number_of_arguments(mth) == 2)
	{
	  switch (*objc_skip_type_qualifiers(mth->method_types))
	    {
	    case _C_CLASS:
	      fptr = (id (*)(void*, void*, id))idMethodGetFunc;
	      break;
	    case _C_ID:
	      fptr = (id (*)(void*, void*, id))idMethodGetFunc;
	      break;
	    case _C_CHR:
	      fptr = (id (*)(void*, void*, id))charMethodGetFunc;
	      break;
	    case _C_UCHR:
	      fptr = (id (*)(void*, void*, id))unsignedCharMethodGetFunc;
	      break;
	    case _C_SHT:
	      fptr = (id (*)(void*, void*, id))shortMethodGetFunc;
	      break;
	    case _C_USHT:
	      fptr = (id (*)(void*, void*, id))unsignedShortMethodGetFunc;
	      break;
	    case _C_INT:
	      fptr = (id (*)(void*, void*, id))intMethodGetFunc;
	      break;
	    case _C_UINT:
	      fptr = (id (*)(void*, void*, id))unsignedIntMethodGetFunc;
	      break;
	    case _C_LNG:
	      fptr = (id (*)(void*, void*, id))longMethodGetFunc;
	      break;
	    case _C_ULNG:
	      fptr = (id (*)(void*, void*, id))unsignedLongMethodGetFunc;
	      break;
	    case 'q':
	      fptr = (id (*)(void*, void*, id))longLongMethodGetFunc;
	      break;
	    case 'Q':
	      fptr = (id (*)(void*, void*, id))unsignedLongLongMethodGetFunc;
	      break;
	    case _C_FLT:
	      fptr = (id (*)(void*, void*, id))floatMethodGetFunc;
	      break;
	    case _C_DBL:
	      fptr = (id (*)(void*, void*, id))doubleMethodGetFunc;
	      break;
	    }

	  if (fptr)
	    {
	      info1 = (void*)(mth->method_imp);
	      info2 = (void*)(mth->method_name);
	    }
	}
    }
  
  // Lookup ivar name
  count = 2;

  while (!fptr && count-- && accessInstanceVariables == YES)
    {
      int i;

      // Make ivar from name
      if(count == 1)
	{
	  strcpy(iname, "_");
	  strcat(iname, ckey);
	}
      else
	{
	  strcpy(iname, ckey);
	}

      while (class)
	{
	  for (i = 0; class->ivars && i < class->ivars->ivar_count; i++)
	    {
	      if (!strcmp(iname, class->ivars->ivar_list[i].ivar_name))
		{
		  switch (*objc_skip_type_qualifiers(class->ivars->ivar_list[i].ivar_type))
		    {
		    case _C_ID:
		      fptr = (id (*)(void*, void*, id))idIvarGetFunc;
		      break;
		    case _C_CHR:
		      fptr = (id (*)(void*, void*, id))charIvarGetFunc;
		      break;
		    case _C_UCHR:
		      fptr = (id (*)(void*, void*, id))unsignedCharIvarGetFunc;
		      break;
		    case _C_SHT:
		      fptr = (id (*)(void*, void*, id))shortIvarGetFunc;
		      break;
		    case _C_USHT:
		      fptr = (id (*)(void*, void*, id))unsignedShortIvarGetFunc;
		      break;
		    case _C_INT:
		      fptr = (id (*)(void*, void*, id))intIvarGetFunc;
		      break;
		    case _C_UINT:
		      fptr = (id (*)(void*, void*, id))unsignedIntIvarGetFunc;
		      break;
		    case _C_LNG:
		      fptr = (id (*)(void*, void*, id))longIvarGetFunc;
		      break;
		    case _C_ULNG:
		      fptr = (id (*)(void*, void*, id))unsignedLongIvarGetFunc;
		      break;
		    case 'q':
		      fptr = (id (*)(void*, void*, id))longLongIvarGetFunc;
		      break;
		    case 'Q':
		      fptr = (id (*)(void*, void*, id))unsignedLongLongIvarGetFunc;
		      break;
		    case _C_FLT:
		      fptr = (id (*)(void*, void*, id))floatIvarGetFunc;
		      break;
		    case _C_DBL:
		      fptr = (id (*)(void*, void*, id))doubleIvarGetFunc;
		      break;
		    }

		  if (fptr)
		    {
		      info2 = (void*)(class->ivars->ivar_list[i].ivar_offset);
		      break;
		    }
		}
	    }

	  class = class->super_class;
	}
    }

  // Lookup method name [- (type)key]
  // Lookup method name [- (type)getKey]
  count = 2;
  class = [instance class];

  while (!fptr && count--)
    {
      if (count == 1)
	{
	  strcpy(iname, ckey);
	}
      else
	{
	  strcpy(iname, "get");
	  strcat(iname, ckey);
	  iname[3] = islower(iname[3]) ? toupper(iname[3]) : iname[3];
	}

      sel = sel_get_any_uid(iname);

      if (sel && ((mth = class_get_instance_method(class, sel))
		  || (mth = class_get_class_method(mclass, sel)))
	  && method_get_number_of_arguments(mth) == 2)
	{
	  switch (*objc_skip_type_qualifiers(mth->method_types))
	    {
	    case _C_ID:
	      fptr = (id (*)(void*, void*, id))idMethodGetFunc;
	      break;
	    case _C_CHR:
	      fptr = (id (*)(void*, void*, id))charMethodGetFunc;
	      break;
	    case _C_UCHR:
	      fptr = (id (*)(void*, void*, id))unsignedCharMethodGetFunc;
	      break;
	    case _C_SHT:
	      fptr = (id (*)(void*, void*, id))shortMethodGetFunc;
	      break;
	    case _C_USHT:
	      fptr = (id (*)(void*, void*, id))unsignedShortMethodGetFunc;
	      break;
	    case _C_INT:
	      fptr = (id (*)(void*, void*, id))intMethodGetFunc;
	      break;
	    case _C_UINT:
	      fptr = (id (*)(void*, void*, id))unsignedIntMethodGetFunc;
	      break;
	    case _C_LNG:
	      fptr = (id (*)(void*, void*, id))longMethodGetFunc;
	      break;
	    case _C_ULNG:
	      fptr = (id (*)(void*, void*, id))unsignedLongMethodGetFunc;
	      break;
	    case 'q':
	      fptr = (id (*)(void*, void*, id))longLongMethodGetFunc;
	      break;
	    case 'Q':
	      fptr = (id (*)(void*, void*, id))unsignedLongLongMethodGetFunc;
	      break;
	    case _C_FLT:
	      fptr = (id (*)(void*, void*, id))floatMethodGetFunc;
	      break;
	    case _C_DBL:
	      fptr = (id (*)(void*, void*, id))doubleMethodGetFunc;
	      break;
	    }

	  if (fptr)
	    {
	      info1 = (void*)(mth->method_imp);
	      info2 = (void*)(mth->method_name);
	    }
	}
    }
  
  // Make binding and insert into map
  if (fptr)
    {
      KeyValueMethod* mkey = NSZoneMalloc(NSDefaultMallocZone(), sizeof(KeyValueMethod));
      GetKeyValueBinding* bin = NSZoneMalloc(NSDefaultMallocZone(), sizeof(GetKeyValueBinding));

      mkey->key = [key copy];
      mkey->class = [instance class];

      bin->access = fptr;
      bin->info1 = info1;
      bin->info2 = info2;

      NSMapInsert(getStoredValueBindings, mkey, bin);
      ret = bin;
    }

  // If no way to access value warn
  if (!ret && keyValueDebug)
    NSLog(@"cannnot get key `%@' for instance of class `%@'",
	  key, NSStringFromClass([instance class]));

  return ret;
}

static SetKeyValueBinding *newSetBinding(NSString *key, id instance, id value)
{
  SetKeyValueBinding *ret = NULL;
  void *info1 = NULL;
  void *info2 = NULL;
  void (*fptr)(void*, void*, id, id) = NULL;
  BOOL idMethod = NO;
  
  // Lookup method name [-(void)setKey:(type)arg]
  {
    Class class = [instance class];
    const char *ckey = [key cString];
    SEL sel;
    struct objc_method *mth;
    char sname[strlen(ckey)+7];

    // Make sel from name
    strcpy(sname, "set");
    strcat(sname, ckey);
    strcat(sname, ":");
    sname[3] = islower(sname[3]) ? toupper(sname[3]) : sname[3];

    sel = sel_get_any_uid(sname);

    if (sel && (mth = class_get_instance_method(class, sel))
	&& method_get_number_of_arguments(mth) == 3
	&& *objc_skip_type_qualifiers(mth->method_types) == _C_VOID)
      {
	char* argType = (char*)(mth->method_types);
      
	argType = (char*)objc_skip_argspec(argType);	// skip return
	argType = (char*)objc_skip_argspec(argType);	// skip self
	argType = (char*)objc_skip_argspec(argType);	// skip SEL
      
	switch (*objc_skip_type_qualifiers(argType))
	  {
	  case _C_ID:
	    fptr = (void (*)(void*, void*, id, id))idMethodSetFunc;
	    idMethod = YES;
	    break;
	  case _C_CHR:
	    fptr = (void (*)(void*, void*, id, id))charMethodSetFunc;
	    break;
	  case _C_UCHR:
	    fptr = (void (*)(void*, void*, id, id))unsignedCharMethodSetFunc;
	    break;
	  case _C_SHT:
	    fptr = (void (*)(void*, void*, id, id))shortMethodSetFunc;
	    break;
	  case _C_USHT:
	    fptr = (void (*)(void*, void*, id, id))unsignedShortMethodSetFunc;
	    break;
	  case _C_INT:
	    fptr = (void (*)(void*, void*, id, id))intMethodSetFunc;
	    break;
	  case _C_UINT:
	    fptr = (void (*)(void*, void*, id, id))unsignedIntMethodSetFunc;
	    break;
	  case _C_LNG:
	    fptr = (void (*)(void*, void*, id, id))longMethodSetFunc;
	    break;
	  case _C_ULNG:
	    fptr = (void (*)(void*, void*, id, id))unsignedLongMethodSetFunc;
	    break;
	  case 'q':
	    fptr = (void (*)(void*, void*, id, id))longLongMethodSetFunc;
	    break;
	  case 'Q':
	    fptr = (void (*)(void*, void*, id, id))unsignedLongLongMethodSetFunc;
	    break;
	  case _C_FLT:
	    fptr = (void (*)(void*, void*, id, id))floatMethodSetFunc;
	    break;
	  case _C_DBL:
	    fptr = (void (*)(void*, void*, id, id))doubleMethodSetFunc;
	    break;
	  }

	if (fptr)
	  {
	    info1 = (void*)(mth->method_imp);
	    info2 = (void*)(mth->method_name);
	  }
      }
  }
   
  // Lookup ivar name
//  NSDebugFLog(@"accessInstanceVariablesDirectly=%d",[NSObject accessInstanceVariablesDirectly]);

  if (!fptr && [NSObject accessInstanceVariablesDirectly])
    {
      const char *ckey = [key cString];
      int keyType=0;

      for (keyType = 0; !fptr && keyType < 2; keyType++)
	{
	  const char* testKey=ckey;
	  char* testKeyDup=NULL;
	  Class class = [instance class];

	  if (keyType==1)
	    {
	      int len=strlen(testKey);
	      testKeyDup=malloc(len+2);
	      testKeyDup[0]='_';
	      strcpy(testKeyDup+1,testKey);
	      testKey=testKeyDup;
	    }

	  //        NSDebugFLog(@"testKey=%s",testKey);    

	  while (!fptr && class)
	    {
	      int i;

	      //          NSDebugFLog(@"class=%@",NSStringFromClass(class));

	      for (i = 0;
		   !fptr && class->ivars && i < class->ivars->ivar_count;
		   i++)
		{
		  if (!strcmp(testKey, class->ivars->ivar_list[i].ivar_name))
		    {
		      //        NSDebugFLog(@"Found");    

		      switch (*objc_skip_type_qualifiers(class->ivars->ivar_list[i].ivar_type))
			{
			case _C_ID:
			  fptr = (void (*)(void*, void*, id, id))idIvarSetFunc;
			  idMethod = YES;
			  break;
			case _C_CHR:
			  fptr = (void (*)(void*, void*, id, id))charIvarSetFunc;
			  break;
			case _C_UCHR:
			  fptr = (void (*)(void*, void*, id, id))unsignedCharIvarSetFunc;
			  break;
			case _C_SHT:
			  fptr = (void (*)(void*, void*, id, id))shortIvarSetFunc;
			  break;
			case _C_USHT:
			  fptr = (void (*)(void*, void*, id, id))unsignedShortIvarSetFunc;
			  break;
			case _C_INT:
			  fptr = (void (*)(void*, void*, id, id))intIvarSetFunc;
			  break;
			case _C_UINT:
			  fptr = (void (*)(void*, void*, id, id))unsignedIntIvarSetFunc;
			  break;
			case _C_LNG:
			  fptr = (void (*)(void*, void*, id, id))longIvarSetFunc;
			  break;
			case _C_ULNG:
			  fptr = (void (*)(void*, void*, id, id))unsignedLongIvarSetFunc;
			  break;
			case 'q':
			  fptr = (void (*)(void*, void*, id, id))longLongIvarSetFunc;
			  break;
			case 'Q':
			  fptr = (void (*)(void*, void*, id, id))unsignedLongLongIvarSetFunc;
			  break;
			case _C_FLT:
			  fptr = (void (*)(void*, void*, id, id))floatIvarSetFunc;
			  break;
			case _C_DBL:
			  fptr = (void (*)(void*, void*, id, id))doubleIvarSetFunc;
			  break;
			}
		      if (fptr) {
			info2 = (void*)(class->ivars->ivar_list[i].ivar_offset);
		      }
		    }
		}
	      class = class->super_class;
	    }

	  if (testKeyDup)
	    {
	      free(testKeyDup);
	      testKeyDup = NULL;
	    }
	}
    }

//  NSDebugFLog(@"fptr=%p",fptr);    

  if (fptr && !idMethod && value == nil)
    return (SetKeyValueBinding *) - 1;

  // Make binding and insert into map

  if (fptr)
    {
      KeyValueMethod *mkey = NSZoneMalloc(NSDefaultMallocZone(), sizeof(KeyValueMethod));
      SetKeyValueBinding *bin = NSZoneMalloc(NSDefaultMallocZone(), sizeof(SetKeyValueBinding));

      mkey->key = [key copy];
      mkey->class = [instance class];

      bin->access = fptr;
      bin->info1 = info1;
      bin->info2 = info2;

      NSMapInsert(setValueBindings, mkey, bin);
      ret = bin;
    }
  // If no way to access value warn
  if (!ret && keyValueDebug)
    NSLog(@"cannnot set key `%@' for instance of class `%@'",
          key, NSStringFromClass([instance class]));
  
  return ret;
}

static SetKeyValueBinding *newSetStoredBinding(NSString *key, id instance, id value)
{
  SetKeyValueBinding *ret = NULL;
  void *info1 = NULL;
  void *info2 = NULL;
  void (*fptr)(void*, void*, id, id) = NULL;
  BOOL idMethod = NO;

  // Lookup ivar _name
  {
    Class class = [instance class];
    const char* ckey = [key cString];
    char  iname[strlen(ckey) + 2];
    int i;

    // Make ivar from name
    strcpy(iname, "_");
    strcat(iname, ckey);
    
    while (class)
      {
	for (i = 0; class->ivars && i < class->ivars->ivar_count; i++)
	  {
	    if (!strcmp(iname, class->ivars->ivar_list[i].ivar_name))
	      {
		switch (*objc_skip_type_qualifiers(class->ivars->ivar_list[i].ivar_type))
		  {
		  case _C_ID:
		    fptr = (void (*)(void*, void*, id, id))idIvarSetFunc;
		    idMethod = YES;
		    break;
		  case _C_CHR:
		    fptr = (void (*)(void*, void*, id, id))charIvarSetFunc;
		    break;
		  case _C_UCHR:
		    fptr = (void (*)(void*, void*, id, id))unsignedCharIvarSetFunc;
		    break;
		  case _C_SHT:
		    fptr = (void (*)(void*, void*, id, id))shortIvarSetFunc;
		    break;
		  case _C_USHT:
		    fptr = (void (*)(void*, void*, id, id))unsignedShortIvarSetFunc;
		    break;
		  case _C_INT:
		    fptr = (void (*)(void*, void*, id, id))intIvarSetFunc;
		    break;
		  case _C_UINT:
		    fptr = (void (*)(void*, void*, id, id))unsignedIntIvarSetFunc;
		    break;
		  case _C_LNG:
		    fptr = (void (*)(void*, void*, id, id))longIvarSetFunc;
		    break;
		  case _C_ULNG:
		    fptr = (void (*)(void*, void*, id, id))unsignedLongIvarSetFunc;
		    break;
		  case 'q':
		    fptr = (void (*)(void*, void*, id, id))longLongIvarSetFunc;
		    break;
		  case 'Q':
		    fptr = (void (*)(void*, void*, id, id))unsignedLongLongIvarSetFunc;
		    break;
		  case _C_FLT:
		    fptr = (void (*)(void*, void*, id, id))floatIvarSetFunc;
		    break;
		  case _C_DBL:
		    fptr = (void (*)(void*, void*, id, id))doubleIvarSetFunc;
		    break;
		  }

		if (fptr)
		  {
		    info2 = (void*)(class->ivars->ivar_list[i].ivar_offset);
		    break;
		  }
	      }
	  }

	class = class->super_class;
      }
  }

  // Lookup method name [-(void)_setKey:(type)arg]
  if (!fptr)
    {
      Class class = [instance class];
      const char* ckey = [key cString];
      SEL sel;
      struct objc_method* mth;
      char  sname[strlen(ckey) + 7];
      
      // Make sel from name
      strcpy(sname, "_set");
      strcat(sname, ckey);
      strcat(sname, ":");
      sname[3] = islower(sname[3]) ? toupper(sname[3]) : sname[3];
      sel = sel_get_any_uid(sname);
      
      if (sel && (mth = class_get_instance_method(class, sel))
	  && method_get_number_of_arguments(mth) == 3
	  && *objc_skip_type_qualifiers(mth->method_types) == _C_VOID)
	{
	  char *argType = (char*)(mth->method_types);
	
	  argType = (char*)objc_skip_argspec(argType);	// skip return
	  argType = (char*)objc_skip_argspec(argType);	// skip self
	  argType = (char*)objc_skip_argspec(argType);	// skip SEL
	
	  switch (*objc_skip_type_qualifiers(argType))
	    {
	    case _C_ID:
	      fptr = (void (*)(void*, void*, id, id))idMethodSetFunc;
	      idMethod = YES;
	      break;
	    case _C_CHR:
	      fptr = (void (*)(void*, void*, id, id))charMethodSetFunc;
	      break;
	    case _C_UCHR:
	      fptr = (void (*)(void*, void*, id, id))unsignedCharMethodSetFunc;
	      break;
	    case _C_SHT:
	      fptr = (void (*)(void*, void*, id, id))shortMethodSetFunc;
	      break;
	    case _C_USHT:
	      fptr = (void (*)(void*, void*, id, id))unsignedShortMethodSetFunc;
	      break;
	    case _C_INT:
	      fptr = (void (*)(void*, void*, id, id))intMethodSetFunc;
	      break;
	    case _C_UINT:
	      fptr = (void (*)(void*, void*, id, id))unsignedIntMethodSetFunc;
	      break;
	    case _C_LNG:
	      fptr = (void (*)(void*, void*, id, id))longMethodSetFunc;
	      break;
	    case _C_ULNG:
	      fptr = (void (*)(void*, void*, id, id))unsignedLongMethodSetFunc;
	      break;
	    case 'q':
	      fptr = (void (*)(void*, void*, id, id))longLongMethodSetFunc;
	      break;
	    case 'Q':
	      fptr = (void (*)(void*, void*, id, id))unsignedLongLongMethodSetFunc;
	      break;
	    case _C_FLT:
	      fptr = (void (*)(void*, void*, id, id))floatMethodSetFunc;
	      break;
	    case _C_DBL:
	      fptr = (void (*)(void*, void*, id, id))doubleMethodSetFunc;
	      break;
	    }

	  if (fptr)
	    {
	      info1 = (void*)(mth->method_imp);
	      info2 = (void*)(mth->method_name);
	    }
	}
    }

  // Lookup ivar name
  if (!fptr)
    {
      Class class = [instance class];
      const char* ckey = [key cString];
      int i;
      
      while (class)
	{
	  for (i = 0; class->ivars && i < class->ivars->ivar_count; i++)
	    {
	      if (!strcmp(ckey, class->ivars->ivar_list[i].ivar_name))
		{
		  switch (*objc_skip_type_qualifiers(class->ivars->ivar_list[i].ivar_type))
		    {
		    case _C_ID:
		      fptr = (void (*)(void*, void*, id, id))idIvarSetFunc;
		      idMethod = YES;
		      break;
		    case _C_CHR:
		      fptr = (void (*)(void*, void*, id, id))charIvarSetFunc;
		      break;
		    case _C_UCHR:
		      fptr = (void (*)(void*, void*, id, id))unsignedCharIvarSetFunc;
		      break;
		    case _C_SHT:
		      fptr = (void (*)(void*, void*, id, id))shortIvarSetFunc;
		      break;
		    case _C_USHT:
		      fptr = (void (*)(void*, void*, id, id))unsignedShortIvarSetFunc;
		      break;
		    case _C_INT:
		      fptr = (void (*)(void*, void*, id, id))intIvarSetFunc;
		      break;
		    case _C_UINT:
		      fptr = (void (*)(void*, void*, id, id))unsignedIntIvarSetFunc;
		      break;
		    case _C_LNG:
		      fptr = (void (*)(void*, void*, id, id))longIvarSetFunc;
		      break;
		    case _C_ULNG:
		      fptr = (void (*)(void*, void*, id, id))unsignedLongIvarSetFunc;
		      break;
		    case 'q':
		      fptr = (void (*)(void*, void*, id, id))longLongIvarSetFunc;
		      break;
		    case 'Q':
		      fptr = (void (*)(void*, void*, id, id))unsignedLongLongIvarSetFunc;
		      break;
		    case _C_FLT:
		      fptr = (void (*)(void*, void*, id, id))floatIvarSetFunc;
		      break;
		    case _C_DBL:
		      fptr = (void (*)(void*, void*, id, id))doubleIvarSetFunc;
		      break;
		    }

		  if (fptr)
		    {
		      info2 = (void*)(class->ivars->ivar_list[i].ivar_offset);
		      break;
		    }
		}
	    }

	  class = class->super_class;
	}
    }

  // Lookup method name [-(void)setKey:(type)arg]
  if (!fptr)
    {
      Class class = [instance class];
      const char* ckey = [key cString];
      SEL sel;
      struct objc_method* mth;
      char  sname[strlen(ckey) + 7];

      // Make sel from name
      strcpy(sname, "set");
      strcat(sname, ckey);
      strcat(sname, ":");
      sname[3] = islower(sname[3]) ? toupper(sname[3]) : sname[3];
      sel = sel_get_any_uid(sname);

      if (sel && (mth = class_get_instance_method(class, sel))
	  && method_get_number_of_arguments(mth) == 3
	  && *objc_skip_type_qualifiers(mth->method_types) == _C_VOID)
	{
	  char *argType = (char*)(mth->method_types);

	  argType = (char*)objc_skip_argspec(argType);	// skip return
	  argType = (char*)objc_skip_argspec(argType);	// skip self
	  argType = (char*)objc_skip_argspec(argType);	// skip SEL
	
	  switch (*objc_skip_type_qualifiers(argType))
	    {
	    case _C_ID:
	      fptr = (void (*)(void*, void*, id, id))idMethodSetFunc;
	      idMethod = YES;
	      break;
	    case _C_CHR:
	      fptr = (void (*)(void*, void*, id, id))charMethodSetFunc;
	      break;
	    case _C_UCHR:
	      fptr = (void (*)(void*, void*, id, id))unsignedCharMethodSetFunc;
	      break;
	    case _C_SHT:
	      fptr = (void (*)(void*, void*, id, id))shortMethodSetFunc;
	      break;
	    case _C_USHT:
	      fptr = (void (*)(void*, void*, id, id))unsignedShortMethodSetFunc;
	      break;
	    case _C_INT:
	      fptr = (void (*)(void*, void*, id, id))intMethodSetFunc;
	      break;
	    case _C_UINT:
	      fptr = (void (*)(void*, void*, id, id))unsignedIntMethodSetFunc;
	      break;
	    case _C_LNG:
	      fptr = (void (*)(void*, void*, id, id))longMethodSetFunc;
	      break;
	    case _C_ULNG:
	      fptr = (void (*)(void*, void*, id, id))unsignedLongMethodSetFunc;
	      break;
	    case 'q':
	      fptr = (void (*)(void*, void*, id, id))longLongMethodSetFunc;
	      break;
	    case 'Q':
	      fptr = (void (*)(void*, void*, id, id))unsignedLongLongMethodSetFunc;
	      break;
	    case _C_FLT:
	      fptr = (void (*)(void*, void*, id, id))floatMethodSetFunc;
	      break;
	    case _C_DBL:
	      fptr = (void (*)(void*, void*, id, id))doubleMethodSetFunc;
	      break;
	    }

	  if (fptr)
	    {
	      info1 = (void*)(mth->method_imp);
	      info2 = (void*)(mth->method_name);
	    }
	}
    }
  
  if (fptr && !idMethod && value == nil)
    return (SetKeyValueBinding *)-1;

  // Make binding and insert into map
  if (fptr)
    {
      KeyValueMethod* mkey = NSZoneMalloc(NSDefaultMallocZone(), sizeof(KeyValueMethod));
      SetKeyValueBinding* bin = NSZoneMalloc(NSDefaultMallocZone(), sizeof(SetKeyValueBinding));

      mkey->key = [key copy];
      mkey->class = [instance class];

      bin->access = fptr;
      bin->info1 = info1;
      bin->info2 = info2;

      NSMapInsert(setStoredValueBindings, mkey, bin);
      ret = bin;
    }

  // If no way to access value warn
  if (!ret && keyValueDebug)
    NSLog(@"cannnot set key `%@' for instance of class `%@'",
	  key, NSStringFromClass([instance class]));
  
  return ret;
}

/*
 * MapTable initialization
 */

static unsigned keyValueMapHash(NSMapTable *table, KeyValueMethod *map)
{
  return [map->key hash] + (((int)(map->class)) >> 4);
}

static BOOL keyValueMapCompare(NSMapTable *table,
			       KeyValueMethod *map1, KeyValueMethod *map2)
{
  return (map1->class == map2->class) && [map1->key isEqual: map2->key];
}

static void mapRetainNothing(NSMapTable *table, KeyValueMethod *map)
{
}

static void keyValueMapKeyRelease(NSMapTable *table, KeyValueMethod *map)
{
  [map->key release];
  NSZoneFree(NSDefaultMallocZone(), map);
}

static void keyValueMapValRelease(NSMapTable *table, void *map)
{
  NSZoneFree(NSDefaultMallocZone(), map);
}

static NSString *keyValueMapDescribe(NSMapTable *table, KeyValueMethod *map)
{
  return [NSString stringWithFormat: @"%@:%@",
		   NSStringFromClass(map->class), map->key];
}

static NSString *describeBinding(NSMapTable *table, GetKeyValueBinding *bin)
{
  return [NSString stringWithFormat: @"%08x:%08x", bin->info1, bin->info2];
}

static NSMapTableKeyCallBacks keyValueKeyCallbacks =
  {
    (unsigned(*)(NSMapTable *, const void *))keyValueMapHash,
    (BOOL(*)(NSMapTable *, const void *, const void *))keyValueMapCompare,
    (void (*)(NSMapTable *, const void *anObject))mapRetainNothing,
    (void (*)(NSMapTable *, void *anObject))keyValueMapKeyRelease,
    (NSString *(*)(NSMapTable *, const void *))keyValueMapDescribe,
    (const void *)NULL
  };

const NSMapTableValueCallBacks keyValueValueCallbacks =
  {
    (void (*)(NSMapTable *, const void *))mapRetainNothing,
    (void (*)(NSMapTable *, void *))keyValueMapValRelease,
    (NSString *(*)(NSMapTable *, const void *))describeBinding
  };

static void initKeyValueBindings(void)
{
  getValueBindings = NSCreateMapTable(keyValueKeyCallbacks, 
				      keyValueValueCallbacks, 31);
  setValueBindings = NSCreateMapTable(keyValueKeyCallbacks, 
				      keyValueValueCallbacks, 31);
  getStoredValueBindings = NSCreateMapTable(keyValueKeyCallbacks, 
					    keyValueValueCallbacks, 31);
  setStoredValueBindings = NSCreateMapTable(keyValueKeyCallbacks, 
					    keyValueValueCallbacks, 31);
  keyValueInit = YES;
}

/* 
 * Access Methods 
 */

static inline void removeAllBindings(void)
{
  NSResetMapTable(getValueBindings);
  NSResetMapTable(setValueBindings);
  NSResetMapTable(getStoredValueBindings);
  NSResetMapTable(setStoredValueBindings);
}

static inline id getValue(NSString *key, id instance, BOOL *found)
{
  KeyValueMethod  mkey = {key, [instance class]};
  GetKeyValueBinding *bin;
  id value = nil;

  // Check Init
  if (!keyValueInit)
    initKeyValueBindings();
  
  //  NSDebugFLog(@"after init");
  // Get existing binding
  bin = (GetKeyValueBinding *)NSMapGet(getValueBindings, &mkey);

  // Create new binding
  if (!bin)
    bin = newGetBinding(key, instance);

  // Get value if binding is ok
  if (bin)
    {
//      NSDebugFLog(@"bin->");
      value = bin->access(bin->info1, bin->info2, instance);
//      NSDebugFLog(@"after bin->");
      *found = YES;
    }

  return value;
}

static inline id getStoredValue(NSString *key, id instance, BOOL *found)
{
  KeyValueMethod  mkey = {key, [instance class]};
  GetKeyValueBinding *bin;
  id value = nil;
  
  // Check Init
  if (!keyValueInit)
    initKeyValueBindings();
  
  // Get existing binding
  bin = (GetKeyValueBinding *)NSMapGet(getStoredValueBindings, &mkey);
  
  // Create new binding
  if (!bin)
    bin = newGetStoredBinding(key, instance);
  
  // Get value if binding is ok
  if (bin)
    {
      value = bin->access(bin->info1, bin->info2, instance);
      *found = YES;
    }

  return value;
}

static inline BOOL setValue(NSString *key, id instance, id value)
{
  KeyValueMethod mkey = {key, [instance class]};
  SetKeyValueBinding *bin;

  // Check Init
  if(!keyValueInit)
    initKeyValueBindings();

  // Get existing binding
  bin = (SetKeyValueBinding *)NSMapGet(setValueBindings, &mkey);

  // Create new binding
  if (!bin)
    bin = newSetBinding(key, instance, value);

  if (bin == (SetKeyValueBinding *)-1)
    {
      [instance unableToSetNilForKey:key];
      return YES;
    }

  // Get value if binding is ok
  if (bin)
    bin->access(bin->info1, bin->info2, instance, value);

  return (bin != NULL);
}

static inline BOOL setStoredValue(NSString *key, id instance, id value)
{
  KeyValueMethod mkey = {key, [instance class]};
  SetKeyValueBinding *bin;

  // Check Init
  if (!keyValueInit)
    initKeyValueBindings();

  // Get existing binding
  bin = (SetKeyValueBinding *)NSMapGet(setStoredValueBindings, &mkey);

  // Create new binding
  if (!bin)
    bin = newSetStoredBinding(key, instance, value);

  if (bin == (SetKeyValueBinding *) - 1)
    {
      [instance unableToSetNilForKey: key];
      return YES;
    }

  // Get value if binding is ok
  if(bin)
    bin->access(bin->info1, bin->info2, instance, value);

  return (bin != NULL);
}

/*
 *  Methods
 */

- (void)setKeyValueCodingWarnings: (BOOL)aFlag //REMOVE
{
  keyValueDebug = aFlag;
}

- (id)valueForKeyPath: (NSString *)key
{
  NSArray *pathArray = [key componentsSeparatedByString: @"."];
  NSEnumerator *pathEnum;
  NSString *path;
  id obj = self;

  pathEnum = [pathArray objectEnumerator];
  while ((path = [pathEnum nextObject]))
    {
      obj = [obj valueForKey: path];
    }

  return obj;
}

- (void)takeValue: value forKeyPath: (NSString *)key
{
  NSArray *pathArray = [key componentsSeparatedByString: @"."];
  NSString *path;
  id obj = self;
  int i, count;

  count = [pathArray count];

  for (i = 0; i < (count - 1); i++)
    {
      path = [pathArray objectAtIndex: i];
      obj = [obj valueForKey: path];
    }

  path = [pathArray lastObject];
  [obj takeValue: value forKey: path];
}

- (NSDictionary *)valuesForKeys: (NSArray *)keys
{
  int i, n = [keys count];
  NSMutableArray *newKeys = [[[NSMutableArray alloc] initWithCapacity: n] 
			      autorelease];
  NSMutableArray *newVals = [[[NSMutableArray alloc] initWithCapacity: n] 
			      autorelease];
  EONull *null = [EONull null];

  for (i = 0; i < n; i++)
    {
      id key = [keys objectAtIndex: i];
      id val = [self valueForKey: key];

      if (val == nil)
	val = null;

      [newKeys addObject: key];
      [newVals addObject: val];
    }

  return [NSDictionary dictionaryWithObjects: newVals forKeys: newKeys];
}

- (void)takeValuesFromDictionary: (NSDictionary *)dictionary
{
  NSEnumerator *keyEnum = [dictionary keyEnumerator];
  id key;
  id val;
  
  while ((key = [keyEnum nextObject]))
    {
      val = [dictionary objectForKey: key];

      if ([val isKindOfClass: [[EONull null] class]])
	val = nil;

      [self takeValue: val forKey: key];
    }
}

@end

 // Implemented in NSObject
@implementation NSObject (EOKeyValueCodingPrimitives)

- (id)valueForKey: (NSString *)key
{
  BOOL found = NO;
  id val = nil;

//  NSDebugFLog(@"valueForKey:");

  val = getValue(key, self, &found);

  if (found == NO)
    val = [self handleQueryWithUnboundKey: key];

  return val;
}

- (void)takeValue: (id)value
           forKey: (NSString *)key
{
  if (!setValue(key, self, value))
    [self handleTakeValue: value forUnboundKey: key];
}

- (id)storedValueForKey: (NSString *)key
{
  BOOL found = NO;
  id val = getStoredValue(key, self, &found);

  if (found == NO)
    val = [self handleQueryWithUnboundKey: key];

  return val;
}

- (void)takeStoredValue: (id)value forKey: (NSString *)key
{
  if (!setStoredValue(key, self, value))
    [self handleTakeValue: value forUnboundKey: key];
}

+ (BOOL)accessInstanceVariablesDirectly
{
  return YES;
}

+ (BOOL)useStoredAccessor
{
  return NO;
}

@end


@implementation NSObject (EOKeyValueCodingCacheControl)

+ (void)flushAllKeyBindings
{
  removeAllBindings();
}

+ (void)flushClassKeyBindings
{
  removeAllBindings();
}

@end


/*
 *  EOKeyValueCodingException raises an exception by default
 */

@implementation NSObject (EOKeyValueCodingException)

- (id)handleQueryWithUnboundKey: (NSString *)key
{
  NSString *reason=nil;

  reason = [NSString stringWithFormat: @"%@ -- %@ 0x%x: cannot find value for key \"%@\"", 
                     NSStringFromSelector(_cmd), 
                     NSStringFromClass([self class]), 
                     self, 
                     key];

  [[NSException exceptionWithName: EOUnknownKeyException
		reason: reason
                userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					  self, EOTargetObjectUserInfoKey,
					key, EOUnknownUserInfoKey,
					nil]] raise];
  return nil;
}

- (void)handleTakeValue: (id)value
          forUnboundKey: (NSString *)key
{
  NSString *reason=nil;

  reason = [NSString stringWithFormat: @"%@ -- %@ 0x%x: cannot set value \"%@\" for key \"%@\"", 
		     NSStringFromSelector(_cmd),
		     NSStringFromClass([self class]),
		     self,
		     value,
		     key];

  [[NSException exceptionWithName: EOUnknownKeyException
		reason: reason
		userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					  self, EOTargetObjectUserInfoKey,
					key, EOUnknownUserInfoKey,
					nil]] raise];
}

- (void)unableToSetNilForKey: (NSString *)key
{
  [NSException raise: NSInvalidArgumentException 
               format: @"%@ -- %@ 0x%x: cannot set EONull value for key \"%@\"", 
               NSStringFromSelector(_cmd),
               NSStringFromClass([self class]),
               self,
               key];
}

@end


#endif
