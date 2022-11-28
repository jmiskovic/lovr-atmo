# lovr-atmo

![header screenshot](header.jpg)

Provides a decent starting environment for sunny [LÖVR](https://lovr.org/) projects.

Sky rendering uses a model of the light scattering through the atmosphere with exposed parameters to modify appearance of sun and the sky. For better performance the atmosphere is rendered onto skybox texture. The color of horizon is made available so it can affect the color of fog or any other scene object.

The shortest way to get this code up and running is:

```Lua
local atmo = require('atmo')
local skybox = require('skybox').new() -- or new(512) for hires

skybox:bake(atmo.draw) -- renders atmosphere into texture

function lovr.draw(pass)
    skybox:draw(pass)
    -- atmo.draw(pass) -- render directly without skybox
end
```

The `skybox.lua` by itself can be used for baking any scene onto the skybox. Best used for static scenes where objects are far away from camera.

![sky variations](skies.gif)

The included `main.lua` example allows playing with atmosphere options to obtain the perfect settings. It features a basic fog model and some unrealistically scaled terrain. On desktop, use the right mouse button to position sun in the sky. Move around (with *WASD* keys) while holding *shift* key to change sun parameters, or holding *ctrl* key to affect the atmosphere hue.

A good overview of the technique can be found in the [Simulating the Colors of the Sky](https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/simulating-sky/simulating-colors-of-the-sky) article. Credit for the sun and atmosphere shader goes to [glsl-atmosphere](https://github.com/wwwtyro/glsl-atmosphere) repository (MIT license) by Rye Terrell.