package shaders;

import flixel.system.FlxAssets.FlxShader;

class OverlayShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec3 uBlendColor;

		void main()
		{
			vec4 base = flixel_texture2D(bitmap, openfl_TextureCoordv);
			if((base.r == 0.0 && base.g == 0.0 && base.b == 0.0) || base.a == 0.0) {
                gl_FragColor = vec4(0.0, 0.0, 0.0, base.a);
                return;
            } else {
                gl_FragColor = vec4(base.r + uBlendColor.r, base.g + uBlendColor.g, base.b + uBlendColor.b, base.a);
                return;
            }
		}')
	public function new(color:FlxColor)
	{
		super();
		this.uBlendColor.value = [color.redFloat - 0.2, color.greenFloat - 0.2, color.blueFloat - 0.2];
	}
}
