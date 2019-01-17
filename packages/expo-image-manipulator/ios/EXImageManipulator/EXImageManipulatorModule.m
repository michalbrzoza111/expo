// Copyright 2018-present 650 Industries. All rights reserved.

#import <EXImageManipulator/EXImageManipulatorModule.h>

@interface EXImageManipulatorModule ()

@property (nonatomic, weak) EXModuleRegistry *moduleRegistry;

@end

@implementation EXImageManipulatorModule

EX_EXPORT_MODULE(ExpoImageManipulator);

- (void)setModuleRegistry:(EXModuleRegistry *)moduleRegistry
{
  _moduleRegistry = moduleRegistry;
}

EX_EXPORT_METHOD_AS(someGreatMethodAsync,
                    options:(NSDictionary *)options
                    resolve:(EXPromiseResolveBlock)resolve
                    reject:(EXPromiseRejectBlock)reject)
{
}

@end
