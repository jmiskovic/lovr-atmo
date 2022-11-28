return lovr.graphics.newShader([[
layout(location = 0) out vec4 PositionView;

vec4 lovrmain() {
  PositionView = ClipFromLocal * VertexPosition;
  return PositionView;
}
]], [[
layout(location = 0) in vec4 PositionView;

Constants {
  vec3 FogColor;
};

vec4 lovrmain() {
  vec4 surface = (flag_colorTexture ? (Color * getPixel(ColorTexture, UV)) : Color);
  float fogAmount = 1.f - exp(-length(PositionView) * 0.01);
  return vec4(mix(surface.rgb, FogColor, fogAmount), surface.a);
}
]])
