package shaders;

import flixel.system.FlxAssets.FlxShader;

class GlowShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec3 uBlendColor;

		void main()
		{
			vec4 base = flixel_texture2D(bitmap, openfl_TextureCoordv);

			float d = length(openfl_TextureCoordv) - 0.2;

			vec3 col = vec3(base.r, base.g, base.b);
			col += clamp(vec3(0.001/d), 0., 1.) * 12.;

			gl_FragColor = vec4(col.r, col.g, col.b, base.a);
			return;
		}')
	public function new(color:FlxColor)
	{
		super();
		this.uBlendColor.value = [color.redFloat, color.greenFloat, color.blueFloat];
	}
}
