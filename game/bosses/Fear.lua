local Boss = require("game.Boss")
local EnemyBullet = require("game.EnemyBullet")
local EnemyBulletEgg = require("game.EnemyBulletEgg")
local PatternManager = require("game.bullets.PatternManager")
local BasePattern = require("game.bullets.BasePattern")
local MultiPattern = require("game.bullets.MultiPattern")
local LambdaPattern = require("game.bullets.LambdaPattern")
local ChargeFanPattern = require("game.bullets.ChargeFanPattern")
local FearBubble = require("game.bosses.FearBubble")

local Turret = require("game.enemies.Turret")
local Mine = require("game.enemies.Mine")
local SuperMine = require("game.enemies.SuperMine")

local Fear = class("game.bosses.Fear", Boss)

local MAX_HEALTH = 600
local ENTER_TIME = 2

Fear.static.STATE_ENTER = 1
Fear.static.STATE_PHASE1 = 2
Fear.static.STATE_PHASE2 = 3
Fear.static.STATE_PHASE3 = 4
Fear.static.STATE_EXPLODING = 5

function Fear:enter()
	Boss.enter(self, "Fear", MAX_HEALTH)

	self.destx = settings.screen_width / 2
	self.desty = 120
	self.x = self.destx
	self.y = -80

	self.state = Fear.static.STATE_ENTER
	self.entered_time = 0
	self.active = false
	self.puking = 0
	self.next_blink = 2*love.math.random()+5

	self.face_anim = prox.Animator("data/animators/bosses/fear_face.lua")
	self.body_anim = prox.Animation("data/animations/bosses/fear_idle.lua")

	self:setRenderer(prox.MultiRenderer())
	self:getRenderer():addRenderer(self.body_anim)
	self:getRenderer():addRenderer(self.face_anim)

	self:setCollider(prox.BoxCollider(170, 54, 0, -12))

	prox.timer.tween(ENTER_TIME, self, {y = self.desty}, "out-sine", function()
		self.active = true
		self.state = Fear.static.STATE_PHASE1
	end)

	self:initPatterns()
end

function Fear:update(dt, rt)
	Boss.update(self, dt, rt)

	if not self.active then
		return
	end

	if self.state == Fear.static.STATE_PHASE1 and self.health < MAX_HEALTH*0.75 then
		self.state = Fear.static.STATE_PHASE2
	elseif self.state == Fear.static.STATE_PHASE2 and self.health < MAX_HEALTH*0.5 then
		self.state = Fear.static.STATE_PHASE3
	end

	if self.left_turret and not self.left_turret:isAlive() then self.left_turret = nil end
	if self.right_turret and not self.right_turret:isAlive() then self.right_turret = nil end

	self.puking = self.puking - dt
	if self.puking <= 0 then
		self.entered_time = self.entered_time + dt
		self.x = self.destx + math.sin(self.entered_time)*8
		self.y = self.desty + math.sin(self.entered_time*1.1)*6
	end

	self.next_blink = self.next_blink - dt
	if self.next_blink <= 0 then
		self.next_blink = 2*love.math.random()* 5
		self.face_anim:setProperty("blink", true)
	end

	self.patterns[self.state]:update(dt)
end

function Fear:initPatterns()
	self.patterns = {}

	local ptn_spawn_turret_left = LambdaPattern(self, 0, 0,
		function(o)
			if not self.left_turret then
				self.face_anim:setProperty("puke", true)
				self.puking = 0.9
				prox.timer.after(0.4, function()
					self.left_turret = self:getScene():add(FearBubble(self.x, self.y+36, 48, 148, 2, function()
						self.left_turret = Turret({x = 48, speed = 0, salvo_size = 1})
						self:getScene():add(self.left_turret)
						self.left_turret.y = 148
					end))
				end)
			end
		end,
		{ delay = 999 }
	)

	local ptn_spawn_turret_right = LambdaPattern(self, 0, 0,
		function(o)
			if not self.right_turret then
				self.face_anim:setProperty("puke", true)
				self.puking = 0.9
				prox.timer.after(0.4, function()
					self.right_turret = self:getScene():add(FearBubble(self.x, self.y+36, 272, 148, 2, function()
						self.right_turret = Turret({x = 272, speed = 0, salvo_size = 1})
						self:getScene():add(self.right_turret)
						self.right_turret.y = 148
					end))
				end)
			end
		end,
		{ delay = 999 }
	)

	local ptn_spawn_mine_left = LambdaPattern(self, 0, 0,
		function(o)
			if not self.left_turret then
				self.face_anim:setProperty("puke", true)
				self.puking = 0.9
				prox.timer.after(0.4, function()
					self.left_turret = self:getScene():add(FearBubble(self.x, self.y+36, 48, 148, 2, function()
						self.left_turret = SuperMine({x = 48, y = 149, speed = 0.25})
						self:getScene():add(self.left_turret)
						self.left_turret.y = 148
					end))
				end)
			end
		end,
		{ delay = 999 }
	)

	local ptn_spawn_mine_right = LambdaPattern(self, 0, 0,
		function(o)
			if not self.right_turret then
				self.face_anim:setProperty("puke", true)
				self.puking = 0.9
				prox.timer.after(0.4, function()
					self.right_turret = self:getScene():add(FearBubble(self.x, self.y+36, 272, 148, 2, function()
						self.right_turret = SuperMine({x = 272, y = 149, speed = 0.25})
						self:getScene():add(self.right_turret)
						self.right_turret.y = 148
					end))
				end)
			end
		end,
		{ delay = 999 }
	)

	local ptn_down = BasePattern(self, 0, 37, {
		start_rotation = math.pi/2,
		shot_delay = 0.13,
		salvo_size = 4,
		salvo_delay = 999
	})

	local ptn_target_left = BasePattern(self, -52, 8, {
		salvo_size = 1,
		salvo_delay = 999,
		target_player = true
	})

	local ptn_target_right = BasePattern(self, 52, 8, {
		salvo_size = 1,
		salvo_delay = 999,
		target_player = true
	})

	local ptn_fan = ChargeFanPattern(self, 0, 0, {
		salvo_delay = 999,
		salvo_size = 5,
		fan_rotation = math.pi/2 - 0.5,
		fan_rotation_offset = 0.25,
		fan_radius = 40
	})

	local ptn_salvo_targeted = BasePattern(self, 0, 37, {
		shot_delay = 0.13,
		salvo_size = 4,
		target_player = true,
		salvo_delay = 999
	})

	local ptn_down_left = BasePattern(self, -52, 8, {
		salvo_size = 1,
		salvo_delay = 999,
		start_rotation = math.pi/2
	})

	local ptn_down_right = BasePattern(self, 52, 8, {
		salvo_size = 1,
		salvo_delay = 0.51,
		start_rotation = math.pi/2
	})

	local ptn_down_leftright = MultiPattern({
		ptn_down_left,
		ptn_down_right
	})

	-- PHASE 1 patterns
	local man1 = PatternManager()
	self.patterns[Fear.static.STATE_PHASE1] = man1
	man1:add(ptn_spawn_turret_left, 1.5)
	man1:add(ptn_down, 1.60)
	man1:add(ptn_target_left, 2.0)
	man1:add(ptn_target_right, 2.0)
	man1:add(ptn_spawn_turret_right, 3)
	man1:add(ptn_down, 1.60)
	man1:add(ptn_target_left, 2.0)
	man1:add(ptn_target_right, 2.0)

	-- PHASE 2 patterns
	local man2 = PatternManager()
	self.patterns[Fear.static.STATE_PHASE2] = man2
	man2:add(ptn_spawn_turret_left, 1.5)
	man2:add(ptn_spawn_turret_right, 3)
	man2:add(ptn_fan, 2)
	man2:add(ptn_fan, 3)
	man2:add(ptn_down_leftright, 1.0)

	-- PHASE 3 patterns
	local man3 = PatternManager()
	self.patterns[Fear.static.STATE_PHASE3] = man3
	for i=1, 2 do
		if i == 1 then
			man3:add(ptn_spawn_mine_left, 3)
		else
			man3:add(ptn_spawn_mine_right, 3)
		end
		man3:add(ptn_salvo_targeted, 2.0)
		man3:add(ptn_salvo_targeted, 2.0)
		man3:add(ptn_target_left, 2.0)
		man3:add(ptn_target_right, 2.0)
	end
end

function Fear:kill()
	Boss.kill(self)

	self.active = false
	self.state = Fear.static.STATE_EXPLODING
	self:getScene():find("screenshaker"):shake(4, 3, 60)

	prox.timer.after(3, function()
		self:purge()
	end)
end

function Fear:getGems()
	return 20
end

return Fear
