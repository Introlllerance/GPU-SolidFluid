// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "FluidSim/AddColor" 
{
	SubShader
	{
		Pass
		{
			ZTest Always
			//Blend SrcAlpha OneMinusSrcAlpha 

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			uniform float3 _ColorCMY;

			uniform float2 _Point;
			uniform float _Radius;
			uniform float _Fill; // val passed in 
			uniform sampler2D _Source;
			uniform sampler2D _Density;
			
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
			    float dis = distance(_Point, IN.uv); // get distance from Point of Impulse
			    
				float impulse = 0;

			    float3 sourceCol = tex2D(_Source, IN.uv).xyz;
				float3 result = sourceCol;
			    if(dis < _Radius) // only if in radius
			    {
			        float a = (_Radius - dis) * 0.5;
					impulse = min(a, 1.0) * _Fill; // weight of lerp

					float dens = tex2D(_Density, IN.uv).x;
			  
					if (dens > 0.f && impulse > 0.f)
					{
						result = float3((sourceCol * dens) + (_ColorCMY * impulse)) / float((dens + impulse));
						//result = ((sourceCol   ) + (_ColorCMY  ) / (2.f );
						//result =  (_ColorCMY * (impulse/dens));
						//float3 result = (float3(0,1,1) * impulse * _Fill );


					}
					else if ( dens <= 0)
					{
						result = (_ColorCMY * impulse);
					}
					
					
					return float4(result,1); // lerp from current to fill (val/ input)


			    } 
				else
				{
					return float4(result, 1);
				}

		
			}
			
			ENDCG

    	}
	}
}