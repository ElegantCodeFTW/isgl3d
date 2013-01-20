/*
 * iSGL3D: http://isgl3d.com
 *
 * Copyright (c) 2010-2012 Stuart Caunt
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "Isgl3dNode.h"
#import "Isgl3dMeshNode.h"
#import "Isgl3dParticleNode.h"
#import "Isgl3dBillboardNode.h"
#import "Isgl3dFollowNode.h"
#import "Isgl3dSkeletonNode.h"
#import "Isgl3dCamera.h"
#import "Isgl3dLight.h"
#import "Isgl3dGLRenderer.h"
#import "Isgl3dQuaternion.h"
#import "Isgl3dDirector.h"
#import "Isgl3dActionManager.h"
#import "Isgl3dAction.h"
#import "Isgl3dMathUtils.h"
#import "Isgl3dMatrix4.h"

#import "Isgl3dAnimatedMeshNode.h"
#import "Isgl3dMatrix.h"
#import "Isgl3dArray.h"


static Isgl3dOcclusionMode Isgl3dNode_OcclusionMode = Isgl3dOcclusionQuadDistanceAndAngle;


@interface Isgl3dNode ()

- (void)updateRotationMatrix;
- (void)updateLocalTransformation; 
@end


#pragma mark -
@implementation Isgl3dNode {
    NSUInteger _frameCount;
    Isgl3dArray * _frameTransformations;
    BOOL _dynamicsNeedUpdate;
}

@synthesize worldTransformation = _worldTransformation;
@synthesize name = _name;
@synthesize parent = _parent;
@synthesize children = _children;
@synthesize enableShadowRendering = _enableShadowRendering;
@synthesize enableShadowCasting = _enableShadowCasting;
@synthesize isPlanarShadowsNode = _isPlanarShadowsNode;
@synthesize alpha = _alpha;
@synthesize transparent = _transparent;
@synthesize alphaCulling = _alphaCulling;
@synthesize alphaCullValue = _alphaCullValue;
@synthesize interactive = _interactive;
@synthesize isVisible = _isVisible;

+ (id)node {
	return [[[self alloc] init] autorelease];
}

- (id)init {    
    if ((self = [super init])) {

		_localTransformation = Isgl3dMatrix4Identity;
		_worldTransformation = Isgl3dMatrix4Identity;

		_rotationX = 0;    	
		_rotationY = 0;    	
		_rotationZ = 0;    	
		_scaleX = 1;    	
		_scaleY = 1;    	
		_scaleZ = 1;    	

    	_eulerAnglesDirty = NO;
		_rotationMatrixDirty = NO;
		_localTransformationDirty = NO;
		_transformationDirty = YES;


       	_children = [[NSMutableArray alloc] init];

    	_enableShadowRendering = YES;
    	_enableShadowCasting = NO;
    	_isPlanarShadowsNode = NO;
    	
    	_hasChildren = NO;

    	_alpha = 1.0;
		_transparent = NO;
		_alphaCullValue = 0.0;
		_alphaCulling = NO;
		
		_lightingEnabled = YES;
		_interactive = NO;
		
		_isVisible = YES;
	}
	
    return self;
}

- (void)dealloc {
    [_dynamics release];
    [_frameTransformations release];
	[_children release];
    [_name release];

	[[Isgl3dActionManager sharedInstance] stopAllActionsForTarget:self];
	
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    Isgl3dNode *copy = [[[self class] allocWithZone:zone] init];
    // do not copy name
	copy->_rotationX = _rotationX;
	copy->_rotationY = _rotationY;
	copy->_rotationZ = _rotationZ;
	copy->_scaleX = _scaleX;
	copy->_scaleY = _scaleY;
	copy->_scaleZ = _scaleZ;
    
    copy->_worldTransformation = _worldTransformation;
    copy->_localTransformation = _localTransformation;

    copy->_transformationDirty = _transformationDirty;
    copy->_localTransformationDirty = _localTransformationDirty;
    copy->_eulerAnglesDirty = _eulerAnglesDirty;
    copy->_rotationMatrixDirty = _rotationMatrixDirty;

    copy->_lightingEnabled = _lightingEnabled;
    copy->_enableShadowCasting = _enableShadowCasting;
    copy->_enableShadowRendering = _enableShadowRendering;
    copy->_isPlanarShadowsNode = _isPlanarShadowsNode;
    copy->_alpha = _alpha;
    copy->_transparent = _transparent;
    copy->_alphaCulling = _alphaCulling;
    copy->_alphaCullValue = _alphaCullValue;
    copy->_interactive = _interactive;
    copy->_isVisible = _isVisible;
    //TODO: Copy dynamics?

	for (Isgl3dNode *child in _children) {
		[copy addChild:[[child copy] autorelease]];
	}
	
    return copy;
}

#pragma mark translation rotation scaling
//TODO: unsafe, doesn't check dirty
- (float)x {
	return _localTransformation.m30;
}

- (void)setX:(float)x {
	_localTransformation.m30 = x;
	_dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (float)y {
	return _localTransformation.m31;
}

- (void)setY:(float)y {
	_localTransformation.m31 = y;
	_dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (float)z {
	return _localTransformation.m32;
}

- (void)setZ:(float)z {
	_localTransformation.m32 = z;
    _dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (Isgl3dVector3)position {
    Isgl3dMatrix4 local = self.transformation;
	return im4ToPosition(&local);
}

- (void)setPosition:(Isgl3dVector3)position {
	_localTransformation.m30 = position.x;
	_localTransformation.m31 = position.y;
	_localTransformation.m32 = position.z;
    _dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (float)rotationX {
	if (_eulerAnglesDirty) {
		[self updateEulerAngles];
	}
	return _rotationX;
}

- (void)setRotationX:(float)rotationX {
	_rotationX = rotationX;
    _dynamicsNeedUpdate = YES;
	_rotationMatrixDirty = YES;
	_localTransformationDirty = YES;
}

- (float)rotationY {
	if (_eulerAnglesDirty) {
		[self updateEulerAngles];
	}
	return _rotationY;
}

- (void)setRotationY:(float)rotationY {
	_rotationY = rotationY;
    _dynamicsNeedUpdate = YES;
	_rotationMatrixDirty = YES;
	_localTransformationDirty = YES;
}

- (float)rotationZ {
	if (_eulerAnglesDirty) {
		[self updateEulerAngles];
	}
	return _rotationZ;
}

- (void)setRotationZ:(float)rotationZ {
	_rotationZ = rotationZ;
    _dynamicsNeedUpdate = YES;
	_rotationMatrixDirty = YES;
	_localTransformationDirty = YES;
}

- (float)scaleX {
	return _scaleX;
}

- (void)setScaleX:(float)scaleX {
	_scaleX = scaleX;
	_dynamicsNeedUpdate = YES;
	_localTransformationDirty = YES;
}

- (float)scaleY {
	return _scaleY;
}

- (void)setScaleY:(float)scaleY {
	_scaleY = scaleY;
	_dynamicsNeedUpdate = YES;
	_localTransformationDirty = YES;
}

- (float)scaleZ {
	return _scaleZ;
}

- (void)setScaleZ:(float)scaleZ {
	_scaleZ = scaleZ;
	_dynamicsNeedUpdate = YES;
	_localTransformationDirty = YES;
}

- (void)setPositionValues:(float)x y:(float)y z:(float)z {
	im4SetTranslation(&_localTransformation, x, y, z);
    _dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (void)translateByValues:(float)x y:(float)y z:(float)z {
	if (_rotationMatrixDirty) {
		[self updateRotationMatrix];
	}
	im4Translate(&_localTransformation, x, y, z);
	_dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (void)translateByVector:(Isgl3dVector3)vector {
	if (_rotationMatrixDirty) {
		[self updateRotationMatrix];
	}
	im4TranslateByVector(&_localTransformation, &vector);
	_dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
}

- (void)pitch:(float)angle {
	if (_rotationMatrixDirty) {
		[self updateRotationMatrix];
	}

    Isgl3dVector3 axis = Isgl3dMatrix4MultiplyVector3(_localTransformation, Isgl3dVector3Right);
	[self rotate:angle x:axis.x y:axis.y z:axis.z];
}

- (void)yaw:(float)angle {
	if (_rotationMatrixDirty) {
		[self updateRotationMatrix];
	}

	Isgl3dVector3 axis = Isgl3dMatrix4MultiplyVector3(_localTransformation, Isgl3dVector3Up);
	[self rotate:angle x:axis.x y:axis.y z:axis.z];
}

- (void)roll:(float)angle {
	if (_rotationMatrixDirty) {
		[self updateRotationMatrix];
	}

	Isgl3dVector3 axis = Isgl3dMatrix4MultiplyVector3(_localTransformation, Isgl3dVector3Backward);
	[self rotate:angle x:axis.x y:axis.y z:axis.z];
}

- (void)rotate:(float)angle x:(float)x y:(float)y z:(float)z {
    if (angle != 0.0) {

        _localTransformation = Isgl3dMatrix4Rotate(_localTransformation, Isgl3dMathDegreesToRadians(angle), x, y, z);
        
        _rotationMatrixDirty = NO;
        _dynamicsNeedUpdate = YES;
        _eulerAnglesDirty = YES;
        _transformationDirty = YES;        
    }
}

- (void)setRotation:(float)angle x:(float)x y:(float)y z:(float)z {
	im4SetRotation(&_localTransformation, angle, x, y, z);
    _dynamicsNeedUpdate = YES;
	_rotationMatrixDirty = NO;
	_eulerAnglesDirty = YES;
	_transformationDirty = YES;
}


- (void)setScale:(float)scale {
	[self setScale:scale scaleY:scale scaleZ:scale];
}

- (void)setScale:(float)scaleX scaleY:(float)scaleY scaleZ:(float)scaleZ {
	_scaleX = scaleX;
	_scaleY = scaleY;
	_scaleZ = scaleZ;
	_dynamicsNeedUpdate = YES;
	_localTransformationDirty = YES;
}

- (void)resetTransformation {
	_localTransformation = Isgl3dMatrix4Identity;
    _dynamicsNeedUpdate = YES;
	_localTransformationDirty = YES;
	_rotationMatrixDirty = NO;
	_eulerAnglesDirty = YES;
}


- (Isgl3dMatrix4)bulletTransform {
    if (_localTransformationDirty) {
		[self updateLocalTransformation];
	}
	Isgl3dMatrix4 normalizedTransform = GLKMatrix4Scale(_localTransformation, 1.0 / _scaleX, 1.0 / _scaleY, 1.0 / _scaleZ);
    return normalizedTransform;
}

- (void)setBulletTransform:(Isgl3dMatrix4)bulletTransform {
    _localTransformation = GLKMatrix4Scale(bulletTransform, _scaleX, _scaleY, _scaleZ);
    
    _dynamicsNeedUpdate = NO; // this method only called by dynamics
	_transformationDirty = YES;
	_rotationMatrixDirty = NO;
	_eulerAnglesDirty = YES;
}

- (void)copyWorldPositionToArray:(float *)position {
	position[0] = _worldTransformation.m30;
	position[1] = _worldTransformation.m31;
	position[2] = _worldTransformation.m32;
	position[3] = _worldTransformation.m33;
}

- (Isgl3dVector3)worldPosition {
    Isgl3dMatrix4 matrix = self.worldTransformation;
	return Isgl3dVector3Make(matrix.m30, matrix.m31, matrix.m32);	
}

- (float)getZTransformation:(Isgl3dMatrix4 *)viewMatrix {
	Isgl3dMatrix4 modelViewMatrix = Isgl3dMatrix4Multiply(*viewMatrix, _worldTransformation);
	float z = modelViewMatrix.m32;
	
	return z;
}

- (Isgl3dVector4)asPlaneWithNormal:(Isgl3dVector3)normal {
	
    Isgl3dVector3 transformedNormal = Isgl3dMatrix4MultiplyVector3(_worldTransformation, normal);
	
	float A = transformedNormal.x;
	float B = transformedNormal.y;
	float C = transformedNormal.z;
	float D = -(A * _worldTransformation.m30 + B * _worldTransformation.m31 + C * _worldTransformation.m32);
	
    return Isgl3dVector4Make(A, B, C, D);
}

- (void)updateEulerAngles {
	Isgl3dVector3 r = im4ToEulerAngles(&_localTransformation);
	_rotationX = r.x;
	_rotationY = r.y;
	_rotationZ = r.z;
	
	_eulerAnglesDirty = NO;
}

- (void)updateRotationMatrix {
	im4SetRotationFromEuler(&_localTransformation, _rotationX, _rotationY, _rotationZ);
	
	_rotationMatrixDirty = NO;
}


- (Isgl3dMatrix4)transformation {
    if (_localTransformationDirty || _rotationMatrixDirty) {
        [self updateLocalTransformation];
    }
    return _localTransformation;
}

- (void)setTransformation:(Isgl3dMatrix4)transformation {
	_localTransformation = transformation;
	
    Isgl3dVector3 currentScale = im4ToScaleValues(&_localTransformation);
    _scaleX = currentScale.x;
    _scaleY = currentScale.y;
    _scaleZ = currentScale.z;
    _localTransformationDirty = NO;
	_dynamicsNeedUpdate = YES;
	_transformationDirty = YES;
	_rotationMatrixDirty = NO;
	_eulerAnglesDirty = YES;
}


- (void)updateLocalTransformation {
	// Translation already set
	
	// Convert rotation matrix into euler angles if necessary
	if (_rotationMatrixDirty) {
		[self updateRotationMatrix];
	}
	
	// Scale transformation (no effect on translation) -- is this necessary? (can't we update like translate?)
	im4Scale(&_localTransformation, _scaleX, _scaleY, _scaleZ);
	
	_localTransformationDirty = NO;
	_transformationDirty = YES;
}


- (void)setTransformationDirty:(BOOL)isDirty {
	_dynamicsNeedUpdate = YES;
	_transformationDirty = isDirty;
}

- (Isgl3dMatrix4)worldTransformation {
    if (_localTransformationDirty || _rotationMatrixDirty || _transformationDirty) {
        Isgl3dMatrix4 parentTrans = _parent.worldTransformation;
        [self updateWorldTransformation:_parent ? &parentTrans : NULL];
    }
    return _worldTransformation;
}


- (void)updateWorldTransformation:(Isgl3dMatrix4 *)parentTransformation {
	
	// Recalculate local transformation if necessary
	if (_localTransformationDirty || _rotationMatrixDirty) {
		[self updateLocalTransformation];
	}
	
	// Update transformation matrices if needed
	if (_transformationDirty) {

		// Let all children know that they must update their world transformation, 
		//   even if they themselves have not locally changed
		if (_hasChildren) {
			for (Isgl3dNode * node in _children) {
				[node setTransformationDirty:YES];
			}
		}

		// Calculate world transformation
		if (parentTransformation) {
            _worldTransformation = Isgl3dMatrix4Multiply(*parentTransformation, _localTransformation);
		} else {
            _worldTransformation = _localTransformation;
		}
		
		_transformationDirty = NO;
	}
    if (_dynamics && _dynamicsNeedUpdate) {
        //TODO: Can't move dynamic rigid body on its own, could remove, move, then add again.
//        [_dynamics updateTransformation];
    }
	// Update all children transformations
	if (_hasChildren) {
		for (Isgl3dNode * node in _children) {
			[node updateWorldTransformation:&_worldTransformation];
	    }
	}
}

#pragma mark scene graph

- (Isgl3dNode *)createNode {
	return [self addChild:[Isgl3dNode node]];
}

- (Isgl3dMeshNode *)createNodeWithMesh:(Isgl3dGLMesh *)mesh andMaterial:(Isgl3dMaterial *)material {
	return (Isgl3dMeshNode *)[self addChild:[Isgl3dMeshNode nodeWithMesh:mesh andMaterial:material]];
}

- (Isgl3dParticleNode *)createNodeWithParticle:(Isgl3dGLParticle *)particle andMaterial:(Isgl3dMaterial *)material {
	return (Isgl3dParticleNode *)[self addChild:[Isgl3dParticleNode nodeWithParticle:particle andMaterial:material]];
}

- (Isgl3dBillboardNode *)createBillboardNodeWithMesh:(Isgl3dGLMesh *)mesh andMaterial:(Isgl3dMaterial *)material {
	return (Isgl3dBillboardNode *)[self addChild:[Isgl3dBillboardNode nodeWithMesh:mesh andMaterial:material]];
}

- (Isgl3dSkeletonNode *)createSkeletonNode {
	return (Isgl3dSkeletonNode *)[self addChild:[Isgl3dSkeletonNode skeletonNode]];
}

- (Isgl3dFollowNode *)createFollowNodeWithTarget:(Isgl3dNode *)target {
	return (Isgl3dFollowNode *)[self addChild:[Isgl3dFollowNode nodeWithTarget:target]];
}

- (Isgl3dLight *)createLightNode {
	return (Isgl3dLight *)[self addChild:[Isgl3dLight light]];
}

- (Isgl3dNode *)addChild:(Isgl3dNode *)child {
	child.parent = self;
	[_children addObject:child];
	_hasChildren = YES;
	
	if (_isRunning) {
		[child activate];
	}
    [self descendantAdded:child];
	return child;
}

- (void)removeChild:(Isgl3dNode *)child {
	child.parent = nil;
	[_children removeObject:child];
	
	if (_isRunning) {
		[child deactivate];
	}
	
	[[Isgl3dActionManager sharedInstance] stopAllActionsForTarget:self];
	
	if ([_children count] == 0) {
		_hasChildren = NO;
	}
    [self descendantRemoved:child];
}

- (void)removeFromParent {
	[_parent removeChild:self];
}

- (void)activate {
	_isRunning = YES;
	for (Isgl3dNode * child in _children) {
		[child activate];
	}
	
	[[Isgl3dActionManager sharedInstance] resumeActionsForTarget:self];
	
	[self onActivated];
}

- (void)deactivate {
	_isRunning = NO;
	for (Isgl3dNode * child in _children) {
		[child deactivate];
	}

	[[Isgl3dActionManager sharedInstance] pauseActionsForTarget:self];
	
	[self onDeactivated];
}

- (void)onActivated {
	// To be over-ridden	
}

- (void)onDeactivated {
	// To be over-ridden	
}

- (void)clearAll {
	[_children removeAllObjects];
}

- (void)renderLights:(Isgl3dGLRenderer *)renderer {
	
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node renderLights:renderer];
			}
	    }
	}
}

- (void)render:(Isgl3dGLRenderer *)renderer opaque:(BOOL)opaque {
	
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node render:renderer opaque:opaque];
			}
	    }
	}
}

- (void)renderForEventCapture:(Isgl3dGLRenderer *)renderer {
	
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node renderForEventCapture:renderer];
			}
	    }
	}
}

- (void)renderForShadowMap:(Isgl3dGLRenderer *)renderer {
	
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node renderForShadowMap:renderer];
			}
	    }
	}
}

- (void)renderForPlanarShadows:(Isgl3dGLRenderer *)renderer {
	
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node renderForPlanarShadows:renderer];
			}
	    }
	}
}

- (void)collectAlphaObjects:(NSMutableArray *)alphaObjects {
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node collectAlphaObjects:alphaObjects];
			}
	    }
	}	
}

- (void)enableAlphaCullingWithValue:(float)value {
	_alphaCulling = YES;
	_alphaCullValue = value;
}

- (void)occlusionTest:(Isgl3dVector3 *)eye normal:(Isgl3dVector3 *)normal targetDistance:(float)targetDistance maxAngle:(float)maxAngle {
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node occlusionTest:eye normal:normal targetDistance:targetDistance maxAngle:maxAngle];
			}
	    }
	}	
}


+ (void)setOcclusionMode:(Isgl3dOcclusionMode)mode {
	Isgl3dNode_OcclusionMode = mode;
}

+ (Isgl3dOcclusionMode)occlusionMode {
	return Isgl3dNode_OcclusionMode;
}

- (BOOL)lightingEnabled {
	return _lightingEnabled;
}

- (void)setLightingEnabled:(BOOL)lightingEnabled {
	_lightingEnabled = lightingEnabled;
}

- (void)createShadowMaps:(Isgl3dGLRenderer *)renderer forScene:(Isgl3dNode *)scene {
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node createShadowMaps:renderer forScene:scene];
			}
	    }
	}
}

- (void)createPlanarShadows:(Isgl3dGLRenderer *)renderer forScene:(Isgl3dNode *)scene {
	if (_hasChildren && _isVisible) {
		for (Isgl3dNode * node in _children) {
			if (node.isVisible) {
				[node createPlanarShadows:renderer forScene:scene];
			}
	    }
	}
}

- (void)enableShadowCastingWithChildren:(BOOL)enableShadowCasting {
	_enableShadowCasting = enableShadowCasting;
	for (Isgl3dNode * node in _children) {
		[node enableShadowCastingWithChildren:enableShadowCasting];
    }
}

- (void)setAlphaWithChildren:(float)alpha {
	_alpha = alpha;
	for (Isgl3dNode * node in _children) {
		[node setAlphaWithChildren:alpha];
    }
}


- (NSArray *)gestureRecognizers {
	return [[Isgl3dDirector sharedInstance] gestureRecognizersForNode:self];
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	[[Isgl3dDirector sharedInstance] addGestureRecognizer:gestureRecognizer forNode:self];
}

- (void)removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	[[Isgl3dDirector sharedInstance] removeGestureRecognizer:gestureRecognizer fromNode:self];
}

- (id<UIGestureRecognizerDelegate>)gestureRecognizerDelegateFor:(UIGestureRecognizer *)gestureRecognizer {
	return [[Isgl3dDirector sharedInstance] gestureRecognizerDelegateFor:gestureRecognizer];
}

- (void)setGestureRecognizerDelegate:(id<UIGestureRecognizerDelegate>)aDelegate forGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	[[Isgl3dDirector sharedInstance] setGestureRecognizerDelegate:aDelegate forGestureRecognizer:gestureRecognizer];
}

- (void)runAction:(Isgl3dAction *)action {
	[[Isgl3dActionManager sharedInstance] addAction:action toTarget:self isPaused:!_isRunning];
}

- (void)stopAction:(Isgl3dAction *)action {
	[[Isgl3dActionManager sharedInstance] stopAction:action];
}

- (void)stopAllActions {
	[[Isgl3dActionManager sharedInstance] stopAllActionsForTarget:self];
}

- (void)addFrameTransformationFromOpenGLMatrix:(float *)transformation {
	Isgl3dMatrix4 matrix;
	im4SetTransformationFromOpenGLMatrix(&matrix, transformation);
	IA_ADD(_frameTransformations, matrix);
    _frameCount++;
}

- (void)setFrame:(unsigned int)frameNumber {
    if (_frameCount > 1) {
        Isgl3dMatrix4 * matrix = IA_GET_PTR(Isgl3dMatrix4 *, _frameTransformations, frameNumber);
        [self setTransformation:*matrix];
    }
	
	for (Isgl3dNode * node in _children) {
		if ([node isKindOfClass:[Isgl3dBoneNode class]]) {
			[(Isgl3dBoneNode *)node setFrame:frameNumber];
		} else if ([node isKindOfClass:[Isgl3dAnimatedMeshNode class]]) {
			[(Isgl3dAnimatedMeshNode *)node setFrame:frameNumber];
		}
        
	}
}

- (NSString *)additionalDescription {
    return nil;
}

- (NSString *)description {    
    return [NSString stringWithFormat:@"<%@ position[%f, %f, %f] rotation[%f, %f, %f] %@>", NSStringFromClass([self class]), self.position.x, self.position.y, self.position.z, self.rotationX, self.rotationY, self.rotationZ, [self.additionalDescription length] ? self.additionalDescription : @""];
}

- (void)descendantAdded:(Isgl3dNode *)descendant {
    [_parent descendantAdded:descendant];
}

- (void)descendantRemoved:(Isgl3dNode *)descendant {
    [_parent descendantRemoved:descendant];
}

- (void)descendantDidAddDynamics:(Isgl3dNode *)descendant {
    [_parent descendantDidAddDynamics:descendant];
}

- (void)descendantWillRemoveDynamics:(Isgl3dNode *)descendant {
    [_parent descendantWillRemoveDynamics:descendant];
}

- (void)setDynamics:(Isgl3dNodeDynamics *)dynamics {
    if (_dynamics!=dynamics) {
        if (_parent && _dynamics && !dynamics) {
            [_parent descendantWillRemoveDynamics:self];
        }
        BOOL addingDynamics = !_dynamics && dynamics;
        [_dynamics release];
        _dynamics = [dynamics retain];
        if (_parent && addingDynamics) {
            [_parent descendantDidAddDynamics:self];
        }
    }
}

- (Isgl3dQuaternion)rotationQuaternion {
    return Isgl3dQuaternionMakeWithMatrix4(self.transformation);
}
    
- (void)setRotationQuaternion:(Isgl3dQuaternion)rotationQuaternion {
    Isgl3dVector3 pos = self.position;
    Isgl3dMatrix4 trans = Isgl3dMatrix4MakeWithQuaternion(rotationQuaternion);
    self.transformation = trans;
    self.position = pos;
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"localTransformation"]) {
        Isgl3dMatrix4 matrix = self.transformation;
        return [NSValue valueWithBytes:&matrix objCType:@encode(Isgl3dMatrix4)];
    } else if ([key isEqualToString:@"rotationQuaternion"]) {
        Isgl3dQuaternion qua = self.rotationQuaternion;
        return [NSValue valueWithBytes:&qua objCType:@encode(Isgl3dQuaternion)];

    } else {
        return [super valueForKey:key];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"localTransformation"]) {
        NSValue *boxedTransform = value;
        Isgl3dMatrix4 matrix;
        [boxedTransform getValue:&matrix];
        self.transformation = matrix;
    } else if ([key isEqualToString:@"rotationQuaternion"]) {
        NSValue *boxedQua = value;
        Isgl3dQuaternion qua;
        [boxedQua getValue:&qua];
        self.rotationQuaternion = qua;
    } else {
        [super setValue:value forKey:key];
    }
    
}

@end
