
/*
    AttributesInspector.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: 2005, 2006

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
#include "AttributeInspector.h"
#include <Foundation/NSObjCRuntime.h>

#define NO_ZEROS(x, i) i ? [x setIntValue:i] : [x setStringValue:@""];

@implementation AttributeInspector
- (void) awakeFromNib
{
  RETAIN(_internalData);
  _flipDict =
    [[NSDictionary alloc] initWithObjectsAndKeys:
      _stringFlip,	@"String",
      _customFlip,	@"Custom", 
      _dataFlip,	@"Data",
      _dateFlip,	@"Date",
      _decimalFlip,	@"Decimal Number",
      _numberFlip,	@"Number",
      nil];

  _valueTypeDict = 
     [[NSDictionary alloc] initWithObjectsAndKeys:
	@"i",	@"int",
	@"d",	@"double",
	@"f",	@"float",
     	@"c",	@"char",
	@"s",	@"short",
	@"I",	@"unsigned int",
	@"C",	@"unsigned char",
	@"S",	@"unsigned short",
	@"l",	@"long",
	@"L",	@"unsigned long",
	@"u",	@"long long",
	@"U",	@"unsigned long long",
     	@"char",		@"c",	
	@"unsigned char",	@"C",	
	@"short",		@"s",	
	@"unsigned short",	@"S",	
	@"int", 		@"i",	
	@"unsigned int", 	@"I",	
	@"long", 		@"l",	
	@"unsigned long", 	@"L",	
	@"long long", 		@"u",	
	@"unsigned long long", 	@"U",	
	@"float", 		@"f",	
	@"double", 		@"d",	
	nil];

  _classTitleDict = 
    [[NSDictionary alloc] initWithObjectsAndKeys:
      @"String",	@"NSString",
      @"Data",		@"NSData",
      @"Number",	@"NSNumber", 
      @"Date",		@"NSCalendarDate",
      @"Decimal Number",	@"NSDecimalNumber",
      @"NSString",		@"String",
      @"NSData",		@"Data",
      @"NSNumber",		@"Number",
      @"NSDecimalNumber",	@"Decimal Number",
      @"NSCalendarDate",	@"Date",
      nil];
}

- (NSString *) _titleForPopUp
{
  NSString *vcn = [(EOAttribute *)[self selectedObject] valueClassName];
  NSString *valueType = [(EOAttribute *)[self selectedObject] valueType];
  NSString *ret;

  ret = [_classTitleDict objectForKey:vcn];
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
  return (NSBox *)[_flipDict objectForKey:title];
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
  EOAttribute *obj = [self selectedObject];
  NSString *title = [_flipSelect titleOfSelectedItem]; 
  NSString *className = [self _classNameForTitle:title];
  
  if (![[obj valueClassName] isEqual:className])
    {
      [obj setValueClassName:className];
    }
  
  if ([className isEqual:@"NSNumber"])
    {
      if (![obj valueType])
        {
	  [obj setValueType:@"d"];
        }
    }
  else
    {
      [obj setValueType:@""];
    }
  
  [self refresh];
}

- (void) refresh
{
  EOAttribute *obj = [self selectedObject];
  NSString *title = [self _titleForPopUp];
  NSBox *flipTo = [self _viewForTitle:title];
  
  [_nameField setStringValue:[obj name]];
  [_extNameField setStringValue:[obj columnName]];
  [_extTypeField setStringValue:[obj externalType]];
  [_flipSelect selectItemWithTitle:title];
  [flipTo setFrame: [_flipView frame]];
  [_internalData replaceSubview:_flipView with:flipTo];
  _flipView = flipTo;
  [self performSelector:
	  NSSelectorFromString([@"update" stringByAppendingString:[title stringByReplacingString:@" " withString:@""]])];
}

- (void) updateString
{
  int tmp;
  tmp = [[self selectedObject] width];
  NO_ZEROS(_string_width,tmp);
}

- (void) updateCustom
{
  EOAttribute *obj = [self selectedObject];
  int tmp;
  tmp = [obj width];
  NO_ZEROS(_custom_width, tmp);
  [_custom_class setStringValue:[obj valueClassName]];
  [_custom_factory setStringValue:[obj valueFactoryMethodName]];
  [_custom_conversion setStringValue:[obj adaptorValueConversionMethodName]];
  [_custom_arg selectItemAtIndex:
	  [_custom_arg indexOfItemWithTag: [obj factoryMethodArgumentType]]];
}

- (void) updateDecimalNumber
{
  EOAttribute *obj = [self selectedObject];
  int tmp;

  tmp = [obj width];
  NO_ZEROS(_decimal_width, tmp);
  tmp = [obj precision];
  NO_ZEROS(_decimal_precision, tmp);

}

- (void) updateNumber
{
  EOAttribute *obj = [self selectedObject];
  NSString *valType = [obj valueType];
  NSString *valueTypeName;
  
  valueTypeName = [_valueTypeDict objectForKey: valType];
  [_valueTypeSelect selectItemWithTitle:valueTypeName];
}

- (void) updateDate
{

}

- (void) updateData
{
  int tmp;

  tmp = [[self selectedObject] width];
  NO_ZEROS(_data_width, tmp);
}

- (BOOL) canInspectObject:(id)obj
{
  return [obj isKindOfClass:[EOAttribute class]];
}

- (IBAction) setValueType:(id)sender
{
  EOAttribute *obj = [self selectedObject];
  NSString *valueType;
  
  if (sender == _valueTypeSelect)
    {
      valueType = [_valueTypeDict objectForKey:[sender titleOfSelectedItem]];
    }
  else if (sender == self)
    {
      valueType = @"";
    }
  
  [obj setValueType:valueType];
}

- (IBAction) setTimeZone:(id)sender;
{
  // fixme	
}

- (IBAction) setWidth:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setWidth:[sender intValue]];
}

- (IBAction) setPrecision:(id)sender;
{
  [(EOAttribute *)[self selectedObject] setPrecision:[sender intValue]];
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

- (IBAction) setInitArgument:(id)sender
{
  [[self selectedObject] setFactoryMethodArgumentType:[[sender selectedItem] tag]];
}
@end

