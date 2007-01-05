
/*
    AttributesInspector.h
 
    Author: Matt Rice <ratmice@gmail.com>
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
  NSDictionary			*_valueTypeDict;
  
  IBOutlet NSBox		*_customFlip; // default
  IBOutlet NSBox		*_dataFlip;
  IBOutlet NSBox		*_dateFlip;
  IBOutlet NSBox		*_decimalFlip;
  IBOutlet NSBox		*_numberFlip;
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
- (IBAction) selectInternalDataType:(id)sender;
- (IBAction) setName:(id)sender;
- (IBAction) setExternalName:(id)sender;
- (IBAction) setExternalType:(id)sender;

/* dependent on value class name */
- (IBAction) setWidth:(id)sender;
- (IBAction) setPrecision:(id)sender;
- (IBAction) setClassName:(id)sender;
- (IBAction) setFactoryMethod:(id)sender;
- (IBAction) setConversionMethod:(id)sender;
- (IBAction) setInitArgument:(id)sender;
- (IBAction) setValueType:(id)sender;
- (IBAction) setTimeZone:(id)sender;
@end

