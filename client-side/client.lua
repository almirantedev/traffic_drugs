local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPclient = Tunnel.getInterface("vRP")
func = Tunnel.getInterface("traffic_drugs")

---- [ VARIABLES ] ----
local seconds = 0
local saleInProgress = false
local pedSold = nil

---- [ THREAD SELL ] ----
CreateThread(function() 
	while true do
		local distance = nil
		if not saleInProgress then
			for line,content in pairs(GetGamePool('CPed')) do
				if content and content ~= GetPlayerPed(-1) then
					local coordsPed = GetEntityCoords(content)
					local myCoords = GetEntityCoords(GetPlayerPed(-1))
	
					distance = Vdist(coordsPed.x, coordsPed.y, coordsPed.z, myCoords.x, myCoords.y, myCoords.z)

					if distance <= 1.5 then
						if IsControlJustPressed(0, 38) and func.hasDrug() and not func.checkSoldPedList(content) then
							func.registerPedSold(content)
							seconds = 8
							saleInProgress = true
							pedSold = content
							TaskPause(content, 100000)
						end
					end
				end
			end
		else 
			drawText("FALTAM ~g~"..seconds.."~w~ PRA TERMINAR A VENDA",4,0.5,0.93,0.38,255,255,255,180)
		end

		Wait(1)
	end
end)

CreateThread(function()
	while true do
		Wait(100)
		if saleInProgress then
			distanceBetweenCoords = Vdist(GetEntityCoords(PlayerPedId()), GetEntityCoords(pedSold))
			if distanceBetweenCoords >= 4 then
				saleInProgress = false
				ClearPedTasks(pedSold)
			end
		end
	end
end)

CreateThread(function()
	while true do
		Wait(1000)
		local x, y, z = table.unpack(vec3(GetEntityCoords(PlayerPedId())))
		if saleInProgress then
			seconds = seconds - 1
			if seconds <= 0 then
				saleInProgress = false
				seconds = 0
				func.sellDrug(x, y, z)
				ClearPedTasks(pedSold)
			end
		end
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWTXT
-----------------------------------------------------------------------------------------------------------------------------------------

function drawText(text, font, x, y, scale, r, g, b, a)
	SetTextFont(font)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x, y)
end