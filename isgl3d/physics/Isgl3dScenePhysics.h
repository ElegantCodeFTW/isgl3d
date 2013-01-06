//
//  Isgl3dNodePhysics.h
//  isgl3d
//
//  Created by Brian Tanner on 1/5/13.
//
//

#import <Foundation/Foundation.h>
#import "Isgl3dVector3.h"


@class Isgl3dNodeDynamics;

@interface Isgl3dScenePhysics : NSObject
@property(nonatomic, assign) Isgl3dVector3 gravity;
- (void)updateDynamics;
- (void)addNodeDynamics:(Isgl3dNodeDynamics *)dynamics;
- (void)removeNodeDynamics:(Isgl3dNodeDynamics *)dynamics;

@end
