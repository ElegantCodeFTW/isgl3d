//
//  Isgl3dNodeDynamics.h
//  isgl3d
//
//  Created by Brian Tanner on 1/5/13.
//
//

#import <Foundation/Foundation.h>
#import "Isgl3dVector3.h"

@class Isgl3dNode;
@class Isgl3dMeshNode;

@interface Isgl3dNodeDynamics : NSObject

@property(readonly, assign) Isgl3dNode *node;

- (id)initWithNode:(Isgl3dNode *)node width:(float)width height:(float)height depth:(float)depth mass:(float)mass restitution:(float)restitution;

- (id)initWithNode:(Isgl3dNode *)node shape:(void *)shape mass:(float)mass restitution:(float)restitution;

- (id)initWithMeshNode:(Isgl3dMeshNode *)meshNode concave:(BOOL)concave mass:(float)mass restitution:(float)restitution;

- (void *)rigidBody;
/**
 * Applies a force, defined as a vector, to the btRigidBody at a given vector position.
 * @param force The force to be applied.
 * @param position The position at which the force is applied.
 */
- (void)applyForce:(Isgl3dVector3)force withPosition:(Isgl3dVector3)position;
- (void)applyCentralForce:(Isgl3dVector3)force;
- (void)updateTransformation;
@end
