#version 330 core
layout (location = 0) in vec3 aPos; // the position variable has attribute position 0
layout (location = 1) in vec3 aColor; // the color variable has attribute position 1
layout (location = 2) in vec2 aTexCoord;
  
out vec3 ourColor; // specify a color output to the fragment shader
out vec2 TexCoord;

uniform mat4 transform;

void main()
{
  gl_Position = transform * vec4(aPos, 1.0f); // see how we directly give a vec3 to vec4's constructor
  ourColor = aColor;
  TexCoord = vec2(aTexCoord.x, aTexCoord.y);
}
