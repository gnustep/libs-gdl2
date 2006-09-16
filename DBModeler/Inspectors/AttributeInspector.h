#include <EOAccess/EOAttribute.h>
#include <EOModeler/EOMInspector.h>

#include <AppKit/NSBox.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSNibDeclarations.h>
#include <Foundation/NSDictionary.h>


@interface AttributeInspector : EOMInspector
{
  IBOutlet NSTextField		*_extNameField;
  IBOutlet NSTextField		*_extTypeField;
  IBOutlet NSPopUpButton	*_valueTypeSelect;
  IBOutlet NSPopUpButton	*_flipSelect;// select which valueClassName/flip
  IBOutlet NSBox		*_flipView; // gets replaced with a *Flip...
  IBOutlet NSBox		*_internalData;
  IBOutlet NSTextField		*_nameField;

  NSDictionary			*_flipDict;
  NSDictionary			*_classTitleDict;
  NSDictionary			*_titleClassDict;
  NSDictionary			*_valueTypeTitleDict;
  NSDictionary			*_valueTypeDict;
  NSDictionary			*_typeValueDict;
  
  IBOutlet NSBox		*_customFlip; // default
  IBOutlet NSBox		*_dataFlip;
  IBOutlet NSBox		*_dateFlip;
  IBOutlet NSBox		*_decimalFlip;
  IBOutlet NSBox		*_doubleFlip;
  IBOutlet NSBox		*_integerFlip;
  IBOutlet NSBox		*_stringFlip;

  NSTextField 			*_custom_width;
  NSTextField			*_custom_class;
  NSTextField			*_custom_factory;
  NSTextField			*_custom_conversion;
  NSPopUpButton			*_custom_arg;

  NSTextField			*_string_width;
  
  NSTextField			*_decimal_precision;
  NSTextField			*_decimal_width;

  NSTextField			*_data_width;

  NSButton			*_date_tz;
}
/* generic */
- (IBAction) setName:(id)sender;
- (IBAction) setExternalName:(id)sender;
- (IBAction) setExternalType:(id)sender;
- (IBAction) setValueClassNameAndType:(id)sender;

/* dependent on value class name */
- (IBAction) setWidth:(id)sender;
- (IBAction) setPrecision:(id)sender;
- (IBAction) setClassName:(id)sender;
- (IBAction) setFactoryMethod:(id)sender;
- (IBAction) setConversionMethod:(id)sender;
- (IBAction) setInitArgument:(id)sender;

- (IBAction) setTimeZone:(id)sender;
@end

