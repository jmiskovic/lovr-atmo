local m = {}
m.__index = m

function m.new(resolution)
  local self = setmetatable({}, m)
  self.resolution = math.floor(resolution or 256)
  assert(self.resolution > 0 and self.resolution < 6000)
  self.cubetex = lovr.graphics.newTexture(
    self.resolution, self.resolution, 6,
    {type='cube', mipmaps=false, usage = {'render', 'sample', 'transfer'}})
  self.horizon_color = lovr.math.newVec3()
  return self
end


function m:bake(drawfn)
  -- render scene to cubemap texture
  local render_pass = lovr.graphics.getPass('render', {self.cubetex, samples=1, mipmap=false})
  local projection = mat4():perspective(math.pi / 2, 1, 0, 0)
  local transforms = {
    mat4():lookAt(vec3(), vec3( 1, 0, 0), vec3(0, 1, 0)),
    mat4():lookAt(vec3(), vec3(-1, 0, 0), vec3(0, 1, 0)),
    mat4():lookAt(vec3(), vec3( 0, 1, 0), vec3(0, 0,-1)),
    mat4():lookAt(vec3(), vec3( 0,-1, 0), vec3(0, 0, 1)),
    mat4():lookAt(vec3(), vec3( 0, 0, 1), vec3(0, 1, 0)),
    mat4():lookAt(vec3(), vec3( 0, 0,-1), vec3(0, 1, 0))
  }
  for i, transform in ipairs(transforms) do
    render_pass:setProjection(i, projection)
    render_pass:setViewPose(i, transform)
  end
  drawfn(render_pass)
  -- read back the horizon color
  local transfer_pass = lovr.graphics.getPass('transfer')
  local readback = transfer_pass:read(self.cubetex, 0, 0, 1)
  lovr.graphics.submit(render_pass, transfer_pass)
  readback:wait()
  local image = readback:getImage()
  -- sample rendered image at three points along the horizon
  local r1, g1, b1 = image:getPixel(0, math.floor(self.resolution / 2))
  local r2, g2, b2 = image:getPixel(math.floor(self.resolution / 2), math.floor(self.resolution / 2))
  local r3, g3, b3 = image:getPixel(math.floor(self.resolution - 1), math.floor(self.resolution / 2))
  -- take harmonic mean, to remove outliers such as sun
  self.horizon_color:set(3 / (1 / r1 + 1 / r2 + 1 / r3),
                         3 / (1 / g1 + 1 / g2 + 1 / g3),
                         3 / (1 / b1 + 1 / b2 + 1 / b3))
end


function m:draw(pass)
  pass:setColor(1,1,1)
  pass:skybox(self.cubetex)
end

return m
