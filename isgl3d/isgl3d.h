/*
 * iSGL3D: http://isgl3d.com
 *
 * Copyright (c) 2010-2011 Stuart Caunt
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

#import "animators/Isgl3dAnimatedMeshNode.h"
#import "animators/Isgl3dAnimationController.h"
#import "animators/Isgl3dBoneBatch.h"
#import "animators/Isgl3dBoneNode.h"
#import "animators/Isgl3dSkeletonNode.h"
#import "billboards/Isgl3dBillboard.h"
#import "cameras/Isgl3dCamera.h"
#import "cameras/Isgl3dFollowCamera.h"
#import "cameras/Isgl3dSpringCamera.h"
#import "containers/Isgl3dBillboardNode.h"
#import "containers/Isgl3dFollowNode.h"
#import "containers/Isgl3dMeshNode.h"
#import "containers/Isgl3dNode.h"
#import "containers/Isgl3dParticleNode.h"
#import "containers/Isgl3dScene3D.h"
#import "core/Isgl3dDirector.h"
#import "core/Isgl3dEAGLView.h"
#import "core/Isgl3dFpsRenderer.h"
#import "core/Isgl3dGLContext.h"
#import "core/Isgl3dGLDepthRenderTexture.h"
#import "core/Isgl3dGLMesh.h"
#import "core/Isgl3dGLTexture.h"
#import "core/Isgl3dGLTextureFactory.h"
#import "core/Isgl3dGLTextureFactoryState.h"
#import "core/Isgl3dGLVBOData.h"
#import "core/Isgl3dGLVBOFactory.h"
#import "core/Isgl3dScheduler.h"
#import "core/Isgl3dUVMap.h"
#import "core/v1.1/Isgl3dGLContext1.h"
#import "core/v1.1/Isgl3dGLDepthRenderTexture1.h"
#import "core/v1.1/Isgl3dGLTextureFactoryState1.h"
#import "core/v1.1/Isgl3dGLVBOFactory1.h"
#import "core/v2.0/Isgl3dGLContext2.h"
#import "core/v2.0/Isgl3dGLDepthRenderTexture2.h"
#import "core/v2.0/Isgl3dGLTextureFactoryState2.h"
#import "core/v2.0/Isgl3dGLVBOFactory2.h"
#import "events/Isgl3dAccelerometer.h"
#import "events/Isgl3dEvent3D.h"
#import "events/Isgl3dEvent3DDispatcher.h"
#import "events/Isgl3dEvent3DHandler.h"
#import "events/Isgl3dEvent3DListener.h"
#import "events/Isgl3dEventType.h"
#import "events/Isgl3dObject3DGrabber.h"
#import "events/Isgl3dTouchedObject3D.h"
#import "events/Isgl3dTouchScreen.h"
#import "events/Isgl3dTouchScreenResponder.h"
#import "events/utils/Isgl3dSingleTouchFilter.h"
#import "isgl3dTypes.h"
#import "lights/Isgl3dLight.h"
#import "lights/Isgl3dShadowCastingLight.h"
#import "materials/Isgl3dAnimatedTextureMaterial.h"
#import "materials/Isgl3dColorMaterial.h"
#import "materials/Isgl3dMaterial.h"
#import "materials/Isgl3dTextureMaterial.h"
#import "math/Isgl3dGLU.h"
#import "math/Isgl3dMatrix.h"
#import "math/Isgl3dQuaternion.h"
#import "math/Isgl3dVector.h"
#import "math/neon/neon_matrix_impl.h"
#import "math/vfp/common_macros.h"
#import "math/vfp/matrix_impl.h"
#import "math/vfp/utility_impl.h"
#import "math/vfp/vfp_clobbers.h"
#import "particles/generators/Isgl3dExplosionParticleGenerator.h"
#import "particles/generators/Isgl3dFountainBounceParticleGenerator.h"
#import "particles/generators/Isgl3dFountainParticleGenerator.h"
#import "particles/generators/Isgl3dParticleGenerator.h"
#import "particles/generators/Isgl3dParticlePath.h"
#import "particles/Isgl3dGLParticle.h"
#import "particles/Isgl3dParticleSystem.h"
#import "primitives/Isgl3dArrow.h"
#import "primitives/Isgl3dCone.h"
#import "primitives/Isgl3dCube.h"
#import "primitives/Isgl3dCubeSphere.h"
#import "primitives/Isgl3dCylinder.h"
#import "primitives/Isgl3dEllipsoid.h"
#import "primitives/Isgl3dGoursatSurface.h"
#import "primitives/Isgl3dMultiMaterialCube.h"
#import "primitives/Isgl3dOvoid.h"
#import "primitives/Isgl3dPlane.h"
#import "primitives/Isgl3dPrimitive.h"
#import "primitives/Isgl3dPrimitiveFactory.h"
#import "primitives/Isgl3dSphere.h"
#import "primitives/Isgl3dTerrainMesh.h"
#import "primitives/Isgl3dTorus.h"
#import "renderers/Isgl3dGLRenderer.h"
#import "renderers/v1.1/Isgl3dGLRenderer1.h"
#import "renderers/v1.1/Isgl3dGLRenderer1State.h"
#import "renderers/v2.0/Isgl3dGLRenderer2.h"
#import "renderers/v2.0/Isgl3dGLRenderer2State.h"
#import "renderers/v2.0/shaders/Isgl3dCaptureShader.h"
#import "renderers/v2.0/shaders/Isgl3dGenericShader.h"
#import "renderers/v2.0/shaders/Isgl3dGLProgram.h"
#import "renderers/v2.0/shaders/Isgl3dParticleShader.h"
#import "renderers/v2.0/shaders/Isgl3dShader.h"
#import "renderers/v2.0/shaders/Isgl3dShaderState.h"
#import "renderers/v2.0/shaders/Isgl3dShadowMapShader.h"
#import "tweener/Isgl3dTween.h"
#import "tweener/Isgl3dTweener.h"
#import "ui/Isgl3dGLUIButton.h"
#import "ui/Isgl3dGLUIComponent.h"
#import "ui/Isgl3dGLUIImage.h"
#import "ui/Isgl3dGLUILabel.h"
#import "ui/Isgl3dGLUIProgressBar.h"
#import "utils/Isgl3dArray.h"
#import "utils/Isgl3dCArray.h"
#import "utils/Isgl3dColorUtil.h"
#import "utils/Isgl3dFloatArray.h"
#import "utils/Isgl3dLog.h"
#import "utils/Isgl3dUShortArray.h"
#import "view/Isgl3dView.h"

NSString * isgl3dVersion();
