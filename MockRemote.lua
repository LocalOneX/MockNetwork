--!nonstrict
--@May 4th, 2025

local module = {}

local RunService = game:GetService("RunService")
local remoteFunction = script:FindFirstChildOfClass("RemoteFunction") --Instance.new("RemoteFunction")
local remoteEvent = script:FindFirstChildOfClass("RemoteEvent") --Instance.new("RemoteEvent")

local connections: {[string]: {[number]: (...any) -> ()}} = {}
local functions: {[string]: (...any) -> ()} = {}

function module:Connect(remoteName: string, callback: (...any) -> ())
	if not connections[remoteName] then
		connections[remoteName] = {}
	end
	
	local idx =	 #connections[remoteName] + 1
	table.insert(connections[remoteName], idx, callback)
	
	--- disconnection task
	return function()
		table.remove(connections[remoteName], idx)
	end
end

function module:Function(remoteName: string, callback: (...any) -> ())
	if not functions[remoteName] then
		functions[remoteName] = {}
	end

	functions[remoteName] = callback

	--- disconnection task
	return function()
		functions[remoteName] = nil
	end
end

function module:FireClient(remoteName: string, player: Player, ...)
	remoteEvent:FireClient(player, remoteName, ...)
end

function module:FireServer(remoteName: string, ...)
	remoteEvent:FireServer(remoteName, ...)
end

function module:InvokeServer(remoteName: string, ...)
	return remoteFunction:InvokeServer(remoteName, ...)
end

function module:InvokeClient(remoteName: string, player: Player, ...)
	return remoteFunction:InvokeClient(player, remoteName, ...)
end

if RunService:IsServer() then
	remoteEvent.OnServerEvent:Connect(function(player: Player, remoteName: string, ...)
		if not connections[remoteName] then
			return
		end
		
		for i, v in ipairs(connections[remoteName]) do
			v(player, ...)
		end
	end)
	
	remoteFunction.OnServerInvoke = function(player: Player, remoteName: string, ...)
		if not functions[remoteName] then 
			return
		end
		 
		return functions[remoteName](player, ...)
	end
else
	remoteEvent.OnClientEvent:Connect(function(remoteName: string, ...)
		if not connections[remoteName] then
			return
		end

		for i, v in ipairs(connections[remoteName]) do
			v(...)
		end
	end)

	remoteFunction.OnClientInvoke = function(remoteName: string, ...)
		if not functions[remoteName] then
			return
		end

		return functions[remoteName](...)
	end
end

return module
