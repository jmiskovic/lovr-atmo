local atmo = require('atmo/atmo')
local skybox = require('atmo/skybox').new(128)
local fogshader = require('atmo/simple-fog')

atmo.gpu.horizon_offset = 3
skybox:bake(atmo.draw)

function lovr.update(dt)
  local vx, vy, vz = vec3(lovr.headset.getVelocity()):unpack()
  local is_changed = false
  if lovr.system.isKeyDown('lalt') then
    atmo.gpu.sun_sharpness = atmo.gpu.sun_sharpness + vx * dt * 0.02
    atmo.gpu.horizon_offset = atmo.gpu.horizon_offset + vy * dt * 0.5
    atmo.gpu.haze = atmo.gpu.haze + vz * dt * 0.2
    is_changed = true
  elseif lovr.system.isKeyDown('lctrl') then
    atmo.gpu.hue.r = atmo.gpu.hue.x + vx * dt * 0.2
    atmo.gpu.hue.g = atmo.gpu.hue.y + vy * dt * 0.2
    atmo.gpu.hue.b = atmo.gpu.hue.z + vz * dt * 0.2
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

  pass:setColor(1,1,1)
  pass:text({0xf0f0f0, [[Drag right mouse button to set the sun position
Scroll the mouse wheel to dim the sun
Hold Ctrl and scroll the mouse wheel to control gamma
Hold Crtl + WASD to modify the atmosphere hue
Hold Alt + WASD to tweak atmosphere parameters]]}, -80, 15, -300,  10,  0, 1,0,0, 0, 'left')
  -- show atmospheric parameters
  local y = 60
  for k, v in pairs(atmo.gpu) do
    pass:text({0x404040, k}, 0, y, -300,  10,  0, 1,0,0,  0, 'right')
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
  pass:setColor(vec3(0.3, 0.3, 0.3):lerp(skybox.horizon_color, 0.2):unpack())
  pass:circle(0, -30, 0, 1500, -math.pi/2, 1,0,0)
  lovr.math.setRandomSeed(0)
  for i = 1, 200 do
    local shade = 0.15 + 0.1 * lovr.math.random()
    pass:setColor(vec3(shade, shade, shade):lerp(skybox.horizon_color, 0.2):unpack())
    pass:cone(lovr.math.randomNormal(500, 0),
              -30,
              lovr.math.randomNormal(500, 0),
              50, lovr.math.randomNormal(5, 20), math.pi / 2, 1,0,0)
  end
end

function lovr.wheelmoved(dx, dy)
  if lovr.system.isKeyDown('lctrl') then
    atmo.gpu.gamma_correction = atmo.gpu.gamma_correction - dy * 0.05
  else
    atmo.gpu.sun_intensity = math.max(0, atmo.gpu.sun_intensity + dy * 0.5)
  end
  skybox:bake(atmo.draw)
end
