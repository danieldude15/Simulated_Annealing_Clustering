using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// This code simulate the visualization of a graph using a simulated annealing appraoch. 
/// The hope behind this project is that proper visualization might also provide good clustering to 
/// some extent.
/// This project uses MonoGame library(open source rejuvenated XNA, which is microsoft long dead c# graphcis api) for 
/// its drawing api.
/// </summary>

namespace Game1
{
  
    public class Game1 : Game
    {
        //window:     
        int window_width = 1920;
        int window_height = 1080;
        /// <summary>
        /// A private inside class to help represent the graph.
        /// </summary>
        private class Graph
        {
            int window_width = 1920;
            int window_height = 1080;
            //Elements of a graph:
            public int       _numberOfVertexes;
            public Vector2[] _vertexesPositions;
            public int [,]   _edgesMatrix;
            public List<int>[] _edgesList;
            public int[] edgesArray;
            public Color[] clusters; // assign each vertex with its own color according to its cluster

            public Graph(int vertexNum, string[] edgesData,String [] vertexesClusters)
            {
                Random rnd = new Random();
                _numberOfVertexes = vertexNum;
                _vertexesPositions = new Vector2[vertexNum];
                _edgesMatrix = new int[vertexNum,vertexNum];//Integer arrays are initialized to 0 by default.
                _edgesList = new List<int>[vertexNum];
                edgesArray = new int[edgesData.Length];
                clusters = new Color[vertexNum];
                for (int i=0;i<vertexNum;i++)
                {
                    _edgesList[i] = new List<int>(vertexNum);
                }
                //parse edges
                for (int i = 0; i < edgesData.Length/2; i += 2)
                {
                    int m = int.Parse(edgesData[i])-1;
                    int k = int.Parse(edgesData[i+1])-1;
                    _edgesMatrix[m,k] = _edgesMatrix[m,k] | 1;
                    _edgesMatrix[k, m] = _edgesMatrix[k, m] | 1;
                    _edgesList[m].Add(k);
                    _edgesList[k].Add(m);
                    edgesArray[i] = m;
                    edgesArray[i + 1] = k; 

                }
                //random init each vertex pos
                for (int i=0;i< this._numberOfVertexes; i++)
                {
                    int posX = rnd.Next(0, window_width);
                    int posY = rnd.Next(0, window_height);
                    _vertexesPositions[i] = new Vector2(posX, posY);
                    switch(int.Parse(vertexesClusters[i]))
                    {
                        case 1:
                            clusters[i] = Color.Chocolate; break;
                        case 2:
                            clusters[i] = Color.Black; break;
                        case 3:
                            clusters[i] = Color.Blue; break;
                        case 4:
                            clusters[i] = Color.Red; break;
                        case 5:
                            clusters[i] = Color.LemonChiffon; break;
                        case 6:
                            clusters[i] = Color.Coral; break;
                        default: break;
                    }
                }
            }
        }   
        //################################################################################

   
        //graphics:
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        Texture2D node_Tex; // the texture of the node. Right now its basiclly a purple rectengle
        Random rnd; 

        Graph HW2_Graph; // the object which holds the information of the graph

        public Game1()
        {   
            graphics = new GraphicsDeviceManager(this);
            graphics.IsFullScreen = true;
            graphics.PreferredBackBufferWidth = 3840;
            graphics.PreferredBackBufferHeight = 2160;
            Content.RootDirectory = "Content";
        }
        //--------------------------------------------------------------------------------------------------------
        protected override void Initialize()
        {
            // TODO: Add your initialization logic here

            base.Initialize();
            node_Tex = Content.Load<Texture2D>("test");
            rnd = new Random(); 
            HW2_Graph = parseNetwork(); // this parses the network file and also creates an initial solution
            HW2_Graph._vertexesPositions = SimulatedAnnealing(HW2_Graph);
        }
        //---------------------------------------------------------------------------------------------------------
        /// <summary>
        /// This is the core of the software, as its the algorithm which bend the solution and hopefully
        /// do so in a meaningful way by moving the nodes in the correct way. 
        /// The solution is thereby the positions of the nodes inside the graph.
        /// input: a graph which already has random positions for each node.
        /// algorithm: the function try to surf the solution space and reach solution nearby the global minimum
        /// output: The best positions for the nodes of the given graph.
        /// </summary>
        /// <param name="graph"></param>
        private Vector2[] SimulatedAnnealing(Graph graph)
        {
            int tempMax = 100;
            int tempMin = 1;
            int imax = 120*graph._numberOfVertexes;// *graph._numberOfVertexes;
            double coolingEffect = 0.95;
            double eular = 2.71828; // eular number
            int K = 5;
            double radius = window_width ;

            Random rnd = new Random();
            Vector2[] Eold;
            Vector2[] Enew;
            Eold = graph._vertexesPositions;
            
            for (int temp = tempMax; temp >= tempMin; temp =(int)((double)temp* coolingEffect))
            {
                Console.WriteLine("Temp: {0}", temp);
                Console.WriteLine("Best cost so far: {0}", cost(Eold));
                radius = Math.Max(200,radius -50);
         
                for (int i = 0; i < imax; i++)
                {
                    Enew = succesor_func(Eold, (int)radius);
                    double delta = cost(Enew) - cost(Eold);

                    //if the solution is bad:
                    if (delta > 0)
                    {
                        if (! (rnd.Next() >= Math.Pow(eular, (-delta / K * temp)))) //choose weather or not to take it 
                        {
                            //accapt bad answear
                            copySolution(Enew, Eold); // Eold = Enew;  
                        }
                    }
                    // if the new solution is better
                    else
                    {
                        //always accept good moves
                        copySolution(Enew, Eold);// Eold = Enew; 
                    }
                }
               // imax += 10;

            }
            Vector2[] finalPositions = new Vector2[graph._numberOfVertexes];
            copySolution(Eold, finalPositions);
            return finalPositions;
        }
        //-----------------------------------------------------------------------------------
        //estimate how good the solution is
        private double cost(Vector2[] solution)
        {
            double g1 = 80000000;        double n1 = 0;
            double g2 = 10;          double n2 = 0;
            double g3 = 0.1;         double n3 = 0;
            double g4 = 0;          double n4 = 0;


            
          
           double distanceSqaure;
            double sub1; double sub2;
            for (int i=0;i<solution.Length;i++)
            {
                for(int j=i;j< solution.Length;j++)
                {
                    if (j != i)
                    {
                        sub1 = (solution[i].X - solution[j].X);
                        sub1 *= sub1;                        //sub1 = (Xi-Xj)^2
                        sub2 = (solution[i].Y - solution[j].Y);
                        sub2 *= sub2;                         //sub1 = (Yi-Yj)^2

                        distanceSqaure = sub1 + sub2;
                        if (distanceSqaure != 0)
                        { 
                        double toAdd = (1 / distanceSqaure);
                        n1 += toAdd;
                        }
                    }
                }
            }
            foreach (Vector2 vec in solution)
            {
                double r1 = 1 / ((vec.X - 0));
                double r2 = 1 / ((window_width - vec.X));
                double r3 = 1 / ((vec.Y - 0));
                double r4 = 1 / ((window_height - vec.Y));
                n2 += r1 * r1 + r2 * r2 + r3 * r3 + r4 * r4;
            }
            //  double score = g1 * n1 + g2 * n2 + g3 * n3+ g4*n4;
            for (int i=0;i<(HW2_Graph.edgesArray.Length)/2;i+=2)
            {
                sub1 = (solution[HW2_Graph.edgesArray[i]].X - solution[HW2_Graph.edgesArray[i + 1]].X);
                sub1 *= sub1;                        //sub1 = (Xi-Xj)^2
                sub2 = (solution[HW2_Graph.edgesArray[i]].Y - solution[HW2_Graph.edgesArray[i + 1]].Y);
                sub2 *= sub2;                         //sub1 = (Yi-Yj)^2
                distanceSqaure = sub1 + sub2;
                n3 += distanceSqaure;
            }
            /*
            int len = HW2_Graph.edgesArray.Length;
            int vertex1; int vertex2;
            int vertex3; int vertex4;
            Vector2 p1; Vector2 p2;
            Vector2 q1; Vector2 q2;
            for (int i = 0; i < (len / 2); i += 2)
            {
                for (int j = i; j < (len / 2); j += 2)
                {
                    if (i != j)
                    {
                        vertex1 = HW2_Graph.edgesArray[j];
                        vertex2 = HW2_Graph.edgesArray[i + 1];
                        vertex3 = HW2_Graph.edgesArray[j];
                        vertex4 = HW2_Graph.edgesArray[j + 1];

                        p1 = solution[vertex1]; p2 = solution[vertex2];
                        q1 = solution[vertex3]; q2 = solution[vertex4];

                        if (FindIntersection(p1, p2, q1, q2)) n4++;
                        //if (doIntersect(p1, p2, q1, q2)) n4++;
                        //   Console.WriteLine("n4 = {0}", n4);
                    }
                }
            }*/
        //    Console.WriteLine("N1*g1 = {0}", n1 * g1);
        //    Console.WriteLine("N3*g3 = {0}", n3*g3);

            double score = n1*g1 + n2*g2+ n3*g3 + n4*g4;
            //double score = n4;
            return score;
        }
        //-----------------------------------------------------------------------------------
        private Vector2[] succesor_func(Vector2[] currentPositions,int circleRadius)
        {

            int len = currentPositions.Length;
            float newPosX, newPosY;
            //The new solution
            Vector2[] suggestedPositions = new Vector2[len];

            //copy all elements:
            for (int i = 0; i < len; i++)
            {
                suggestedPositions[i] = new Vector2(currentPositions[i].X, currentPositions[i].Y);
                if (false)
                {
                    if (chance(0.03))
                    {
                        newPosX = rnd.Next(0, window_width);
                        newPosY = rnd.Next(0, window_height);
                        suggestedPositions[i] = new Vector2(newPosX, newPosY);
                    }
                }
            }

            if (true)
            {
                //change a random vertex location:
                int vertexToMoveIndex = rnd.Next(0, len - 1);
                double maxDistance = circleRadius;
                double distance;

               do
                {
                    newPosX = rnd.Next(0, window_width);
                    newPosY = rnd.Next(0, window_height);
                    float aDist = newPosX - suggestedPositions[vertexToMoveIndex].X;
                    float bDist = newPosY - suggestedPositions[vertexToMoveIndex].Y;
                    distance = Math.Sqrt(aDist * aDist + bDist * bDist);
                }
                while (distance > maxDistance);
                suggestedPositions[vertexToMoveIndex] = new Vector2(newPosX, newPosY);
            }
            return suggestedPositions;
        }
        //---------------------------------------------------------------------------------------------
        /// <summary>
        /// Copy values from the source vectors array to the destination vectors array
        /// </summary>
        /// <param name="src"></param>
        /// <param name="des"></param>
        void copySolution(Vector2[] src, Vector2[] des)
        {
            for(int i=0; i< src.Length;i++)
            {
                des[i].X = src[i].X;
                des[i].Y = src[i].Y;
            }
        }
        //----------------------------------------------------------------------------------------------
        private Boolean chance(double percent)
        {
            int integerPerc = (int)(percent * 100);
            Random rnd = new Random();
          //  int newFactor = rnd.Next(5, 20);
            return (rnd.Next(1, 100) <= integerPerc);
            //return (rnd.Next(1, 100) <= newFactor);

        }

        // Given three colinear Vector2s p, q, r, the function checks if 
        // Vector2 q lies on line segment 'pr' 
        bool onSegment(Vector2 p, Vector2 q, Vector2 r)
        {
            if (q.X <= Math.Max(p.X, r.X) && q.X >= Math.Min(p.X, r.X) &&
                q.Y <= Math.Max(p.Y, r.Y) && q.Y >= Math.Min(p.Y, r.Y))
                return true;

            return false;
        }
        private bool FindIntersection(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4)
        {
            // Get the segments' parameters.
            float dx12 = p2.X - p1.X;
            float dy12 = p2.Y - p1.Y;
            float dx34 = p4.X - p3.X;
            float dy34 = p4.Y - p3.Y;

            // Solve for t1 and t2
            float denominator = (dy12 * dx34 - dx12 * dy34);

            float t1 =
                ((p1.X - p3.X) * dy34 + (p3.Y - p1.Y) * dx34)
                    / denominator;
            if (float.IsInfinity(t1))
            {
                return false;
            }

            float t2 =
                ((p3.X - p1.X) * dy12 + (p1.Y - p3.Y) * dx12)
                    / -denominator;

            // The segments intersect if t1 and t2 are between 0 and 1.
            bool segments_intersect =
                ((t1 >= 0) && (t1 <= 1) &&
                 (t2 >= 0) && (t2 <= 1));
            return segments_intersect;
        }
        // To find orientation of ordered triplet (p, q, r). 
        // The function returns following values 
        // 0 --> p, q and r are colinear 
        // 1 --> Clockwise 
        // 2 --> Counterclockwise 
        int orientation(Vector2 p, Vector2 q, Vector2 r)
        {
            // See https://www.geeksforgeeks.org/orientation-3-ordered-Vector2s/ 
            // for details of below formula. 
            int val = (int)((q.Y - p.Y) * (r.X - q.X) - (q.X - p.X) * (r.Y - q.Y));

            if (val == 0) return 0;  // colinear 

            return (val > 0) ? 1 : 2; // clock or counterclock wise 
        }

        // The main function that returns true if line segment 'p1q1' 
        // and 'p2q2' intersect. 
        bool doIntersect(Vector2 p1, Vector2 q1, Vector2 p2, Vector2 q2)
        {
            // Find the four orientations needed for general and 
            // special cases 
            int o1 = orientation(p1, q1, p2);
            int o2 = orientation(p1, q1, q2);
            int o3 = orientation(p2, q2, p1);
            int o4 = orientation(p2, q2, q1);

            // General case 
            if (o1 != o2 && o3 != o4)
                return true;

            // Special Cases 
            // p1, q1 and p2 are colinear and p2 lies on segment p1q1 
            if (o1 == 0 && onSegment(p1, p2, q1)) return true;

            // p1, q1 and q2 are colinear and q2 lies on segment p1q1 
            if (o2 == 0 && onSegment(p1, q2, q1)) return true;

            // p2, q2 and p1 are colinear and p1 lies on segment p2q2 
            if (o3 == 0 && onSegment(p2, p1, q2)) return true;

            // p2, q2 and q1 are colinear and q1 lies on segment p2q2 
            if (o4 == 0 && onSegment(p2, q1, q2)) return true;

            return false; // Doesn't fall in any of the above cases 
        }
        //----------------------------------------------------------------------------------------------
        protected override void Draw(GameTime gameTime) // this function will be called after initialize
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);
            base.Draw(gameTime);
            spriteBatch.Begin();
            /* Actual drawing -- > */ drawNetwork(spriteBatch, HW2_Graph);
            spriteBatch.End();
        }

        //--------------------------------------------------------------------------------------------------------
        private void drawNetwork(SpriteBatch spriteBatch,Graph graph)
        {
            int vertex = graph._numberOfVertexes;
            Vector2[] positions = graph._vertexesPositions;
           
            for(int i = 0;i < vertex;i++)
            {
                for(int j=0;j< vertex;j++)
                {
                    if(graph._edgesMatrix[i,j] == 1)
                    {
                        DrawLine(spriteBatch, positions[i], positions[j], Color.White);
                    }
                }
            }
            for (int i = 0; i < vertex; i++)
            {
                Color nodeColor = graph.clusters[i];
                Vector2 pos = positions[i];
                spriteBatch.Draw(node_Tex, pos, nodeColor);
            }
        }
        //--------------------------------------------------------------------------------------------------------
        private Graph parseNetwork()
        {
            //init path for the net file needed to be parsed
            string networkFileName = "HW2Net.txt";
            string path = System.IO.Path.Combine(Environment.CurrentDirectory, @"", networkFileName);            
            string inputText = System.IO.File.ReadAllText(path);//read the whole net as a string
            string[] numbers = Regex.Split(inputText, @"\D+");//find all numbers in this text.
            int numberOfVertexes = int.Parse(numbers[1]);
            Console.WriteLine("There are {0} vertexes in this network", numberOfVertexes);
            String[] edges = (numbers.ToList().GetRange(2, numbers.Length- 3)) .ToArray() ;


            string clustersFileName = "HW2Clust.txt";
            string clustersFilePath = System.IO.Path.Combine(Environment.CurrentDirectory, @"", clustersFileName);
            string clustersInputText = System.IO.File.ReadAllText(clustersFilePath);//read the whole net as a string
            string[] clustersInfo = Regex.Split(clustersInputText, @"\D+");//find all numbers in this text.
            string[] clusters = (clustersInfo.ToList().GetRange(2, numberOfVertexes)).ToArray();
            Graph outputGraph = new Graph(numberOfVertexes, edges, clusters);

            return outputGraph;
        }
        //--------------------------------------------------------------------------------------------------------
        protected void DrawLine(SpriteBatch spriteBatch, Vector2 begin, Vector2 end, Color color, int width = 1)
        {
            Rectangle r = new Rectangle((int)begin.X, (int)begin.Y, (int)(end - begin).Length() + width, width);
            Vector2 v = Vector2.Normalize(begin - end);
            float angle = (float)System.Math.Acos(Vector2.Dot(v, -Vector2.UnitX));
            if (begin.Y > end.Y) angle = MathHelper.TwoPi - angle;
            Texture2D Pixel = Content.Load<Texture2D>("pixel"); 
            spriteBatch.Draw(Pixel, r, null, color, angle, Vector2.Zero, SpriteEffects.None, 0);
        }
        //-------------------------------------------------------------------------------------------------------

       //Game api functions we dont really need:
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);

            // TODO: use this.Content to load your game content here
        }
        protected override void UnloadContent()
        {
            // TODO: Unload any non ContentManager content here
        }
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            // TODO: Add your update logic here

            base.Update(gameTime);
        }

       
    }
}
