
-- --------
-- Setup

local gwarptorio={}
local util = require("util")
local mod_gui = require("mod-gui")
local function new(x,a,b,c,d,e,f,g) local t,v=setmetatable({},x),rawget(x,"__init") if(v)then v(t,a,b,c,d,e,f,g) end return t end
function table.Count(t) local c=0 for k,v in pairs(t)do c=c+1 end return c end
function table.First(t) for k,v in pairs(t)do return k,v end end
function table.Random(t) local c,i=table.Count(t),1 if(c==0)then return end local rng=math.random(1,c) for k,v in pairs(t)do if(i==rng)then return v end i=i+1 end end
local function istable(x) return type(x)=="table" end
local function printx(m) for k,v in pairs(game.players)do v.print(m) end end

local Vector2={} Vector2.__index=Vector2 setmetatable(Vector2,Vector2)
function Vector2.__call(x,y) x=x or 0 y=y or 0 local t={} setmetatable(t,Vector2) t.x=x t.y=y t[1]=t.x t[2]=t.y return t end
function Vector2.__add(a,b) local t={} setmetatable(t,Vector2) t.x=a.x+b.x t.y=a.y+b.y t[1]=t.x t[2]=t.y return t end
function Vector2.__mul(a,b) local t={} setmetatable(t,Vector2) t.x=a.x*b.x t.y=a.y*b.y t[1]=t.x t[2]=t.y return t end
function Vector2:AddAngle(r,d) local t={} setmetatable(t,Vector2) t.x=self.x+math.sin(r)*d t.y=self.y+math.cos(r)*d t[1]=t.x t[2]=t.y return t end
function Vector2:Length() return math.sqrt(self.x^2+self.y^2) end


warptorio=warptorio or {}

function warptorio.FlipDirection(v) return (v+4)%8 end

require("control_planets")
-- --------
-- Logistics & Teleporters

local TELL={} TELL.__index=TELL warptorio.TeleporterMeta=TELL
function TELL.__init(self,n) self.name=n self.dir={{"input","output"},{"input","output"}} gwarptorio.Teleporters[n]=self end
TELL.LogisticsEnts={"loader1","loader2","chest1","chest2","pipe1","pipe2","pipe3","pipe4","pipe5","pipe6"}

function TELL:CheckLoaderDirection(i,a,b) if(not a or not a.valid or not b or not b.valid)then return end
	if(a.loader_type ~= self.dir[i][1])then -- A has rotated
		self.dir[i][1]=a.loader_type
		self.dir[i][2]=(a.loader_type=="input" and "output" or "input")
		b.loader_type=self.dir[i][2]
	elseif(b.loader_type ~= self.dir[i][2])then -- B has rotated
		self.dir[i][2]=b.loader_type
		self.dir[i][1]=(b.loader_type=="input" and "output" or "input")
		a.loader_type=self.dir[i][1]
	end
end

function TELL:SpawnPointA(n,f,pos) local e=warptorio.SpawnEntity(f,n,pos.x,pos.y) self.PointA=e return e end
function TELL:SpawnPointB(n,f,pos) local e=warptorio.SpawnEntity(f,n,pos.x,pos.y) self.PointB=e return e end
function TELL:SetPointA(e) self.PointA=e end
function TELL:SetPointB(e) self.PointB=e end
function TELL:BalanceLogistics()
	if(self.logs)then
		self:CheckLoaderDirection(1,self.logs["loader1-a"],self.logs["loader1-b"])
		self:CheckLoaderDirection(2,self.logs["loader2-a"],self.logs["loader2-b"])
		if(self.dir[1][1]=="input")then warptorio.BalanceLogistics(self.logs["chest1-a"],self.logs["chest1-b"])
		else warptorio.BalanceLogistics(self.logs["chest1-b"],self.logs["chest1-a"])
		end
		if(self.dir[2][1]=="input")then warptorio.BalanceLogistics(self.logs["chest2-a"],self.logs["chest2-b"])
		else warptorio.BalanceLogistics(self.logs["chest2-b"],self.logs["chest2-a"])
		end

		for i=1,6,1 do warptorio.BalanceLogistics(self.logs["pipe"..i.."-a"],self.logs["pipe"..i.."-b"],true) end
	end
	warptorio.BalanceLogistics(self.PointA,self.PointB) -- energy
end

function TELL:Warpout() local f=gwarptorio.Floors.main:GetSurface().name
	if(self:ValidPointA() and self.PointA.surface.name==f)then self:DestroyPointA() end
	if(self:ValidPointB() and self.PointB.surface.name==f)then self:DestroyPointB() end
	for k,v in pairs(self.logs)do if(v and v.valid and v.surface.name==f)then v.destroy() self.logs[k]=nil end end -- transfer contents .. eventually
end
function TELL:Warpin() warptorio.TeleCls[self.name]() end
function TELL:ValidPointA() return (self.PointA and self.PointA.valid) end
function TELL:ValidPointB() return (self.PointB and self.PointB.valid) end
function TELL:ValidPoints() return (self:ValidPointA() and self:ValidPointB()) end
function TELL:DestroyPoints() self:DestroyPointA() self:DestroyPointB() end
function TELL:DestroyPointA() if(self.PointA and self.PointA.valid)then self.PointA.destroy() self.PointA=nil end end
function TELL:DestroyPointB() if(self.PointB and self.PointB.valid)then self.PointB.destroy() self.PointB=nil end end
function TELL:DestroyLogisticsA() if(self.logs)then for k,v in pairs(self.LogisticsEnts)do local e=self.logs[v.."-a"] if(e)then if(e.valid)then e.destroy() end self.logs[v.."-a"]=nil end end end end
function TELL:DestroyLogisticsB() if(self.logs)then for k,v in pairs(self.LogisticsEnts)do local e=self.logs[v.."-b"] if(e)then if(e.valid)then e.destroy() end self.logs[v.."-b"]=nil end end end end
function TELL:DestroyLogistics() if(self.logs)then for k,v in pairs(self.logs)do if(v and v.valid)then v.destroy() end end self.logs={} end end
function TELL:UpgradeLogistics() if(self.logs)then self:DestroyLogistics() end self:SpawnLogistics() end
function TELL:UpgradeEnergy() self:Warpin() end

function TELL:SpawnLogistics() if(not self.logs)then self.logs={} end
	local lv=gwarptorio.Research["factory-logistics"] or 0 if(lv==0)then return end
	local chest,belt local pipe="warptorio-logistics-pipe"
	if(lv==1)then chest,belt="wooden-chest","loader"
	elseif(lv==2)then chest,belt="iron-chest","fast-loader"
	elseif(lv==3)then chest,belt="steel-chest","express-loader"
	elseif(lv==4)then chest,belt="buffer-chest","express-loader" end

	local a=self.PointA
	local b=self.PointB
	if(a and a.valid)then
		local f,p=a.surface,a.position
		local v=self.logs["loader1-a"] if(not v or not v.valid)then v=warptorio.SpawnEntity(f,belt,p.x-2,p.y-1,defines.direction.south) self.logs["loader1-a"]=v v.loader_type=self.dir[1][1] end
		local v=self.logs["loader2-a"] if(not v or not v.valid)then v=warptorio.SpawnEntity(f,belt,p.x+2,p.y-1,defines.direction.south) self.logs["loader2-a"]=v v.loader_type=self.dir[2][1] end
		local v=self.logs["chest1-a"] if(not v or not v.valid)then self.logs["chest1-a"]=warptorio.SpawnEntity(f,chest,p.x-2,p.y+1) end
		local v=self.logs["chest2-a"] if(not v or not v.valid)then self.logs["chest2-a"]=warptorio.SpawnEntity(f,chest,p.x+2,p.y+1) end
		local v=self.logs["pipe1-a"] if(not v or not v.valid)then self.logs["pipe1-a"]=warptorio.SpawnEntity(f,pipe,p.x-3,p.y+1,defines.direction.west) end
		local v=self.logs["pipe2-a"] if(not v or not v.valid)then self.logs["pipe2-a"]=warptorio.SpawnEntity(f,pipe,p.x+3,p.y+1,defines.direction.east) end
		if(lv>=2)then
			local v=self.logs["pipe3-a"] if(not v or not v.valid)then self.logs["pipe3-a"]=warptorio.SpawnEntity(f,pipe,p.x-3,p.y,defines.direction.west) end
			local v=self.logs["pipe4-a"] if(not v or not v.valid)then self.logs["pipe4-a"]=warptorio.SpawnEntity(f,pipe,p.x+3,p.y,defines.direction.east) end
		end if(lv>=4)then
			local v=self.logs["pipe5-a"] if(not v or not v.valid)then self.logs["pipe5-a"]=warptorio.SpawnEntity(f,pipe,p.x-3,p.y-1,defines.direction.west) end
			local v=self.logs["pipe6-a"] if(not v or not v.valid)then self.logs["pipe6-a"]=warptorio.SpawnEntity(f,pipe,p.x+3,p.y-1,defines.direction.east) end
		end
		warptorio.playsound("warp_in",f)
	end

	if(b and b.valid)then
		local f,p=b.surface,b.position
		local v=self.logs["loader1-b"] if(not v or not v.valid)then v=warptorio.SpawnEntity(f,belt,p.x-2,p.y-1,defines.direction.south) self.logs["loader1-b"]=v v.loader_type=self.dir[1][2] end
		local v=self.logs["loader2-b"] if(not v or not v.valid)then v=warptorio.SpawnEntity(f,belt,p.x+2,p.y-1,defines.direction.south) self.logs["loader2-b"]=v v.loader_type=self.dir[2][2] end
		local v=self.logs["chest1-b"] if(not v or not v.valid)then self.logs["chest1-b"]=warptorio.SpawnEntity(f,chest,p.x-2,p.y+1) end
		local v=self.logs["chest2-b"] if(not v or not v.valid)then self.logs["chest2-b"]=warptorio.SpawnEntity(f,chest,p.x+2,p.y+1) end
		local v=self.logs["pipe1-b"] if(not v or not v.valid)then self.logs["pipe1-b"]=warptorio.SpawnEntity(f,pipe,p.x-3,p.y+1,defines.direction.west) end
		local v=self.logs["pipe2-b"] if(not v or not v.valid)then self.logs["pipe2-b"]=warptorio.SpawnEntity(f,pipe,p.x+3,p.y+1,defines.direction.east) end
		if(lv>=2)then
			local v=self.logs["pipe3-b"] if(not v or not v.valid)then self.logs["pipe3-b"]=warptorio.SpawnEntity(f,pipe,p.x-3,p.y,defines.direction.west) end
			local v=self.logs["pipe4-b"] if(not v or not v.valid)then self.logs["pipe4-b"]=warptorio.SpawnEntity(f,pipe,p.x+3,p.y,defines.direction.east) end
		end if(lv>=4)then
			local v=self.logs["pipe5-b"] if(not v or not v.valid)then self.logs["pipe5-b"]=warptorio.SpawnEntity(f,pipe,p.x-3,p.y-1,defines.direction.west) end
			local v=self.logs["pipe6-b"] if(not v or not v.valid)then self.logs["pipe6-b"]=warptorio.SpawnEntity(f,pipe,p.x+3,p.y-1,defines.direction.east) end
		end
		warptorio.playsound("warp_in",f)
	end

	for k,v in pairs(self.logs)do v.minable=false v.destructible=false end
end

local tpcls={} warptorio.TeleCls=tpcls
function tpcls.offworld()
	local lv=gwarptorio.Research["teleporter-energy"] or 0
	local lgv=gwarptorio.Research["factory-logistics"] or 0
	local x=gwarptorio.Teleporters["offworld"] if(not x)then x=new(TELL,"offworld") end
	x.cost=true
	local m=gwarptorio.Floors.main
	local f=m:GetSurface()
	local bpos={-1,-9}
	local makeA="warptorio-teleporter-"..lv
	if(x:ValidPointA() and x.PointA.name~=makeA)then x:DestroyPointA() end
	if(not x.PointA or not x.PointA.valid)then warptorio.cleanbbox(f,-3,-7,7,3) local e=x:SpawnPointA("warptorio-teleporter-"..lv,f,{x=-1,y=-6}) e.minable=false e.destructible=false end

	local makeB="warptorio-teleporter-gate-"..lv
	if(x:ValidPointB() and x.PointB.name~=makeB)then bpos=x.PointB.position x.PointB.destroy() x.PointB=nil end
	if(not x.PointB)then local e=x:SpawnPointB("warptorio-teleporter-gate-"..lv,f,f.find_non_colliding_position("warptorio-teleporter-gate-"..lv,bpos,0,1,1)) end

	if(lgv>=0)then x:SpawnLogistics() end
	warptorio.playsound("warp_in",f.name)
	return x
end
function tpcls.b1(lv)
	local lv=gwarptorio.Research["factory-energy"] or 0 local lgv=gwarptorio.Research["factory-logistics"] or 0
	local x=gwarptorio.Teleporters["b1"] if(not x)then x=new(TELL,"b1") end
	local m=gwarptorio.Floors.main local f=m:GetSurface()
	local mb=gwarptorio.Floors.b1 local fb=mb:GetSurface()
	local makeA,makeB="warptorio-underground-"..lv,"warptorio-underground-"..lv
	if(x:ValidPointA())then if(x.PointA.surface~=f)then x:DestroyPointA() self:DestroyLogisticsA() elseif(x.PointA~=makeA)then x:DestroyPointA() end end
	if(x:ValidPointB())then if(x.PointB.surface~=fb)then x:DestroyPointB() self:DestroyLogisticsB() elseif(x.PointB~=makeB)then x:DestroyPointB() end end
	if(not x.PointA or not x.PointA.valid)then warptorio.cleanbbox(f,-3,5,7,3) local e=x:SpawnPointA(makeA,f,{x=-1,y=5}) e.minable=false end
	if(not x.PointB or not x.PointB.valid)then warptorio.cleanbbox(fb,-3,-6,7,3) local e=x:SpawnPointB(makeB,fb,{x=-1,y=-6}) e.minable=false e.destructible=false end

	if(lgv>0)then x:SpawnLogistics() end
	warptorio.playsound("warp_in",f.name)
	return x
end
function tpcls.b2(lv) lv=lv or 0
	local lv=gwarptorio.Research["factory-energy"] or 0
	local lgv=gwarptorio.Research["factory-logistics"] or 0
	local x=gwarptorio.Teleporters["b2"] if(not x)then x=new(TELL,"b2") end
	local m=gwarptorio.Floors.b1 local f=m:GetSurface()
	local mb=gwarptorio.Floors.b2 local fb=mb:GetSurface()
	local makeA,makeB="warptorio-underground-"..lv,"warptorio-underground-"..lv
	if(x:ValidPointA())then if(x.PointA.surface~=f)then x:DestroyPointA() self:DestroyLogisticsA() elseif(x.PointA~=makeA)then x:DestroyPointA() end end
	if(x:ValidPointB())then if(x.PointB.surface~=fb)then x:DestroyPointB() self:DestroyLogisticsB() elseif(x.PointB~=makeB)then x:DestroyPointB() end end
	if(not x:ValidPointA())then warptorio.cleanbbox(f,-3,6,7,3) local e=x:SpawnPointA(makeA,f,{x=-1,y=6}) e.minable=false end
	if(not x:ValidPointB())then warptorio.cleanbbox(fb,-3,-6,7,3) local e=x:SpawnPointB(makeB,fb,{x=-1,y=-6}) e.minable=false e.destructible=false end
	if(lgv>0)then x:SpawnLogistics() end

	warptorio.playsound("warp_in",f.name)
	return x
end


function warptorio.InitTeleporters(event) end --for k,v in pairs(warptorio.TeleCls)do if(not gwarptorio.Teleporters[k])then gwarptorio.Teleporters[k]=v() end end end


function warptorio.TickTeleporters(e) for k,v in pairs(gwarptorio.Teleporters)do if(v.PointA and v.PointB and v.PointA.valid and v.PointB.valid)then
	for i,e in pairs({v.PointA,v.PointB})do
		local o=(i==1 and v.PointB or v.PointA) local x=e.position local p=e.surface.find_entities_filtered{area={{x.x-1.1,x.y-1.1},{x.x+1.1,x.y+1.1}},type="character"}
		for a,b in pairs(p)do
			local inv=b.get_main_inventory().get_item_count()
			if(e.energy and v.cost and false)then
				local bp=o.position local dist=math.sqrt((x.x+bp.x)^2+(x.y+bp.y)^2) local jc=(inv*2000)*(1+dist/200)
				if(e.energy<jc)then warptorio.PrintToCharacter(b,"Not enough energy to teleport! You may have too much in your inventory") break end
				e.energy=math.max(e.energy-jc,0)
				warptorio.playsound("stairs",e.surface.name,e.position) warptorio.playsound("stairs",o.surface.name,o.position)
			else
				warptorio.playsound("teleport",e.surface.name,e.position) warptorio.playsound("teleport",o.surface.name,o.position)
			end
			warptorio.safeteleport(b,o.position,o.surface)
		end
	end
end end end

-- Teleporter mined/destroyed/rebuilt
function warptorio.OnBuiltEntity(event) local e=event.created_entity if(warptorio.IsTeleporterGate(e))then local t=gwarptorio.Teleporters["offworld"] t:SetPointB(e) t:Warpin() end
end script.on_event(defines.events.on_built_entity, warptorio.OnBuiltEntity)

function warptorio.OnPlayerMinedEntity(event) local e=event.entity if(warptorio.IsTeleporterGate(e))then local t=gwarptorio.Teleporters["offworld"] t:DestroyLogisticsB() end
end script.on_event(defines.events.on_player_mined_entity,warptorio.OnPlayerMinedEntity)

function warptorio.OnEntityDied(event) local e=event.entity if(warptorio.IsTeleporterGate(e))then local t=gwarptorio.Teleporters["offworld"] t:DestroyLogisticsB() t.PointB=nil t:Warpin() end
end script.on_event(defines.events.on_entity_died,warptorio.OnEntityDied)

function warptorio.IsTeleporterGate(e) return (e.name:sub(1,25)=="warptorio-teleporter-gate") end

-- --------
-- Logistics system

function warptorio.GetLogisticsEnergyCost(c) return 200 end
function warptorio.SpendLogisticsEnergy(c) end

function warptorio.GetSteamTemperature(v) local t={name="steam",amount=1,temperature=15} local c=v.remove_fluid(t)
	if(c~=0)then return 15 else t.temperature=165 c=v.remove_fluid(t) if(c~=0)then return 165 else t.temperature=500 c=v.remove_fluid(t) if(c~=0)then return 500 end end end return 15
end

local logz={} warptorio.Logistics=logz
function logz.BalanceEnergy(a,b) local x=(a.energy+b.energy)/2 a.energy,b.energy=x,x end
function logz.BalanceHeat(a,b) local x=(a.temperature+b.temperature)/2 a.temperature,b.temperature=x,x end

function logz.MoveContainer(a,b) local ac,bc=a.get_inventory(defines.inventory.chest),b.get_inventory(defines.inventory.chest)
	for k,v in pairs(ac.get_contents())do local t={name=k,count=v} local c=bc.insert(t) if(c>0)then ac.remove({name=k,count=c}) end end
end
function logz.BalanceFluid(a,b) local af,bf=a.get_fluid_contents(),b.get_fluid_contents() local aff,afv=table.First(af) local bff,bfv=table.First(bf) afv=afv or 0 bfv=bfv or 0
	if((not aff and not bff) or (aff and bff and aff~=bff) or (afv==0 and bfv==0))then return end
	if(not aff)then aff=bff elseif(not bff)then bff=aff end
	local v=(afv+bfv)/2
	
	if(aff=="steam")then
		local temp=15 local at=warptorio.GetSteamTemperature(a) local bt=warptorio.GetSteamTemperature(b) temp=math.max(at,bt)
		a.clear_fluid_inside() b.clear_fluid_inside() a.insert_fluid({name=aff,amount=v,temperature=temp}) b.insert_fluid({name=bff,amount=v,temperature=temp})
	else
		a.clear_fluid_inside() b.clear_fluid_inside() a.insert_fluid({name=aff,amount=v}) b.insert_fluid({name=bff,amount=v})
	end
end
function logz.MoveFluid(a,b) local af,bf=a.get_fluid_contents(),b.get_fluid_contents() local aff,afv=table.First(af) local bff,bfv=table.First(bf)
	if((not aff and not bff) or (aff and bff and aff~=bff) or (afv==0 and bfv==0))then return end
	if(aff=="steam")then
		local temp=15 local at=warptorio.GetSteamTemperature(a) local bt=warptorio.GetSteamTemperature(b) temp=math.max(at,bt)
		local c=b.insert_fluid({name=aff,amount=afv,temperature=temp}) if(c>0)then a.remove_fluid{name=aff,amount=c} end
	else
		local c=b.insert_fluid({name=aff,amount=afv}) if(c>0)then a.remove_fluid{name=aff,amount=c} end
	end
end

function warptorio.BalanceLogistics(a,b,bal) if(not a or not b or not a.valid or not b.valid)then return end -- cost is removed because it's derp
	if(a.type=="accumulator" and b.type==a.type)then -- transfer energy
		warptorio.Logistics.BalanceEnergy(a,b)
	elseif(a.type=="container" and b.type==a.type)then -- transfer items
		warptorio.Logistics.MoveContainer(a,b)
	elseif(a.type=="pipe-to-ground" and b.type==a.type)then -- transfer fluids
		if(bal==true)then warptorio.Logistics.BalanceFluid(a,b)
		else warptorio.Logistics.MoveFluid(a,b)
		end
	elseif(a.temperature and b.temperature)then
		warptorio.Logistics.BalanceHeat(a,b)
	end
end

function warptorio.TickLogistics(e)
	for k,v in pairs(gwarptorio.Teleporters)do v:BalanceLogistics() end
end


-- --------
-- Warptorio Entities

function warptorio.SpawnEntity(f,n,x,y,dir,type) return f.create_entity{name=n,position={x,y},force=game.forces.player,direction=dir,type=type} end

function warptorio.InitEntities()
	local main=gwarptorio.Floors.main
	local b1=gwarptorio.Floors.b1
	local b2=gwarptorio.Floors.b2

	local e=main.f.create_entity{name="warptorio-reactor",position={-1,-1},force=game.forces.player}
	main.ents.warp_reactor=e
	e.minable=false
end

warptorio.BadCloneTypes={"offshore-pump","resource","warptorio-underground-1"}

local clone={} warptorio.OnEntCloned=clone
clone["warp-reactor"] = function(event)
	if gwarptorio.warpenergy then event.destination.insert{name="warptorio-reactor-fuel-cell",count=1} end
	gwarptorio.warp_reactor = event.destination
end

function warptorio.OnEntityCloned(e) local d=e.destination local type,name=d.type,d.name if(type=="character" or warptorio.BadCloneTypes[name])then e.destination.destroy() return
	elseif(clone[name])then clone[name](e) end
end script.on_event(defines.events.on_entity_cloned, warptorio.OnEntityCloned)




-- ----
-- further setup

function warptorio.OnLoad()
	--if(not global.warptorio)then global.warptorio={} end gwarptorio=(gwarptorio or global.warptorio)
	gwarptorio=global.warptorio
	for k,v in pairs(gwarptorio.Floors)do setmetatable(v,warptorio.FloorMeta) end
	for k,v in pairs(gwarptorio.Teleporters)do setmetatable(v,warptorio.TeleporterMeta) end
end script.on_load(warptorio.OnLoad)




function warptorio.TickWarpEnergy(e)
	--*** warp energy upgrade update
	if global.warp_energy_research == 1 and global.warp_reactor.valid then
		transfert_resources(global.warp_reactor, global.warp_heat_pipe, "average")
	end
	
end


function warptorio.TickPollution()
	gwarptorio.Floors.main:GetSurface().pollute({-1,-1},gwarptorio.pollution_amount)

	local m=gwarptorio.Floors
	local pb1=m.b1:GetSurface().get_total_pollution()
	local pb2=m.b2:GetSurface().get_total_pollution()
	gwarptorio.Floors.main:GetSurface().pollute({-1,-1},pb1+pb2)
	m.b1:GetSurface().clear_pollution()
	m.b2:GetSurface().clear_pollution()
	
	gwarptorio.pollution_amount = gwarptorio.pollution_amount * settings.global['warptorio_warp_polution_factor'].value
	local calculate_expansion_cooldown = math.floor(gwarptorio.base_expansion_cooldown / game.forces["enemy"].evolution_factor / 100)
	if calculate_expansion_cooldown > 3600*60 then game.map_settings.enemy_expansion.min_expansion_cooldown = 3600*60-1 else game.map_settings.enemy_expansion.min_expansion_cooldown = calculate_expansion_cooldown end
	game.map_settings.enemy_expansion.max_expansion_cooldown = game.map_settings.enemy_expansion.min_expansion_cooldown + 1
	
end
function warptorio.TickWarpAlarm()
	if gwarptorio.warp_charging == 1 then 
		if gwarptorio.warp_time_left <= 3600 then 
			warptorio.playsound("warp_alarm", gwarptorio.Floors.main:GetSurface().name)
		end
	end 
end
function warptorio.TickAccelerator(e)
	
	--*** warp accelerator logic
	if gwarptorio.warp_accelerator ~= nil and gwarptorio.warp_charging == 0 then
		if gwarptorio.warp_accelerator.energy > 5*math.pow(10, 6)-1 then
			gwarptorio.warp_accelerator.energy = 0
			gwarptorio.warp_charge_time = gwarptorio.warp_charge_time *0.99
			local caption = "   Charge Time : " .. util.formattime(math.ceil(60*global.warp_charge_time))
			warptorio.updatelabel("time_left",caption)
		end
	end
end

function warptorio.TickStabilizer(e)
	--*** bitter anger clean capacity
	if global.warp_stabilizer_accumulator ~= nil then
		local stabilize = 0
		if global.warp_stabilizer_accumulator_discharge_count == 0 and global.warp_stabilizer_accumulator.energy > 1*math.pow(10, 8)-1 then
			global.warp_stabilizer_accumulator_discharge_count = 1
			stabilize = 1
			if global.warp_stabilizer_accumulator_research_level > 1 then
				create_warp_stab_accu(2)
			end	
		elseif global.warp_stabilizer_accumulator_discharge_count == 1 and global.warp_stabilizer_accumulator.energy > 1*math.pow(10, 10)-1 and global.warp_stabilizer_accumulator_research_level > 1 then
			stabilize = 1
			if global.warp_stabilizer_accumulator_research_level > 2 then
				create_warp_stab_accu(3)
			end					
		elseif global.warp_stabilizer_accumulator_discharge_count == 2 and global.warp_stabilizer_accumulator.energy > 1*math.pow(10, 11)-1 and global.warp_stabilizer_accumulator_research_level > 2 then
			stabilize = 1
			global.warp_stabilizer_accumulator_discharge_count = 3
		end
		if stabilize == 1 then
			game.forces["enemy"].evolution_factor=0	
			global.polution_amount = 1
			game.surfaces[global.current_surface].clear_pollution()
			game.surfaces[global.current_surface].set_multi_command{command={type=defines.command.flee, from=global.warp_reactor}, unit_count=1000, unit_search_distance=500}
			surface_play_sound("reactor-stabilized", global.current_surface)	

		end
	end
end

function warptorio.TickTimers(e)
	if(gwarptorio.warp_charging==1)then
		gwarptorio.warp_time_left=60*gwarptorio.warp_charge_time - (e-gwarptorio.warp_charge_start_tick)
		warptorio.updatelabel("time_left","   Time to warp : " .. util.formattime(gwarptorio.warp_time_left))
		if(gwarptorio.warp_time_left<=0)then
			warptorio.Warpout()
			gwarptorio.time_spent_start_tick=e
		end
	end
	gwarptorio.time_passed=e - gwarptorio.time_spent_start_tick
	warptorio.updatelabel("time_passed_label","   Time passed on this planet : " .. util.formattime(gwarptorio.time_passed))
end

function warptorio.Tick(ev) local e=ev.tick
	if(e%5==0)then
		warptorio.TickLogistics(e)
		if(e%30==0)then
			warptorio.TickTeleporters(e)
			if(e%60==0)then
				warptorio.TickTimers(e)
				if(e%120==0)then
					-- attack left behind engineers (removed because not needed and factorissimo support)
					warptorio.TickPollution(e)
					warptorio.TickWarpAlarm(e)
					warptorio.TickWarpEnergy(e)
					warptorio.TickWarpAlarm(e)
					warptorio.TickAccelerator(e)
					warptorio.TickStabilizer(e)
				end
			end
		end
	end
end script.on_event(defines.events.on_tick,warptorio.Tick)





function warptorio.OnPlayerRespawned(event) -- teleport to warp platform on respawn
	local cf=warptorio.current_surface local gp=game.players[event.player_index]
	if(gp.character.surface~=cf)then local pos=game.surfaces[warptorio.current_surface].find_non_colliding_position("character",{0,-5},0,1,1) gp.teleport(pos,warptorio.current_surface) end
end script.on_event(defines.events.on_player_respawned,warptorio.OnPlayerRespawned)



-- -------
-- Upgrades

local upcs={} warptorio.UpgradeClass=upcs

function warptorio.DoUpgrade(ev) local up=ev.name local u=warptorio.Research[up] if(u)then
	if(type(u)=="table")then local lv=ev.level gwarptorio.Research[u[1]]=lv local c=warptorio.UpgradeClass[u[1]] if(c)then c(lv,u[2]) end -- (gwarptorio.Research[u[1]] or 0)+1
	elseif(type(u)=="function")then u() end
end end script.on_event(defines.events.on_research_finished,function(event) warptorio.DoUpgrade(event.research) end)

function warptorio.GetUpgrade(up) local u=warptorio.Research[u] if(u)then
	if(type(u)=="table")then local lv=gwarptorio.Research[u[1]] or 0 return lv,u[2] end
end end

upcs["platform-size"]=function(lv,f) local n=f(lv) local m=gwarptorio.Floors.main m.OuterSize=n m:SetSize(m.OuterSize+m.InnerSize) warptorio.BuildPlatform() end
upcs["platform-inner"]=function(lv,f) local n=f(lv) local m=gwarptorio.Floors.main m.InnerSize=n m:SetSize(m.OuterSize+m.InnerSize) warptorio.BuildPlatform() end
upcs["factory-size"]=function(lv,f) local n=f(lv) local m=gwarptorio.Floors.b1 m:SetSize(n) warptorio.BuildB1() end
upcs["boiler-size"]=function(lv,f) local n=f(lv) local m=gwarptorio.Floors.b2 m:SetSize(n) warptorio.BuildB2() end
upcs["teleporter-energy"]=function(lv) gwarptorio.Teleporters.offworld:UpgradeEnergy() end
upcs["factory-logistics"]=function(lv) for k,v in pairs(gwarptorio.Teleporters)do v:UpgradeLogistics() end end
upcs["factory-energy"]=function(lv) local m=gwarptorio.Teleporters
	if(m.b1)then m.b1:UpgradeEnergy() end if(m.b2)then m.b2:UpgradeEnergy() end
	for i=1,4,1 do if(m["edge"..i])then m["edge"..i]:UpgradeEnergy() end end
end

upcs["factory-beacon"]=function(lv,f) local m=gwarptorio.Floors.b1 local inv={}
	if(m.beacon and m.beacon.valid)then inv=m.beacon.get_module_inventory().get_contents() end
	warptorio.cleanbbox(m:GetSurface(),-2,-2,1,1) m.beacon=warptorio.SpawnEntity(m:GetSurface(),"warptorio-beacon-"..lv,-1,-1) m.beacon.minable=false m.beacon.destructible=false
	for k,v in pairs(inv)do m.beacon.get_module_inventory().insert({name=k,count=v}) end
	warptorio.playsound("warp_in",m:GetSurface().name)
end
upcs["reactor"]=function(lv) local m=gwarptorio.Floors.b2
	if(not m.heat1 or not m.heat1.valid)then local e=warptorio.SpawnEntity(m:GetSurface(),"heat-pipe",-1,0) e.minable=false e.destructible=false m.heat1=e end
	if(lv>=1 and (not m.heat2 or not m.heat2.valid))then local e=warptorio.SpawnEntity(m:GetSurface(),"heat-pipe",-1,1) e.minable=false e.destructible=false m.heat2=e end
	if(lv>=2 and (not m.heat3 or not m.heat3.valid))then local e=warptorio.SpawnEntity(m:GetSurface(),"heat-pipe",-1,2) e.minable=false e.destructible=false m.heat3=e end
	if(lv>=3 and (not m.heat4 or not m.heat4.valid))then local e=warptorio.SpawnEntity(m:GetSurface(),"heat-pipe",-1,3) e.minable=false e.destructible=false m.heat4=e end
	warptorio.playsound("warp_in",m:GetSurface().name)
end
upcs["stabilizer"]=function(lv) local m=gwarptorio.Floors.main
	warptorio.cleanbbox(m:GetSurface(),-6,-2,-4,0) local e=warptorio.SpawnEntity(m:GetSurface(),"warptorio-stabilizer-"..lv,-5,-1) m.stabilizer=e e.minable=false
	warptorio.playsound("warp_in",m:GetSurface().name)
end
upcs["accelerator"]=function(lv) local m=gwarptorio.Floors.main
	warptorio.cleanbbox(m:GetSurface(),-3,-3,2,2) local e=warptorio.SpawnEntity(m:GetSurface(),"warptorio-accelerator-"..lv,4,-1) e.minable=false
end

local ups={} warptorio.Research=warptorio.Research or ups
ups["warptorio-platform-size-1"] = {"platform-size",function() return 16 end}
ups["warptorio-platform-size-2"] = {"platform-size",function() return 48 end}
ups["warptorio-platform-size-3"] = {"platform-size",function() return 64 end}
ups["warptorio-platform-size-4"] = {"platform-size",function() return 64+16 end}
ups["warptorio-platform-size-5"] = {"platform-size",function() return 64+32 end}
ups["warptorio-platform-size-6"] = {"platform-size",function() return 64+48 end}
ups["warptorio-platform-size-7"] = {"platform-size",function() return 128 end}

ups["warptorio-platform-inner-1"] = {"platform-inner",function() return 16 end}
ups["warptorio-platform-inner-2"] = {"platform-inner",function() return 20 end}
ups["warptorio-platform-inner-3"] = {"platform-inner",function() return 24 end}

ups["warptorio-factory-0"] = function() warptorio.TeleCls.b1() end
ups["warptorio-factory-1"] = {"factory-size",function() return 32 end}
ups["warptorio-factory-2"] = {"factory-size",function() return 48 end}
ups["warptorio-factory-3"] = {"factory-size",function() return 64 end}
ups["warptorio-factory-4"] = {"factory-size",function() return 64+16 end}
ups["warptorio-factory-5"] = {"factory-size",function() return 64+32 end}
ups["warptorio-factory-6"] = {"factory-size",function() return 64+48 end}
ups["warptorio-factory-7"] = {"factory-size",function() return 128 end}

ups["warptorio-boiler-0"] = function() warptorio.TeleCls.b2() end
ups["warptorio-boiler-1"] = {"boiler-size",function() return 32 end}
ups["warptorio-boiler-2"] = {"boiler-size",function() return 48 end}
ups["warptorio-boiler-3"] = {"boiler-size",function() return 64 end}
ups["warptorio-boiler-4"] = {"boiler-size",function() return 64+16 end}
ups["warptorio-boiler-5"] = {"boiler-size",function() return 64+32 end}
ups["warptorio-boiler-6"] = {"boiler-size",function() return 64+48 end}
ups["warptorio-boiler-7"] = {"boiler-size",function() return 128 end}

ups["warptorio-reactor-1"] = {"reactor"}
ups["warptorio-reactor-2"] = {"reactor"}
ups["warptorio-reactor-3"] = {"reactor"}
ups["warptorio-reactor-4"] = {"reactor"}

ups["warptorio-teleporter-0"] = function() warptorio.TeleCls.offworld() end
ups["warptorio-teleporter-1"] = {"teleporter-energy"}
ups["warptorio-teleporter-2"] = {"teleporter-energy"}
ups["warptorio-teleporter-3"] = {"teleporter-energy"}
ups["warptorio-teleporter-4"] = {"teleporter-energy"}
ups["warptorio-teleporter-5"] = {"teleporter-energy"}

ups["warptorio-energy-1"] = {"factory-energy"}
ups["warptorio-energy-2"] = {"factory-energy"}
ups["warptorio-energy-3"] = {"factory-energy"}
ups["warptorio-energy-4"] = {"factory-energy"}
ups["warptorio-energy-5"] = {"factory-energy"}

ups["warptorio-logistics-1"] = {"factory-logistics"}
ups["warptorio-logistics-2"] = {"factory-logistics"}
ups["warptorio-logistics-3"] = {"factory-logistics"}
ups["warptorio-logistics-4"] = {"factory-logistics"}

ups["warptorio-beacon-1"] = {"factory-beacon"}
ups["warptorio-beacon-2"] = {"factory-beacon"}
ups["warptorio-beacon-3"] = {"factory-beacon"}

ups["warptorio-radar-1"] = {"radar"}
ups["warptorio-radar-2"] = {"radar"}
ups["warptorio-radar-3"] = {"radar"}

ups["warptorio-stabilizer-1"] = {"stabilizer"}
ups["warptorio-stabilizer-2"] = {"stabilizer"}
ups["warptorio-stabilizer-3"] = {"stabilizer"}
ups["warptorio-stabilizer-4"] = {"stabilizer"}

ups["warptorio-accelerator-1"] = {"accelerator"}


ups["warptorio-warpenergy-0"] = function() gwarptorio.warpenergy=true end

-- ups["warptorio-train-1"] = function() warptorio.TeleCls.train() end
-- ups["warptorio-train-2"] = function() warptorio.TeleCls.train2() end

-- ups["warptorio-boiler-water-1"] = {"boiler-water"}


-- --------
-- Gui



function warptorio.BuildGui(player)

	button_warp = mod_gui.get_frame_flow(player).add{type = "button", name = "warp", caption = {"warp"}}
	mod_gui.get_frame_flow(player).add{type = "label", name = "time_passed_label", caption = {"time-passed-label", "-"}}	
	mod_gui.get_frame_flow(player).add{type = "label", name = "time_left", caption = {"time-left", "-"}}
	mod_gui.get_frame_flow(player).add{type = "label", name = "number_of_warps_label", caption = {"number-of-warps-label", "-"}}
	
	local label = mod_gui.get_frame_flow(player).number_of_warps_label
	label.caption = "   Warp number : " .. (gwarptorio.warpzone or 0)
	
	local label = mod_gui.get_frame_flow(player).time_left
	label.caption = "   Charge Time : " .. util.formattime(0) --global.warp_time_left)

	
end

script.on_event(defines.events.on_gui_click, function(event)
	local gui = event.element
	if gui.name == "warp" then
		gwarptorio.warp_charge_start_tick = event.tick
		gwarptorio.warp_charging = 1
	end
end)


-- Initialize Players
function warptorio.InitPlayer(e)
	local i=e.player_index
	local p=game.players[i]
	warptorio.BuildGui(p)
	--if(i==1)then warptorio.Initialize() end
	warptorio.safeteleport(p.character,{0,-5},gwarptorio.Floors.main:GetSurface())
end script.on_event(defines.events.on_player_created,warptorio.InitPlayer)

-- --------
-- Platforms

local FLOOR={} FLOOR.__index=FLOOR warptorio.FloorMeta=FLOOR
function FLOOR.__init(self,n,z) global.warptorio.Floors[n]=self self.f,self.n=f,n self.ents={} self:SetSize(z) end
function FLOOR:SetSize(z) self.z,self.x,self.y,self.w,self.h=z,-z/2,-z/2,z,z self:CalcSizebox() end
function FLOOR:CalcSizebox() self.pos={self.x,self.y} self.size={self.w,self.h}
	self.bbox={self.x+self.w,self.y+self.h} self.area={self.pos,self.bbox} self.sizebox={self.pos,self.size} end
function FLOOR:GetPos() return self.pos end
function FLOOR:GetSize() return self.size end
function FLOOR:GetBBox() return self.bbox end
function FLOOR:GetSizebox() return {self.pos,self.size} end
function FLOOR:SetSurface(f) self.f=f end
function FLOOR:GetSurface() return self.f end
function FLOOR:BuildSurface(id) if(self:GetSurface())then return end
	local f=game.create_surface(id,{width=self.w-1,height=self.h-1})
	f.always_day = true
	f.daytime=0.5
	f.request_to_generate_chunks({0,0},10)
	f.force_generate_chunk_requests()
	local e=f.find_entities() for k,v in pairs(e)do e[k].destroy() end
	--f.name=id
	f.destroy_decoratives({area={self.pos,self.bbox}})
	self:SetSurface(f)
	return f
end

function warptorio.GetFloor(n) return global.warptorio.Floors[n] end
function warptorio.CurrentFloor() return global.warptorio.Floors["main"] end

function warptorio.InitFloors() -- init_floors(f)
	local f=game.surfaces["nauvis"]
	local m=new(FLOOR,"main",6)
	m:SetSurface(f)
	m.InnerSize=7
	m.OuterSize=2
	local z=m.InnerSize+m.OuterSize
	m:SetSize(m.InnerSize+m.OuterSize)

	warptorio.BuildPlatform(z)
	warptorio.cleanbbox(f,math.floor(-z/2),math.floor(-z/2),z,z)

	local m=new(FLOOR,"b1",15)
	local f=m:BuildSurface("warpfloor-b1")
	warptorio.BuildB1()

	local m=new(FLOOR,"b2",15)
	local f=m:BuildSurface("warpfloor-b2")
	warptorio.BuildB2()
end

function warptorio.BuildPlatform() local m=gwarptorio.Floors.main local f=m:GetSurface() local z=m.z local lv=(gwarptorio.Research["platform-inner"] or 0)
	warptorio.LayFloor("warp-tile",f,math.floor(-z/2),math.floor(-z/2),z,z,true) -- main platform

	if(lv>0)then
		warptorio.LayFloor("hazard-concrete-left",f,-4,-8,7,3) --teleporter
		warptorio.LayFloor("hazard-concrete-left",f,-6,-2,2,2) -- stabilizer
		warptorio.LayFloor("hazard-concrete-left",f,3,-2,2,2) -- stabilizer 2
		warptorio.LayFloor("hazard-concrete-left",f,-4,4,7,3) -- underground
	end

	local z=25 --m.InnerSize or 24
	warptorio.LayBorder("hazard-concrete-left",f,math.floor(-z/2),math.floor(-z/2),z,z)
end

function warptorio.BuildB1() local m=gwarptorio.Floors.b1 local f=m:GetSurface() local z=m.z
	warptorio.LayFloor("warp-tile",f,math.floor(-z/2),math.floor(-z/2),z,z)
	warptorio.LayFloor("hazard-concrete-left",f,-4,-7,7,3)
	warptorio.LayFloor("hazard-concrete-left",f,-3,-3,5,5)

	warptorio.playsound("warp_in",f.name)
end

function warptorio.BuildB2() local m=gwarptorio.Floors.b2 local f,z=m:GetSurface(),m.z

	warptorio.LayFloor("warp-tile",f,math.floor(-z/2),math.floor(-z/2),z,z)
	warptorio.LayFloor("hazard-concrete-left",f,-4,-7,7,3)
	warptorio.LayFloor("hazard-concrete-left",f,-4,3,7,3)
	warptorio.LayFloor("hazard-concrete-left",f,-2,-2,3,3)

	warptorio.playsound("warp_in",f.name)
end

-- ----
-- Floor helpers

function warptorio.CountEntities() local c=0 for k,v in pairs(gwarptorio.Floors)do local e=v.f.find_entities(v.area) for a,b in pairs(e)do c=c+1 end end return c end


-- --------
-- Warpout




function warptorio.RandomPlanet(z) z=z or gwarptorio.warpzone local zp={} for k,v in pairs(warptorio.Planets)do if((v.zone or 0)<z)then for i=1,(v.rng or 1) do table.insert(zp,k) end end end
	return warptorio.Planets[table.Random(zp)] end

function warptorio.DoNextPlanet()
	local w=warptorio.RandomPlanet(gwarptorio.warpzone+1)
	return w
end

function warptorio.BuildNewPlanet()
	local rng=math.random(1,table.Count(warptorio.Planets))
	local w if(gwarptorio.nextplanet)then w=warptorio.Planets[gwarptorio.nextplanet] gwarptorio.nextplanet=warptorio.DoNextPlanet() else w=warptorio.RandomPlanet() end
	local lvl=gwarptorio.Research["radar"] or 0

	if(lvl>=2)then game.print(w.name) end
	game.print(w.desc)

	local seed=(game.surfaces["nauvis"].map_gen_settings.seed + math.random(0,4294967295)) % 4294967296
	local t=(w.gen and table.deepcopy(w.gen) or {}) t.seed=seed if(w.fgen)then w.fgen(t,lvl>=3) end local f = game.create_surface("warpsurf_"..gwarptorio.warpzone,t)
	f.request_to_generate_chunks({0,0},2) f.force_generate_chunk_requests()
	if(w.spawn)then w.spawn(f) end
	return f
end


function warptorio.Warpout()
	gwarptorio.warp_charge = 0
	gwarptorio.warp_charging=0
	gwarptorio.warpzone = gwarptorio.warpzone+1
	warptorio.updatelabel("number_of_warps_label","    Warp number : " .. gwarptorio.warpzone)

	-- charge time
	local c=warptorio.CountEntities()
	gwarptorio.warp_charge_time=1 --10+c/settings.global['warptorio_warp_charge_factor'].value + gwarptorio.warpzone*0.5
	gwarptorio.warp_time_left = 1 --60*gwarptorio.warp_charge_time
	warptorio.updatelabel("time_left","   Charge Time : " .. util.formattime(gwarptorio.warp_time_left))

	-- create next surface
	 local f=warptorio.BuildNewPlanet()
	--local f = game.create_surface("warpsurf_"..gwarptorio.warpzone,{seed=(game.surfaces["nauvis"].map_gen_settings.seed + math.random(0,4294967295)) % 4294967296})
	--f.request_to_generate_chunks({0,0},1)
	--f.force_generate_chunk_requests()

	-- Do the thing
	for k,v in pairs(gwarptorio.Teleporters)do v:Warpout() end

	local m=gwarptorio.Floors.main
	local c=m:GetSurface()
	local bbox=m.area
	c.clone_area{source_area=bbox, destination_area=bbox, destination_surface=f, expand_map=false, clone_tiles=true, clone_entities=true, clone_decoratives=false, clear_destination=true}

	gwarptorio.Floors.main:SetSurface(f)
	for k,v in pairs(gwarptorio.Teleporters)do v:Warpin() end

	-- teleport players to new surface
	for k,v in pairs(game.players)do
		local p,b=m:GetPos(),m:GetBBox()
		if(v.character~=nil and warptorio.isinbbox(v.character.position,{x=p[1],y=p[2]},{x=b[1],y=b[2]}))then v.teleport(f.find_non_colliding_position("character",{0,-4},0,1,1),f) end
	end

	-- radar stuff -- game.forces.player.chart(game.player.surface, {lefttop = {x = -1024, y = -1024}, rightbottom = {x = 1024, y = 1024}})
	game.forces.player.chart(f,{lefttop={x=-1024,y=-1024},rightbottom={x=1024,y=1024}})

	-- build void
	warptorio.LayFloorVec("out-of-map",c,m:GetPos(),m:GetSize())

	-- delete abandoned surfaces
	for k,v in pairs(game.surfaces)do if(#(v.find_entities_filtered{type="character"})<1)then local n=v.name if(n:sub(1,10)=="warpsurf_")then game.delete_surface(v) end end end

	-- stuff to reset
	gwarptorio.surf_to_leave_angry_biters_counter = 0
	game.forces["enemy"].evolution_factor=0
	gwarptorio.pollution_amount=1
	gwarptorio.warp_stabilizer_accumulator_discharge_count = 0

	-- warp sound
	warptorio.playsound("warp_in", c.name)
	warptorio.playsound("warp_in", f.name)

	-- What an odd bug.
	warptorio.BuildPlatform()
end


-- --------
-- Helper functions

function warptorio.layvoid(f,x,y,z) warptorio.FillSquare("out-of-map",f,x,y,z,z) end

function warptorio.LayFloor(tex,f,x,y,w,h,b) if(b)then local bbox={area={{x,y},{x+w,y+h}}} f.destroy_decoratives(bbox) end
	local t={} for i=0,w-1 do for j=0,h-1 do table.insert(t,{name=tex,position={i+x,j+y}}) end end f.set_tiles(t) end

function warptorio.LayBorder(tex,f,x,y,w,h,b) if(b)then local bbox={area={{x,y},{x+w,y+h}}} f.destroy_decoratives(bbox) end
	local t={} w=w-1 h=h-1
	for i=0,w do table.insert(t,{name=tex,position={x+i,y}}) table.insert(t,{name=tex,position={x+i,y+h}}) end
	for j=0,h do table.insert(t,{name=tex,position={x,y+j}}) table.insert(t,{name=tex,position={x+w,y+j}}) end
	f.set_tiles(t)
end

function warptorio.LayFloorVec(tx,f,p,z,b) if(b)then f.destroy_decoratives({area=b}) end
	local t={} for i=0,z[1]-1 do for j=0,z[2]-1 do table.insert(t,{name=tx,position={i+p[1],j+p[2]}}) end end f.set_tiles(t) end
function warptorio.cleanbbox(f,x,y,w,h) local e=f.find_entities({{x,y},{x+w,y+h}})
	for k,v in ipairs(e)do if(v.type~="character")then v.destroy() else warptorio.safeteleport(v,{0,0},f) end end end
function warptorio.safeteleport(e,x,f) local xf=f.find_non_colliding_position(e.name,x,0,1,1)
	if(e.type=="character")then for k,v in pairs(game.players)do if(v.character==e)then v.teleport(xf,f) end end end end

function warptorio.PrintToCharacter(c,msg,x) for k,v in pairs(game.players)do if(v.character==c)then v.print(msg) end end end
function warptorio.updatelabel(lbl,txt) for k,v in pairs(game.players)do local lb=mod_gui.get_frame_flow(v) local lb2=lb[lbl] lb2.caption=txt end end
function warptorio.isinbbox(pos,pos1,pos2) return not ( (pos.x<pos1.x or pos.y<pos1.y) or (pos.x>pos2.x or pos.y>pos2.y) ) end
function warptorio.playsound(pth,f,x) for k,v in pairs(game.connected_players)do if(v.surface.name==f)then v.play_sound{path=pth,position=x} end end end


function warptorio.spawnbiters(type,n,f) local tbl=game.surfaces[f].find_entities_filtered{type="character"}
	for k,v in ipairs(tbl)do
		for j=1,n do local a,d=math.random(0,2*math.pi),150 local x,y=math.cos(a)*d+v.position.x,math.sin(a)*d+v.position.y
			local p=game.surfaces[f].find_non_colliding_position(t,{x,y},0,2,1)
			local e=game.surfaces[f].create_entity{name=type,position=p}
		end
		game.surfaces[f].set_multi_command{command={type=defines.command.attack,target=v},unit_count=n}
	end
end





function warptorio.Initialize() if(not global.warptorio)then global.warptorio={} gwarptorio=global.warptorio else gwarptorio=global.warptorio return end
	gwarptorio.warpzone=0

	gwarptorio.surf_to_leave_angry_biters_counter = 0
	gwarptorio.pollution_amount = 1

	gwarptorio.warp_charge_time= 1--10 --in seconds
	gwarptorio.warp_charge_start_tick = 0
	gwarptorio.warp_charging = 0
	gwarptorio.warp_timeleft = 60*10
	gwarptorio.warp_reactor = nil

	gwarptorio.time_spent_start_tick = 0
	gwarptorio.time_passed = 0

	gwarptorio.pollution_amount = 1 --settings.global['warptorio_warp_polution_factor'].value
	gwarptorio.base_expansion_cooldown = 1000 * 60
	gwarptorio.charge_factor = settings.global['warptorio_warp_charge_factor'].value


	gwarptorio.Teleporters={}
	gwarptorio.Research={}
	gwarptorio.Floors={}

	warptorio.InitFloors()
	warptorio.InitEntities()
	warptorio.InitTeleporters()

	game.map_settings.pollution.diffusion_ratio = 0.1
	game.map_settings.pollution.pollution_factor = 0.0000001
		
	game.map_settings.pollution.min_to_diffuse=15
	game.map_settings.unit_group.min_group_gathering_time = 600
	game.map_settings.unit_group.max_group_gathering_time = 2 * 600
	game.map_settings.unit_group.max_unit_group_size = 200
	game.map_settings.unit_group.max_wait_time_for_late_members = 2 * 360
	game.map_settings.unit_group.settler_group_min_size = 1
	game.map_settings.unit_group.settler_group_max_size = 1

--[[


--local warp_charge_time_lengthening = settings.global['warptorio_warp_charge_time_lengthening'].value --in seconds
--local warp_charge_time_at_start = settings.global['warptorio_warp_charge_time_at_start'].value --in seconds


	global.warp_reactor = nil
	global.warp_stabilizer_accumulator = nil
	global.warp_stabilizer_accumulator_discharge_count = 0
	global.warp_stabilizer_accumulator_research_level = 0

]]
end script.on_init(warptorio.Initialize)

