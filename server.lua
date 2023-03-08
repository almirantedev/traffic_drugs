local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")

func = {}
Tunnel.bindInterface("traffic_drugs", func)

---- [ VARIABLES ] ----
local blips = {}
local pedsSold = {}
local selectedDrug = {}

---- [ CHECK FOR DRUGS ] ----
function func.hasDrug()
	local source = source
	local user_id = vRP.getUserId(source)

	local quantitySell = math.random(config.quantity[1],config.quantity[2])
	local value = math.random(config.drugValue[1], config.drugValue[2])
	local total = quantitySell * value

	for line, content in pairs(config.drugs) do
		if config.creative then
			if vRP.getInventoryItemAmount(user_id, content)[1] >= quantitySell then
				selectedDrug[user_id] = { content, quantitySell, total }
				return true
			end
		else
			if vRP.getInventoryItemAmount(user_id, content) >= quantitySell then
				selectedDrug[user_id] = { content, quantitySell, total }
				return true
			end
		end
		
	end

	return false
end

---- [ SELL DRUGS ] ----
function func.sellDrug(x, y, z)
	local source = source
	local user_id = vRP.getUserId(source)

	local acceptedSell = math.random(100)
	
	if config.creative then
		if acceptedSell <= 80 then
			if vRP.tryGetInventoryItem(user_id, selectedDrug[user_id][1], selectedDrug[user_id][2], true) then
				vRPC.createObjects(source, "mp_safehouselost@", "package_dropoff", "prop_paper_bag_small", 16, 28422, 0.0, -0.05, 0.05, 180.0, 0.0, 0.0)
				Citizen.Wait(3000)
				
				vRP.generateItem(user_id, "dollars", selectedDrug[user_id][3], true)
				TriggerClientEvent("inventory:Update", source, "updateMochila")
				vRPC.removeObjects(source)
			end
		else
			local polices = vRP.numPermission("Police")
			local ped = GetPlayerPed(source)
			local coords = GetEntityCoords(ped)
	
			for k,v in pairs(polices) do
				async(function()
					vRPC.playSound(v, "ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")
					TriggerClientEvent("NotifyPush", v, { code = 20, title = "Venda de Drogas", x = coords["x"], y = coords["y"], z = coords["z"], criminal = "Ligação Anônima", time = "Recebido às "..os.date("%H:%M"), blipColor = 16 })
				end)
			end
		end
	else
		if acceptedSell <= 80 then
			if vRP.tryGetInventoryItem(user_id, selectedDrug[user_id][1], selectedDrug[user_id][2]) then
				vRPclient._playAnim(source, false, {{"mp_safehousevagos@","package_dropoff"}}, false)
				vRP.giveInventoryItem(user_id, "dinheiro-sujo", selectedDrug[user_id][3])
				TriggerClientEvent("Notify",source,"sucesso","Você vendeu "..selectedDrug[user_id][2].." "..selectedDrug[user_id][1].." por "..selectedDrug[user_id][3].." dinheiro sujo!",8000)
			end
		else
			for l,w in pairs(polices) do
				local policePlayer = vRP.getUserSource(parseInt(w))
				if policePlayer then
					async(function()
						local ids = idgens:gen()
						blips[ids] = vRPclient.addBlip(policePlayer, x, y, z, 1, 59, "Tráfico de drogas", 0.8, false)
						TriggerClientEvent('chatMessage', policePlayer, "911", {64,64,255} ,"^1Venda de drogas^0 acontecendo nesse momento")
						SetTimeout(30000, function() vRPclient.removeBlip(policePlayer,blips[ids]) idgens:free(ids) end)
					end)
				end
			end
		end
	end
end

---- [ REGISTER SOLD PED  ] ----
function func.registerPedSold(pedId)
	pedsSold[pedId] = true
end

---- [ CHECK SOLD PED LIST  ] ----
function func.checkSoldPedList(pedId)
	if pedsSold[pedId] then
		return true
	else
		return false
	end
end

---- [ PLAYER DISCONNECT  ] ----
AddEventHandler("playerDisconnect",function(user_id)
	if selectedDrug[user_id] then
		selectedDrug[user_id] = nil
	end
end)