package shaders;

import flixel.system.FlxAssets.FlxShader;

class FastBlurShader extends FlxShader {
	@:glFragmentSource('
#pragma header

uniform float uBrightness;
uniform float uBlur;

vec2 fixvec2(float x, float y) { // makes an uv the same across sizes
	vec2 val = vec2(x, y);
	val.xy *= vec2(1280.0, 720.0);
	val.xy /= openfl_TextureSize.xy;
	return val;
}
vec2 fixvec2(vec2 uv) { // makes an uv the same across sizes
	vec2 val = uv;
	val.xy *= vec2(1280.0, 720.0);
	val.xy /= openfl_TextureSize.xy;
	return val;
}

vec2 random(vec2 p) {
	//p += vec2(uBlur, uBlur);
	p = vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3)));
	return fract(sin(p)*4375.5);
}
void main() {
	vec2 uv = openfl_TextureCoordv;
	vec2 fragCoord = openfl_TextureCoordv * openfl_TextureSize.xy;

	vec2 blur = vec2(uBlur) * vec2(1.0, openfl_TextureSize.x / openfl_TextureSize.y);

	//float blur = iMouse.x/iResolution.x * 0.1;
	vec4 a = flixel_texture2D(bitmap, uv+fixvec2(random(uv)*blur - blur / 2.0)) * uBrightness;
	a += flixel_texture2D(bitmap, uv+fixvec2(random(uv+0.1)*blur - blur / 2.0)) * uBrightness;
	a += flixel_texture2D(bitmap, uv+fixvec2(random(uv+0.2)*blur - blur / 2.0)) * uBrightness;
	a += flixel_texture2D(bitmap, uv+fixvec2(random(uv+0.3)*blur - blur / 2.0)) * uBrightness;
	gl_FragColor = a / 4.0;
}')

	public function new() {
		super();
		this.uBrightness.value = [1.0];
		this.uBlur.value = [0.1];
	}

	public var brightness(get, set):Float;

	function get_brightness() {
		return this.uBrightness.value[0];
	}
	function set_brightness(val:Float) {
		return this.uBrightness.value[0] = val;
	}

	public var blur(get, set):Float;

	function get_blur() {
		return this.uBlur.value[0];
	}
	function set_blur(val:Float) {
		return this.uBlur.value[0] = val;
	}
}