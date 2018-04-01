#version 330 core

#define MAX_LIGHT_COUNT 10
#define PI 3.1415926535897932384626433832795

struct Light {
  vec4 position;
  vec3 direction;
  vec3 color;
  float angle;
};

uniform uint uniLightCount;
uniform Light uniLights[MAX_LIGHT_COUNT];

uniform vec3 uniCameraPos;

uniform mat4 uniViewProjMatrix;

uniform struct Material {
  float metallicFactor;
  float roughnessFactor;

  sampler2D albedoMap;
  sampler2D normalMap;
  sampler2D metallicMap;
  sampler2D roughnessMap;
  sampler2D ambientOcclusionMap;
} uniMaterial;

in MeshInfo {
  vec3 vertPosition;
  vec2 vertTexcoords;
  vec3 vertNormal;
} fragMeshInfo;
in vec3 fragNormal;

layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec3 bufferNormal;

// Normal Distribution Function: Trowbridge-Reitz GGX
float computeNormalDistrib(vec3 normal, vec3 halfVec, float roughness) {
  float sqrRough  = roughness * roughness;
  float frthRough = sqrRough * sqrRough;

  float halfVecAngle    = max(dot(halfVec, normal), 0.0);
  float sqrHalfVecAngle = halfVecAngle * halfVecAngle;

  float divider = (sqrHalfVecAngle * (frthRough - 1.0) + 1.0);
  divider       = PI * divider * divider;

  return sqrRough / divider;
}

// Fresnel: Shlick
vec3 computeFresnel(float cosTheta, vec3 baseReflectivity) {
  return baseReflectivity + (1.0 - baseReflectivity) * pow(1.0 - cosTheta, 5.0);
}

// Shlick GGX for Geometry part
float computeShlickGGX(float viewAngle, float roughness) {
  float incrRough   = (roughness + 1.0);
  float roughFactor = (incrRough * incrRough) / 8.0;

  float denom = viewAngle * (1.0 - roughFactor) + roughFactor;

  return viewAngle / denom;
}

// Geometry: Smith's Shlick GGX
float computeGeometry(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
  float viewAngle  = max(dot(viewDir, normal), 0.0);
  float lightAngle = max(dot(lightDir, normal), 0.0);

  float ggx1       = computeShlickGGX(viewAngle, roughness);
  float ggx2       = computeShlickGGX(lightAngle, roughness);

  return ggx1 * ggx2;
}

void main() {
  bufferNormal = normalize(fragNormal);

  vec3 albedo     = pow(texture(uniMaterial.albedoMap, fragMeshInfo.vertTexcoords).rgb, vec3(2.2)); // Gamma correction (sRGB presumed)
  float metallic  = texture(uniMaterial.metallicMap, fragMeshInfo.vertTexcoords).r;
  float roughness = texture(uniMaterial.roughnessMap, fragMeshInfo.vertTexcoords).r;
  float ambOcc    = texture(uniMaterial.ambientOcclusionMap, fragMeshInfo.vertTexcoords).r;

  vec3 normal  = normalize(fragMeshInfo.vertNormal);
  vec3 viewDir = normalize(uniCameraPos - fragMeshInfo.vertPosition);

  // Base Fresnel (F)
  vec3 baseReflectivity = mix(vec3(0.04), albedo, metallic);

  vec3 lightRadiance = vec3(0.0);

  for (uint lightIndex = 0u; lightIndex < uniLightCount; ++lightIndex) {
    vec3 fullLightDir;

    if (uniLights[lightIndex].position.w != 0.0) {
      fullLightDir = uniLights[lightIndex].position.xyz - fragMeshInfo.vertPosition;
    } else {
      fullLightDir = -uniLights[lightIndex].direction;
    }

    float distance    = length(fullLightDir);
    float attenuation = 1.0 / (distance * distance);

    vec3 lightDir = normalize(fullLightDir);
    vec3 halfDir  = normalize(viewDir + lightDir);
    vec3 radiance = uniLights[lightIndex].color * attenuation;

    // Normal distrib (D)
    float normalDistrib = computeNormalDistrib(normal, halfDir, roughness);

    // Fresnel (F)
    vec3 fresnel = computeFresnel(max(dot(halfDir, viewDir), 0.0), baseReflectivity);

    // Geometry (G)
    float geometry = computeGeometry(normal, viewDir, lightDir, roughness);

    vec3 DFG      = normalDistrib * fresnel * geometry;
    float divider = 4.0 * max(dot(viewDir, normal), 0.0) * max(dot(lightDir, normal), 0.0);
    vec3 specular = DFG / max(divider, 0.001);

    vec3 diffuse = vec3(1.0) - fresnel;
    diffuse     *= 1.0 - metallic;

    lightRadiance += (diffuse * albedo / PI + specular) * radiance * max(dot(lightDir, normal), 0.0);
  }

  vec3 ambient = vec3(0.03) * albedo/* * ambOcc*/;
  vec3 color   = ambient + lightRadiance;

  // HDR tone mapping
  color = color / (color + vec3(1.0));
  // Gamma correction
  color = pow(color, vec3(1.0 / 2.2));

  fragColor = vec4(color, 1.0);
}