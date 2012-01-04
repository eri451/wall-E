
local string = string
local floor = math.floor


local gem_colors = {}
gem_colors[-2] = {136, 136, 136}   -- border
gem_colors[-1] = { 85,  85,  85}   -- brick
gem_colors[0] =  {  0,   0,   0}   -- background

gem_colors[1] = {187,  34,   0}
gem_colors[2] = {  0, 170, 187}
gem_colors[3] = {  0, 187,   0}
gem_colors[4] = {187, 187,   0}
gem_colors[5] = {136,   0, 187}
gem_colors[6] = {  0, 187, 187}

local function Color(c)
    return string.format("%02X%02X%02X", floor(c[1]), floor(c[2]), floor(c[3]))
end


function Field:draw()

    local layer = self.layer
    if self.state ~= "normal" then
        layer = (layer - 1) % self.width + 1
    end

    local g = {}
    for i = 0, self.height+1 do
        local row = {}
        for j = 0, self.width+1 do
            row[j] = {}
            for i, col in ipairs(gem_colors[0]) do
                row[j][i] = col
            end
        end
        g[i] = row
    end

    for _z = 0, self.width+1 do
        local z = ((self.width - _z) + layer) % self.width + 1
        for y = 0, self.height+1 do
            local row = self.grid[z][y] or {}
            for x = 0, self.width+1 do

                local gem = row[x]
                if self.state == "normal" and y > 0 and x == self.x then
                    -- also draw active column
                    gem = self.column[self.y - y + 1] or gem
                end
                local is_empty =
                    g[y][x][1] == gem_colors[0][1] and
                    g[y][x][2] == gem_colors[0][2] and
                    g[y][x][3] == gem_colors[0][3]
                gem = gem or -2
                for i, col in ipairs(gem_colors[gem]) do
                    if is_empty or gem ~= 0 then
                        g[y][x][i] = col * _z/(self.width+1)
                        if gem ~= -2 then
                            g[y][x][i] = g[y][x][i] * (
                                (z == layer or
                                (x==self.x and
                                y>=self.y-2 and
                                y<=self.y)) and
                                1 or 0.3)
                        end
                    end
                end
            end
        end
    end
    for y = 0, self.height+1 do
        for x = 0, self.width+1 do
            wall:pixel(self.pos + x-1, y-1, Color(g[y][x]))
        end
    end

	-- draw flashing gems
	if self.state == "highlight" then
		for _, coords in pairs(self.gems_in_line) do
			local color = ({ "ffffff", "000000" })[self.state_delay % 3 + 1]
			if color then
				wall:pixel(self.pos + coords.x-1, coords.y-1, color)
			end
		end
	end

	-- draw score
	local score = self.score
	local y = self.height
	local x = self.pos == 0 and self.width or self.pos-1
	while score > 0 and y >= 0 do
		if score % 2 > 0 then
			wall:pixel(x, y, "aaaaaa")
		end
		score = math.floor(score / 2)
		y = y - 1
	end
end


