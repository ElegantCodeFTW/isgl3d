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

#import <Foundation/Foundation.h>
#import "Isgl3dMathTypes.h"
#import "Isgl3dVector3.h"
#import "Isgl3dVector4.h"


#import <GLKit/GLKMath.h>


#define Isgl3dMatrix4Identity GLKMatrix4Identity

#define Isgl3dMatrix4Matrix GLKMatrix4Make
#define Isgl3dMatrix4MakeAndTranspose GLKMatrix4MakeAndTranspose
#define Isgl3dMatrix4MakeWithArray GLKMatrix4MakeWithArray
#define Isgl3dMatrix4MakeWithArrayAndTranspose GLKMatrix4MakeWithArrayAndTranspose
#define Isgl3dMatrix4MakeWithRows GLKMatrix4MakeWithRows
#define Isgl3dMatrix4MakeWithColumns GLKMatrix4MakeWithColumns
#define Isgl3dMatrix4MakeWithQuaternion GLKMatrix4MakeWithQuaternion
#define Isgl3dMatrix4MakeTranslation GLKMatrix4MakeTranslation
#define Isgl3dMatrix4MakeScale GLKMatrix4MakeScale
#define Isgl3dMatrix4MakeRotation GLKMatrix4MakeRotation
#define Isgl3dMatrix4MakeXRotation GLKMatrix4MakeXRotation
#define Isgl3dMatrix4MakeYRotation GLKMatrix4MakeYRotation
#define Isgl3dMatrix4MakeZRotation GLKMatrix4MakeZRotation
#define Isgl3dMatrix4MakePerspective GLKMatrix4MakePerspective
#define Isgl3dMatrix4MakeFrustum GLKMatrix4MakeFrustum
#define Isgl3dMatrix4MakeOrtho GLKMatrix4MakeOrtho
#define Isgl3dMatrix4MakeLookAt GLKMatrix4MakeLookAt
#define Isgl3dMatrix4GetMatrix3 GLKMatrix4GetMatrix3
#define Isgl3dMatrix4GetMatrix2 GLKMatrix4GetMatrix2
#define Isgl3dMatrix4GetRow GLKMatrix4GetRow
#define Isgl3dMatrix4GetColumn GLKMatrix4GetColumn
#define Isgl3dMatrix4SetRow GLKMatrix4SetRow
#define Isgl3dMatrix4SetColumn GLKMatrix4SetColumn
#define Isgl3dMatrix4Transpose GLKMatrix4Transpose
#define Isgl3dMatrix4Invert GLKMatrix4Invert
#define Isgl3dMatrix4InvertAndTranspose GLKMatrix4InvertAndTranspose
#define Isgl3dMatrix4Multiply GLKMatrix4Multiply
#define Isgl3dMatrix4Add GLKMatrix4Add
#define Isgl3dMatrix4Subtract GLKMatrix4Subtract
#define Isgl3dMatrix4Translate GLKMatrix4Translate
#define Isgl3dMatrix4TranslateWithVector3 GLKMatrix4TranslateWithVector3
#define Isgl3dMatrix4TranslateWithVector4 GLKMatrix4TranslateWithVector4
#define Isgl3dMatrix4Scale GLKMatrix4Scale
#define Isgl3dMatrix4ScaleWithVector3 GLKMatrix4ScaleWithVector3
#define Isgl3dMatrix4ScaleWithVector4 GLKMatrix4ScaleWithVector4
#define Isgl3dMatrix4Rotate GLKMatrix4Rotate
#define Isgl3dMatrix4RotateWithVector3 GLKMatrix4RotateWithVector3
#define Isgl3dMatrix4RotateWithVector4 GLKMatrix4RotateWithVector4
#define Isgl3dMatrix4RotateX GLKMatrix4RotateX
#define Isgl3dMatrix4RotateY GLKMatrix4RotateY
#define Isgl3dMatrix4RotateZ GLKMatrix4RotateZ
#define Isgl3dMatrix4MultiplyVector3 GLKMatrix4MultiplyVector3
#define Isgl3dMatrix4MultiplyVector3WithTranslation GLKMatrix4MultiplyVector3WithTranslation
#define Isgl3dMatrix4MultiplyAndProjectVector3 GLKMatrix4MultiplyAndProjectVector3
#define Isgl3dMatrix4MultiplyVector3Array GLKMatrix4MultiplyVector3Array
#define Isgl3dMatrix4MultiplyVector3ArrayWithTranslation GLKMatrix4MultiplyVector3ArrayWithTranslation
#define Isgl3dMatrix4MultiplyAndProjectVector3Array GLKMatrix4MultiplyAndProjectVector3Array
#define Isgl3dMatrix4MultiplyVector4 GLKMatrix4MultiplyVector4
#define Isgl3dMatrix4MultiplyVector4Array GLKMatrix4MultiplyVector4Array
