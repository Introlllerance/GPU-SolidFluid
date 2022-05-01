// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "FluidSim/AdvectColor" // decleration (where to find / Name)
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
			uniform sampler2D _Density;
			
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
			

			float4 frag(v2f IN) : COLOR   // fragment function input is the output from vertex Semantic? is Color
			{
				float2 offset = 1.0 / _ScreenParams.xy;

			    float2 u = tex2D(_Velocity, IN.uv).xy; // vel at current pos
			    
			    float2 coordB = IN.uv - (u * _InverseSize * _TimeStep);   // backwardstracing 
			    
				// linear interpolate

			
				float3 col00, col01, col10, col11, colCenter; 
				float d00, d01, d10, d11, dCenter; 


				colCenter = tex2D(_Source, (coordB)).xyz;
				col00 = tex2D(_Source, (coordB + float2(0, offset.y))).xyz;
				col01 = tex2D(_Source, (coordB + float2(offset.x, 0))).xyz;
				col10 = tex2D(_Source, (coordB + float2(0, -offset.y))).xyz;
				col11 = tex2D(_Source, (coordB + float2(-offset.x, 0))).xyz;
				
				dCenter = tex2D(_Density, (coordB));
				d00 = tex2D(_Density, (coordB + float2(0 , offset.y)));
				d01 = tex2D(_Density, (coordB + float2(offset.x, 0)));
				d10 = tex2D(_Density, (coordB + float2(0 , -offset.y)));
				d11 = tex2D(_Density, (coordB + float2(-offset.x, 0)));


				//float a = (dCenter * .5f + d00 * .125f + d01 * .125f + d10 * .125f + d11 * *.125f) / 5.f;
				float3 colMixed = float3(1, 1, 1);// is black, when no density

				// can make a white edge, if the value is larger
				if (dCenter > 0.00001f)
				{				
					float a = (dCenter + d00 + d01 + d10 + d11) / 5.f;

					colMixed = (colCenter * .5f * dCenter / a) + (col00 * .125f * d00 / a) + (col01 * .125f * d01 / a) + (col10 * .125f * d10 / a) + (col11 * .125f * d11 / a);
					//float3 colMixed = (colCenter * .5f ) + (col00 * .125f ) + (col01 * .125f ) + (col10 * .125f ) + (col11 * .125f);
				}
				
			    //float4 result = _Dissipation * tex2D(_Source, (coord));// tex2d gives back the value of the sample2D at the coords (interpolates)
				// but how does it take the everage of all textures 
			    
				//result = tex2D(_Source, (coordB ));


				colMixed = float3(max(0, min(1, colMixed.x)), max(0, min(1, colMixed.y)), max(0, min(1, colMixed.z)));


				float4 result = float4(colMixed, 1);
				

				// check for obstacles 
				float solid = tex2D(_Obstacles, IN.uv).x;
			    
				if (solid > 0.0) result = float4(0, 0, 0, 0);

			    return result;
			}
			
			ENDCG

    	}
	}
}