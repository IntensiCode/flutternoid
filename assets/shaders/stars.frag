#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;

out vec4 fragColor;

// Star Nest by Pablo Roman Andrioli
// License: MIT

#define iterations 12
#define formuparam 0.65

#define volsteps 20
#define stepsize 0.1

#define zoom   2.900
#define tile   0.450
#define speed  0.001

#define brightness 0.0005
#define darkmatter 0.500
#define distfading 0.830
#define saturation 0.700

void main()
{
    vec2 fragCoord = FlutterFragCoord();
    //get coords and direction
    vec2 uv=fragCoord.xy/iResolution.xy-.5;
    uv.y*=iResolution.y/iResolution.x;
    vec3 dir=vec3(uv*zoom,1.);
    float time=iTime*speed+.25;

    //mouse rotation
    float a1=0.0;
    float a2=0.0;
    mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
    mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
    dir.xz*=rot1;
    dir.xy*=rot2;
    vec3 from=vec3(1.,.5,0.5);
    from+=vec3(0,time,-2.);
    from.xz*=rot1;
    from.xy*=rot2;

    //volumetric rendering
    float s=0.1,fade=1.;
    vec3 v=vec3(0.);
    for (int r=0; r<volsteps; r++) {
        vec3 p=from+s*dir*.5;
        p = abs(vec3(tile)-mod(p,vec3(tile*2.))); // tiling fold
        float pa,a=pa=0.;
    for (int i=0; i<iterations; i++) {
    p=abs(p)/dot(p,p)-formuparam; // the magic formula
    a+=abs(length(p)-pa); // absolute sum of average change
    pa=length(p);
    }
    float dm=max(0.,darkmatter-a*a*.001); //dark matter
    a*=a*a; // add contrast
    if (r>6) fade*=1.-dm; // dark matter, don't render near
    //v+=vec3(dm,dm*.5,0.);
    v+=fade;
    v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
    fade*=distfading; // distance fading
    s+=stepsize;
    }
    v=mix(vec3(length(v)),v,saturation); //color adjust
    fragColor = vec4(v*.01,1.);

}
