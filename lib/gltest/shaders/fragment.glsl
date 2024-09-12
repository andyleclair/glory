#version 330 core
out vec4 FragColor;
  
uniform vec4 vertexColor; // setting this in OpenGL

void main()
{
    FragColor = vertexColor;
} 
