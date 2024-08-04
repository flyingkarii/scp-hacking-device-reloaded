SWEP.PrintName			    = "SCP - Hacking Device"
SWEP.Category				= "GuthSCP"
SWEP.Author			        = "zgredinzyyy & Guthen"
SWEP.Instructions		    = "Press Left Mouse Button to hack nearest doors."

SWEP.Spawnable              = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		    = "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		    = "none"

SWEP.Weight	                = 5
SWEP.AutoSwitchTo		    = false
SWEP.AutoSwitchFrom		    = false

SWEP.Slot			        = 1
SWEP.SlotPos			    = 2
SWEP.DrawAmmo			    = false
SWEP.DrawCrosshair		    = true

SWEP.ViewModel			    = "models/weapons/v_grenade.mdl"
SWEP.WorldModel			    = "models/weapons/w_grenade.mdl"

SWEP.ShouldDropOnDie 		= false

SWEP.HoldType 				= "slam"

SWEP.UseHands 				= false
SWEP.ShowViewModel 			= false
SWEP.ShowWorldModel 		= false

SWEP.GuthSCPLVL       		= 0 -- Starting with 0 so player can't open doors without hacking and let keycard system asociate this SWEP with keycard

--  swep construction kit
local model = "models/props/hdevice/hdevice.mdl"
SWEP.VElements = {
	["keycard"] = {
		type = "Model",
		model = model,
		bone = "ValveBiped.Bip01_R_Finger0",
		rel = "",

		pos = Vector( 4, -1, -0.519 ),
		angle = Angle( -8.183, -10.52, -99.351 ),
		size = Vector( 0.625, 0.625, 0.625 ),

		color = Color( 255, 255, 255, 255 ),
		surpresslightning = false,
		material = "",
		skin = 4,
		bodygroup = {}
	}
}
SWEP.WElements = {
	["keycard"] = {
		type = "Model",
		model = model,
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",

		pos = Vector( 4.5, 4, -1.558 ),
		angle = Angle( -3.507, -92.338, -59.611 ),
		size = Vector( 0.755, 0.755, 0.755 ),

		color = Color( 255, 255, 255, 255 ),
		surpresslightning = false,
		material = "",
		skin = 4,
		bodygroup = {}
	}
}
SWEP.ViewModelBoneMods = {
	["ValveBiped.Grenade_body"] = { scale = Vector( 0.009, 0.009, 0.009 ), pos = Vector( 0, 0, 0 ), angle = Angle( 0, 0, 0 ) }
}


local hackingdevice_hack_time = CreateConVar("hdevice_hack_time", "5", {FCVAR_REPLICATED,FCVAR_ARCHIVE}, "Amount of seconds needed for hacking device to open certain door.")
local hackingdevice_hack_max = CreateConVar("hdevice_hack_max", "5", {FCVAR_REPLICATED,FCVAR_ARCHIVE}, "Highest level that the device can crack.")

local newGuthSCP = guthscp.modules.guthscpkeycard
local newGuthSCPconfig = guthscp.configs.guthscpkeycard

function SWEP:Success(ent)
	self.isHacking = false
	self.Owner:SetNWBool("isHacking", false)
	if SERVER then guthscp.player_message( "Hacking Done!" ) end
	ent:Use(self.Owner,ent,4,1) -- Opening Doors
	self.Owner:EmitSound("ambient/energy/spark3.wav", 65, 100, 1, CHAN_AUTO) -- Sounds exported from HL2
end

function SWEP:Open(ent)
	ent:Use(self.Owner,ent,4,1)
end

function SWEP:Failure(fail) -- 1 = Moved mouse, moved too far, 2 = Hacking limited to certain LVL, else = Button blocked
	self.isHacking = false
	self.Owner:SetNWBool("isHacking", false)
	if fail == 1 then
		if SERVER then guthscp.player_message( self.Owner, "Hacking FAILED!" ) end
	elseif fail == 2 then
		if SERVER then guthscp.player_message( self.Owner, "Hacking limited to LVL " .. hackingdevice_hack_max:GetInt() .. " Keycard" ) end
	else
		if SERVER then guthscp.player_message( self.Owner, "Can't hack this!" ) end 
	end
end

function SWEP:PrimaryAttack()

	self.nextFire = 0

    local tr = self.Owner:GetEyeTrace()
	local ent = tr.Entity
	local trLVL = newGuthSCP.get_entity_level(ent)

	-- check if everything ok
	if not newGuthSCP then return end -- If no Base Guthen Keycard sys = end
	if not newGuthSCPconfig.keycard_available_classes[ ent:GetClass() ] then return end -- No keycard table
	if not newGuthSCP.exceptionButtonID then return end -- No buttons file
	if not newGuthSCP.exceptionButtonID[game.GetMap()] then return end -- No setting for that map

	if trLVL < 0 then if SERVER then guthscp.player_message( self.Owner, "No Hack needed !" ) end return end

	if not self.isHacking then
		if IsValid(tr.Entity) and tr.HitPos:Distance(self.Owner:GetShootPos()) < 50 and trLVL == 0 and not newGuthSCP.exceptionButtonID[game.GetMap()][ent:MapCreationID()] then
			self:Open(ent)

		elseif IsValid(tr.Entity) and tr.HitPos:Distance(self.Owner:GetShootPos()) < 50 and trLVL <= hackingdevice_hack_max:GetInt() and not newGuthSCP.exceptionButtonID[game.GetMap()][ent:MapCreationID()] then
			self.Owner:EmitSound("ambient/machines/keyboard1_clicks.wav", 60, 100, 1, CHAN_AUTO)
			if SERVER then guthscp.player_message( self.Owner, "Hacking Started!" ) end
			self.isHacking = true
			self.Owner:SetNWBool("isHacking", true)
			self.startHack = CurTime()
			self.endHack = CurTime() + newGuthSCP.get_entity_level(ent)*hackingdevice_hack_time:GetInt()
			self.Owner:SetNWInt("endHack", self.endHack)

		elseif newGuthSCP.exceptionButtonID[game.GetMap()][ent:MapCreationID()] then
			self:Failure(3)

		elseif IsValid(tr.Entity) and tr.HitPos:Distance(self.Owner:GetShootPos()) < 50 and trLVL ~= 0 and trLVL > hackingdevice_hack_max:GetInt() then
			self:Failure(2)

		end
	end
end

function SWEP:SecondaryAttack() end

function SWEP:Think()
    local tr = self.Owner:GetEyeTrace()
	local ent = tr.Entity
	local ply = self:GetOwner()

    if not self.startHack then
		self.startHack = 0
		self.endHack = 0
	end

	if self.isHacking and IsValid(ply) then
		local tr = self.Owner:GetEyeTrace()	
		if not IsValid(tr.Entity) or tr.HitPos:Distance(ply:GetShootPos()) > 50 or not newGuthSCPconfig.keycard_available_classes[ ent:GetClass() ] then
			self:Failure(1)
		elseif self.endHack <= CurTime() then
			self:Success(tr.Entity)
		end
	else
		self.startHack = 0
		self.endHack = 0
	end
	
	self:NextThink(CurTime())
	return true
end

function SWEP:DrawHUD()
	
    local ply = self:GetOwner()
	if not IsValid( ply ) or not ply:Alive() then return end

	local trg = ply:GetEyeTrace().Entity
	local tr = self.Owner:GetEyeTrace()

	if not IsValid( trg ) then return end
	if not newGuthSCP then return end
	if not newGuthSCPconfig.keycard_available_classes[ trg:GetClass() ] then return end
	
    if newGuthSCP.get_entity_level(trg) and tr.HitPos:Distance(ply:GetShootPos()) < 50 then

		if newGuthSCP.get_entity_level(trg) < 0 then draw.SimpleText( "No hack needed", "ChatFont", ScrW()/2+50, ScrH()/2, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER ) return end

		draw.SimpleText( "Keycard LVL Required: " .. newGuthSCP.get_entity_level(trg), "ChatFont", ScrW()/2+50, ScrH()/2, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		if newGuthSCP.get_entity_level(trg) ~= 0 then
			draw.SimpleText( "Estimated Hack Time: " .. newGuthSCP.get_entity_level(trg)*hackingdevice_hack_time:GetInt() .. "s", "ChatFont", ScrW()/2+50, ScrH()/2+15, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end

		if ply:GetNWBool("isHacking") then
			surface.SetDrawColor( 255, 255, 255, 128 )
			surface.DrawOutlinedRect( ScrW()/2-50, ScrH()/2+40, 100, 20, 1.5 )

			surface.SetDrawColor(0,175,0,255)
			surface.DrawRect(ScrW()/2-50, ScrH()/2+40, ((self.Owner:GetNWInt("endHack")-CurTime())/(hackingdevice_hack_time:GetInt()*newGuthSCP.get_entity_level(trg)))*100, 20)
			
			surface.SetDrawColor( 175, 255, 0, 50 )
			surface.DrawOutlinedRect( ScrW()/2-50, ScrH()/2+40, 100, 20, 10 )

			draw.SimpleText(math.Round(((ply:GetNWInt("endHack")-CurTime())/(hackingdevice_hack_time:GetInt()*newGuthSCP.get_entity_level(trg)))*100, 1) .. "%", "ChatFont", ScrW()/2, ScrH()/2+50, Color( 95, 235, 95 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
end

--
-- SWEP Construction Kit
--

function SWEP:Initialize()

	if GuthSCP then 
		self.Owner:ChatPrint("HDevice-reloaded - Guthen Keycard System found but outdated, please update your keycard system, HDevice-reloaded will be disable while you don't update.")
	end

	if not GuthSCP and not newGuthSCP then
		self.Owner:ChatPrint("HDevice-reloaded - Guthen Keycard System not found, HDevice-reloaded won't work without it.")
	end

	if CLIENT then
	
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
		
	end

end

function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

if CLIENT then

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			// we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end
			
		end

		for k, name in ipairs( self.vRenderOrder ) do
		
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (!v.bone) then continue end
			
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			
			if (!pos) then continue end
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			// Technically, if there exists an element with the same name as a bone
			// you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r // Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				// make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			// !! ----------- !! //
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				// !! WORKAROUND !! //
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				// !! ----------- !! //
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end

	/**************************
		Global utility code
	**************************/
	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v) // recursion ho!
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end
	
end


