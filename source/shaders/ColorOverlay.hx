package shaders;


class ColorOverlay extends flixel.system.FlxAssets.FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float red;
        uniform float green;
        uniform float blue;
        uniform float alpha;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            gl_FragColor = vec4(red * color.a, green * color.a, blue * color.a, alpha);
        }

    ')
	public function new(vertColorInput:FlxColor, ?spriteAlpha:Float = 1.0)
	{
        super();
        this.red.value = [vertColorInput.redFloat];
        this.green.value = [vertColorInput.greenFloat];
        this.blue.value = [vertColorInput.blueFloat];
        this.alpha.value = [spriteAlpha];
	}
}