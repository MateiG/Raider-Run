local gen_vector = require "scripts.gen_vector"

player = {}

function player:init(x, y, image, w, h)
  self.pos = gen_vector:init(x, y) or gen_vector:init(0, 0)
  self.box = gen_vector:init(w, h) or gen_vector:init(0, 0)
  self.spr = love.graphics.newImage()
end

function player:draw()
     love.graphics.draw(self.pos.x, self.pos.y, self.spr)
end
