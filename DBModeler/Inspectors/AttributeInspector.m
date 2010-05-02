/*
    AttributesInspector.m
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006
    Author: David Wetzel <dave@turbocat.de>
    Date: 2010

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
#include "AttributeInspector.h"

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSObjCRuntime.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#define NO_ZEROS(x, i) i ? [x setIntValue:i] : [x setStringValue:@""];

@implementation AttributeInspector
- (void) awakeFromGSMarkup //awakeFromNib
{
  RETAIN(_internalData);
  _flipDict =
    [[NSDictionary alloc] initWithObjectsAndKeys:
      [_stringFlip contentView],      @"NSString",
      [_customFlip contentView],      @"Custom", 
      [_dataFlip contentView],        @"NSData",
      [_dateFlip contentView],        @"NSCalendarDate",
      [_decimalFlip contentView],     @"NSDecimalNumber",
      [_numberFlip contentView],      @"NSNumber",
      nil];

  _valueTypeDict = 
     [[NSDictionary alloc] initWithObjectsAndKeys:
        @"i", @"int",
        @"d", @"double",
        @"f", @"float",
        @"c", @"char",
        @"s", @"short",
        @"I", @"unsigned int",
        @"C", @"unsigned char",
        @"S", @"unsigned short",
        @"l", @"long",
        @"L", @"unsigned long",
        @"u", @"long long",
        @"U", @"unsigned long long",
        @"char",               @"c",        
        @"unsigned char",      @"C",        
        @"short",              @"s",        
        @"unsigned short",     @"S",        
        @"int",                @"i",        
        @"unsigned int",       @"I",        
        @"long",               @"l",        
        @"unsigned long",      @"L",        
        @"long long",          @"u",        
        @"unsigned long long", @"U",        
        @"float",              @"f",        
        @"double",             @"d",        
        nil];

  _classTitleDict = 
    [[NSDictionary alloc] initWithObjectsAndKeys:
      @"0",          @"NSString",
      @"1",          @"NSDecimalNumber",
      @"2",          @"NSNumber", 
      @"3",          @"NSCalendarDate",
      @"4",          @"NSData",
      nil];
  
}

- (NSString *) _titleForPopUp
{
  NSString *vcn = [(EOAttribute *)[self selectedObject] valueClassName];
  NSString *ret;

  NSLog(@"_titleForPopUp:vcn '%@' ",vcn);
  
  ret = [_classTitleDict objectForKey:vcn];
  NSLog(@"_titleForPopUp:ret '%@' ",ret);
  if (!ret) 
    return @"Custom";

  return ret;
}

- (NSString *)_classNameForTitle:(NSString *)title
{
  return [_classTitleDict objectForKey:title];
}

- (NSBox *) _viewForTitle:(NSString *)title
{
  
  NSBox * myview = [_flipDict objectForKey:title];
  
  if (!myview) {
    myview = [_flipDict objectForKey:@"Custom"];
  }
  
  return myview;
}

- (float) displayOrder
{
  return 0;
}

- (IBAction) setName:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setName:[sender stringValue]];
}

- (IBAction) setExternalName:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setColumnName:[sender stringValue]];
}

- (IBAction) setExternalType:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setExternalType:[sender stringValue]];
}

- (IBAction) selectInternalDataType:(id)sender;
{
  EOAttribute *attr = [self selectedObject];

  switch  ([[sender selectedItem] tag]) {
    case 0: 
      [attr setValueClassName:@"NSString"];
      break;
    case 1: 
      [attr setValueClassName:@"NSDecimalNumber"];
      break;
    case 2: 
      [attr setValueClassName:@"NSNumber"];
      break;
    case 3: 
      [attr setValueClassName:@"NSCalendarDate"];
      break;
    case 4: 
      [attr setValueClassName:@"NSData"];
      break;
    case 5: 
      [attr setValueClassName:@"Custom"];
      break;
    default:
      break;
  }
  
  [self refresh];
}

- (void) putSubViewBack
{
  NSView * subView = nil;
  
  if ([[_flipView subviews] count] > 0) {
    
    subView = [[_flipView subviews] objectAtIndex:0];
        
    [subView removeFromSuperviewWithoutNeedingDisplay];
  }
  
}

- (IBAction) changeValueType:(NSPopUpButton*) sender
{
  EOAttribute * attr = [self selectedObject];
  
  switch  ([[sender selectedItem] tag]) {
    case 0: /* int */
      [attr setValueType:@"i"];
      break;
    case 1: /* double */
      [attr setValueType:@"d"];
      break;
    case 2: /* float */
      [attr setValueType:@"f"];
      break;
    case 3: /* char */
      [attr setValueType:@"c"];
      break;
    case 4: /* short */
      [attr setValueType:@"s"];
      break;
    case 5: /* unsigned int */
      [attr setValueType:@"I"];
      break;
    case 6: /* unsigned char */
      [attr setValueType:@"C"];
      break;
    case 7: /* unsigned short */
      [attr setValueType:@"S"];
      break;
    case 8: /* long */
      [attr setValueType:@"l"];
      break;
    case 9: /* unsigned long */
      [attr setValueType:@"L"];
      break;
    case 10: /* long long */
      [attr setValueType:@"u"];
      break;
    case 11: /* unsigned long long */
      [attr setValueType:@"U"];
      break;
    default:
      break;
  }
  
}

- (void) _updateValueTypePopUpWithAttribute:(EOAttribute*) attr
{
  NSString *valueType      = [attr valueType];
  unichar  valueTypeChar;
  
  if ((valueType)  && ([valueType length])) {
    valueTypeChar = [valueType characterAtIndex:0];
  } else {
    return;
  }

  
  NSInteger tagValue = 0;
  
  switch (valueTypeChar) {
    case 'i':
      tagValue = 0;
      break;
    case 'd':
      tagValue = 1;
      break;
    case 'f':
      tagValue = 2;
      break;
    case 'c':
      tagValue = 3;
      break;
    case 's':
      tagValue = 4;
      break;
    case 'I':
      tagValue = 5;
      break;
    case 'C':
      tagValue = 6;
      break;
    case 'S':
      tagValue = 7;
      break;
    case 'l':
      tagValue = 8;
      break;
    case 'L':
      tagValue = 9;
      break;
    case 'u':
      tagValue = 10;
      break;
    case 'U':
      tagValue = 11;
      break;
    default:
      break;
  }

  [_valueTypePopUp selectItemWithTag:tagValue];

}

- (void) _updateStringViewWithAttribute:(EOAttribute*) attr
{
    NO_ZEROS(_string_width, [attr width]);
}


- (void) _updateDecimalNumberViewWithAttribute:(EOAttribute*) attr

{
  NO_ZEROS(_decimal_scale, [attr scale]);
  NO_ZEROS(_decimal_precision, [attr precision]);  
}

- (void) _updateDataViewWithAttribute:(EOAttribute*) attr
{  
  NO_ZEROS(_data_width, [attr width]);
}

- (void) _updateCustomViewWithAttribute:(EOAttribute*) attr
{
  NSString * tmpStr = nil;
  NO_ZEROS(_custom_width, [attr width]);
  [_custom_class setStringValue:[attr valueClassName]];
  
  tmpStr = [attr valueFactoryMethodName];
  
  if (!tmpStr) {
    [attr setValueFactoryMethodName:@""];
  }
  
  tmpStr = [attr adaptorValueConversionMethodName];
  
  if (!tmpStr) {
    [attr setAdaptorValueConversionMethodName:@""];
  }

  
  [_custom_factory setStringValue:[attr valueFactoryMethodName]];
  [_custom_conversion setStringValue:[attr adaptorValueConversionMethodName]];
  [_custom_arg selectItemWithTag:[attr factoryMethodArgumentType]];
}


- (void) _updateValueClassPopUpWithAttribute:(EOAttribute*) attr
{
  NSString  * tagString = [_classTitleDict objectForKey:[attr valueClassName]];
  NSInteger tagValue = 0;
  
  if (!tagString) {
    tagValue = 5; // custom
    [self _updateCustomViewWithAttribute:attr];
  } else {
    tagValue = [tagString integerValue];
    
    switch (tagValue) {
      case 0: // NSString
        [self _updateStringViewWithAttribute:attr];
        break;
      case 1: // NSDecimalNumber
        [self _updateDecimalNumberViewWithAttribute:attr];
        break;
      case 2: // NSNumber
        [self _updateValueTypePopUpWithAttribute:attr];
        break;
      case 3: // NSCalendarDate
              // nothing for now
        break;
      case 4: // NSData
        [self _updateDataViewWithAttribute:attr];
        break;
      default:
        break;
    }
        
  }
  
  [_valueClassSelect selectItemWithTag:tagValue];
}

- (void) refresh
{
  EOAttribute *obj = [self selectedObject];
  NSString *title = [obj valueClassName];
  NSBox *flipTo = [self _viewForTitle:title];
  
  [_nameField setStringValue:[obj name]];
  [_extNameField setStringValue:[obj columnName]];
  [_extTypeField setStringValue:[obj externalType]];
  
  if ([obj isDerived]) {
    [_derivedPopUp selectItemWithTag:1];
  } else {
    [_derivedPopUp selectItemWithTag:0];
  }
  
  [self putSubViewBack];
  [_flipView setNeedsDisplay:YES];

  [_flipView addSubview:flipTo];
   
  [self _updateValueClassPopUpWithAttribute:obj];
  
}



- (void) updateNumber
{
  EOAttribute *obj = [self selectedObject];
  NSString *valType = [obj valueType];
  NSString *valueTypeName;
  
  valueTypeName = [_valueTypeDict objectForKey: valType];
  NSLog(@"updateNumber %@", valueTypeName);
  [_valueClassSelect selectItemWithTitle:valueTypeName];
}


- (BOOL) canInspectObject:(id)obj
{
  NSLog(@"%s: %@", __PRETTY_FUNCTION__, obj);
  return [obj isKindOfClass:[EOAttribute class]];
}

- (IBAction) setValueType:(id)sender
{
  EOAttribute *obj = [self selectedObject];
  NSString *valueType = nil;
  
  
  [obj setValueType:valueType];
}

- (IBAction) setDerived:(id)sender
{
  NSLog(@"%s:%@",__PRETTY_FUNCTION__, sender);
//  EOAttribute *obj = [self selectedObject];

//  if ([sender tag] == 0) { // Column
//    [obj setIsDerived:NO];
//  } else {
//    [obj setIsDerived:YES];
//  }

}

- (IBAction) setTimeZone:(id)sender;
{
  // fixme
}

- (IBAction) changeLevel:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setFactoryMethodArgumentType:[[sender selectedItem] tag]];
}

- (IBAction) setWidth:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setWidth:[sender intValue]];
}

- (IBAction) setPrecision:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setPrecision:[sender intValue]];
}

- (IBAction) setScale:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setScale:[sender intValue]];
}

- (IBAction) setClassName:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setValueClassName:[sender stringValue]];
}

- (IBAction) setFactoryMethod:(id)sender;
{
  [[self selectedObject] setValueFactoryMethodName:[sender stringValue]];

}

- (IBAction) setConversionMethod:(id)sender;
{
  [[self selectedObject] setAdaptorValueConversionMethodName:[sender stringValue]];
}

- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id obj = [notif object];

  if (obj == _extNameField)
    [self setExternalName:_extNameField];
  else if (obj == _extTypeField)
    [self setExternalType:_extTypeField];
  else if (obj == _nameField)
    [self setName:_nameField];
  else if (obj == _custom_width
	   || obj == _data_width
	   || obj == _string_width)
    [self setWidth:obj];
  else if (obj == _decimal_scale)
    [self setScale:obj];
  else if (obj == _decimal_precision)
    [self setPrecision:_decimal_precision];
  else if (obj == _custom_class)
    [self setClassName:_custom_class];
  else if (obj == _custom_factory)
    [self setFactoryMethod:_custom_factory];
  else if (obj == _custom_conversion)
    [self setConversionMethod:_custom_conversion];
}

@end

