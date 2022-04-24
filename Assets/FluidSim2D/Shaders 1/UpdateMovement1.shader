Shader "FluidSim/UpdateMovement1"
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

			uniform sampler2D _Velocity;
			uniform sampler2D _Density;

			uniform float2 _Point;
			uniform float _Radius;
			uniform float _ImpulsScale;


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
				float2 V = tex2D(_Velocity, IN.uv).xy;
				float D = tex2D(_Density, IN.uv).x;

				float2 dis = (IN.uv - _Point);
				
				float2 result = V;

				if (dis.x * dis.x + dis.y * dis.y < _Radius * _Radius)
				{				
					float2 dir = normalize(dis);
					result = V + dir * _ImpulsScale - D * dir * 2.f;
				}


				return float4(result, 0, 1);

			}

			ENDCG

		}
	}
}
