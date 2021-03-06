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

precision highp float;


#define MAX_LIGHTS 4
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

struct Material {
	vec4 ambientColor;
	vec4 diffuseColor;
	vec4 specularColor;
	float shininess;
};

attribute vec4 a_vertex;
attribute vec3 a_normal;

uniform mat4 u_mvpMatrix;
uniform mat4 u_mvMatrix;
uniform mat3 u_normalMatrix;

uniform vec4 u_sceneAmbientColor;

uniform Material u_material;
uniform Light u_light[MAX_LIGHTS];
uniform bool u_lightEnabled[MAX_LIGHTS];

uniform bool u_includeSpecular;
uniform bool u_lightingEnabled;

varying lowp vec4 v_color;
varying lowp vec4 v_specular;


#ifdef TEXTURE_MAPPING_ENABLED
attribute vec2 a_texCoord;

varying mediump vec2 v_texCoord;
#endif

#ifdef NORMAL_MAPPING_ENABLED
varying vec3 v_normal;
varying vec3 v_lightDir;
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


vec3 ecPosition3;
vec3 normal;
vec3 eye;
vec4 vertexPosition;
vec3 vertexNormal;


void pointLight(const in Light light,
                const in vec3 eye,
                const in vec3 ecPosition3,
                const in vec3 normal,
				inout vec4 ambient,
				inout vec4 diffuse,
				inout vec4 specular) {
    
	float nDotVP;
	float eDotRV;
	float pf;
	float attenuation;
	float d;
	vec3 VP;
	vec3 reflectVector;
    
    
	// Check if light source is NOT directional or constant attenuation is NOT 1.0
//    if (light.position.w == 0.0 || light.attenuation.x == 1.0) {
    if (light.position.w == 0.0) {
        attenuation = 1.0;
		VP = light.position.xyz;
        VP = normalize(VP); // added
    } else {
		// Vector between light position and vertex
		VP = vec3(light.position.xyz - ecPosition3);
		
		// Distance between the two
		d = length(VP);
		
		// Normalise
		VP = normalize(VP);
        attenuation = 1.0;

		// Calculate attenuation
		vec3 attDist = vec3(1.0, d, d * d);
		attenuation = 1.0 / dot(light.attenuation, attDist);
        
		// Calculate spot lighting effects
		if (light.spotCutoffAngle > 0.0) {
			float spotFactor = dot(-VP, light.spotDirection);
			if (spotFactor >= cos(radians(light.spotCutoffAngle))) {
				spotFactor = pow(spotFactor, light.spotFalloffExponent);
                
			} else {
				spotFactor = 0.0;
			}
			attenuation *= spotFactor;
		}

	}
    
	// angle between normal and light-vertex vector    
	nDotVP = max(0.0, dot(VP, normal));
    
 	ambient += light.ambientColor * attenuation;
	if (nDotVP > 0.0) {
		diffuse += light.diffuseColor * (nDotVP * attenuation);;

		if (u_includeSpecular) {
			// reflected vector (i.e. half-vector)
			reflectVector = normalize(reflect(-VP, normal));
			
			// angle between eye and reflected vector
			eDotRV = max(0.0, dot(normal, reflectVector));
			pf = pow(eDotRV, 128.0 * u_material.shininess); // is shininess a clamped float?
			specular += light.specularColor * (pf * attenuation);
		}
	}
	
}

void doLighting() {
	vec4 amb = vec4(0.0);
	vec4 diff = vec4(0.0);
	vec4 spec = vec4(0.0);
    
	if (u_lightingEnabled) {
        
        vec4 ecPosition4 = u_mvMatrix * vertexPosition;
		ecPosition3 = ecPosition4.xyz / ecPosition4.w;
        
        normal = u_normalMatrix * vertexNormal;
        
        eye = -normalize(ecPosition3);
		normal = normalize(normal);
        
        for (int i=0; i<MAX_LIGHTS; i++) {
            if (u_lightEnabled[i]) {
                pointLight(u_light[i], eye, ecPosition3, normal, amb, diff, spec);
            }
        }
		v_color.rgb = (u_sceneAmbientColor.rgb + amb.rgb) * u_material.ambientColor.rgb + diff.rgb * u_material.diffuseColor.rgb;
		v_color.a = u_material.diffuseColor.a; // why do we separate alpha here?
		
		v_color = clamp(v_color, 0.0, 1.0);
		v_specular.rgb = spec.rgb * u_material.specularColor.rgb;
		v_specular.a = u_material.specularColor.a;
		
	} else {
		v_color = u_material.diffuseColor;
		v_specular = spec;
	}
}

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
	vertexPosition = a_vertex;
	vertexNormal = a_normal;
#endif
	
	doLighting();
    
#ifdef TEXTURE_MAPPING_ENABLED
	v_texCoord = a_texCoord;
#endif
	
#ifdef NORMAL_MAPPING_ENABLED
    v_normal = u_normalMatrix * a_normal;
#endif
    
#if defined(NORMAL_MAPPING_ENABLED) || defined(ENVIRONMENT_MAPPING_ENABLED)
    vec4 vPosition4 = u_mvMatrix * vertexPosition;
    vec3 vPosition3 = vPosition4.xyz / vPosition4.w;
#endif
    
#ifdef NORMAL_MAPPING_ENABLED
    v_lightDir = normalize(u_light[0].position.xyz - vPosition3);
#endif
    
#ifdef ENVIRONMENT_MAPPING_ENABLED    
//    vec3 vEyeVertex = normalize(vPosition3);
    // reflected vector
//    vec4 vCoords = vec4(reflect(vEyeVertex, vertexNormal), 1.0);
    vec4 vCoords = vec4(reflect(vPosition3, vertexNormal), 1.0);
    
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
	
	gl_Position = u_mvpMatrix * vertexPosition;
}
