﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Custom/fire" {
		Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Scale ("Scale", Vector) = (1,1,1)
		_Translate ("Translate", Vector) = (1,1,1)

		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
	Pass {
		Cull front
    	Blend SrcAlpha OneMinusSrcAlpha
		CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			
			float3 _Scale;
			float3 _Translate;

			struct v2f 
			{
    			float4 pos : SV_POSITION;
    			float3 worldPos : TEXCOORD0;
			};

			struct Ray
			{
				float3 origin;
				float3 dir;
			};

			struct BBox {
			    float3 Min;
			    float3 Max;
			};

			//find intersection points of a ray with a box
			bool intersectBox(Ray r, BBox aabb, out float t0, out float t1)
			{
			    float3 invR = 1.0 / r.dir;
			    float3 tbot = invR * (aabb.Min-r.origin);
			    float3 ttop = invR * (aabb.Max-r.origin);
			    float3 tmin = min(ttop, tbot);
			    float3 tmax = max(ttop, tbot);
			    float2 t = max(tmin.xx, tmin.yz);
			    t0 = max(t.x, t.y);
			    t = min(tmax.xx, tmax.yz);
			    t1 = min(t.x, t.y);
			    return t0 <= t1;
			}

			bool sampleColor(float3 pos) {
				return length(pos - _Translate) < 0.5f;
			}


			// Vertex Shader
			v2f vert(appdata_base v)
			{
    			v2f OUT;
    			OUT.pos = UnityObjectToClipPos(v.vertex);
    			OUT.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    			return OUT;
			}
	
			// Fragment Shader
			float4 frag(v2f IN) : COLOR
			{
				float3 cameraPos = _WorldSpaceCameraPos;
				float3 direction = normalize(IN.worldPos - cameraPos);
				
				Ray ray;
				ray.origin = cameraPos;
				ray.dir = direction;

				float near, far;
				BBox bbox;
				bbox.Min = float3(-0.5,-0.5,-0.5)*_Scale + _Translate;
				bbox.Max = float3(0.5,0.5,0.5)*_Scale + _Translate;

				intersectBox(ray, bbox, near, far);

				// Ray marching
				float3 rayStart = ray.origin + ray.dir * near;
				float3 rayEnd = ray.origin + ray.dir * far;

				float stepSize = 0.1f; // TODO: Change stepSize
				
				float dist = length(rayEnd - rayStart);
				float3 ds = normalize(rayEnd - rayStart) * stepSize;
				int numStep = dist / stepSize;
				
				float3 rayPos = rayStart;
				for (int i = 0; i < numStep; i++, rayPos += ds) {
					if (sampleColor(rayPos)) {
						return float4(1.0, 1.0, 1.0, 1.0);
					}
				}

				return float4(1.0, 0.0, 0.0, 1.0);
			}
			
			ENDCG
	}	
	}
}
