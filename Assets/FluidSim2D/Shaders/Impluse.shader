// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "FluidSim/Impluse" 
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
			
			uniform float2 _Point;
			uniform float _Radius;
			uniform float _Fill; // val passed in 
			uniform sampler2D _Source;
			
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
			    float d = distance(_Point, IN.uv); // get distance from Point of Impulse
			    
				float impulse = 0;
			    
			    if(d < _Radius) // only if in radius
			    {
			        float a = (_Radius - d) * 0.5;
					impulse = min(a, 1.0); // weight of lerp
			    } 

				float source = tex2D(_Source, IN.uv).x;
			  
			  	return max(0, lerp(source, _Fill, impulse)).xxxx; // lerp from current to fill (val/ input)
			}
			
			ENDCG

    	}
	}
}