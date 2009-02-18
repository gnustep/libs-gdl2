#include "Trading.h"
#include "TradingData.h"

int main()
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  id trading = [[Trading alloc] init];
  id data = [[TradingData alloc] init]; 

  [trading recreateTables];
  [data fillTables]; 
  [data saveChanges];
  
  [trading release];
  [data release];
  [pool release];
  return 0;
}
