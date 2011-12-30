require "helper"
require "wall"
require "framework"

-- values

nr = 42
blobs = {}


-- helpervalues
local __maxbound = 1.5
local __reznr = 1 / nr
local __maxd = 0

--------------------------------------------------------------------------------


function update()
    for _, blob in ipairs(blobs) do
        local d = 0.9
        blob.dir.x = (blob.dir.x + R()*d - d*0.5)*0.9
        blob.dir.y = (blob.dir.y + R()*d - d*0.5)*0.9

        --blob.strength = (blob.strength + R()*10 - 5)*0.8
        --blob.radius = (blob.radius     + R()*0.1 - 0.05)

        blob.x = blob.x + blob.dir.x
        blob.y = blob.y + blob.dir.y

        local w = wall.width * __maxbound - wall.width
        if blob.x > wall.width * __maxbound then
            blob.x = - w
        elseif blob.x < - w then
            blob.x = wall.width * __maxbound
        end

        local h = wall.height * __maxbound - wall.height
        if blob.y > wall.height * __maxbound then
            blob.y = - h
        elseif blob.y < - h then
            blob.y = wall.height * __maxbound
        end


        for k, c in pairs(blob.color) do
            blob.color[k] = c + R()*10 - 5
        end

        if tick%50 == 0 then
            local c = blob.color
            local tmp = c.r
            c.r = c.g
            c.g = c.b
            c.b = tmp
        end
    end

    tick = tick + 1
end

function draw()

    for y = 1, wall.height do
        for x = 1, wall.width do
            local curpos = {x=x,y=y}

            local r,g,b = 0,0,0
            for _, blob in ipairs(blobs) do

                local d = dist(curpos, blob)
                if d < 0.9 then d = d * 0.9 end
                --d = math.log(d)*2
                --d = math.log((d*d) / (__maxd*__maxd))
                ---d = math.log10((__maxd / (d * blob.radius))
                d = math.log((__maxd*blob.radius) / d)
                --d = (1 - d) / __maxd
                --d = math.log(d)

                d = d * blob.strength

                r = r + blob.color.r * d
                g = g + blob.color.g * d
                b = b + blob.color.b * d
            end

            local m = 1
            --local sum = (r + g + b)/3
            --local m = inbound(sum/256)--inbound(math.sqrt(sum))
            --if m == 0 then m = -m end
            --if sum < 33 and sum > 188 then m = 0 end


            r = inbound(m*r * __reznr,0,255)
            g = inbound(m*g * __reznr,0,255)
            b = inbound(m*b * __reznr,0,255)

            --print(x,y,r,g,b)

            wall:pixel(x-1, y-1, hex(r,g,b))
        end
    end

end

--------------------------------------------------------------------------------

function love.load()
    wall = Wall("ledwall", 1338, 3)

    __maxd = math.sqrt(wall.width*wall.height)

    time = love.timer.getTime() * 1000

    tick = 0


    -- initialize

    for i=1,nr do
        local blob = {
            dir={
                x = R()*1.5-0.75,
                y = R()*1.5-0.75,
            },
            strength = (R()*9 + 1),
            radius = R()+0.5,
            color = {r=0,g=0,b=0},--{ r=R(150,200), g=R(150,200), b=R(150.200) },
            x = R()*wall.width*__maxbound,
            y = R()*wall.height*__maxbound,
        }

        for i, c in ipairs(shuffle({"r","g","b"})) do
            blob.color[c] = R() * 40 + 60 * i
        end

        table.insert(blobs, blob)
    end

end


function love.keypressed(key)
    if key == "escape" then
        love.event.push "q"
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