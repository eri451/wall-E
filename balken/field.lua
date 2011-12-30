Field = Object:new()

require "bot"
require "draw"

function Field:init(pos, key_state)
	self.pos = pos
	self.key_state = key_state
	self.height = 15
	self.width = 7

	-- init clear grid
	self.grid = {}
    for h = 1, self.width do
        local layer = {}
        for i = 1, self.height do
            local row = {}
            for j = 1, self.width do
                row[j] = 0
            end
            layer[i] = row
        end
        self.grid[h] = layer
    end

	-- how many different sorts of gems
	self.level = 5
	-- inverse dropping speed
	self.drop_delay = 20

	-- start layer - 1
	self.layer = 0

	self.score = 0
	self.drop_count = 0
	self.combo_count = 0

	self.column = {}
	self:newColumn()

	self.state = "normal"
	self.state_delay = 0

	self.gems_in_line = {}
	self.opponent = nil

	self.raise = 0
	self.current_raise = 0

	self.input = { dx = 0, rep = 0 }

end


function Field:setOpponent(opponent)
	self.opponent = opponent
end


function Field:raiseField(count)
	self.raise = self.raise + count
	if self.state == "normal" then
		self.state = "wait"
		self.state_delay = 10
	end
end


function Field:newColumn()
    self.layer = (self.layer + 1) % self.width + 1
	self.x = 4
	self.y = 1
	self.column[1] = math.random(self.level)
	self.column[2] = math.random(self.level)
	self.column[3] = math.random(self.level)
end


function Field:pushColumn()
	for y = 1, 3 do
		if self.y - y + 1 > 0 then
			self.grid[self.layer][self.y - y + 1][self.x] = self.column[y]
		end
	end
end



function Field:collision()
	if self.x < 1 or self.x > self.width or self.y > self.height then
		return true
	end
	for y = math.max(1, self.y - 2), self.y do
		if self.grid[self.layer][y][self.x] ~= 0 then
			return true
		end
	end
	return false
end


function Field:collapse()
	local grid = self.grid
	local ret = false
    for z = 1, self.width do
        for x = 1, self.width do
            local drop = false
            for y = self.height, 1, -1 do
                drop = drop or grid[z][y][x] == 0
                if drop then
                    grid[z][y][x] = grid[z][y - 1] and grid[z][y - 1][x] or 0
                    ret = grid[z][y][x] > 0 or ret
                end
            end
        end
    end
	return ret
end


function Field:update()

	self.state_delay = self.state_delay - 1
	if self.state == "normal" then

		local events = self:getInput()

		if events.rot then
			local c = self.column
			c[1], c[2], c[3] = c[3], c[1], c[2]
		end
		-- x-movement
		if events.dx ~= 0 then
			local x = self.x
			self.x = self.x + events.dx
			if self:collision() then
				self.x = x
			end
		end
		-- y-movement
		self.drop_count = self.drop_count + 1
		local y = self.y
		if events.down or self.drop_count >= self.drop_delay then
			self.y = self.y + 1
			self.drop_count = 0
		end
		if self:collision() then
			self.y = y

			self:pushColumn()
			if self.y < 3 then
				self.state = "over"
				self.state_delay = 30
			else
				-- check for gems to be removed from the grid
				self.combo_count = 0
				if self:findGemsInLine() then
					self.state = "highlight"
					self.state_delay = 20
				else
					self.state = "wait"
					self.state_delay = 10
				end
			end
		end

	elseif self.state == "highlight" then
		if self.state_delay == 0 then

			-- remove gems
			for _, coords in pairs(self.gems_in_line) do
				self.grid[coords.z][coords.y][coords.x] = 0
				self.score = self.score + 1
			end
			self.gems_in_line = {}

			self.state = "collapse"
			self.state_delay = 2
		end

	elseif self.state == "collapse" then
		if self.state_delay == 0 then

			if self:collapse() then
				-- keep collapsing
				self.state_delay = 2
			else
				if self:findGemsInLine() then
					self.state = "highlight"
					self.state_delay = 20
				else
					self.state = "wait"
					self.state_delay = 10

					-- initiate lowering of one's field
					-- and raising of opponent's field
					if self.combo_count > 1 then
						self.raise = self.raise - (self.combo_count - 1)
						if self.raise < 0 then
							if self.opponent then
								self.opponent:raiseField(-self.raise)
							end
							self.raise = 0
						end
					end

				end
			end
		end

	elseif self.state == "wait" then
		if self.state_delay == 0 then

			if self.current_raise > self.raise then
				-- lower the field
				self.current_raise = self.current_raise - 1

                for z = 1, self.width do
                    for x = 1, self.width do
                        for y = self.height, 2, -1 do
                            self.grid[z][y][x] = self.grid[z][y - 1][x]
                        end
                        self.grid[z][1][x] = 0
                    end
                end
				self.state_delay = 2

			elseif self.current_raise < self.raise then
				-- raise the field
				self.current_raise = self.current_raise + 1
				self.state_delay = 2
                for z = 1, self.width do
                    for x = 1, self.width do
                        if self.grid[z][1][x] > 0 then
                            self.state = "over"
                            self.state_delay = 30
                        end
                        for y = 1, self.height-1 do
                            self.grid[z][y][x] = self.grid[z][y + 1][x]
                        end
                        self.grid[z][self.height][x] = -1
                    end
                end

			else
				self:newColumn()
				self.state = "normal"
			end
		end

	elseif self.state == "over" then
		-- TODO

		if self.state_delay == 0 then
			love.event.push "q"
		end

	end
end

local spiral = {}
do
    local p = { x = 0, y = 0 }
    local d, n, s = "y", 1, 1
    for c = 1, 3 do
        for _ = 1, 2 do
            for i = 1, n do
                table.insert(spiral, {p.x,p.y})
                p[d] = p[d] + s*1
            end
        d = d == "y" and "x" or "y"
        end
        s = s * -1
        n = n + 1
    end
end

function Field:findGemsInLine()

	-- TODO: make the code look nicer

	local grid = self.grid
	local z = self.layer

	local function addGem(x, y, z)
		self.gems_in_line[y .. " " .. x .. " " .. z] = { x = x, y = y, z = z }
	end

    local function getCell(x, y, z)
        z = grid[z]
        if z ~= nil then
            y = z[y]
            if y ~= nil then
                return y[x]
            end
        end
    end

    for z = 1, self.width-2 do
        for y = 1, self.height-2 do
            for x = 1, self.width-2 do
                for _, range in ipairs({ {1,9,1}, {2,5,0} }) do
                    local _y = range[3]
                    for i = range[1], range[2] do
                        local _x, _z = spiral[i][1], spiral[i][2]
                        local cell = getCell(x,y,z)
                        if cell > 0 and
                           cell == getCell(x + 1*_x, y + 1*_y, z + 1*_z) and
                           cell == getCell(x + 2*_x, y + 2*_y, z + 2*_z) then
                            addGem(x, y, z)
                            addGem(x + 1*_x, y + 1*_y, z + 1*_z)
                            addGem(x + 2*_x, y + 2*_y, z + 2*_z)
                            self.combo_count = self.combo_count + 1
                        end
                    end
                    -- the turbine
                end
            end
        end
    end

	-- return true if we found something
	return next(self.gems_in_line) ~= nil
end



