AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.CurrentFrame = 1
ENT.AutomaticFrameAdvance = true
ENT.IsDriving = true

ENT.HeliHealth = 1000


--[[
] getpos 
setpos -6035.359863 -12358.002930 6992.468750;setang 16.686962 103.439026 0.000000
] getpos 
setpos -6248.479004 -12077.458984 7177.575195;setang 15.564962 93.802872 0.000000
] getpos 
setpos -6276.358398 -11657.900391 7374.932129;setang 15.564962 93.802872 0.000000
setpos -6279.127930 -10642.440430 7646.234863;setang 1.902966 87.928818 0.000000
setpos -6259.794434 -10107.982422 7757.910156;setang 1.902966 87.928818 0.000000
setpos -6214.511230 -8855.887695 7834.942383 ;setang 1.902966 87.928818 0.000000
setpos -6114.824707 -7255.318359 7862.200684 ;setang 1.770970 84.826836 0.000000
setpos -6026.898438 -6284.037598 8139.105469 ;setang 1.770970 84.826836 0.000000
setpos -5864.648438 -4491.857422 8342.057617 ;setang 1.770970 84.826836 0.000000
setpos -5507.418457 -546.073120 8219.565430  ;setang 1.770970 84.826836 0.000000

]]--

ENT.AnimationFrames = {
	{Vector(-7193.824707, 2191.467041, 2982), Angle(7.284145, 360.960670, 0.000000)},
	--{Vector(-4275.979492, -9860.513672, 7708.817871), Angle(7.284145, 155.960670, 0.000000)},
	--{Vector(-4597.427246, -10339.702148, 7635.128906), Angle(7.284145, 155.960670, 0.000000)},
	--{Vector(-5175.886230, -11197.750977, 7425.307129), Angle(15.666143, 151.802559, 0.000000)},
	--{Vector(-5563.604004, -11823.052734, 7218.962891), Angle(15.666143, 151.802559, 0.000000)},
	--{Vector(-5640.890625, -12282.607422, 7081.575684), Angle(30.714140, 158.036652, 0.000000)},
	--{Vector(-5765.103516, -12459.101562, 6961.891602), Angle(40.416229, 100.226669, 0.000000)},
	----{Vector(-5853.703613, -12483.550781, 6892.699707), Angle(41.076244, 144.939255, 0.000000)},
	--{Vector(-5917.630371, -12485.637695, 6778.127930), Angle(0, 91.479073, 0.000000)},
	--{Vector(-3565.6950683594, 4776.1674804688, 2613.4487304688), Angle(11.7333984375, -9.151611328125, 0.1153564453125)},
	--{Vector(-3579.9892578125, 4816.9077148438, 2495.892578125), Angle(-0.19775390625, 1.043701171875, 0.0164794921875)},
}


ENT.EscapeAnimationFrames = {
	--{Vector(-5917.630371, -12485.637695, 6778.127930), Angle(0, 91.479073, 0.000000)},
	--{Vector(-5878.4067382812, -12484.545898438, 6856.67578125), Angle(0.416229, 80.226669, 0.000000)},
	--{Vector(-5878.4067382812, -12484.545898438, 6974.42578125), Angle(0.416229, 60.226669, 0.000000)},
	--{Vector(-5934.9755859375, -12498.293945312, 7039.5498046875), Angle(3.4442138671875, 40.5548095703125, -10.508422851563)},
	--{Vector(-6017.2202148438, -12482.491210938, 7099.6884765625), Angle(1.5380859375, 2.5048828125, -17.550659179688)},
	--{Vector(-6101.2534179688, -12185.892578125, 7126.9829101562), Angle(0.340576171875, 1.1480712890625, -21.8408203125)},
	--{Vector(-6187.7641601562, -11532.302734375, 7150.4169921875), Angle(0.3350830078125, 0.9063720703125, -22.78564453125)},
	--{Vector(-6236.921875, -6680.9052734375, 7525.8208007813), Angle(0.3350830078125, 0.999755859375, -22.78564453125)},
	--{Vector(-6241.5131835938, -6612.9321289063, 7562.7905273438), Angle(0.3350830078125, 0.999755859375, -22.78564453125)},
	--{Vector(-6812.9526367188, -6682.66015625, 8164.1323242188), Angle(0.3350830078125, 0.999755859375, -22.78564453125)},
	--{Vector(-7978.1083984375, -6773.4458007813, 8925.6455078125), Angle(0.3350830078125, 0.999755859375, -22.78564453125)},
	--{Vector(-5864.648438, -4491.857422, 8342.057617),  Angle(-0.208740234375, 0, -27.789916992188)},
	{Vector(-8150.7016601563, -8995.3076171875, 7575.5991210938), Angle(7.284145, 340.960670, 0.000000)},
	{Vector(-7997.884765625, -8783.466796875, 7550.0073242188), Angle(7.284145, 330.960670, 0.000000)},
	{Vector(-7772.4379882813, -8515.2255859375, 7518.9565429688), Angle(7.284145, 320.960670, 0.000000)},
	{Vector(-7310.3544921875, -8164.0932617188, 7469.3701171875), Angle(7.284145, 310.960670, 0.000000)},
	{Vector(-6837.916015625, -8027.7690429688, 7432.1206054688), Angle(7.284145, 300.960670, 0.000000)},


}

-- Every animation timer belongs to this helicopter, including map cleanup.
function ENT:GRUTimerName(suffix)
	return "RXGRUHeli_" .. self:EntIndex() .. "_" .. suffix
end

function ENT:GRUTimer(suffix, delay, repetitions, callback)
	local name = self:GRUTimerName(suffix)
	self.RXGRUTimers = self.RXGRUTimers or {}
	self.RXGRUTimers[name] = true
	timer.Create(name, delay, repetitions, function()
		if not IsValid(self) then timer.Remove(name) return end
		callback()
	end)
	return name
end

function ENT:LinearMotion(endpos, speed, islast)
if !IsValid(self) then return end
	local timerName = self:GRUTimerName("linear_motion")
	timer.Remove(timerName)

	local ratio = 0
	local time = 0
	local startpos = self:GetPos()

	self:GRUTimer("linear_motion", FrameTime(), 0, function()
		if !IsValid(self) then return end
	    ratio = math.min(ratio + speed, 1)
	    time = time + FrameTime()
	    self:SetPos(LerpVector(ratio, startpos, endpos))

	    if self:GetPos():DistToSqr(endpos) < 1 then
	    	self:SetPos(endpos)
	    end

	    if self:GetPos() == endpos then
		timer.Remove(timerName)
	    	if islast and !isfunction(islast) then
	    		self.PropellerSound:Stop()
	    		local physobj = self:GetPhysicsObject()
				if IsValid(physobj) then physobj:EnableMotion(false) end
	    		self.IsFlying = false
	    		self.IsDriving = false
	    		self:SetBodygroup(2,0)
	    		self:SetBodygroup(3,1)
	    		self:ChangeRotating()
	    		self:AddGestureSequence(self:LookupSequence("door_open"), false)
				--self:ResetSequence(self:LookupSequence("door_opened"))
				--self:ResetSequenceInfo()
				--self:ManipulateBoneAngles(0, Angle(0,90,0))
				self:EmitSound("nextoren/vo/chopper/chopper_evacuate_start_"..math.random(1,7)..".wav", 110, 100, 1.2, CHAN_VOICE, 0, 0)
			elseif isfunction(islast) then
				islast()
			end
	    end
	end)
end

function ENT:LinearAngle(endangle, speed)
if !IsValid(self) then return end
	local timerName = self:GRUTimerName("linear_angle")
	timer.Remove(timerName)

    local ratio = 0
    local startangle = self:GetAngles()
    local startangle_table = startangle:Unpack()
    local endangle_table = endangle:Unpack()
    local startangle_tovector = Vector(startangle[1], startangle[2], startangle[3])
    local endangle_tovector = Vector(endangle[1], endangle[2], endangle[3])

    self:GRUTimer("linear_angle", FrameTime(), 0, function()
        if !IsValid(self) then return end
        ratio = math.min(ratio + speed, 1)
        self:SetAngles(LerpAngle(ratio, startangle, endangle))

        	
        if startangle_tovector:DistToSqr(endangle_tovector) < 1 then
            self:SetAngles(endangle)
        end

        if self:GetAngles() == endangle then
            timer.Remove(timerName)
            return true
        end
    end)
end

function ENT:Initialize()
	self:SetModel("models/imperator/gru_heli/heli_v2.mdl")

	self:SetMoveType( MOVETYPE_NONE )


	self:PhysicsInit( SOLID_VPHYSICS )

	self:SetSolid( SOLID_VPHYSICS )

	self:SetTrigger(true)

	self.IsFlying = true

	self.HelicopterHealth = self.HeliHealth
	self.IsBroken = false

	local filt = RecipientFilter()
	filt:AddAllPlayers()

	self.PropellerSound = CreateSound(self, "nextoren/others/helicopter/helicopter_propeller.wav", filt)
	self.PropellerSound:Play()

	self:SetPos(self.AnimationFrames[1][1])
	self:SetAngles(self.AnimationFrames[1][2])

	self.HoverBasePos = self:GetPos()
	self.HoverBaseAng = self:GetAngles()

	self:PhysicsDestroy()

	local physobj = self:GetPhysicsObject()
	if IsValid(physobj) then physobj:EnableMotion(false) end


	self:ResetSequence(self:LookupSequence("rotating"))
	self:ResetSequenceInfo()
	--self:SetBodygroup(0,3)
	--self.at4 = ents.Create("prop_physics")
	--self.at4:SetModel("models/hunter/plates/plate8.mdl")
	--self.at4:SetPos(Vector(-5917.9985351562, -11373.69140625, 7523.3461914062))
	--self.at4:SetAngles(Angle(0, 0, 90))
	--self.at4:Spawn()
	--self.at4:SetMoveType(MOVETYPE_NONE)
	--self.at4:PhysicsInit(SOLID_NONE)
	--self.at4:SetSolid( SOLID_NONE )
	--self.at4:SetMaterial("models/props_pipes/GutterMetal01a")
--
	--self.at42 = ents.Create("prop_physics")
	--self.at42:SetModel("models/hunter/plates/plate8.mdl")
	--self.at42:SetPos(Vector(-5917.9985351562, -11373.69140625, 7223.3461914062))
	--self.at42:SetAngles(Angle(0, 0, 90))
	--self.at42:Spawn()
	--self.at42:SetMoveType(MOVETYPE_NONE)
	--self.at42:PhysicsInit(SOLID_NONE)
	--self.at42:SetSolid( SOLID_NONE )
	--self.at42:SetMaterial("models/props_pipes/GutterMetal01a")
--
	--self.at43 = ents.Create("prop_physics")
	--self.at43:SetModel("models/hunter/plates/plate8.mdl")
	--self.at43:SetPos(Vector(-5917.9985351562, -11373.69140625, 6863.3461914062))
	--self.at43:SetAngles(Angle(0, 0, 90))
	--self.at43:Spawn()
	--self.at43:SetMoveType(MOVETYPE_NONE)
	--self.at43:PhysicsInit(SOLID_NONE)
	--self.at43:SetSolid( SOLID_NONE )
	--self.at43:SetMaterial("models/props_pipes/GutterMetal01a")

	self.at4e = ents.Create("gru_evacuation")
	self.at4e:SetPos(Vector(-7193, 2191, 2102))
	self.at4e:SetAngles(Angle(0, 0, 0))
	self.at4e:Spawn()
	self.at4e:SetMoveType(MOVETYPE_NONE)
	self.at4e:PhysicsInit(SOLID_NONE)
	self.at4e:SetSolid( SOLID_NONE )
	--self.at4e:SetMaterial("models/props_pipes/GutterMetal01a")
	--Bonemerge("models/ogrx/props/gru_heli/mil_mi-8_hip.mdl", self)
	--models/ogrx/props/gru_heli/mi8_body1
	--for k1,v1 in pairs(self:GetMaterials()) do
	--	--print(v1)
	----	if k1 == 9 then
	--	--	print("гойда")
	--		print(v1)
	--		
	--		--self:SetSubMaterial(1,"models/imperator/female/no_draw")
	--	--	print("гойда")
	--	--end
	--end

	--for _, gate in pairs(ents.FindInBox( Vector(-1495.2327880859, 7149.9833984375, 1876.9328613281), Vector(-1083.5562744141, 7242.2333984375, 1660.4428710938) )) do gate:Fire("Open") end

	--	for i = 2, #self.AnimationFrames do
	--		timer.Create("helicopter__anim_"..tostring(i), 1.5 * ( i - 2 ), 1, function()
	--			self:LinearMotion(self.AnimationFrames[i][1], 0.005, i == #self.AnimationFrames)
	--			self:LinearAngle(self.AnimationFrames[i][2], 0.005)
	--		end)
	--	end
--
	--local remembername = "Frame_Advance_"..self:EntIndex()
	--timer.Create(remembername, FrameTime(), 999999999, function()
	--	if IsValid(self) then
	--		self:FrameAdvance()
	--	else
	--		timer.Remove(remembername)
	--	end
	--end)

end

function ENT:ChangeRotating(start)

	local unid = self:GRUTimerName("playback")

	self:GRUTimer("playback", FrameTime(), 0, function()

		if !IsValid(self) or (!start and self:GetPlaybackRate() <= 0) or (start and self:GetPlaybackRate() >= 1) then
			timer.Remove(unid)
			return
		end

		if start then
			self:SetPlaybackRate(math.Approach(self:GetPlaybackRate(), 1, FrameTime()/2))
		else
			self:SetPlaybackRate(math.Approach(self:GetPlaybackRate(), 0, FrameTime()/2))
		end

	end)

end

function ENT:Explode(tem)

	if self.Blownup then return end

	local pos = self:GetPos()
	local dmg = 625
	local dmgowner = self

	self.Blownup = true

	local r_inner = 550
	local r_outer = r_inner * 1.15

	for i = 2, #self.AnimationFrames do
		timer.Remove("helicopter__anim_"..tostring(i))
	end

	--util.BlastDamage(self, dmgowner, pos, r_outer, dmg)

	--[[
	local effect = EffectData()
	effect:SetStart(pos)
	effect:SetOrigin(pos)
	effect:SetScale(r_outer)
	effect:SetRadius(r_outer)
	effect:SetMagnitude(dmg)
	util.Effect("Explosion", effect, true, true)]]

	if !self.IsFlying then
		ParticleEffect("gas_explosion_main", self:GetPos(), Angle(0,0,0), game.GetWorld())
		BroadcastLua("ParticleEffect(\"gas_explosion_main\", Vector("..tostring(self:GetPos().x)..", "..tostring(self:GetPos().y)..", "..tostring(self:GetPos().z).."), Angle(0,0,0), game.GetWorld())")
		local dmginfo = DamageInfo()
		dmginfo:SetDamageType(DMG_BLAST)
		dmginfo:SetDamage(450)
		local savepos = self:GetPos()

		sound.Play( "bullet/explode/large_4.wav", savepos, 125, 100, 1.3 )

		self:Remove()

		util.BlastDamageInfo(dmginfo, savepos, 1450)
	else

		local filt = RecipientFilter()
		filt:AddAllPlayers()

		self:SetCollisionGroup(COLLISION_GROUP_WORLD)

		self.PropellerSound:Stop()
		self.PropellerSound = CreateSound(self, "nextoren/others/helicopter/apache_damage_alarm.wav", filt)
		self.PropellerSound:Play()


		local fallpos = GroundPos(self:GetPos())
		self:LinearMotion(fallpos, 0.005, function()
			ParticleEffect("gas_explosion_main", self:GetPos(), Angle(0,0,0), game.GetWorld())
			BroadcastLua("ParticleEffect(\"gas_explosion_main\", Vector("..tostring(self:GetPos().x)..", "..tostring(self:GetPos().y)..", "..tostring(self:GetPos().z).."), Angle(0,0,0), game.GetWorld())")
			local dmginfo = DamageInfo()
			dmginfo:SetDamageType(DMG_BLAST)
			dmginfo:SetDamage(450)
			local savepos = self:GetPos()

			sound.Play( "bullet/explode/large_4.wav", savepos, 125, 100, 1.3 )

			self.NOMOREEXPLOSIONS = true

			self:Remove()

			util.BlastDamageInfo(dmginfo, savepos, 1450)
		end)
		self:Ignite(1000)
		if IsValid(self.at4e) then
			--self.at4:Remove()
			--self.at42:Remove()
			--self.at43:Remove()
			self.at4e:Remove()
		end


		local _timername = self:GRUTimerName("crush")
		self:GRUTimer("crush", FrameTime(), 0, function()
			if IsValid(self) then
				local curang = self:GetManipulateBoneAngles(0)
				local curpos = self:GetManipulateBoneAngles(0)
				local yaw = math.Clamp(curang.yaw + math.random(0.5, 2), 0, 360)
				if yaw == 360 then
					yaw = -3.5
				end
				self:ManipulateBonePosition(0, Vector(curpos.x, math.Clamp(curpos.y + math.random(0.5, 2), 0, 70), curpos.z))
				self:ManipulateBoneAngles(0, Angle(0, math.Clamp(curang.yaw + math.random(0.5, 2), 0, 360), math.Clamp(curang.roll + math.random(0.5, 2), 0, 90)))
			else
				timer.Remove(_timername)
			end
		end)

		self.IsBroken = true
	end

	--for _, ply in pairs(player.GetAll()) do
	--	if ply:GTeam() == tem then
	--		ply:RXSENDNotify("l:ci_choppa_down")
	--		ply:AddToStatistics("l:choppa_bonus", 600)
	--	end
	--end

end

--[[
function ENT:PhysicsCollide()
	if self.IsBroken and !self.NOMOREEXPLOSIONS then
		ParticleEffect("gas_explosion_main", self:GetPos(), Angle(0,0,0), game.GetWorld())
		BroadcastLua("ParticleEffect(\"gas_explosion_main\", Vector("..tostring(self:GetPos().x)..", "..tostring(self:GetPos().y)..", "..tostring(self:GetPos().z).."), Angle(0,0,0), game.GetWorld())")
		local dmginfo = DamageInfo()
		dmginfo:SetDamageType(DMG_BLAST)
		dmginfo:SetDamage(450)
		local savepos = self:GetPos()

		sound.Play( "bullet/explode/large_4.wav", savepos, 125, 100, 1.3 )

		self.NOMOREEXPLOSIONS = true

		self:Remove()

		util.BlastDamageInfo(dmginfo, savepos, 1450)
	end
end]]

function ENT:Escape()
	if self.Evacuating or self.Blownup then return end
	self.Evacuating = true
	--self:AddGestureSequence(self:LookupSequence("door_close"), false)
	--self:ChangeRotating(true)
	if IsValid(self.at4e) then
		--self.at4:Remove()
		--self.at42:Remove()
		--self.at43:Remove()
		self.at4e:Remove()
	end
	self:GRUTimer("depart", 1, 1, function()
		self.PropellerSound:Play()
		self:ManipulateBoneAngles(0, Angle(0,0,0))
		self:SetBodygroup(2, 3)
		self:SetBodygroup(4, 0)
		self.IsFlying = false
		for i = 1, #self.EscapeAnimationFrames do
			self:GRUTimer("departure_frame_" .. i, i, 1, function()
				self:LinearMotion(self.EscapeAnimationFrames[i][1], 0.01)
				self:LinearAngle(self.EscapeAnimationFrames[i][2], 0.01)
			end)
		end
		self:GRUTimer("remove", #self.EscapeAnimationFrames, 1, function()
			self:Remove()
		end)
	end)
end


function ENT:Touch(ply)
	if !IsValid(ply) then return end
	if !ply:IsPlayer() then return end
	if ply:GTeam() == TEAM_SPEC then return end
	if !ply:Alive() or ply:Health() <= 0 then return end
	if self.IsDriving != true then return end
	ply:Kill()
end

function ENT:Think()
	--if self:GetPos() == self.AnimationFrames[#self.AnimationFrames][1] and self.IsDriving == true then self:SetBodygroup(1, 1) self.IsDriving = false end
	--if self.IsDriving and self:GetBodygroup(0) != 3 then self:SetBodygroup(0, 3) end
	--if !self.IsDriving and self:GetBodygroup(0) != 0 then self:SetBodygroup(0, 0) end
	--self:NextThink(CurTime() + FrameTime() )
--
	local mypos = self:GetPos()
	local ang = self:GetAngles()
--
	--if !self.RotorWash then
	--	self.RotorWash = ents.Create("env_rotorwash_emitter")
	--	self.RotorWash:SetPos(self.Entity:GetPos())
	--	self.RotorWash:SetParent(self.Entity)
	--	self.RotorWash:Activate()
	--end

	local pos1, pos2 = mypos + ang:Forward()*-450 + ang:Right()*-150 + ang:Up()*-150, mypos + ang:Forward()*350 + ang:Right()*150 + ang:Up()*150

	for k, v in ipairs(ents.FindInBox(pos1, pos2)) do
		if v:GetClass():find("cw_kk_ins2_projectile_") then
			if !v.Fuse and v.selfDestruct then
				v:selfDestruct()
			end
		end
	end

	if !self.Blownup and !self.Evacuating then
        
        local time = CurTime()
        local posAmp = 16      -- амплитуда смещения (единиц)
        local angAmp = 4       -- амплитуда углов (градусов)

        -- Используем комбинацию синусов и косинусов с разными частотами для естественности
        local dx = math.sin(time * 1.3) * posAmp * 0.7 + math.cos(time * 2.1) * posAmp * 0.3
        local dy = math.sin(time * 1.7) * posAmp * 0.6 + math.cos(time * 2.4) * posAmp * 0.4
        local dz = math.sin(time * 2.2) * posAmp * 0.5 + math.cos(time * 1.8) * posAmp * 0.5

        local dPitch = math.sin(time * 1.1) * angAmp * 0.8 + math.cos(time * 1.9) * angAmp * 0.2
        local dYaw   = math.sin(time * 1.5) * angAmp * 0.6 + math.cos(time * 2.3) * angAmp * 0.4
        local dRoll  = math.sin(time * 1.9) * angAmp * 0.7 + math.cos(time * 1.4) * angAmp * 0.3

        local newPos = self.HoverBasePos + Vector(dx, dy, dz)
        local newAng = Angle(
            self.HoverBaseAng.p + dPitch,
            self.HoverBaseAng.y + dYaw,
            self.HoverBaseAng.r + dRoll
        )

        self:SetPos(newPos)
        self:SetAngles(newAng)
    end

    self:NextThink(CurTime() + FrameTime())
    return true
end

function ENT:OnTakeDamage( dmginfo )
	--self:Escape()
	if self.NOMOREEXPLOSIONS or self.Blownup then return end
	--if dmginfo:GetDamageType() == DMG_BLAST and IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() and dmginfo:GetAttacker():GTeam() == TEAM_CHAOS then
	--	self:Explode(TEAM_CHAOS)
	--end
--
	if dmginfo:GetDamageType() == DMG_BLAST and IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() and dmginfo:GetAttacker():GTeam() != TEAM_GRU then
		self:Explode(dmginfo:GetAttacker():GTeam())
	end


	--if IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker():IsPlayer() and dmginfo:GetAttacker():GTeam() == TEAM_GRU then
	--	--if GRU_Objective != "Срыв эвакуации" then
	--		dmginfo:GetAttacker():RXSENDNotify(Color(255,0,0), "l:gru_psycho_pt1 ", color_white, "l:gru_psycho_pt2")
	--		return
	--	--end
	--	--local Ef = EffectData()
	--	--Ef:SetOrigin(dmginfo:GetDamagePosition())
	--	--Ef:SetEntity(self)
	--	--util.Effect("helicopter_impact", Ef)
		self.HelicopterHealth = self.HelicopterHealth - dmginfo:GetDamage()
		if self.HelicopterHealth <= 0 then
			self:Explode(dmginfo:GetAttacker():GTeam())
		end
	--end

	return dmginfo:GetDamage()
end

function ENT:OnRemove()
	for name in pairs(self.RXGRUTimers or {}) do timer.Remove(name) end
	if self.PropellerSound then self.PropellerSound:Stop() end

	if IsValid(self.at4e) then
		--self.at4:Remove()
		--self.at42:Remove()
		--self.at43:Remove()
		self.at4e:Remove()
	end

end
