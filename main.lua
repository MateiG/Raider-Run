--[[
    CSIM 2018
    Lecture 1

    -- Main Program --
    Author: Lucas N. Ferreira
    lferreira@ucsc.edu
]]

-- Loading external libraries
local sti = require "lib.sti"
local push = require "lib.push"
require("camera")

-- Setting values of global variables
local gameWidth, gameHeight = 1280, 640
local maxWidth, maxHeight = 5400, 640
local windowWidth, windowHeight, flags = love.window.getMode()
gravity = 185
generated_missile = false

items_loc = {
	scroll_x = 320,
	scroll_y = 165,
	axe_x = 590,
	axe_y = 170
}
tree1 = {
	x = 325,
	y = 195,
	w = 115,
	h = 214
}
tree2 = {
	x = 576,
	y = 195,
	w = 115,
	h = 214
}
tree3 = {
	x = 1088,
	y = 195,
	w = 115,
	h = 214
}
ground = {
	x = 0,
	y = 360,
	w = 5400,
	h = 280
}

function generate_player()
	player = {
		x = gameWidth / 2,
		y = gameHeight / 2 - 50,
		w = 28,
		h = 32
	}
	shield_sprite = love.graphics.newImage("sprites/shield.png")

	astronaut = love.graphics.newImage("sprites/astronaut.png")
	iron_man = love.graphics.newImage("sprites/iron_man.png")
	all_player_sprites = {astronaut, iron_man}
	-- player_left = love.graphics.newImage("sprites/hero_left.png")

	player.char = 2
	player.sprite = all_player_sprites[player.char]

	player.b = love.physics.newBody(world, player.x + player.w / 2, player.y + player.h / 2, "dynamic") -- "player" makes it not move
	player.s = love.physics.newRectangleShape(player.w, player.h)         -- set size to 200,50 (x,y)
	player.f = love.physics.newFixture(player.b, player.s)
	player.f:setUserData("Player")

	player.can_jump = true

	player.energy = 100

	player.rotate = 0

	player.move_speed = 450

	player.shield = 10

	player.score = 0
	god_sprite = love.graphics.newImage("sprites/god.png")
	-- particle_system = love.graphics.newParticleSystem(god_sprite, 1000)
end

function change_sprite()
	change = love.keyboard.isDown("c")
	if change then
		function love.keyreleased(key)
			if key == "c" then
				if player.char == 1 then
					player.char = 2
					player.move_speed = 450
					to_track = true
					fric = 1
					gravity = 185
				else
					player.char = 1
					player.move_speed = 150
					gravity = 0
					fric = 0
				end
				player.sprite = all_player_sprites[player.char]
		 end
		end
	end
end

function bound_player (pl_x, pl_y, pl_w, pl_h, edge, vel)

	if pl_y <= 5 then
		pl_y = 10
		player.b:setLinearVelocity(0, 100)
	end
	if pl_x <= 5 then
		pl_x = 10
		player.b:setLinearVelocity(100, 0)
	end
	if pl_x + pl_w >= edge - 5 then
		pl_x = edge - 10 - pl_w
		player.b:setLinearVelocity(-100, 0)
	end
	player.b:setPosition(pl_x, pl_y)
end

function get_input(r, l, u, d)

	if( love.keyboard.isDown(r) ) then
		player.b:applyForce(player.move_speed, 0)
		if player.rotate <= math.pi/2 then
			player.rotate = player.rotate + 0.08
		end
	end

	if( love.keyboard.isDown(l) ) then
		player.b:applyForce(-player.move_speed, 0)

		if player.rotate >= -math.pi/2 then
			player.rotate = player.rotate - 0.08
		end
	end

	if( love.keyboard.isDown(u) ) then
		if player.char == 2 then
			if player.energy > 10 then
				player.energy = player.energy - 1
				player.b:applyForce(0, -player.move_speed)
				if player.rotate <= -0.05 then
					player.rotate = player.rotate + 0.08
				elseif player.rotate >= 0.05 then
				player.rotate = player.rotate - 0.08
				end
			end
		else
			player.b:applyForce(0, -player.move_speed)

			if player.rotate <= -0.05 then
				player.rotate = player.rotate + 0.08
			elseif player.rotate >= 0.05 then
			player.rotate = player.rotate - 0.08
			end
		end
	end

	if( love.keyboard.isDown(d) ) then
		player.b:applyForce(0, player.move_speed)
	end
	player.b:setAngle(player.rotate)
end

function generate_missile()
	missile = {
		w = 12,
		h = 29,
	}
	missile.x = player.x + player.w / 2
	missile.y = player.y - player.h * 2
	missile.rotate = 0
	missile.speed = 400

	missile_sprite = love.graphics.newImage("sprites/missile.png")
	missile.sprite = missile_sprite

	missile.b = love.physics.newBody(world, missile.x + missile.h / 2, missile.y + missile.w / 2, "dynamic") -- "player" makes it not move
	missile.s = love.physics.newRectangleShape(missile.w, missile.h)         -- set size to 200,50 (x,y)
	missile.f = love.physics.newFixture(missile.b, missile.s)
	missile.f:setUserData("Missile")

	generated_missile = true
	missile.lowest = maxWidth + 1000
	missile.dif_coords = {missile.x, missile.y}
end

function missile_collide_enemy(col_dist, enemy_counter)
	if col_dist <= missile.w + missile.h then
		missile.b:destroy()
		missile = {}
		all_enemies[enemy_counter].b:destroy()
		table.remove(all_enemies, enemy_counter)
		generated_missile = false
	end
end

function enemy_collide_player(enem_co)
	distance = math.sqrt((all_enemies[enem_co].x - player.x)^2 + (all_enemies[enem_co].y - player.y) ^ 2)
	if distance < player.h * 2 then
		all_enemies[enem_co].b:destroy()
		table.remove(all_enemies, enem_co)
		player.shield = player.shield - 1
		-- print(player.shield)
		return true
	end
	return false
end

function update_missile()
	if generated_missile then
		missile.lowest = maxWidth + 1000
		lowest_en_c = #all_enemies
		for en_c = 1, #all_enemies do
			cur_en_x = all_enemies[en_c].x
			cur_en_y = all_enemies[en_c].y

			dif_x = cur_en_x - missile.x
			dif_y = cur_en_y - missile.y
			distance = math.sqrt(dif_x ^ 2 + dif_y ^ 2)
			-- norm_x = math.abs(dif_x)
			-- norm_y = math.abs(dif_y)
			if distance < missile.lowest then
				missile.lowest = distance
				missile.dif_coords = {dif_x, dif_y}
				lowest_en_c = en_c
			end
		end

		if #all_enemies == 0 then
			missile.b:setPosition(missile.x, missile.y)
			missile.rotate = -math.pi / 2
			missile.b:setAngle(missile.rotate - math.pi / 2)
		else
			ang_x = missile.dif_coords[1]
			ang_y = missile.dif_coords[2]

			missile.b:setLinearVelocity(missile.speed * (ang_x / missile.lowest), missile.speed * (ang_y / missile.lowest))
			missile.x = missile.b:getX()
			missile.y = missile.b:getY()

			missile.rotate = math.pi / 2 - math.atan2(missile.dif_coords[1] , missile.dif_coords[2])
			missile.b:setAngle(missile.rotate - math.pi / 2)
			missile_collide_enemy(missile.lowest, lowest_en_c)
		end
	end
	if generated_missile then
		if missile.x < 0 or missile.x > maxWidth or missile.y < 0 then
			missile.b:destroy()
			missile = {}
			generated_missile = false
		end
	end
end

function player_ability()
	activate = love.keyboard.isDown("space")
	if activate then
		function love.keyreleased(key)
			if key == "space" then
				if player.char == 2 then
					if generated_missile == false then
						-- print("shoot")
						generate_missile()
					end
				elseif player.char == 1 then
					if to_track then
						to_track = false
					else
						to_track = true
					end

				end
			end
		end
	end


	god_mode = love.keyboard.isDown("k")
	if god_mode then
		function love.keyreleased(key)
			if key == "k" then
				player.move_speed = 10000
				player.sprite = love.graphics.newImage("sprites/god.png")
				-- camera:setBounds(0, 0, 10000, 10000)
				camera:scale(2, 2)
				camera:setBounds(-10000 ^ 10, -10000 ^ 10, 10000 ^ 10, 10000 ^ 10)
				to_bound = false
				gravity = 0
				player.shield = 999
				player.energy = 999
			end
		end
	end

end

function generate_enemies(number_enemies)

	for i=1, number_enemies do
		enemy = {
			x = math.random(player.x - gameWidth / 2, player.x + gameWidth / 2),
			y = math.random(0, 100),
			w = 38,
			h = 36
		}
		enemy.sprite = love.graphics.newImage("sprites/baddy1.png")

		enemy.b = love.physics.newBody(world, enemy.x - enemy.w / 2, enemy.y - enemy.h / 2, "dynamic") -- "player" makes it not move
		enemy.s = love.physics.newRectangleShape(enemy.w, enemy.h)         -- set size to 200,50 (x,y)
		enemy.f = love.physics.newFixture(enemy.b, enemy.s)
		enemy.f:setUserData("Enemy" .. i)
		enemy.rotate = 0
		enemy.b:setAngle(enemy.rotate)
		table.insert(all_enemies, enemy)
		-- print(#all_enemies)
	end
end

function enemies_follow()
		for i = 1, #all_enemies do
			dif_x = all_enemies[i].x - player.x
			dif_y = all_enemies[i].y - player.y
			distance = math.sqrt(dif_x ^ 2 + dif_y ^ 2)
			if to_track then
				all_enemies[i].b:applyForce(200 * (player.x - all_enemies[i].x) / distance, 200 * (player.y - all_enemies[i].y) / distance)
				all_enemies[i].x = all_enemies[i].b:getX()
				all_enemies[i].y = all_enemies[i].b:getY()
			else
				all_enemies[i].b:applyForce(0,0)
				all_enemies[i].b:setPosition(all_enemies[i].x, all_enemies[i].y)
			end
		end
end

function remove_enemies ()
	index = 0
	for i = 1, #all_enemies do
		cur_en = all_enemies[i]
		if cur_en.x < 0 then
			index = i
		elseif cur_en.x + cur_en.w > maxWidth then
			index = i
		elseif cur_en.y < 0 then
			index = i
		elseif cur_en.y > ground.y + 100 then
			index = i
		end
	end
	if index > 0 then
		table.remove(all_enemies, index)
	end
end
function generate_trees(number_trees)
	all_trees = {}
	tree_sprite = love.graphics.newImage("sprites/PixelTree.png")
	for i=1, number_trees do
		tree = {
			x = 100
		}
		tree.x = tree.x + 300 * i
		tree.y = 195
		tree.w = 115
		tree.h = 214

		tree.b = love.physics.newBody(world, tree.x + tree.w/2 + 20, tree.y + tree.h/2, "static")
		tree.s = love.physics.newRectangleShape(tree.w, tree.h)         -- set size to 200,50 (x,y)
		tree.f = love.physics.newFixture(tree.b, tree.s)
		tree.f:setUserData("Tree"..i)
		tree.sprite = tree_sprite

		table.insert(all_trees, tree)
	end
end

function love.load()
 	font = love.graphics.newFont("fonts/neuro_font.ttf")
	love.graphics.setFont(font)
	has_paused = false
	game_over = false
	to_bound = true
	new_t = 0

	push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {fullscreen = false})

	all_enemies = {}
	all_missiles = {}
	time_c = 0
	fric = 1
	to_track = true
	en_gen = 1

	-- world = love.physics.newWorld(0, 285, true)
	world = love.physics.newWorld(0, gravity, true)

	background = love.graphics.newImage("map/testMap.png")
	paused_pic = love.graphics.newImage("sprites/pausedPic.png")

	enemy_sprite = love.graphics.newImage("sprites/baddy1.png")

	generate_player()
	generate_enemies(2)
	-- generate_trees(3)


	ground.b = love.physics.newBody(world, ground.x + ground.w/2, ground.y + ground.h / 2 + 20, "static") -- "player" makes it not move
	ground.s = love.physics.newRectangleShape(ground.w, ground.h)         -- set size to 200,50 (x,y)
	ground.f = love.physics.newFixture(ground.b, ground.s)
	ground.f:setFriction(fric)
	ground.f:setUserData("Ground")
	camera:setBounds(0, 0, maxWidth - gameWidth, maxHeight - gameHeight)

end

function love.update(dt)
	paused = love.keyboard.isDown("p")
	if paused then
		function love.keyreleased(key)
			if key == "p" then
				if has_paused == true	then
					has_paused = false
				else
					has_paused = true
				end
			end
		end
	end
	if has_paused == false then
		new_t = new_t + 1
		if new_t % 10 == 0 then
			player.score = player.score + 1
		end
		print(player.score)
		if to_bound then
			camera:setPosition(player.x - gameWidth / 2, player.y - gameHeight / 2)
		else
			camera:setPosition(player.x- gameWidth * (camera.scaleX / 2), player.y - gameHeight * (camera.scaleY / 2))
		end
		time_c = time_c + 1
		en_gen = en_gen + 1
		if time_c >= 60 * 3 then
			time_c = 0
			generate_enemies(math.floor(1 + en_gen / (60 * 3)))
			print(en_gen % (60 * 3))
			print("real")
			print(en_gen)
		end
		if player.energy < 100 then
			player.energy = player.energy + 0.2
		end
		if to_track == false then
			player.energy = player.energy - 0.3
		end
		if player.energy <= 0 then
			player.shield = player.shield - 0.01
			player.energy = 0
		end
		if player.y > 343 then
			player.shield = player.shield - 0.01
		end
		-- player.energy = player.energy + 1
		-- print(player.energy)


		get_input("d", "a", "w", "s", player.x, player.y, 100, jump_speed)
		if to_bound then
			bound_player(player.x, player.y, player.w, player.h, maxWidth, 75)
		end
		change_sprite()
		player_ability()
		enemies_follow()
		remove_enemies()
		update_missile()

		for a = 1, #all_enemies do
			br = enemy_collide_player(a)
			if br then
				break
			end
		end
		if(player.shield <= 0) then
			love.load()
		end

		-- update_enemy()
		world:setGravity(0, gravity)
		world:update(dt)


		player.x, player.y = player.b:getPosition()
		-- print(x .. "    " .. y)
		-- print(love.mouse.getX() .. "  " .. love.mouse.getY())
	end
	leave = love.keyboard.isDown("escape")
	if leave then
		love.event.quit()
	end
end

function love.draw()
	push:start()
  camera:set()
	-- enemy_actions()

	love.graphics.draw(background, 0, 0)
	-- for index = 1, #all_trees do
	-- 	love.graphics.draw(all_trees[index].sprite, all_trees[index].x, all_trees[index].y)
	-- 	love.graphics.polygon("line", all_trees[index].b:getWorldPoints(all_trees[index].s:getPoints()))
	-- 	-- print(all_trees[index].x)
	-- end

	for index = 1, #all_enemies do
		love.graphics.draw(all_enemies[index].sprite, all_enemies[index].x - all_enemies[index].w / 2, all_enemies[index].y - all_enemies[index].h / 2)
		-- love.graphics.polygon("line", all_enemies[index].b:getWorldPoints(all_enemies[index].s:getPoints()))
	end
	love.graphics.draw(player.sprite, player.x, player.y, player.rotate, 1, 1, player.w/2, player.h/2)
	-- love.graphics.polygon("line", player.b:getWorldPoints(player.s:getPoints()))
	if generated_missile then
		love.graphics.draw(missile.sprite, missile.x, missile.y, missile.rotate, 1, 1, missile.w / 2, missile.h / 2)
		-- love.graphics.polygon("line", missile.b:getWorldPoints(missile.s:getPoints()))
	end
	love.graphics.setColor(0,0,0,1)
	love.graphics.print("Press K...", 1200, 600)
	love.graphics.setColor(0,0,0,0)
	camera:unset()
	love.graphics.draw(shield_sprite, 125, 0)
	love.graphics.print(math.floor(player.shield), 150, 0)
	love.graphics.setColor(0,0,0,1)

	if player.energy < 30 or player.shield < 3  then
		love.graphics.setColor(1,0,0,1)
	else
		love.graphics.setColor(0,0,0,1)
	end

	love.graphics.print(player.shield, 150, 0)
	love.graphics.print("Energy: " .. math.floor(player.energy) .. "%", 0, 0)
	if player.char == 1 then
		love.graphics.print("NO GRAVITY", 0, 50)
	end
	if has_paused then
		love.graphics.draw(paused_pic, gameWidth / 2 - 100, gameHeight / 2 - 100)
	end

	if player.shield <= 0 then
		love.graphics.print("Did you find the easter-egg? Try again!", gameWidth / 2 - 100, gameHeight / 2 - 100)
	end
	love.graphics.print("Score: " .. player.score, gameWidth - 90, 0)
	push:finish()
end

function sigmoid(x, l, k, input)
	e = 2.718281828459
	return (l / (1 + e ^ (-k * (input - x))))
end

function math.clamp(x, min, max)
  return x < min and min or (x > max and max or x)
end
