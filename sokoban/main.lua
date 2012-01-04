require "helper"
require "wall"
require "framework"

-- values

env = {
}

-- this value is used for blocing new keyentrys
block_keyevents = false
level_stack = {}

-- helpervalues
-- local __maxbound = 1.5
-- local __reznr = 1 / (nr*0.1) -- / (nr*3)
-- local __maxd = 0


local operator = {
    ["+"]=function(a,b)return a+b end,
    ["-"]=function(a,b)return a-b end}

--------------------------------------------------------------------------------

Player = Object:new()
function Player:init(opts)
    opts = opts or {}
    self.pos = { x = opts.x, y=opts.y }
    self.old_pos = { x = opts.x, y=opts.y }
    self.color = opts.color or hex( 200, 200, 200 )
end

function Player:update()

    local old_pos = {x = self.pos.x, y = self.pos.y}
    local dir = {x = 0, y = 0}
    for cursor_dir, oc in pairs({left="-x", right="+x", up="-y", down="+y" }) do
        if wall.input[1][cursor_dir] and not block_keyevents then
            block_keyevents = true
            local o, c = oc:sub(1,1), oc:sub(2)
            if c == 'x' then
                if o == '-' then
                    dir.x = -1
                else
                    dir.x = 1
                end
            elseif c == 'y' then
                if o == '-' then
                    dir.y = -1
                else
                    dir.y = 1
                end
            end
        end
    end

    self.pos.x = self.pos.x + dir.x
    self.pos.y = self.pos.y + dir.y

    local x, y = round(self.pos.x), round(self.pos.y)
    local reset_player = false

    -- if next pixel is boulder don't move
    if env.level.level[x][y]  == '#' then
        reset_player = true
    end

    -- if next is boulder move boulder too
    if env.level.boxes[x] and env.level.boxes[x][y] then
        -- calculate next position of box
        local box_x = x + dir.x
        local box_y = y + dir.y
        -- if box is movebal move :)
        if env.level.level[box_x][box_y]  ~= '#' and not (env.level.boxes[box_x] and env.level.boxes[box_x][box_y]) then
            env.level.boxes[x][y] = false
            env.level.boxes[box_x] = env.level.boxes[box_x] or {}
            env.level.boxes[box_x][box_y] = true
        else 
            reset_player = true
        end
    end

    -- dont move the player if some unallowed movement occured
    if reset_player then
        self.pos.x = old_pos.x
        self.pos.y = old_pos.y
    end
    x, y = round(self.pos.x), round(self.pos.y)
    -- remove old position
    wall:pixel(round(old_pos.x), round(old_pos.y), env.level.background_color)
    wall:pixel(x, y, self.color)
    --end
end

function Player:draw()
    local x, y = self.pos.x, self.pos.y
end

--------------------------------------------------------------------------------

Level = Object:new()
function Level:init(opts)
    self.level_size = {x = 16, y = 16}
    self.level = {}
    self.boxes = {}
    self.holes = {}
    self.current_level = 1
    self.boulder_color = hex( 0, 0, 150 )
    self.box_color = hex( 200, 200, 0 )
    self.hole_color = hex( 150, 0, 0)
    self.filled_color = hex( 0, 150, 0)
    self.background_color = hex(0, 0, 0)
    self.player = {x = 0, y = 0}

end

function Level:update()
    --redraw holes
    for x in pairs(self.holes) do
        for y in pairs(self.holes[x]) do
            if self.holes[x][y] then
                wall:pixel(x, y, self.hole_color)
            end
        end
    end
    --redraw boxes
    for x in pairs(self.boxes) do
        for y in pairs(self.boxes[x]) do
            if self.boxes[x][y] and self.holes[x] and self.holes[x][y] then
                wall:pixel(x, y, self.filled_color)
            elseif self.boxes[x][y] then
                wall:pixel(x, y, self.box_color)
            end
        end
    end
end

function Level:draw(opts)
    local pos_x = 0
    local pos_y = 0

    -- redraw whole screen
    self.level = {}
    self.boxes = {}
    self.holes = {}
    for x = 0, self.level_size['x'] do
        for y = 0, self.level_size['y'] do
            wall:pixel(x, y, self.background_color)
        end
    end

    -- place the level in the middle of the field
    local start_pos_x = math.floor((self.level_size.x - level_stack[self.current_level]['width']) / 2 )
    pos_x = start_pos_x
    local start_pos_y = math.floor((self.level_size.y - level_stack[self.current_level]['height']) / 2 )
    pos_y = start_pos_y

    for _, line in ipairs(level_stack[self.current_level]) do
        for c in line:gmatch('.') do
            self.level[pos_x] = self.level[pos_x] or {}
            self.level[pos_x][pos_y] =  c
            if c == '#' then
                wall:pixel(pos_x, pos_y, self.boulder_color)
            elseif c == '$' then
                wall:pixel(pos_x, pos_y, self.box_color)
                self.boxes[pos_x] = self.boxes[pos_x] or {}
                self.boxes[pos_x][pos_y] = true
            elseif c == '.' then
                wall:pixel(pos_x, pos_y, self.hole_color)
                self.holes[pos_x] = self.holes[pos_x] or {}
                self.holes[pos_x][pos_y] = true
            elseif c == '*' then
                wall:pixel(pos_x, pos_y, self.box_color)
                self.holes[pos_x] = self.holes[pos_x] or {}
                self.holes[pos_x][pos_y] = true
                self.boxes[pos_x] = self.boxes[pos_x] or {}
                self.boxes[pos_x][pos_y] = true
            elseif c == '@' then
                env.player.pos.x = pos_x
                env.player.pos.y = pos_y
            end
            pos_x = pos_x + 1
        end
        pos_x = start_pos_x
        pos_y = pos_y + 1
    end
end

function Level:nextLevel(opts)
    self.current_level = (self.current_level) % #level_stack + 1
    self:draw()
end

function Level:restartLevel(opts)
    self:draw()
end

--------------------------------------------------------------------------------

function update()
    wall:update_input()

    env.level:update()
    env.player:update()

    tick = tick + 1
end

function draw()

    env.player:draw()

end

--------------------------------------------------------------------------------

function love.load()
    local level_file = io.open('level.txt')


    local i = 0
    local level_counter = 0
    local current_level_height = 0
    for line in level_file:lines() do
        -- first 6 lines are copyright informations
        if i > 6 then
            -- empty line means new level
            if line == '' then
                level_counter = level_counter + 1
                current_level_height = 0
            elseif not string.match(line, '^;') then
                current_level_height = current_level_height + 1
                level_stack[level_counter] = level_stack[level_counter] or {height = 0, width = 0}
                table.insert(level_stack[level_counter], line)
                level_stack[level_counter]['height'] =  current_level_height
                level_stack[level_counter]['width'] =  math.max(level_stack[level_counter]['width'], string.len(line))
            end
        end
        i = i + 1
    end

    wall = Wall(false, 1338, 3, false) -- "176.99.24.251"
    --wall = Wall('176.99.24.251', 1338, 2, false) -- "176.99.24.251"

--     __maxd = math.sqrt(wall.width*wall.height)

    time = love.timer.getTime() * 1000

    env.player = Player {
        x = -1,
        y = -1
    }

    env.level = Level {}

    env.level:draw()

    tick = 0

end

function love.keypressed(key)
    if key == "escape" then
        love.event.push "q"
    end
    if key == "n" then
        env.level:nextLevel()
    end
    if key == "r" then
        env.level:restartLevel()
    end
end

function love.keyreleased(key)
    block_keyevents = false
end

function love.update(dt)
    -- constant 30 FPS
    local t = love.timer.getTime() * 1000
    time = time + 1000 / 23
    love.timer.sleep(time - t)

    update()
end


function love.draw()
    draw()
    -- send the stuff abroad
    wall:draw()
end
