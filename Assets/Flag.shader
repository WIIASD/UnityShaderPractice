Shader "Unlit/Flag"
{
    Properties
    {
        _Speed ("Speed", Range(0,1)) = 0.1
        _Amp ("Amplitude", Float) = 0.5
        _Freq ("Frequency", Float) = 5
        _DistortionFreq ("Distortion Frequency", Float) = 1
        _DistortionAmp ("Distortion Amplitude", Float) = 0.5
        _PivotOffset("Pivot Offset", Float) = 0
        _UVOffset("UV Offset", Float) = 0
    }

    CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag

        #define TAU 6.283185307179586

        #include "UnityCG.cginc"

        float _Amp;
        float _Freq;
        float _UVOffset;
        float _PivotOffset;
        float _DistortionFreq;
        float _DistortionAmp;
        float _Speed;

        float remap(float v, float min_v, float max_v, float target_min, float target_max){
            return target_min + (v - min_v) * (target_max - target_min)/(max_v - min_v);
        }

        float sin_wave (float x, float _offset, float frequency, float amplitude){
            return sin((x - _offset) * frequency) * amplitude;
        }

        float inverse_lerp(float a, float b, float v){
            return (v-a)/(b-a);
        }

        float flag(float x, float y, float _offset){
            float distortion_offset = sin(y * _DistortionFreq) * _DistortionAmp;
            float flg = sin_wave(x, _offset - distortion_offset, _Freq, _Amp) ;
            float smooth_flg = flg * x;
            return smooth_flg;
        }

        struct mesh_data
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
        };

        struct vertex_output
        {
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : TEXCOORD1;
        };

        vertex_output vert_shared(mesh_data v){
            vertex_output o;
            if(v.uv.x > _PivotOffset){
                v.uv.x += remap(v.uv.x, _PivotOffset, 1, 0, _UVOffset) - _PivotOffset;
            }else{
                v.uv.x = 0;
            }
            float time_offset = _Time.y * _Speed;
            //time_offset = 0;
            v.vertex.y = flag(v.uv.x, v.uv.y, time_offset);
            //v.vertex.z += v.uv.x * v.uv.x * 0.3;
            //v.vertex.y = 0; 
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv + _UVOffset;
            o.normal = v.normal;
            return o;
        }

        float4 frag_shared (vertex_output i) : SV_Target
        {
            float time_offset = _Time.y * _Speed;
            //time_offset = 0;
            float flg = flag(i.uv.x, i.uv.y, time_offset) * sign(i.normal.y);
            return remap(flg, -_Amp, _Amp, 0, 1);
        }
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        //Front facing pass
        Pass
        {
            Cull Back

            CGPROGRAM

            vertex_output vert (mesh_data v)
            {
                return vert_shared(v);
            }

            float4 frag (vertex_output i) : SV_Target{
                return frag_shared(i);
            }
            
            ENDCG
        }
        
        //Back facing pass
        Pass
        {
            Cull Front

            CGPROGRAM

            vertex_output vert (mesh_data v)
            {
                v.normal *= -1; // flip normal, the only line different from the previous pass
                return vert_shared(v);
            }

            float4 frag (vertex_output i) : SV_Target{
                return frag_shared(i);
            }

            ENDCG
        }
    }
}
