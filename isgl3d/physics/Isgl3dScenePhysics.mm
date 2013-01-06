//
//  Isgl3dNodePhysics.m
//  isgl3d
//
//  Created by Brian Tanner on 1/5/13.
//
//

#import "Isgl3dScenePhysics.h"
#import "Isgl3dNodeDynamics.h"

#include "btBulletDynamicsCommon.h"

@implementation Isgl3dScenePhysics {
    btDiscreteDynamicsWorld *_discreteDynamicsWorld;
    btDefaultCollisionConfiguration *_collisionConfig;
	btDbvtBroadphase *_broadphase;
    btCollisionDispatcher *_collisionDispatcher;
	btSequentialImpulseConstraintSolver *_constraintSolver;
    
	NSTimeInterval _lastStepTime;
	NSMutableArray * _physicsObjects;
}

- (id)init {
    self = [super init];
    if (self) {
        _collisionConfig = new btDefaultCollisionConfiguration();
		_broadphase = new btDbvtBroadphase();
		_collisionDispatcher = new btCollisionDispatcher(_collisionConfig);
		_constraintSolver = new btSequentialImpulseConstraintSolver;
		_discreteDynamicsWorld = new btDiscreteDynamicsWorld(_collisionDispatcher, _broadphase, _constraintSolver, _collisionConfig);
		_discreteDynamicsWorld->setGravity(btVector3(0,-10,0));
        _lastStepTime = [NSDate timeIntervalSinceReferenceDate];
    }
    return self;
}

- (void)setGravity:(Isgl3dVector3)gravity {
    _discreteDynamicsWorld->setGravity(btVector3(gravity.x, gravity.y, gravity.z));
}

- (GLKVector3)gravity {
    btVector3 btGravity = _discreteDynamicsWorld->getGravity();
    return Isgl3dVector3Make(btGravity.m_floats[0], btGravity.m_floats[1], btGravity.m_floats[2]);
}

- (void)updateDynamics {
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval timeInterval = currentTime - _lastStepTime;

	_discreteDynamicsWorld->stepSimulation(timeInterval, 2);
	_lastStepTime = currentTime;
}

- (void)dealloc {
	[_physicsObjects release];
    
    delete _discreteDynamicsWorld;
	delete _collisionConfig;
	delete _broadphase;
	delete _collisionDispatcher;
	delete _constraintSolver;
    
    [super dealloc];
}

- (void)addNodeDynamics:(Isgl3dNodeDynamics *)dynamics {
    _discreteDynamicsWorld->addRigidBody((btRigidBody *)[dynamics rigidBody]);
}

- (void)removeNodeDynamics:(Isgl3dNodeDynamics *)dynamics {
    _discreteDynamicsWorld->removeRigidBody((btRigidBody *)[dynamics rigidBody]);
}


@end
