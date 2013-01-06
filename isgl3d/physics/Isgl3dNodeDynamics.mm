//
//  Isgl3dNodeDynamics.m
//  isgl3d
//
//  Created by Brian Tanner on 1/5/13.
//
//

#import "Isgl3dNodeDynamics.h"
#import "Isgl3dMotionState.h"
#include "btBulletDynamicsCommon.h"

@implementation Isgl3dNodeDynamics {
    Isgl3dMotionState *_motionState;
    btCollisionShape *_shape;
    btRigidBody *_rigidBody;
}

- (id)initWithNode:(Isgl3dNode *)node width:(float)width height:(float)height depth:(float)depth mass:(float)mass restitution:(float)restitution {

    btCollisionShape *shape = new btBoxShape(btVector3(width, height, depth));
    return [self initWithNode:node shape:shape mass:mass restitution:restitution];
}

- (id)initWithNode:(Isgl3dNode *)node shape:(void *)shape mass:(float)mass restitution:(float)restitution {
    
    self = [super init];
    if (self) {
        // Create a motion state for the object
        _node = node;
        _motionState = new Isgl3dMotionState(node);
        
        _shape = (btCollisionShape *)shape;
        
        // Create a rigid body
        btVector3 localInertia(0, 0, 0);
        _shape->calculateLocalInertia(mass, localInertia);
        _rigidBody = new btRigidBody(mass, _motionState, _shape, localInertia);
        _rigidBody->setRestitution(restitution);
        _rigidBody->setActivationState(DISABLE_DEACTIVATION);
    }
    return self;
}


- (void)dealloc {
	_node = nil;
    delete _motionState;
    delete _shape;
	delete _rigidBody->getMotionState();
	delete _rigidBody->getCollisionShape();
	delete _rigidBody;
    
	[super dealloc];
}

- (void *)rigidBody {
    return _rigidBody;
}

- (void)applyForce:(Isgl3dVector3)force withPosition:(Isgl3dVector3)position {
    btVector3 bodyForce(force.x, force.y, force.z);
    btVector3 bodyPosition(position.x, position.y, position.z);

    _rigidBody->applyForce(bodyForce, bodyPosition);    
}

- (void)updateTransformation {
    
}

@end
