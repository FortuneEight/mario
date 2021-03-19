--[[
    GD50
    Super Mario Bros. Remake

    -- PlayState Class --
]]

PlayState = Class{__includes = BaseState}

local key = love.graphics.newImage('graphics/key.png')
local goalpost = love.graphics.newImage('graphics/goalpost.png')
local keyScale = 1
LEVEL_NUM = 0

SAVED_X = 0
SAVED_Y = 0

function PlayState:init()
    self.camX = 0
    self.camY = 0
    self.level = LevelMaker.generate(100, 15)
    self.length = 100
    self.tileMap = self.level.tileMap
    self.background = math.random(3)
    self.backgroundX = 0
    LEVEL_NUM = 1
    PLAYER_WALK_SPEED = 60

    self.gravityOn = true
    self.gravityAmount = 6

    self.player = Player({
        x = 0, y = 0,
        width = 16, height = 20,
        texture = 'green-alien',
        stateMachine = StateMachine {
            ['idle'] = function() return PlayerIdleState(self.player) end,
            ['walking'] = function() return PlayerWalkingState(self.player) end,
            ['jump'] = function() return PlayerJumpState(self.player, self.gravityAmount) end,
            ['falling'] = function() return PlayerFallingState(self.player, self.gravityAmount) end
        },
        map = self.tileMap,
        level = self.level,
        hasHit = false,
        hasKey = false
    })

    -- self.normTiles = {}
    -- local counter1 = 0
    -- local counter2 = 0
    -- for k, tile in pairs(self.level) do
    --     if tile
    -- end

    self.allLevels = {}

    self.keyX = math.random((self.length / 2) * TILE_SIZE)
    self.keyY = math.random(VIRTUAL_HEIGHT / 4)
    self.keyIsTaken = false

    self:spawnEnemies()

    self.player:changeState('falling')
end

function PlayState:update(dt)
    -- self.level.objects = self.player.level.objects
    -- self.tileMap = self.player.tileMap
    Timer.update(dt)

    -- remove any nils from pickups, etc.
    self.level:clear()

    -- update player and level
    self.player:update(dt)
    self.level:update(dt)
    self:updateCamera()

    -- if self.player.x - self.player.width > self.keyX and self.player.x - self.player.width < self.keyX + 20 and self.player.y - self.player.width > self.keyY and self.player.y - self.player.height < self.keyY + 20 then
    --     self.keyIsTaken = true
    -- else
    --     if self.keyIsTaken ~= true then
    --         self.keyIsTaken = false
    --     end
    -- end

    if self.player.x > self.keyX + (7 * keyScale) or self.keyX > self.player.x + self.player.width then
        if self.keyIsTaken ~= true then
            self.keyIsTaken = false
            self.player.hasKey = false 
        end
    elseif self.player.y > self.keyY + (4 * keyScale) or self.keyY > self.player.y + self.player.height then
        if self.keyIsTaken ~= true then
            self.keyIsTaken = false
            self.player.hasKey = false 
        end
    else
        if self.keyIsTaken ~= true then
            gSounds['pickup']:play()
        end
        self.keyIsTaken = true
        self.player.hasKey = true  
    end

    -- constrain player X no matter which state
    if self.player.x <= 0 then
        self.player.x = 0
    elseif self.player.x > TILE_SIZE * self.tileMap.width - self.player.width then
        self.player.x = TILE_SIZE * self.tileMap.width - self.player.width
    end

    if math.floor(self.player.x / TILE_SIZE) == self.length - 1 and self.keyIsTaken == true and self.player.hasHit then
        gSounds['pickup']:play()
        if LEVEL_NUM == 5 then
            gStateMachine:change('win')
        end
        SAVED_X = 0
        SAVED_Y = 0
        self.length = self.length + 50
        self.level = LevelMaker.generate(self.length, 15)
        self.tileMap = self.level.tileMap
        self.player.map = self.tileMap
        self.player.level = self.level
        self.player.x = 0
        self.player.y = 0
        self.player.hasKey = false
        self.player.hasHit = false
        self.background = math.random(3)
        self:spawnEnemies()
        LEVEL_NUM = LEVEL_NUM + 1
        self.keyX = math.random((self.length / 2) * TILE_SIZE)
        self.keyY = math.random(VIRTUAL_HEIGHT / 4)
        self.keyIsTaken = false
        PLAYER_WALK_SPEED = math.min(PLAYER_WALK_SPEED * 1.2, 200)
    end

    if love.keyboard.isDown('r') then
        -- reset player
        self.player.x = SAVED_X
        self.player.y = SAVED_Y
        self.player.dy = 0
        self.player:changeState('falling')
    end

    if love.keyboard.isDown('p') then
        SAVED_X = self.player.x
        SAVED_Y = self.player.y
    end
end

function PlayState:render()
    love.graphics.push()
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    
    -- translate the entire view of the scene to emulate a camera
    love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))
    
    self.level:render()

    self.player:render()

    -- key test
    -- love.graphics.setColor(0, 0, 0, 1)
    -- if self.keyIsTaken ~= true then
    --     love.graphics.rectangle('fill', self.keyX, self.keyY, 20, 20)
    -- end

    -- key
    love.graphics.push()
    love.graphics.scale(0.5, 0.5)
    if self.keyIsTaken ~= true then
        -- love.graphics.scale(keyScale, keyScale)
        love.graphics.draw(key, self.keyX * 2, self.keyY * 2)
    elseif self.keyIsTaken and self.player.hasHit ~= true then
        love.graphics.draw(key, (self.player.x - TILE_SIZE) * 2, self.player.y * 2)
    elseif self.keyIsTaken and self.player.hasHit then
        love.graphics.draw(goalpost, ((self.length * TILE_SIZE) - 20) * 2, (VIRTUAL_HEIGHT / 3) * 2)
    end
    love.graphics.pop()
    love.graphics.pop()
    
    -- render score
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(tostring(self.player.score), 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(self.player.score), 4, 4)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(tostring(math.floor(((self.player.x / TILE_SIZE) / self.length) * 1000) / 10) .. '%', 5, VIRTUAL_HEIGHT - 40)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print(tostring(math.floor(((self.player.x / TILE_SIZE) / self.length) * 1000) / 10) .. '%', 4, VIRTUAL_HEIGHT - 40)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print('Level ' .. tostring(LEVEL_NUM), 5, VIRTUAL_HEIGHT - 25)
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.print('Level ' .. tostring(LEVEL_NUM), 4, VIRTUAL_HEIGHT - 25)

    -- on the bottom, make a green slider
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.rectangle('fill', 0, VIRTUAL_HEIGHT - 10, ((self.player.x / TILE_SIZE) / self.length) * VIRTUAL_WIDTH, 10)

    


    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:updateCamera()
    -- clamp movement of the camera's X between 0 and the map bounds - virtual width,
    -- setting it half the screen to the left of the player so they are in the center
    self.camX = math.max(0,
        math.min(TILE_SIZE * self.tileMap.width - VIRTUAL_WIDTH,
        self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

    -- adjust background X to move a third the rate of the camera for parallax
    self.backgroundX = (self.camX / 3) % 256
end

--[[
    Adds a series of enemies to the level randomly.
]]
function PlayState:spawnEnemies()
    -- spawn snails in the level
    for x = 1, self.tileMap.width do

        -- flag for whether there's ground on this column of the level
        local groundFound = false

        for y = 1, self.tileMap.height do
            if not groundFound then
                if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
                    groundFound = true

                    -- random chance, 1 in 20
                    if math.random(20) == 1 then
                        
                        -- instantiate snail, declaring in advance so we can pass it into state machine
                        local snail
                        snail = Snail {
                            texture = 'creatures',
                            x = (x - 1) * TILE_SIZE,
                            y = (y - 2) * TILE_SIZE + 2,
                            width = 16,
                            height = 16,
                            stateMachine = StateMachine {
                                ['idle'] = function() return SnailIdleState(self.tileMap, self.player, snail) end,
                                ['moving'] = function() return SnailMovingState(self.tileMap, self.player, snail) end,
                                ['chasing'] = function() return SnailChasingState(self.tileMap, self.player, snail) end
                            }
                        }
                        snail:changeState('idle', {
                            wait = math.random(5)
                        })

                        table.insert(self.level.entities, snail)
                    end
                end
            end
        end
    end
end