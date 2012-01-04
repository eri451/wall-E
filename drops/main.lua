require "helper"
require "wall"

require 'socket'
math.randomseed(socket.gettime()*10000)

-- helpers

function R(...)
    return math.random(...)
end

function hex(r,g,b)
    if g == nil then
        b = r.b
        g = r.g
        r = r.r
    end
    for _, c in pairs({r,g,b}) do c= inbound(c) end
    return string.format("%.2x%.2x%.2x",math.sqrt(r)*255,math.sqrt(g)*255,math.sqrt(b)*255)
end

function shuffle(t)
  local n = #t

  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end

  return t
end

function inbound(p, _min, _max)
    if _min == nil then _min = 0 end
    if _max == nil then _max = 1 end
    if p > _max then p = _max elseif p < _min then p = _min end
    return p
end

function sqdist(a, b)
    local x = b.x - a.x
    local y = b.y - a.y
    return x*x + y*y
end

function dist(...)
    return math.sqrt(sqdist(...))
end

-- values

pix1= {}
pix2= {}
tick= 0

--------------------------------------------------------------------------------

function fade(buffer, step)
    local w= wall.width
    local h= wall.height
    
    for y= 1, h do
	for x= 1, w do
	    buffer[y*w+x].r= inbound(buffer[y*w+x].r-step, 0, 1.0)
	    buffer[y*w+x].g= inbound(buffer[y*w+x].g-step, 0, 1.0)
	    buffer[y*w+x].b= inbound(buffer[y*w+x].b-step, 0, 1.0)
	end
    end
end    

function blur(buffer, dx, dy)
    local w= wall.width
    local h= wall.height
    
    local f0= 0.5+dx
    local f1= 0.5-dx
    local f2= 0.5+dy
    local f3= 0.5-dy
    local fx= -2	--- (math.sin(tick*0.014)*0.5 + 1)
    local fa= .125
    local fb= .125
    local fc= .125
    local fd= .125
    
    
    for y= 1, h do
	for x= 1, w do
	    for _, c in ipairs({ "r", "g" , "b" }) do
	        pix2[y*w+x][c]= inbound( (pix1[y*w+x-1][c]*f0 + pix1[y*w+x+1][c]*f1 +
		    		         pix1[(y-1)*w+x][c]*f2 + pix1[(y+1)*w+x][c]*f3 +
		    		         pix1[(y-1)*w+x-1][c]*fa + pix1[(y-1)*w+x+1][c]*fb +
		    		         pix1[(y+1)*w+x-1][c]*fc + pix1[(y+1)*w+x+1][c]*fd +
				         pix2[y*w+x][c]*fx) * .8, 0, 2.0)
--				         pix2[y*w+x][c]*fx) * .2, -1, 2.0)
	    end
	end
    end    
end


nextdrops= 0
function update()
    local w= wall.width
    local h= wall.height

    blur(pix1, math.sin(tick*0.00649)*.1, math.cos(tick*.0127)*.1)
    --fade(pix1, 1)
    local p= pix1
    pix1= pix2
    pix2= p
    
    tick= tick+1
    
    
    if tick>nextdrops then
    for i=1,R(1,2) do
        local x= R(2, w-1)
	local y= R(2, h-1)
	for _, c in ipairs({"r", "g", "b"}) do
		--print(pixels[y*w+x][c])
		pix1[y*w+x][c]= inbound(pix1[y*w+x][c] + R(0, 1), 0, 1.0)
	end
    end
    nextdrops= R(tick+10, tick+200)
    end
end

function draw()
    local w= wall.width
    local h= wall.height
    
    for y= 1, h do
	for x= 1, w do
	    wall:pixel(x-1, y-1, hex(pix1[y*w+x]))
	end
    end
--            wall:pixel(x-1, y-1, hex(r,g,b))
end

--------------------------------------------------------------------------------

function love.load()
    wall = Wall("176.99.24.251", 1338, 1)

    __maxd = math.sqrt(wall.width*wall.height)

    time = love.timer.getTime() * 1000

    tick = 0

    -- initialize

    local w= wall.width
    local h= wall.height
    
    for y= -1, h+1 do
	for x= -1, w+1 do
	    pix1[y*w+x+1]= { r=0, g=0, b=0 }
	    pix2[y*w+x+1]= { r=0, g=0, b=0 }
	end
    end
end


function love.keypressed(key)
    w= 0
    if key == "escape" then
        love.event.push "q"
    elseif key == " " then
	print("space")
	w= w+1
	if w%2==0 then
		wall:init()
	else
		wall:init("176.99.24.251", 1338, 4)
	end
    end
end

function love.update(dt)
    -- constant 30 FPS
    local t = love.timer.getTime() * 1000
    time = time + 1000 / 30
    love.timer.sleep(time - t)

    update()
end


function love.draw()
    draw()
    -- send the stuff abroad
    wall:draw()
end