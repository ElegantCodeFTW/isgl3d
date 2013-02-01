/*
 * Phong Shader
 *
 * Copyright (c) 2013 Brian Tanner
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

precision highp float;

#define MAX_LIGHTS 3
#define MAX_BONES 4

struct Light {
	vec4 position;
	vec4 ambientColor;
	vec4 diffuseColor;
	vec4 specularColor;
	vec3 attenuation;
	float spotCutoffAngle;
	vec3 spotDirection;
	float spotFalloffExponent;
};

attribute vec4 a_vertex;
attribute vec3 a_normal;

uniform mat4 u_mvpMatrix;
uniform mat4 u_mvMatrix;
uniform mat3 u_normalMatrix;


uniform Light u_light[MAX_LIGHTS];
uniform bool u_lightEnabled[MAX_LIGHTS];

varying vec3 v_lightDir[MAX_LIGHTS];
varying float v_lightAttenuation[MAX_LIGHTS];
varying vec3 v_normal;
varying vec3 v_eyeVec3;

#ifdef TEXTURE_MAPPING_ENABLED
attribute vec2 a_texCoord;

varying mediump vec2 v_texCoord;
#endif


#ifdef ENVIRONMENT_MAPPING_ENABLED
varying mediump vec3 v_envTexCoord;
uniform mat4 u_mInverseView;
#endif

#ifdef SHADOW_MAPPING_ENABLED
varying highp vec4 v_shadowCoord;
uniform vec4 u_shadowCastingLightPosition;
uniform mat4 u_mcToLightMatrix;
#endif

#ifdef SHADOW_MAPPING_DEPTH_ENABLED
varying highp vec4 v_shadowCoord;
uniform vec4 u_shadowCastingLightPosition;
uniform mat4 u_mcToLightMatrix;
#endif


#ifdef SKINNING_ENABLED
attribute mediump vec4 a_boneIndex;
attribute mediump vec4 a_boneWeights;
uniform mediump	int u_boneCount;
uniform highp mat4 u_boneMatrixArray[8];
uniform highp mat3 u_boneMatrixArrayIT[8];
#endif


#ifdef SKINNING_ENABLED
void doSkinning() {
	
	mediump ivec4 boneIndex = ivec4(a_boneIndex);
	mediump vec4 boneWeights = a_boneWeights;
	
	if (u_boneCount > 0) {
		highp mat4 boneMatrix = u_boneMatrixArray[boneIndex.x];
		mediump mat3 normalMatrix = u_boneMatrixArrayIT[boneIndex.x];
        int j;
        
		vertexPosition = boneMatrix * a_vertex * boneWeights.x;
		vertexNormal = normalMatrix * a_normal * boneWeights.x;
		j = 1;
        
		for (int i=1; i<MAX_BONES; i++) {
			if (j >= u_boneCount)
                break;
            
            // "rotate" the vector components
			boneIndex = boneIndex.yzwx;
			boneWeights = boneWeights.yzwx;
            
			boneMatrix = u_boneMatrixArray[boneIndex.x];
			normalMatrix = u_boneMatrixArrayIT[boneIndex.x];
            
			vertexPosition += boneMatrix * a_vertex * boneWeights.x;
			vertexNormal += normalMatrix * a_normal * boneWeights.x;
            
            j++;
		}	
	}	
}
#endif



void main(void) {
	
    

#ifdef SKINNING_ENABLED
	doSkinning();
#else
	vec4 vertexPosition = a_vertex;
	vec3 vertexNormal = a_normal;
#endif

    gl_Position = u_mvpMatrix * vertexPosition;
    
    v_normal = normalize(u_normalMatrix * vertexNormal);

    vec4 ecPosition4 = u_mvMatrix * vertexPosition;
    vec3 ecPosition3 = ecPosition4.xyz / ecPosition4.w;
    
    v_eyeVec3 = -normalize(ecPosition3);
    
    for (int i=0; i<MAX_LIGHTS; i++) {
        if (u_lightEnabled[i]) {
            float attenuation = 1.0;
            if (u_light[i].position.w == 0.0) {
                v_lightDir[i] = -normalize(u_light[i].position.xyz);
            } else {
                vec3 lightVec3 = vec3(u_light[i].position.xyz - ecPosition3);
                v_lightDir[i] = normalize(lightVec3);

                // Distance between the two
                float d = length(lightVec3);
                
                // Calculate attenuation
                vec3 attDist = vec3(1.0, d, d * d);
                attenuation = 1.0 / dot(u_light[i].attenuation, attDist);
                
                // Calculate spot lighting effects
                if (u_light[i].spotCutoffAngle > 0.0) {
                    float spotFactor = dot(-v_lightDir[i], u_light[i].spotDirection);
                    if (spotFactor >= cos(radians(u_light[i].spotCutoffAngle))) {
                        spotFactor = pow(spotFactor, u_light[i].spotFalloffExponent);
                    } else {
                        spotFactor = 0.0;
                    }
                    attenuation *= spotFactor;
                }
            }
            v_lightAttenuation[i] = attenuation;
        }
    }
    
#ifdef TEXTURE_MAPPING_ENABLED
	v_texCoord = a_texCoord;
#endif
    
#ifdef ENVIRONMENT_MAPPING_ENABLED    
//    vec3 vEyeVertex = normalize(vPosition3);
    // reflected vector
//    vec4 vCoords = vec4(reflect(vEyeVertex, vertexNormal), 1.0);
    vec4 vCoords = vec4(reflect(ecPosition3, vertexNormal), 1.0);
    
    // rotate by flipped
    vCoords = u_mInverseView * vCoords;
    v_envTexCoord.xyz = normalize(vCoords.xyz);
#endif

#ifdef SHADOW_MAPPING_ENABLED
	v_shadowCoord = u_mcToLightMatrix * vertexPosition;
#endif

#ifdef SHADOW_MAPPING_DEPTH_ENABLED
	v_shadowCoord = u_mcToLightMatrix * vertexPosition;
#endif
	
}
