// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "FluidSim/Advect" // decleration (where to find / Name)
{
	SubShader // most of the logic
	{
    	Pass // can have multiple passes has multiple affects
    	{
			ZTest Always

			CGPROGRAM // what is a CG Programm?
			#include "UnityCG.cginc"
			#pragma target 3.0
			#pragma vertex vert		// define the vertex shader function
			#pragma fragment frag   // frag define 
			
			uniform sampler2D _Velocity;
			uniform sampler2D _Source;
			uniform sampler2D _Obstacles;
			
			uniform float2 _InverseSize;
			uniform float _TimeStep;
			uniform float _Dissipation;
		
			// what vertex function is going to need or is it the output???
						// i think its output
			struct v2f
			{
				float4  pos : SV_POSITION;
				float2  uv : TEXCOORD0;
			};

			v2f vert(appdata_base v)   // output v2f
			{
    			v2f OUT; // create a v2f var -> that gets returned 
    			OUT.pos = UnityObjectToClipPos(v.vertex); // translate pos to ...???
    			OUT.uv = v.texcoord.xy;
    			return OUT;
			}
			
			float4 frag(v2f IN) : COLOR   // ragment function input is the output from vertex Semantic? is Color
			{
			
			    float2 u = tex2D(_Velocity, IN.uv).xy; // vel at current pos
			    
			    float2 coord = IN.uv - (u * _InverseSize * _TimeStep);   // backwardstracing 
			    
			    float4 result = _Dissipation * tex2D(_Source, coord);// tex2d gives back the value of the sample2D at the coords
				// but how does it take the everage of all textures 
			    
				float solid = tex2D(_Obstacles, IN.uv).x;
			    
				if (solid > 0.0) result = float4(0, 0, 0, 0);

			    return result;
			}
			
			ENDCG

    	}
	}
}