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
      _doubleFlip,	@"Double",
      _integerFlip,	@"Integer",
      nil];

  _valueTypeDict = 
     [[NSDictionary alloc] initWithObjectsAndKeys:
        @"",	@"",
     	@"c",	@"char",
	@"C",	@"unsigned char",
	@"s",	@"short",
	@"S",	@"unsigned short",
	@"i",	@"int",
	@"I",	@"unsigned int",
	@"l",	@"long",
	@"L",	@"unsigned long",
	@"u",	@"long long",
	@"U",	@"unsigned long long",
	@"f",	@"float",
	@"d",	@"double",
	nil];
   _typeValueDict = 
     [[NSDictionary alloc] initWithObjectsAndKeys:
        @"",			@"",
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

  /*
   * class name = key, pop-up item = value,
   * "Custom" is not found,
   * double and integer are both NSNumbers, but handled specially,
   * double is the default if a value type is not specified.
   */
  _classTitleDict = 
    [[NSDictionary alloc] initWithObjectsAndKeys:
      @"String",	@"NSString",
      @"Data",		@"NSData",
      @"Double",	@"NSNumber", // Integer and Double, Double is default.
      @"Date",		@"NSCalendarDate",
      @"Decimal Number",	@"NSDecimalNumber",
      nil];
  
  _titleClassDict = 
    [[NSDictionary alloc] initWithObjectsAndKeys:
      @"NSString",		@"String",
      @"NSData",		@"Data",
      @"NSNumber",		@"Double",
      @"NSNumber",		@"Integer",
      @"NSDecimalNumber",	@"Decimal Number",
      @"NSCalendarDate",	@"Date",
      nil];
  
   _valueTypeTitleDict =
    [[NSDictionary alloc] initWithObjectsAndKeys:
      @"d",	@"Double",
      @"i",	@"Integer",
      nil];
}

- (NSString *) _titleForPopUp
{
  NSString *vcn = [(EOAttribute *)[self selectedObject] valueClassName];
  NSString *valueType = [(EOAttribute *)[self selectedObject] valueType];
  NSString *ret;

  if (valueType)
    {
      if ([vcn isEqual: @"NSNumber"])
        {
	  if ([valueType isEqual:@"d"])
            return @"Double";
	  else if ([valueType isEqual:@"i"])
	    return @"Integer";
        }
    }
   ret = [_classTitleDict objectForKey:vcn];
   if (!ret) 
     return @"Custom";

   return ret;
}

- (NSString *)_valueTypeForTitle:(NSString *)title
{
  return [_valueTypeTitleDict objectForKey:title];
}

- (NSString *)_classNameForTitle:(NSString *)title
{
  return [_titleClassDict objectForKey:title];
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

- (IBAction) setValueClassNameAndType:(id)sender;
{
  EOAttribute *obj = [self selectedObject];
  NSString *title = [_flipSelect titleOfSelectedItem]; 
  NSString *className = [self _classNameForTitle:title];
  NSString *valueType = [self _valueTypeForTitle:title];
  
  if (![[obj valueClassName] isEqual:className])
    {
      [obj setValueClassName:className];
    }
  if (![[obj valueType] isEqual:valueType]) 
    {
      [obj setValueType:valueType];
    }
  [self refresh];
}

- (void) refresh
{
  EOAttribute *obj = [self selectedObject];
  NSString *title = [self _titleForPopUp];
  NSBox *flipTo = [self _viewForTitle:title];
  NSString *valType = [obj valueType];
  NSString *valueTypeName = 
	  [_typeValueDict objectForKey: valType ? valType : @""];
  
  [_nameField setStringValue:[obj name]];
  [_extNameField setStringValue:[obj columnName]];
  [_extTypeField setStringValue:[obj externalType]];
  [_valueTypeSelect selectItemWithTitle:valueTypeName];
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

- (void) updateInteger
{
}

- (void) updateDate
{
  // fixme
}

- (void) updateData
{
  int tmp;

  tmp = [[self selectedObject] width];
  NO_ZEROS(_data_width, tmp);
}

- (void) updateDouble;
{

}

- (BOOL) canInspectObject:(id)obj
{
  return [obj isKindOfClass:[EOAttribute class]];
}

- (IBAction) setValueType:(id)sender
{
  id valueType = [_valueTypeDict objectForKey:[sender titleOfSelectedItem]];
  [(EOAttribute *)[self selectedObject] setValueType:valueType];
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
  [[self selectedObject] setValueClassName:[sender stringValue]];
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

