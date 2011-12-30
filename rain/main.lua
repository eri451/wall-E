require "helper"
require "wall"

function tohex(colour)
    return string.format("%.2x%.2x%.2x",unpack(colour))
end

function inbound(p)
    if p > 1 then p = 1 elseif p < 0 then p = 0 end
    return p
end

function love.keypressed(key)
    if key == "escape" then
        love.event.push "q"

    end

end

function love.load()
    wall = Wall("ledwall", 1338, 3)

    time = love.timer.getTime() * 1000

    tick = 0

end

drops = {}
-- colours = {"ff0000", "0000ff", "00ff00", "ff00ff", "ffff00", "00ffff"}
colours = {{255,0,0}, {0,0,255}, {0,255,0}, {255,0,255}, {255,255,0}, {0,255,255}}

function love.update(dt)
    -- constant 30 FPS
    local t = love.timer.getTime() * 1000
    time = time + 1000 / 30
    love.timer.sleep(time - t)

    if math.random(2) == 1 then
        local drop = {
            x = math.random(0, 15),
            dy = dy(),
            y = 0,
            colour = colours[math.random(1, 6)],
            fadesteps = math.random(4,10),
        }
        local p, r,g,b
        r, g, b = unpack(drop.colour)
        p = inbound(drop.dy * 1.3)
        r, g, b = r*p, g*p, b*p
        drop.colour = {r,g,b}
        
        table.insert(drops, drop)
    end

        function dy()
            dy = math.random()
            if dy >= 0.4 then
                return dy
            else
                return 1
            end
        end

    for i, drop in ipairs(drops) do
        drop.y = drop.y + drop.dy
        if drop.y > 15 + drop.fadesteps + 1 then
            table.remove(drops, i)
        end
        if i >= 30 then
            table.remove(drops, i)
        end
    end


end

function drop()
    for _, drop in ipairs(drops) do
        local y = math.floor(drop.y)
        --wall:pixel(drop.x, y, colours[drop.colour])
        wall:pixel(drop.x, y, tohex(drop.colour))

        local p, r,g,b
        local steps = drop.fadesteps
        for i = steps, 0, -1 do
            p = inbound(i * 1/(steps+1))
            r, g, b = unpack(drop.colour)
            r, g, b = r*p, g*p, b*p
            wall:pixel(drop.x, y - steps + i - 1, tohex({r,g,b}))
        end
    end

end

function love.draw()

    drop()
    -- send the stuff abroad
    wall:draw()
end