-- local gen_vector = class()

vector = {}
function gen_vector:init(x, y)
    self.x = x
    self.y = y
end

function gen_vector:add(v)
    return gen_vector(self.x + v.x, self.y + v.y)
end

function gen_vector:sub(v)
    return gen_vector(self.x - v.x, self.y - v.y)
end

function gen_vector:mul(s)
    return gen_vector(self.x * s, self.y * s)
end

function gen_vector:div(s)
    return gen_vector(self.x/s, self.y/s)
end

function gen_vector:mag()
    return math.sqrt(self.x*self.x + self.y*self.y)
end

function gen_vector:norm()
    return self:div(self:mag())
end

return gen_vector
