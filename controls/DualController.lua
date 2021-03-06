local PlayerController = require("controls.PlayerController")
local Ship = require("game.Ship")

local DualController = class("controls.DualController", PlayerController)

local SWITCH_COOLDOWN = 0.30
local SWITCH_MAX_SPEED = 10

function DualController:enter(binding, ship_left, ship_right, chain, switch)
	PlayerController.enter(self, binding, ship_left, ship_right, chain)

	self.switch = switch or false
	self.switch_cooldown = 0
	self.trigger_down = false
end

function DualController:update(dt, rt)
	self.ship_left:setMovement(self.binding:getAxis("leftx"), self.binding:getAxis("lefty"))
	self.ship_right:setMovement(self.binding:getAxis("rightx"), self.binding:getAxis("righty"))

	if self.binding:isDown("leftshoot") then
		self.ship_left:shoot()
	end
	if self.binding:isDown("rightshoot") then
		self.ship_right:shoot()
	end

	if self.binding:wasPressed("leftretract") then
		self.chain:retract(1)
	end

	if self.binding:wasPressed("rightretract") then
		self.chain:retract(2)
	end

	if self.binding:getAxis("triggerright") > 0.6 then
		if not self.trigger_down then
			self.chain:sword()
		end
		self.trigger_down = true
	elseif self.binding:getAxis("triggerright") < 0.4 then
		self.trigger_down = false
	end

	local leftsp = math.sqrt(self.ship_left.xspeed^2 + self.ship_left.yspeed^2)
	local rightsp = math.sqrt(self.ship_right.xspeed^2 + self.ship_right.yspeed^2)

	if leftsp < SWITCH_MAX_SPEED and rightsp < SWITCH_MAX_SPEED then
		self.switch_cooldown = self.switch_cooldown - rt
	else
		self.switch_cooldown = SWITCH_COOLDOWN
	end

	if self.switch and self.ship_left.x - self.ship_right.x > 10 and self.switch_cooldown <= 0 then
		self.ship_left, self.ship_right = self.ship_right, self.ship_left
		self.ship_left:setSide(Ship.static.SIDE_LEFT)
		self.ship_right:setSide(Ship.static.SIDE_right)
	end
end

return DualController
