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

#define MAX_LIGHTS 3

precision highp float;

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

uniform Light u_light[MAX_LIGHTS];
uniform bool u_lightEnabled[MAX_LIGHTS];
uniform Material u_material;
uniform int u_includeSpecular;
uniform vec4 u_sceneAmbientColor;

varying vec3 v_normal;
varying vec3 v_eyeVec3;
varying vec3 v_lightDir[MAX_LIGHTS];
varying float v_lightAttenuation[MAX_LIGHTS];

#ifdef TEXTURE_MAPPING_ENABLED
varying mediump vec2 v_texCoord;

uniform sampler2D s_texture;
#endif

#ifdef NORMAL_MAPPING_ENABLED
uniform sampler2D s_nm_texture;
#endif

#ifdef SPECULAR_MAPPING_ENABLED
uniform sampler2D s_sm_texture;
#endif

#ifdef ALPHA_TEST_ENABLED
uniform lowp float u_alphaTestValue;
#endif

#ifdef SHADOW_MAPPING_ENABLED
varying highp vec4 v_shadowCoord;
uniform sampler2D s_shadowMap;
const highp vec4 unpackFactors = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
#endif

#ifdef SHADOW_MAPPING_DEPTH_ENABLED
varying highp vec4 v_shadowCoord;
uniform sampler2D s_shadowMap;
#endif

#ifdef ENVIRONMENT_MAPPING_ENABLED
varying mediump vec3 v_envTexCoord;
uniform samplerCube s_em_texture;
uniform	float u_fReflect;
#endif

void main() {
    vec4 ambient = vec4(0.0);
    vec4 diffuse = vec4(0.0);
    vec4 specular = vec4(0.0);
    
    ambient = u_sceneAmbientColor;
    for (int i=0; i<MAX_LIGHTS; ++i) {
        if (u_lightEnabled[i]) {            
            float lambertTerm = dot(v_normal, v_lightDir[i]);
            ambient += u_light[i].ambientColor * v_lightAttenuation[i];
            if (lambertTerm > 0.0) {
                diffuse += u_light[i].diffuseColor * lambertTerm * v_lightAttenuation[i];
                if (u_includeSpecular == 1) {
                    vec3 reflectVector = reflect(-v_lightDir[i], v_normal);
                    float specularFactor = pow(max(dot(reflectVector, v_eyeVec3), 0.0), u_material.shininess);
                    specular += u_light[i].specularColor * specularFactor;
                }
            }
        }
    }
    vec4 ambient_material = u_material.ambientColor;
    vec4 diffuse_material = u_material.diffuseColor;
    
// this is where the blend mode comes in, material vs texture
    lowp vec4 color = vec4(0.0);
#ifdef TEXTURE_MAPPING_ENABLED
    lowp vec4 tex_color = texture2D(s_texture, v_texCoord);
// if decal
    ambient_material = mix(ambient_material, tex_color, tex_color.a);;
    diffuse_material = mix(diffuse_material, tex_color, tex_color.a);;

#endif
    color += ambient * ambient_material;
    color += diffuse * diffuse_material;
    
    color.a = u_material.diffuseColor.a;
    
#ifdef ENVIRONMENT_MAPPING_ENABLED
    lowp vec4 env_color = textureCube(s_em_texture, v_envTexCoord);
    color = mix(color, env_color, u_fReflect);
#endif
    
#ifdef ALPHA_TEST_ENABLED
	if (color.a <= u_alphaTestValue) {
		discard;
	}
#endif
    
#ifdef NORMAL_MAPPING_ENABLED
	lowp vec3 normalAdjusted = normalize(texture2D(s_nm_texture, v_texCoord.st).rgb * 2.0 - 1.0 + v_normal);
	lowp float diffuseIntensity = max(0.0, dot(normalAdjusted, v_lightDir));
	lowp vec3 vReflection        = normalize(reflect(-normalAdjusted, v_lightDir));
	lowp float specularIntensity = max(0.0, dot(normalAdjusted, vReflection));
    
	if (diffuseIntensity > 0.98) {
		highp float fSpec = pow(specularIntensity, 64.0);
		color.rgb = color.rgb + vec3(fSpec);
	}
    color.rgb = color.rgb * diffuseIntensity;
#endif
    
    lowp float shadowFactor = 1.0;

#ifdef SHADOW_MAPPING_ENABLED
    if (v_shadowCoord.w > 0.0) {
        highp vec4 shadowTextureCoordinate = v_shadowCoord / v_shadowCoord.w;
        shadowTextureCoordinate = (shadowTextureCoordinate + 1.0) / 2.0;
        
        const float bias = 0.0005;
        
        highp vec4 packedZValue = texture2D(s_shadowMap, shadowTextureCoordinate.st);
        highp float unpackedZValue = dot(packedZValue,unpackFactors);
        
        if ((unpackedZValue+bias) < shadowTextureCoordinate.z) {
            shadowFactor = 0.5;
            specular = vec4(0.0);
        }
    }
#endif
    
#ifdef SHADOW_MAPPING_DEPTH_ENABLED
    if (v_shadowCoord.w > 0.0) {
        highp vec4 shadowTextureCoordinate = v_shadowCoord / v_shadowCoord.w;
        shadowTextureCoordinate = (shadowTextureCoordinate + 1.0) / 2.0;
        
        float distanceFromLight = texture2D(s_shadowMap, shadowTextureCoordinate.st).z;
        
        const float bias = 0.0005;
        
        if ((distanceFromLight+bias) < shadowTextureCoordinate.z) {
            shadowFactor = 0.5;
            specular = vec4(0.0);
        }
    }
#endif

#ifdef SPECULAR_MAPPING_ENABLED
    specular = specular * texture2D(s_sm_texture, v_texCoord);
#endif

	color = vec4(shadowFactor * (color.rgb + specular.rgb), color.a);
    color = clamp(color, 0.0, 1.0);
    
	gl_FragColor = color;
}