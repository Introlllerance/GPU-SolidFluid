
using System.Collections;
using UnityEngine;
using System.Collections.Generic;

namespace FluidSim2DProject
{

    public class Test : MonoBehaviour
    {

        public Color m_fluidColor = Color.red;

        public Color m_obstacleColor = Color.white;
      
        public Material m_guiMat, m_advectMat, m_buoyancyMat, m_updateMovementMat, m_divergenceMat, m_jacobiMat, m_impluseMat, m_gradientMat, m_obstaclesMat;

        RenderTexture m_guiTex, m_divergenceTex;// m_obstaclesTex;
        RenderTexture[] m_velocityTex, m_densityTex, m_pressureTex, m_temperatureTex, m_obstaclesTex;

        [SerializeField] float m_impulseTemperature = 10.0f;
        [SerializeField] float m_impulseDensity = 1.0f;
        [SerializeField] [Range(0.95f, 1.1f)] float m_temperatureDissipation = 0.99f;
        [SerializeField] [Range(0.95f, 1.1f)] float m_velocityDissipation = 0.99f;
        [SerializeField] [Range(0.95f, 1.1f)] float m_densityDissipation = 0.9999f;
        [SerializeField] float m_ambientTemperature = 0.0f;
        [SerializeField] float m_smokeBuoyancy = 1.0f;
        [SerializeField] float m_smokeWeight = 0.05f;

        // Scales For what? 
        float m_cellSize = 1.0f;
        float m_gradientScale = 1.0f;

        Vector2 m_inverseSize;

        [SerializeField] int m_numJacobiIterations = 80;

        // Impuls / Mouseinput
        Vector2 m_implusePos = new Vector2(0.5f, 0.1f);
        [SerializeField] float m_impluseRadius = 0.1f;
        [SerializeField] float m_mouseImpluseRadius = 0.05f;
        [SerializeField] float m_impulseScale = 2.0f;

        // Obstacle 
        public List<Vector2> m_obstaclePos = new List<Vector2>();
   
        float m_obstacleRadius = 0.05f;

        // view field
        Rect m_rect;
        [SerializeField] int m_width = 512;
        [SerializeField] int m_height = 512;
        
 
        void Start()
        {
            // add Obstacles
            m_obstaclePos.Add(new Vector2(0.5f, 0.4f));
            m_obstaclePos.Add(new Vector2(0.5f, 0.7f));
            m_obstaclePos.Add(new Vector2(0.4f, 0.8f));

            Vector2 size = new Vector2(m_width, m_height);
            Vector2 pos = new Vector2(Screen.width / 2, Screen.height / 2) - size * 0.5f;// from the middle of screen to the (0,0)-coor of the rect (caus you need 0 0 pos) 
            m_rect = new Rect(pos, size); // create a rect for the pos of the texture to draw (draw in the rect)

            m_inverseSize = new Vector2(1.0f / m_width, 1.0f / m_height);

            // make rendertexture Array and then indexies for current and next (smart way cleaner and you can change easily) 
            m_velocityTex = new RenderTexture[2];
            m_densityTex = new RenderTexture[2];
            m_temperatureTex = new RenderTexture[2];
            m_pressureTex = new RenderTexture[2];
            m_obstaclesTex = new RenderTexture[2];

            // init/ create Rendertextures
            CreateSurface(m_velocityTex, RenderTextureFormat.RGFloat, FilterMode.Bilinear);
            CreateSurface(m_densityTex, RenderTextureFormat.RFloat, FilterMode.Bilinear);
            CreateSurface(m_temperatureTex, RenderTextureFormat.RFloat, FilterMode.Bilinear);
            CreateSurface(m_pressureTex, RenderTextureFormat.RFloat, FilterMode.Point);
            CreateSurface(m_obstaclesTex, RenderTextureFormat.RFloat, FilterMode.Point);

            // make specific textures 
            m_guiTex = new RenderTexture(m_width, m_height, 0, RenderTextureFormat.ARGB32);
            m_guiTex.filterMode = FilterMode.Bilinear;
            m_guiTex.wrapMode = TextureWrapMode.Clamp;
            m_guiTex.Create();

            m_divergenceTex = new RenderTexture(m_width, m_height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            m_divergenceTex.filterMode = FilterMode.Point;
            m_divergenceTex.wrapMode = TextureWrapMode.Clamp;
            m_divergenceTex.Create();

            //m_obstaclesTex = new RenderTexture(m_width, m_height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            //m_obstaclesTex.filterMode = FilterMode.Point;
            //m_obstaclesTex.wrapMode = TextureWrapMode.Clamp;
            //m_obstaclesTex.Create();
        }

        void OnGUI() // GUI = graphical user interface 
        {
            GUI.DrawTexture(m_rect, m_guiTex);
        }

        void CreateSurface(RenderTexture[] surface, RenderTextureFormat format, FilterMode filter)
        {
            // why do it 2 times manually ???
            surface[0] = new RenderTexture(m_width, m_height, 0, format, RenderTextureReadWrite.Linear); // RenderTextureReadWrite = Color space conversion mode of a RenderTexture. "Linear" Render texture contains linear (non-color) data; don't perform color conversions on it.
            surface[0].filterMode = filter;
            surface[0].wrapMode = TextureWrapMode.Clamp;
            surface[0].Create();

            surface[1] = new RenderTexture(m_width, m_height, 0, format, RenderTextureReadWrite.Linear);
            surface[1].filterMode = filter;
            surface[1].wrapMode = TextureWrapMode.Clamp;
            surface[1].Create();
        }

        void Advect(RenderTexture velocity, RenderTexture source, RenderTexture dest, float dissipation, float timeStep)
        {
            // Advect a texture based on the velocity witth backwardstracing
            // and let the texture dissipate
            m_advectMat.SetVector("_InverseSize", m_inverseSize);
            m_advectMat.SetFloat("_TimeStep", timeStep);
            m_advectMat.SetFloat("_Dissipation", dissipation);
            m_advectMat.SetTexture("_Velocity", velocity);
            m_advectMat.SetTexture("_Source", source);
            m_advectMat.SetTexture("_Obstacles", m_obstaclesTex[0]);

            Graphics.Blit(null, dest, m_advectMat); // copies source into a rendertexture with shader (bit block transfer)
        }

        void ApplyBuoyancy(RenderTexture velocity, RenderTexture temperature, RenderTexture density, RenderTexture dest, float timeStep)
        {
            //Buoyancy based on Temperatur/ smoke ambiente and Density and weight and bouyandyVar 
            m_buoyancyMat.SetTexture("_Velocity", velocity);
            m_buoyancyMat.SetTexture("_Temperature", temperature);
            m_buoyancyMat.SetTexture("_Density", density);
            m_buoyancyMat.SetFloat("_AmbientTemperature", m_ambientTemperature);
            m_buoyancyMat.SetFloat("_TimeStep", timeStep);
            m_buoyancyMat.SetFloat("_Sigma", m_smokeBuoyancy);
            m_buoyancyMat.SetFloat("_Kappa", m_smokeWeight);

            Graphics.Blit(null, dest, m_buoyancyMat);
        }
        void UpdateMovement(RenderTexture velocity, RenderTexture density, RenderTexture dest,Vector2 pos)
        {
            //Buoyancy based on Temperatur/ smoke ambiente and Density and weight and bouyandyVar 
            m_updateMovementMat.SetTexture("_Velocity", velocity);
            m_updateMovementMat.SetTexture("_Density", density);

            m_updateMovementMat.SetVector("_Point", pos);
            m_updateMovementMat.SetFloat("_Radius", m_impluseRadius);
            m_updateMovementMat.SetFloat("_ImpulsScale", m_impulseScale);
        

            Graphics.Blit(null, dest, m_updateMovementMat);
        }


        void ApplyImpulse(RenderTexture source, RenderTexture dest, Vector2 pos, float radius, float val)
        {
            m_impluseMat.SetVector("_Point", pos);
            m_impluseMat.SetFloat("_Radius", radius);
            m_impluseMat.SetFloat("_Fill", val);
            m_impluseMat.SetTexture("_Source", source);

            Graphics.Blit(null, dest, m_impluseMat);
        }

        void ComputeDivergence(RenderTexture velocity, RenderTexture dest)
        {
            m_divergenceMat.SetFloat("_HalfInverseCellSize", 0.5f / m_cellSize);
            m_divergenceMat.SetTexture("_Velocity", velocity);
            m_divergenceMat.SetVector("_InverseSize", m_inverseSize);
            m_divergenceMat.SetTexture("_Obstacles", m_obstaclesTex[0]);

            Graphics.Blit(null, dest, m_divergenceMat);
        }

        void Jacobi(RenderTexture pressure, RenderTexture divergence, RenderTexture dest)
        {

            m_jacobiMat.SetTexture("_Pressure", pressure);
            m_jacobiMat.SetTexture("_Divergence", divergence);
            m_jacobiMat.SetVector("_InverseSize", m_inverseSize);
            m_jacobiMat.SetFloat("_Alpha", -m_cellSize * m_cellSize);
            m_jacobiMat.SetFloat("_InverseBeta", 0.25f);
            m_jacobiMat.SetTexture("_Obstacles", m_obstaclesTex[0]);

            Graphics.Blit(null, dest, m_jacobiMat);
        }

        void SubtractGradient(RenderTexture velocity, RenderTexture pressure, RenderTexture dest)
        {
            m_gradientMat.SetTexture("_Velocity", velocity);
            m_gradientMat.SetTexture("_Pressure", pressure);
            m_gradientMat.SetFloat("_GradientScale", m_gradientScale);
            m_gradientMat.SetVector("_InverseSize", m_inverseSize);
            m_gradientMat.SetTexture("_Obstacles", m_obstaclesTex[0]);

            Graphics.Blit(null, dest, m_gradientMat);
        }

        void AddObstacles()
        {

            // i have to make 2 textures read from one then blit from the other to the material -> swap
            for (int i = 0; i < m_obstaclePos.Count; i++)
            {
                m_obstaclesMat.SetTexture("_Obstacle", m_obstaclesTex[0]);
                m_obstaclesMat.SetVector("_InverseSize", m_inverseSize);
                m_obstaclesMat.SetVector("_Point", m_obstaclePos[i]);
                m_obstaclesMat.SetFloat("_Radius", m_obstacleRadius);
                  
                Graphics.Blit(null, m_obstaclesTex[1], m_obstaclesMat);
                Swap(m_obstaclesTex);

            }

        }

        void ClearSurface(RenderTexture surface)
        {
            Graphics.SetRenderTarget(surface);
            GL.Clear(false, true, new Color(0, 0, 0, 0));
            Graphics.SetRenderTarget(null);
        }

        void Swap(RenderTexture[] texs)
        {
            RenderTexture temp = texs[0];
            texs[0] = texs[1];
            texs[1] = temp;
        }

        void FixedUpdate()
        {
            //Obstacles only need to be added once unless changed.
            AddObstacles();

            //Set the density field and obstacle color.
            m_guiMat.SetColor("_FluidColor", m_fluidColor);
            m_guiMat.SetColor("_ObstacleColor", m_obstacleColor);

            int READ = 0;
            int WRITE = 1;
            float dt = 0.125f;

            /* 
            1. Advect -> Swap
            2. apply buoyancyn??? -> swap
            3. apply Impulse(dens and tempe refresh) -> Swap
            4. apply impulse through mouse -> swap
            5. Project (Divergenze, Clear surface -> Jacobi + swap(gradientfield of pressure) -> Subtract gradient + swap)
            6. Render Texture

            +Check in all function for obstacles/boundary
            */


            //Advect velocity against its self
            Advect(m_velocityTex[READ], m_velocityTex[READ], m_velocityTex[WRITE], m_velocityDissipation, dt);
            //Advect temperature against velocity
            Advect(m_velocityTex[READ], m_temperatureTex[READ], m_temperatureTex[WRITE], m_temperatureDissipation, dt);
            //Advect density against velocity
            Advect(m_velocityTex[READ], m_densityTex[READ], m_densityTex[WRITE], m_densityDissipation, dt);

            Swap(m_velocityTex);
            Swap(m_temperatureTex);
            Swap(m_densityTex);

            // change the velocity of flow based on temperatur and density of fluid
            //ApplyBuoyancy(m_velocityTex[READ], m_temperatureTex[READ], m_densityTex[READ], m_velocityTex[WRITE], dt);

            //Swap(m_velocityTex);

            //Add particles at specific point
            if (false)
            {
                ApplyImpulse(m_temperatureTex[READ], m_velocityTex[WRITE], m_implusePos, m_impluseRadius, m_impulseTemperature);
                ApplyImpulse(m_densityTex[READ], m_densityTex[WRITE], m_implusePos, m_impluseRadius, m_impulseDensity);
                UpdateMovement(m_velocityTex[READ], m_densityTex[READ], m_velocityTex[WRITE], m_implusePos);

                Swap(m_temperatureTex);
                Swap(m_densityTex);
                Swap(m_velocityTex);
            }

            //If left click down add impluse, if right click down remove impulse from mouse pos.
            if(Input.GetMouseButton(0) || Input.GetMouseButton(1))
            {
                Vector2 pos = Input.mousePosition;

                pos.x -= m_rect.xMin;
                pos.y -= m_rect.yMin;

                pos.x /= m_rect.width;
                pos.y /= m_rect.height;

                float sign = (Input.GetMouseButton(0)) ? 1.0f : -1.0f;

                ApplyImpulse(m_temperatureTex[READ], m_temperatureTex[WRITE], pos, m_mouseImpluseRadius, m_impulseTemperature);
                ApplyImpulse(m_densityTex[READ], m_densityTex[WRITE], pos, m_mouseImpluseRadius, m_impulseDensity * sign);
                UpdateMovement(m_velocityTex[READ], m_densityTex[READ], m_velocityTex[WRITE], pos);

                Swap(m_temperatureTex);
                Swap(m_densityTex);
                Swap(m_velocityTex);


            }

            ///////////// Project ////////////////

            //Calculates how divergent the velocity is
            ComputeDivergence(m_velocityTex[READ], m_divergenceTex);

            ClearSurface(m_pressureTex[READ]); // Set Pressure = 0

            int i = 0;
            for (i = 0; i < m_numJacobiIterations; ++i)
            {
                Jacobi(m_pressureTex[READ], m_divergenceTex, m_pressureTex[WRITE]);
                Swap(m_pressureTex);
            }

            //Use the pressure tex that was last rendered into. This computes divergence free velocity
            SubtractGradient(m_velocityTex[READ], m_pressureTex[READ], m_velocityTex[WRITE]);

            Swap(m_velocityTex);

            //Render the tex you want to see into gui tex. Will only use the red channel
            m_guiMat.SetTexture("_Obstacles", m_obstaclesTex[0]);
            Graphics.Blit(m_densityTex[READ], m_guiTex, m_guiMat);
        }
    }

}