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

function blur(pix1, pix2, dx, dy)
    local w= wall.width
    local h= wall.height
    
    local f0= 0.25+dx
    local f1= 0.25-dx
    local f2= 0.25+dy
    local f3= 0.25-dy
    local fx= -.25	--- (math.sin(tick*0.014)*0.5 + 1)
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
				         pix2[y*w+x][c]*fx) * .6, 0, 2.0)
--				         pix2[y*w+x][c]*fx) * .2, -1, 2.0)
	    end
	    pix2[y*w+x].alive= pix1[y*w+x].alive 
	end
    end    
end


function life(buf1, buf2)
    local w= wall.width
    local h= wall.height
    
    local neighborcount= {}
    
    local aliveTotal= 0

    for y= 0, h do
	for x= 0, w do
	    neighborcount[y*w+x+1]= 0
	    for _, o in ipairs({ {-1,-1}, { 0,-1}, { 1,-1},
				 {-1, 0}, 	   { 1, 0},
				 {-1, 1}, { 0, 1}, { 1, 1}}) do
	        if buf1[(y+o[1])*w+x+o[2]+1].alive==1 then neighborcount[y*w+x+1]= neighborcount[y*w+x+1]+1 end
	    end
	end
    end
    for y= 0, h do
	for x= 0, w do
		buf2[y*w+x+1]= { r= buf1[y*w+x+1].r, g= buf1[y*w+x+1].g, b= buf1[y*w+x+1].b, alive= buf1[y*w+x+1].alive }
	
		local neighbors= neighborcount[y*w+x+1]
		local alive= buf2[y*w+x+1].alive
		
-- Any live cell with fewer than two live neighbours dies, as if caused by under-population.
		if neighbors<2 and alive~=0 then 
		    buf2[y*w+x+1].alive= 0	--= { r=.5,g=0,b=0, alive=0 }
		end
-- Any live cell with two or three live neighbours lives on to the next generation.
		if (neighbors==2 or neighbors==3) and alive~=0 then 
		    buf2[y*w+x+1].alive= 1	--= { r=1,g=1,b=1, alive=1 }
		end
-- Any live cell with more than three live neighbours dies, as if by overcrowding.
		if neighbors>3 and alive~=0 then 
		    buf2[y*w+x+1].alive= 0	--= { r=0,g=0,b=0, alive=0 }
		end
-- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
		if neighbors==3 and alive==0 then 
		    buf2[y*w+x+1]= { r=1,g=1,b=1, alive=1 }
		end
		
		if buf2[y*w+x+1].alive==1 then aliveTotal= aliveTotal+1 end
	end
    end
    
    return aliveTotal
end

lastAlive= 0
curAlive= 0

nextdrops= 0
function update()
    local w= wall.width
    local h= wall.height

    -- blur(pix1, pix2, math.sin(tick*0.00649)*.1, math.cos(tick*.0127)*.1)
    if tick%3==0 then 
	lastAlive= curAlive
	curAlive= life(pix1, pix2)
    end
	--fade(pix2, .1)
--	blur(pix1, pix2, 0, 0)
	fade(pix2, .1)
	local p= pix1
	pix1= pix2
	pix2= p

    
    tick= tick+1
    
    
    if tick>nextdrops then
        if math.abs(curAlive-lastAlive)<2 or tick>nextdrops+1000 then
	    for i=1,R(1,15) do
		local x= R(1, w)
		local y= R(1, h)
		for _, c in ipairs({"r", "g", "b"}) do
			--print(pixels[y*w+x][c])
			pix1[y*w+x][c]= inbound(pix1[y*w+x][c] + R(.5, .5), 0, 1.0)
		end
		pix1[y*w+x].alive= 1
	    end
	    nextdrops= tick+5	--R(tick+1, tick+1)
	end
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
    wall = Wall("176.99.24.251", 1338, 2)

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