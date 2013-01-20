//
//  Isgl3dNodeDynamics.m
//  isgl3d
//
//  Created by Brian Tanner on 1/5/13.
//
//

#import "Isgl3dNodeDynamics.h"
#import "Isgl3dMotionState.h"
#import "isgl3d.h"
#include "btBulletDynamicsCommon.h"
#import "btShapeHull.h"
#import "btConvexHullShape.h"

@implementation Isgl3dNodeDynamics {
    Isgl3dMotionState *_motionState;
    btCollisionShape *_shape;
    btRigidBody *_rigidBody;
}

- (id)initWithNode:(Isgl3dNode *)node width:(float)width height:(float)height depth:(float)depth mass:(float)mass restitution:(float)restitution {

    btCollisionShape *shape = new btBoxShape(btVector3(width, height, depth));
    return [self initWithNode:node shape:shape mass:mass restitution:restitution];
}

- (id)initWithMeshNode:(Isgl3dMeshNode *)meshNode concave:(BOOL)concave mass:(float)mass restitution:(float)restitution {
    
    self = [super init];
    if (self) {
        // Create a motion state for the object
        _node = meshNode;
        _motionState = new Isgl3dMotionState(_node);

        btVector3 scale(meshNode.scaleX, meshNode.scaleY, meshNode.scaleZ);
        if (concave) {
            _shape = [self buildConcaveFromMesh:meshNode.mesh scale:scale];
            
        } else {
            _shape = [self buildHullFromMesh:meshNode.mesh scale:scale];
        }
        
        // Create a rigid body
        btVector3 localInertia(0, 0, 0);
        if (!concave) {
            _shape->calculateLocalInertia(mass, localInertia);
        }
        _rigidBody = new btRigidBody(mass, _motionState, _shape, localInertia);
        if (concave) {
            _rigidBody->setCollisionFlags(_rigidBody->getCollisionFlags() | btCollisionObject::CF_KINEMATIC_OBJECT);//STATIC_OBJECT
        }
        btVector3 scaling = _rigidBody->getCollisionShape()->getLocalScaling();
        _rigidBody->setRestitution(restitution);
        _rigidBody->setActivationState(DISABLE_DEACTIVATION);
    }
    return self;
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

- (btConvexHullShape *)buildHullFromMesh:(Isgl3dGLMesh *)mesh scale:(btVector3)scale  {
    btConvexHullShape *originalShape = new btConvexHullShape((btScalar*)mesh.vertexData, mesh.numberOfVertices, mesh.vboData.stride);
    originalShape->setLocalScaling(scale);
//    //create a hull approximation
//	btShapeHull *hull = new btShapeHull(originalShape);
//	btScalar margin = originalShape->getMargin();
//	hull->buildHull(margin);
//	btConvexHullShape* simplifiedConvexShape = new btConvexHullShape((btScalar *)hull->getVertexPointer(),hull->numVertices());
//    delete hull;
//    return simplifiedConvexShape;
    return originalShape;
}

- (btScaledBvhTriangleMeshShape *)buildConcaveFromMesh:(Isgl3dGLMesh *)mesh scale:(btVector3)scale {
    
    btTriangleIndexVertexArray *vertArray = new btTriangleIndexVertexArray();
    btIndexedMesh indexedMesh;
    indexedMesh.m_numTriangles  = mesh.numberOfElements / 3;
    indexedMesh.m_triangleIndexBase   = mesh.indices;
    indexedMesh.m_triangleIndexStride = 3 * sizeof(unsigned short);
    indexedMesh.m_numVertices         = mesh.numberOfVertices;
    indexedMesh.m_vertexBase          = mesh.vertexData;
    indexedMesh.m_vertexStride        = mesh.vboData.stride;
    vertArray->addIndexedMesh(indexedMesh, PHY_SHORT);

//    vertArray->setScaling(scale);
//	btTriangleIndexVertexArray *vertArray = new btTriangleIndexVertexArray(totalTriangles, (int *)mesh.indices, 3*sizeof(int), mesh.numberOfVertices, (btScalar *)mesh.vertexData, mesh.vboData.stride);
    
	bool useQuantizedAabbCompression = true;
    
	btVector3 aabbMin(-1000,-1000,-1000),aabbMax(1000,1000,1000);
    
    return new btScaledBvhTriangleMeshShape(new btBvhTriangleMeshShape(vertArray, useQuantizedAabbCompression,aabbMin,aabbMax), scale);
}

- (void)dealloc {
	_node = nil;
    delete _motionState;
    delete _shape;
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

- (void)applyCentralForce:(Isgl3dVector3)force {
    btVector3 bodyForce(force.x, force.y, force.z);
    _rigidBody->applyCentralForce(bodyForce);
}

- (void)updateTransformation {
    
}

@end
