local m = {}
m.__index = m

local cubemap_transforms = {
  Mat4():lookAt(vec3(), vec3( 1, 0, 0), vec3(0, 1, 0)),
  Mat4():lookAt(vec3(), vec3(-1, 0, 0), vec3(0, 1, 0)),
  Mat4():lookAt(vec3(), vec3( 0, 1, 0), vec3(0, 0,-1)),
  Mat4():lookAt(vec3(), vec3( 0,-1, 0), vec3(0, 0, 1)),
  Mat4():lookAt(vec3(), vec3( 0, 0, 1), vec3(0, 1, 0)),
  Mat4():lookAt(vec3(), vec3( 0, 0,-1), vec3(0, 1, 0))
}

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
  local render_pass = lovr.graphics.newPass({self.cubetex, samples=1})
  local projection = mat4():perspective(math.pi / 2, 1, 0, 0)
  for i, transform in ipairs(cubemap_transforms) do
    render_pass:setProjection(i, projection)
    render_pass:setViewPose(i, transform)
  end
  drawfn(render_pass)
  lovr.graphics.submit(render_pass)
  -- read back the horizon color
  local readbacks = {
    self.cubetex:newReadback(0, 0, 1, 1),
    self.cubetex:newReadback(0, 0, 2, 1),
    self.cubetex:newReadback(0, 0, 3, 1),
    self.cubetex:newReadback(0, 0, 4, 1),
    self.cubetex:newReadback(0, 0, 5, 1),
    self.cubetex:newReadback(0, 0, 6, 1)
  }
  for i, readback in ipairs(readbacks) do
    readback:wait()
  end

  self.images = {}
  for i, readback in ipairs(readbacks) do
    readback:wait()
    self.images[i] = readback:getImage()
    --lovr.filesystem.write('img'..i..'.png', self.images[i]:encode())
  end

  -- sample rendered images at four points along the horizon
  local r1, g1, b1 = self.images[1]:getPixel(math.floor(self.resolution / 2), math.floor(self.resolution / 2))
  local r2, g2, b2 = self.images[2]:getPixel(math.floor(self.resolution / 2), math.floor(self.resolution / 2))
  local r3, g3, b3 = self.images[5]:getPixel(math.floor(self.resolution / 2), math.floor(self.resolution / 2))
  local r4, g4, b4 = self.images[6]:getPixel(math.floor(self.resolution / 2), math.floor(self.resolution / 2))
  -- take harmonic mean, to remove outliers such as sun
  self.horizon_color:set(4 / (1 / r1 + 1 / r2 + 1 / r3 + 1 / r4),
                         4 / (1 / g1 + 1 / g2 + 1 / g3 + 1 / g4),
                         4 / (1 / b1 + 1 / b2 + 1 / b3 + 1 / b4))
end


function m:draw(pass)
  pass:setColor(1,1,1)
  pass:skybox(self.cubetex)
end

return m
