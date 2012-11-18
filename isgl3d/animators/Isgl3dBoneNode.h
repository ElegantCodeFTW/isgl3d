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

#import "Isgl3dMeshNode.h"
@class Isgl3dArray;

/**
 * NOTE: Animation has been moved up into the Isgl3d class, all node hierarchies are animatable. 
 *       This class in now used for debugging to create a visible mesh for a parent node structure.
 *
 * The Isgl3dBoneNode is used to render the bones (or rather the joints) of a skeleton coming from an imported 3D model.
 * 
 * The bone node, as with all nodes in iSGL3D, is organised as a hierarchy of children related to a parent node. This
 * is the same as the structure of bones in a 3D model. For example an elbow joint could be a child of a shoulder joint:
 * the elbow transformation is the product of both its own transformation matrix and the shoulder's transformation. 
 * 
 * Isgl3dBoneNodes do not necessarily have to be created for a 3D model and have no influence on an Isgl3dAnimatedMesh, but
 * they can be useful to examine the movement of a skeleton.
 * 
 * Isgl3dBoneNodes are typically added to an Isgl3dSkeletonNode which helps automate the animation of the bones.
 */
@interface Isgl3dBoneNode : Isgl3dMeshNode

/**
 * Allocates and initialises (autorelease) bone node.
 */
+ (id)boneNode;

/**
 * Intialises the bone node.
 */
- (id)init;

/**
 * Creates an Isgl3dBoneNode and automatically adds it as a child.
 * @return Isgl3dBoneNode (autorelease) The created bone node.
 */
- (Isgl3dBoneNode *) createBoneNode;

@end
