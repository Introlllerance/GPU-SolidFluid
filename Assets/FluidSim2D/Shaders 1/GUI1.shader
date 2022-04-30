// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "FluidSim/GUI1" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
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
			
			sampler2D _MainTex;
			sampler2D _Obstacles;
			float3 _FluidColor, _ObstacleColor;
		
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
			 	float3 col = tex2D(_MainTex, IN.uv).xyz;
			 	
			 	float obs = tex2D(_Obstacles, IN.uv).x;
			 	
				float3 obsColorCMY = float3(1, 1, 1) - _ObstacleColor;
			 	float3 result = lerp(col, obsColorCMY, obs);
			 	
				return float4(result,1);
			}
			
			ENDCG

    	}
	}
}
