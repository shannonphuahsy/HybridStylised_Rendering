Shader "Custom/ToonShader"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        _ShadowThreshold ("Shadow Threshold", Range(0,1)) = 0.5
        _ShadowSmooth ("Shadow Smoothness", Range(0.001,0.3)) = 0.08
        _ShadowColor ("Shadow Color", Color) = (0.75,0.75,0.8,1)

        _ToonSteps ("Toon Steps", Range(1,8)) = 2  

        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Range(0,1)) = 0.05

        _InnerLineColor ("Inner Line Color", Color) = (0,0,0,1)
        _InnerLineStrength ("Inner Line Strength", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }


        Pass
        {
            Name "Outline"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float _OutlineWidth;
            float4 _OutlineColor;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                float width = min(_OutlineWidth, 0.1);
                positionWS += normalWS * width;
                OUT.positionCS = TransformWorldToHClip(positionWS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            float4 _BaseColor;
            float _ShadowThreshold;
            float _ShadowSmooth;
            float4 _ShadowColor;
            float _ToonSteps; 
            float4 _InnerLineColor;
            float _InnerLineStrength;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float2 uv         : TEXCOORD2;
                float4 shadowCoord: TEXCOORD3;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionCS = TransformWorldToHClip(positionWS);
                OUT.positionWS = positionWS;
                OUT.normalWS = normalize(normalWS);
                OUT.uv = IN.uv;
                OUT.shadowCoord = TransformWorldToShadowCoord(positionWS);

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                float3 viewDir = normalize(GetWorldSpaceViewDir(IN.positionWS));
                Light mainLight = GetMainLight(IN.shadowCoord);
                float3 lightDir = normalize(mainLight.direction);

                float NdotL = dot(normal, lightDir);
                float shadowThreshold = min(_ShadowThreshold, 0.8);

                float lightBand = smoothstep(
                    shadowThreshold - _ShadowSmooth,
                    shadowThreshold + _ShadowSmooth,
                    NdotL
                );

                lightBand = floor(lightBand * _ToonSteps) / _ToonSteps;

                lightBand *= mainLight.shadowAttenuation;

                float4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float3 baseColor = tex.rgb * _BaseColor.rgb;

                float3 shaded = lerp(_ShadowColor.rgb * baseColor, baseColor, lightBand);

  
                float3 dx = ddx(normal);
                float3 dy = ddy(normal);
                float curvature = saturate(length(dx) + length(dy));
                float curvatureLine = smoothstep(0.1, 0.3, curvature);

                float3 tex_dx = ddx(tex.rgb);
                float3 tex_dy = ddy(tex.rgb);
                float textureContrast = length(tex_dx) + length(tex_dy);
                float textureLine = smoothstep(0.05, 0.2, textureContrast);

                float combinedLine = saturate(curvatureLine + textureLine);

                shaded = lerp(shaded, _InnerLineColor.rgb, combinedLine * _InnerLineStrength);

                return float4(shaded, tex.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}
