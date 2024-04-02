package shaders;

class OutlineShader extends flixel.system.FlxAssets.FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float red;
        uniform float green;
        uniform float blue;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            if(color.r > 0.01 || color.g > 0.01 || color.b > 0.01 || color.a == 0.0) {
                gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                return;
            } else {
                gl_FragColor = vec4(red, green, blue, 1.0);
                return;
            }
        }

    ')

    public function new(color:Array<Float>) {
        super();
        this.red.value = [color[0]];
        this.green.value = [color[1]];
        this.blue.value = [color[2]];
    }
}