Shader "Watercolor"
{
    Properties
    {
        _PaperTex("Paper Texture", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}

        _FlattenStrength("Flatten Strength", Range(0,3)) = 1.2  
        _EdgeStrength("Edge Strength", Range(0,1)) = 0.2
        _NoiseStrength("Noise Strength", Range(0,0.8)) = 0.5
        _PaperStrength("Paper Strength", Range(0,1)) = 0.5       

        _Warmth("Warm Highlights", Range(0,0.8)) = 0
        _Cool("Cool Shadows", Range(0,0.2)) = 0

        _ToonSteps("Toon Steps", Range(2,12)) = 6
        _ToonStrength("Toon Strength", Range(0,1)) = 0.8
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "WatercolorShader"
            ZWrite Off
            ZTest Always
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D(_PaperTex);  SAMPLER(sampler_PaperTex);
            TEXTURE2D(_Noise);     SAMPLER(sampler_Noise);

            float _FlattenStrength;
            float _EdgeStrength;
            float _NoiseStrength;
            float _PaperStrength;
            float _Warmth;
            float _Cool;
            float _ToonSteps;
            float _ToonStrength;

            struct VIn { uint vertexID : SV_VertexID; };
            struct VOut { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

            VOut Vert(VIn i)
            {
                VOut o;
                o.pos = GetFullScreenTriangleVertexPosition(i.vertexID);
                o.uv = GetFullScreenTriangleTexCoord(i.vertexID);
                return o;
            }

            float3 Scene(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv).rgb;
            }

            float3 Flatten(float2 uv)
            {
                float2 tex = _BlitTexture_TexelSize.xy;
                float3 c0 = Scene(uv);

                float3 sum = c0;
                float wsum = 1;

                float radii[3] = { 1.0, 3.0, 6.0 };

                for (int r = 0; r < 3; r++)
                {
                    float2 o = tex * radii[r];
                    float3 ca = Scene(uv + o);
                    float3 cb = Scene(uv - o);

                    float wA = 1.0 / (1.0 + length(ca - c0) * 12);
                    float wB = 1.0 / (1.0 + length(cb - c0) * 12);

                    sum += ca * wA + cb * wB;
                    wsum += wA + wB;
                }

                float3 flat = sum / wsum;
                return lerp(c0, flat, _FlattenStrength);
            }

            float3 PainterToon(float3 col)
            {
                float l = dot(col, float3(0.299,0.587,0.114));
                float stepVal = floor(l * _ToonSteps) / _ToonSteps;
                float3 toon = col * (stepVal / max(l, 0.001));
                return lerp(col, toon, _ToonStrength);
            }

            float3 PainterEdges(float2 uv, float3 col)
            {
                float2 tex = _BlitTexture_TexelSize.xy;

                float3 dx = abs(Scene(uv + float2(tex.x,0)) - Scene(uv - float2(tex.x,0)));
                float3 dy = abs(Scene(uv + float2(0,tex.y)) - Scene(uv - float2(0,tex.y)));

                float edge = saturate((dx.r+dy.r + dx.g+dy.g + dx.b+dy.b) * 1.6);

                float3 q = floor(col * 6) / 6;
                return lerp(col, q, edge * _EdgeStrength);
            }

            float3 Noise(float2 uv, float3 col)
            {
                float n = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, uv * 2).r;

                float noiseFactor = 1.0 + (n - 0.5) * 2.0;

                float3 noisyCol = col * noiseFactor;

                float noiseStrength = min(_NoiseStrength, 0.8);
                return lerp(col, noisyCol, _NoiseStrength);
            }

            float3 WarmCool(float3 col)
            {
                float l = dot(col, float3(0.299, 0.587, 0.114));

                float3 warmHue = float3(1.0, 0.85, 0.70);   
                float3 coolHue = float3(0.70, 0.80, 1.0);  

                float3 target = lerp(coolHue * _Cool, warmHue * _Warmth, l);

                float3 shifted = lerp(col, target, 0.35);  

                return shifted;
            }

            float3 ApplyPaper(float2 uv, float3 col)
            {
                float p = SAMPLE_TEXTURE2D(_PaperTex, sampler_PaperTex, uv * 2).r;

                float paperOffset = (p - 0.5);

                float3 paperEffect = col * (1.0 + paperOffset);

                float paperStrength = min(_PaperStrength, 0.8);
                return lerp(col, paperEffect, _PaperStrength);
            }

            float4 Frag(VOut i) : SV_Target
            {
                float2 uv = i.uv;

                float3 col = Flatten(uv);
                col = PainterToon(col);
                col = PainterEdges(uv, col);
                col = Noise(uv, col);
                col = WarmCool(col);
                col = ApplyPaper(uv, col);

                return float4(col, 1);
            }

            ENDHLSL
        }
    }
}