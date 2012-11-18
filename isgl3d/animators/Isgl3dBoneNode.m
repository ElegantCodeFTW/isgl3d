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

#import "Isgl3dBoneNode.h"
#import "Isgl3dPrimitiveFactory.h"
#import "Isgl3dColorMaterial.h"

@implementation Isgl3dBoneNode 

+ (id)boneNode {
	return [[[self alloc] init] autorelease];
}

- (id)init {
    if ((self = [super initWithMesh:[[Isgl3dPrimitiveFactory sharedInstance] boneMesh] andMaterial:[[[Isgl3dColorMaterial alloc] initWithHexColors:@"FFFF00" diffuse:@"FFFF00" specular:@"FFFF00" shininess:0] autorelease]])) {
    }
	
    return self;
}

- (void)dealloc {
	[super dealloc];
}

- (Isgl3dBoneNode *) createBoneNode {
	return (Isgl3dBoneNode *)[self addChild:[Isgl3dBoneNode boneNode]];
}

@end
