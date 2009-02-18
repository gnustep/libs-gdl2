#import <Foundation/Foundation.h>
#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>

@interface TradingData : NSObject
{
  EOEditingContext *ec;
  EODatabaseDataSource *productGroupDS;
  EODatabaseDataSource *productDS;
  EODatabaseDataSource *suppliersDS;
  EODatabaseDataSource *priceListDS;
  EODatabaseDataSource *priceListPosDS;
  EODatabaseDataSource *orderDS;
  EODatabaseDataSource *orderPosDS;
  EODatabaseDataSource *customerDS;
  EODatabaseDataSource *customerGroupDS;
}
- (void) saveChanges;
- (void) fillTables;
- (id) addSupplierNamed:(NSString *)name;
- (id) addProductGroup:(NSString *)name;
- (id) addProduct:(NSString*)name price:(NSDecimalNumber *)price
	supplier:(id)supplier
	group:(id)group;
- (id) addProduct:(id)product
	 price:(NSDecimalNumber *)price 
	toPriceList:(id)priceList;
- (id) addPriceList:(NSString *)name
	 forGroup:(id)group; 
- (id) addCustomer:(NSString *)customer;
- (id) addCustomer:(NSString *)customer group:(id)group;
- (id) addCustomerGroup:(NSString *)name;
- (id) customer:(id)customer
	 order:(id)product;
- (id) customer:(id)customer
	order:(id)product
	quantity:(int)quantity;
- (id) customer:(id)customer
	order:(id)product
	quantity:(int)quantity
	posNr:(int)posNr;

- (id) createOrderForCustomer:(id)customer;
- (id) order:(id)order
 product:(id)product
 quantity:(int)quantity;
@end


