package shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.Shader;

class Scanlines extends FlxShader
{
    #if(openfl >= "8.0.0")
	@:glFragmentSource('
		#pragma header
		const float scale = 1.0;

		void main()
		{
			if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y / scale), 2.0) == 0.0)
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
			else
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
		}')
    #else
    @fragment var fragment = '
		const float scale = 1.0;

		void main()
		{
			if (mod(floor(${Shader.vTexCoord}.y * ${Shader.uTextureSize}.y / scale), 2.0) == 0.0)
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
			else
				gl_FragColor = texture2D(${Shader.uSampler}, ${Shader.vTexCoord});
		}';
    #end
	public function new()
	{
		super();
	}
}