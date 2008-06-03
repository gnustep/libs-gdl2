#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>
#include <Foundation/Foundation.h>

@interface Trading : NSObject
{
  EOModel *_model;
  EOAdaptor *_adaptor;
  EOAdaptorChannel *_channel;
  EOAdaptorContext *_context;
  Class _exprClass;
}
+ (EOModel *)defaultModel;
- (id) initWithModel:(EOModel *)model;
- (id) initWithModel:(EOModel *)model adaptorName:(NSString *)adaptorName;
- (id) initWithModel:(EOModel *)model
	adaptorName:(NSString*)adaptorName
	connectionDictionary:(NSDictionary *)connDict;

- (BOOL) isOpen;
- (void) open;
- (void) close;

- (void) recreateTables;
- (void) dropTables;
- (void) createTables;


- (EOAdaptor *)adaptor;
- (EOAdaptorChannel *)channel;
- (EOAdaptorContext *)context;
- (Class)exprClass;
- (EOModel *)model;
@end
