
Shader "FluidSim/CMYtoRGB"
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

			uniform sampler2D CMY;


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


				float3 cmy = tex2D(CMY, IN.uv).xyz;
				float3 rgb = float3(1, 1, 1) - cmy;

				return float4 (rgb,1.f);
			}

			ENDCG

		}
	}
}