// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "FluidSim/Jacobi" 
{
	SubShader 
	{
    	Pass 
    	{
			ZTest Always

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			
			uniform sampler2D _Pressure;
			uniform sampler2D _Divergence;
			uniform sampler2D _Obstacles;
			
			uniform float _Alpha;
			uniform float _InverseBeta;
			uniform float2 _InverseSize;
			
			struct v2f 
			{
    			float4  pos : SV_POSITION;
    			float2  uv : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
    			v2f OUT;
    			OUT.pos = UnityObjectToClipPos(v.vertex);
    			OUT.uv = v.texcoord.xy;
    			return OUT;
			}
			
			float4 frag(v2f IN) : COLOR
			{
			    // Find neighboring pressure:
			    float pN = tex2D(_Pressure, IN.uv + float2(0, _InverseSize.y)).x;
			    float pS = tex2D(_Pressure, IN.uv + float2(0, -_InverseSize.y)).x;
			    float pE = tex2D(_Pressure, IN.uv + float2(_InverseSize.x, 0)).x;
			    float pW = tex2D(_Pressure, IN.uv + float2(-_InverseSize.x, 0)).x;
			    float pC = tex2D(_Pressure, IN.uv).x;
			
			    // Find neighboring obstacles:
			    float bN = tex2D(_Obstacles, IN.uv + float2(0, _InverseSize.y)).x;
			    float bS = tex2D(_Obstacles, IN.uv + float2(0, -_InverseSize.y)).x;
			    float bE = tex2D(_Obstacles, IN.uv + float2(_InverseSize.x, 0)).x;
			    float bW = tex2D(_Obstacles, IN.uv + float2(-_InverseSize.x, 0)).x;
			
			    // Use center pressure for solid cells:
			    if(bN > 0.0) pN = pC;
			    if(bS > 0.0) pS = pC;
			    if(bE > 0.0) pE = pC;
			    if(bW > 0.0) pW = pC;
			
			    float bC = tex2D(_Divergence, IN.uv).x; // boundary current
			    
			    return (pW + pE + pS + pN + _Alpha * bC) * _InverseBeta; // Jacobi 
			}
			
			ENDCG

    	}
	}
}