#include "TradingData.h"

#define PDEC2(x) \
[NSDecimalNumber decimalNumberWithMantissa:x \
exponent:-2 \
isNegative:NO]

@implementation TradingData
- (id) init
{

  self = [super init];

  if (self)
  {
    ec = [[EOEditingContext alloc] init];

    customerDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"Customer"];
    customerGroupDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"CustomerGroup"];
    productGroupDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"ProductGroup"];
    productDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"Product"];
    suppliersDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"Supplier"];
    priceListDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"PriceList"];
    priceListPosDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"PriceListPos"];
    orderDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"Order"];
    orderPosDS = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:@"OrderPos"];
  }

  return self;
}

- (void) dealloc
{
  [ec release];
  [customerDS release];
  [customerGroupDS release];
  [productGroupDS release];
  [productDS release];
  [suppliersDS release];
  [priceListDS release];
  [priceListPosDS release];
  [orderDS release];
  [orderPosDS release];
}

- (void) fillTables 
{
  id fsfSup, mysqlSup, postgreSup, publicSup, acmeSup;
  id implGrp, softGrp;
  id folkGrp;
  id rake, shovel, pitchfork, mysql, postgresql, sqlite, gnustep, gcc;
  id salePriceList;
  id customer;
  id order;
 
  implGrp = [self addProductGroup:@"Implements of destruction"];
  softGrp = [self addProductGroup:@"Software"];

  fsfSup = [self addSupplierNamed:@"The Free Software Foundation"];
  gnustep = [self addProduct:@"GNUstep"
	 price:PDEC2(2595)
	 supplier:fsfSup
	 group:softGrp]; 
  gcc = [self addProduct:@"gcc"
	 price:PDEC2(4995)
	 supplier:fsfSup
	 group:softGrp]; 
  mysqlSup = [self addSupplierNamed:@"MySQL AB"];
  mysql = [self addProduct:@"MySQL"
	 price:PDEC2(3000)
	 supplier:fsfSup
	 group:softGrp]; 


  postgreSup = [self addSupplierNamed:@"The PostgreSQL Global Development Group"];
  postgresql = [self addProduct:@"PostgreSQL"
	 price:PDEC2(3000)
	 supplier:postgreSup
	 group:softGrp]; 


  publicSup = [self addSupplierNamed:@"sqlite.org"];
  sqlite = [self addProduct:@"SQLite"
	 price:PDEC2(1500)
	 supplier:publicSup
	 group:softGrp]; 


  acmeSup = [self addSupplierNamed:@"ACME"];
  shovel = [self addProduct:@"Shovel"
	price:PDEC2(1400)
	 supplier:acmeSup
	 group:implGrp]; 

  rake = [self addProduct:@"Rake"
	 price:PDEC2(1295)
	 supplier:acmeSup
	 group:implGrp]; 
  pitchfork = [self addProduct:@"Pitchfork"
	 price:PDEC2(1800)
	 supplier:acmeSup
	 group:implGrp]; 

  folkGrp = [self addCustomerGroup:@"Angry Townfolk"];

  [self customer:[self addCustomer:@"Angry Townsperson1" group:folkGrp]
		order:rake
		quantity:3];
  [self customer:[self addCustomer:@"Angry Townsperson2" group:folkGrp]
		order:shovel];
  
  [self customer:[self addCustomer:@"Angry Townsperson3" group:folkGrp]
		order:rake
		quantity:2];
  
  customer = [self addCustomer:@"Test Customer1"];
  order = [self createOrderForCustomer:customer];

  [self order:order product:mysql quantity:5];
  [self order:order product:postgresql quantity:1];
  [self order:order product:rake quantity:2];

  [self customer:[self addCustomer:@"Test Customer2"]
		order:postgresql];
  [self customer:[self addCustomer:@"Test Customer3"]
		order:sqlite];


  salePriceList = [self addPriceList:@"Farm Supply Sale"
				forGroup:folkGrp];
 
  [self addProduct:pitchfork
	price:PDEC2(1675)
	toPriceList:salePriceList];
  [self addProduct:rake
	price:PDEC2(800)
	toPriceList:salePriceList];
  [self addProduct:shovel
	price:PDEC2(995)
	toPriceList:salePriceList];

  [self saveChanges];
}

- (id) addPriceList:(NSString *)name
	forGroup:(id)grp
{
  id record = [priceListDS createObject];
  [record takeValue:name forKey:@"name"]; 
  [record addObject:grp toBothSidesOfRelationshipWithKey:@"customerGroup"]; 
  return record;
}

- (id) addProduct:(id)product
	price:(NSDecimalNumber *)price
	toPriceList:(id)priceList
{
  id record = [priceListPosDS createObject];

  [record addObject:product toBothSidesOfRelationshipWithKey:@"product"];
  [record takeValue:price forKey:@"price"];
  [record addObject:priceList toBothSidesOfRelationshipWithKey:@"priceList"];
  [priceListPosDS insertObject:record];
  return record;
}

- (id) addProductGroup:(NSString *)productGroupName
{
  id record = [productGroupDS createObject];
  
  [record takeValue:productGroupName forKey:@"name"];

  return record;     
}

- (id) addSupplierNamed:(NSString *)name
{
  id record = [suppliersDS createObject];

  [record takeValue:name forKey:@"name"];

  [suppliersDS insertObject:record];

  return record;
}

- (id) addProduct:(NSString *)productName
	price:(NSDecimalNumber *)price
	supplier:(id)supplier
	group:(id)productGroup
{
  id record = [productDS createObject];
 
  [record takeValue:productName forKey:@"name"];
  [record takeValue:price forKey:@"price"];
  [record addObject:supplier toBothSidesOfRelationshipWithKey:@"supplier"];
  [record addObject:productGroup toBothSidesOfRelationshipWithKey:@"productGroup"];

  [productDS insertObject:record];
  return record;
}
- (id) addCustomerGroup:(NSString *)name
{
  id record = [customerGroupDS createObject];

  [record takeValue:name forKey:@"name"];

  [customerGroupDS insertObject:record];
  return record;
}

- (id) addCustomer:(NSString *)name
{
  return [self addCustomer:name group:nil];
}

- (id) addCustomer:(NSString *)name
	group:(id)group
{
  id record = [customerDS createObject];

  [record takeValue:name forKey:@"name"];
  [record addObject:group toBothSidesOfRelationshipWithKey:@"customerGroup"]; 

  [customerDS insertObject:record];
  return record;
}

- (id) createOrderForCustomer:(id)customer
{
  id order = [orderDS createObject];
  [order takeValue:[NSDate date] forKey:@"date"];
  [order addObject:customer toBothSidesOfRelationshipWithKey:@"customer"];
  [orderDS insertObject:order];
  return order;
}

- (id) order:(id)order
	product:(id)product
	quantity:(int)quantity
{
  id orderPos = [orderPosDS createObject];
  NSNumber *price = [product valueForKey:@"price"]; 
  NSNumber *qNum = [NSNumber numberWithInt:quantity]; 
  /* this should really not be in the database but in some business logic */
  NSNumber *value = [NSNumber numberWithDouble:((double)quantity) * [price doubleValue]]; 
  [orderPos addObject:product toBothSidesOfRelationshipWithKey:@"product"];
  [orderPos addObject:order toBothSidesOfRelationshipWithKey:@"order"];
  /* FIXME customer group pricing */
  [orderPos takeValue:price forKey:@"price"];
  [orderPos takeValue:qNum forKey:@"quantity"];
  [orderPos takeValue:value forKey:@"value"];
 
  /* FIXME this should be a relationship to a pos table */
  [orderPos takeValue:[NSNumber numberWithInt:1] forKey:@"posnr"];
  return orderPos;
}

- (id) customer:(id)customer
	 order:(id)product
{
   return [self customer:customer order:product quantity:1]; 
}

- (id) customer:(id)customer
	order:(id)product
	quantity:(int)quantity
{
  return [self customer:customer order:product quantity:quantity posNr:1]; 
}

- (id) customer:(id)customer
	order:(id)product
	quantity:(int)quantity
	posNr:(int)posNr
{
  id order = [orderDS createObject];
  id orderPos = [orderPosDS createObject];
  NSNumber *price = [product valueForKey:@"price"]; 
  NSNumber *qNum = [NSNumber numberWithInt:quantity]; 
  NSNumber *value = [NSNumber numberWithDouble:((double)quantity) * [price doubleValue]]; 

  [order takeValue:[NSDate date] forKey:@"date"];
  [order addObject:customer toBothSidesOfRelationshipWithKey:@"customer"];

  [orderPos addObject:order toBothSidesOfRelationshipWithKey:@"order"];
  /* FIXME customer group pricing */
  [orderPos takeValue:price forKey:@"price"];
  [orderPos takeValue:qNum forKey:@"quantity"];
  [orderPos takeValue:value forKey:@"value"];
  /* fixme this should be a relationship to a pos table */
  [orderPos takeValue:[NSNumber numberWithInt:posNr] forKey:@"posnr"];
  [orderPos addObject:product toBothSidesOfRelationshipWithKey:@"product"];

  return order;
}

- (void) saveChanges
{
  [ec saveChanges];
}

@end
