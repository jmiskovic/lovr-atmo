local atmo = require('atmo/atmo')
local skybox = require('atmo/skybox').new()
local fogshader = require('atmo/simple-fog')

skybox:bake(atmo.draw)

function lovr.update(dt)
  local vx, vy, vz = vec3(lovr.headset.getVelocity()):unpack()
  local is_changed = false
  if lovr.system.isKeyDown('lshift') then
    atmo.gpu.sun_sharpness = atmo.gpu.sun_sharpness + vx * dt * 10
    atmo.gpu.horizon_offset = atmo.gpu.horizon_offset + vy * dt * 100
    atmo.gpu.haze = atmo.gpu.haze + vz * dt * 20
    is_changed = true
  elseif lovr.system.isKeyDown('lctrl') then
    atmo.gpu.hue.r = atmo.gpu.hue.x + vx * dt * 10
    atmo.gpu.hue.g = atmo.gpu.hue.y + vy * dt * 10
    atmo.gpu.hue.b = atmo.gpu.hue.z + vz * dt * 10
    is_changed = true
  end
  if lovr.headset.isDown('left', 'trigger') then
    local v = vec3(quat(lovr.headset.getOrientation('left')):direction())
    atmo.gpu.sun_position:lerp(v, dt * 0.5)
    is_changed = true
  end
  if is_changed then
    skybox:bake(atmo.draw)
  end
end


function lovr.draw(pass)
  skybox:draw(pass)
  -- show atmospheric parameters
  local y = 50
  for k, v in pairs(atmo.gpu) do
    pass:text({0x404040, k}, 0, y,    -300,  10,   0, 1,0,0,  0, 'right')
    if type(v) == 'number' then
      v = string.format('%1.2f', v)
    else
      v = string.format('%1.2f, %1.2f, %1.2f', v.x, v.y, v.z)
    end
      pass:text({0xe0a000, v}, 20, y, -300,  10, 0, 1,0,0,  0, 'left')
    y = y + 10
  end
  -- basic landscape scene
  pass:setShader(fogshader)
  pass:send('FogColor', lovr.math.gammaToLinear(skybox.horizon_color:unpack()))
  pass:setColor(vec3(0.3, 0.3, 0.3):lerp(skybox.horizon_color, 0.5):unpack())
  pass:circle(0, 0, 0, 500, -math.pi/2, 1,0,0)
  lovr.math.setRandomSeed(0)
  for i = 1, 200 do
    pass:cone(lovr.math.randomNormal(50, 0),
              0,
              lovr.math.randomNormal(50, 0),
              5, lovr.math.randomNormal(0.5, 2), math.pi / 2, 1,0,0)
  end
end
