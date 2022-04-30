
Shader "FluidSim/RGBtoCMY"
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

			uniform sampler2D RGB;


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
				float3 rgb = tex2D(RGB, IN.uv).xyz;
				float3 cmy = float3(1, 1, 1) - rgb;

				return float4 (cmy,1.f) ;

			}

			ENDCG

		}
	}
}
