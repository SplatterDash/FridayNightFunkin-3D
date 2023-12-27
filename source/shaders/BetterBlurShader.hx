package shaders;

class BetterBlurShader extends flixel.system.FlxAssets.FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float r;
        uniform int axis;

        void main()
        {
            float x,y,rr=r*r,d,w,w0;
            vec4 texture = flixel_texture2D(bitmap, openfl_TextureCoordv);
            vec2 p=0.5*(vec2(1.0,1.0)+texture.zw);
            vec4 col=vec4(0.0,0.0,0.0,0.0);
            w0=0.5135/pow(r,0.96);
            if (axis==0) for (d=1.0/openfl_TextureSize.x,x=-r,p.x+=x*d;x<=r;x++,p.x+=d){ w=w0*exp((-x*x)/(2.0*rr)); col+=flixel_texture2D(bitmap, p)*w; }
            if (axis==1) for (d=1.0/openfl_TextureSize.y,y=-r,p.y+=y*d;y<=r;y++,p.y+=d){ w=w0*exp((-y*y)/(2.0*rr)); col+=flixel_texture2D(bitmap, p)*w; }
            gl_FragColor=col;
        }
    ')

    public function new(rad:Float)
        {
            super();
            this.r.value = [rad];
            this.axis.value = [0];
        }
}