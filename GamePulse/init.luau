--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamePulseClient = require(script.GamePulseClient)
local GamePulseEvent = require(script.GamePulseEvent)

local isServer = game:GetService("RunService"):IsServer()

local CLIENT_EVENT_NAME = "__GAMEPULSE_CLIENT_EVENT"

local GamePulse = {}
GamePulse._initialized = false
GamePulse._event = (nil :: any) :: RemoteEvent -- client only

-- Client initialization, not sure if this should be here as this will yield any requiring scripts, but it keeps the client code init-less
if not isServer then
	GamePulse._event = ReplicatedStorage:WaitForChild(CLIENT_EVENT_NAME, 10) :: RemoteEvent

	if not GamePulse._event then
		warn(
			"[GamePulse] Infinite yield possible; Client event still not found in ReplicatedStorage. Make sure the server initialized GamePulse correctly."
		)
		GamePulse._event = ReplicatedStorage:WaitForChild(CLIENT_EVENT_NAME) :: RemoteEvent
	end

	GamePulse._initialized = true
end

--[[
	[SERVER ONLY]
	Initializes GamePulse with given API key and optional endpoint URL. This method must be called before any events can be sent.
]]
function GamePulse.Init(apiKey: string, endpointUrl: string?)
	if not isServer then
		warn("[GamePulse] Init() called on client. This method can only be called on the server.")
		return
	end

	if GamePulse._initialized then
		warn("[GamePulse] Init called more than once. Ignoring.")
		return
	end

	GamePulse._initialized = true

	GamePulseClient.Configure(apiKey, endpointUrl)
	GamePulseClient.Start()

	local Event = Instance.new("RemoteEvent", ReplicatedStorage)
	Event.Name = CLIENT_EVENT_NAME

	Event.OnServerEvent:Connect(function(player: Player, eventName: string, data: any)
		GamePulse.Event(eventName, data)
	end)
end

--[[
	Sends an event to GamePulse with the given name and data. Must call Init() on the server before using this method.
	If called from the client, the server-side event will be fired which then sends the event to GamePulse.
]]
function GamePulse.Event(eventName: string, data: any)
	if not GamePulse._initialized then
		warn("[GamePulse] Event() called before Init(). Event dropped.")
		return
	end

	if isServer then
		GamePulseClient.Send(GamePulseEvent.new(eventName, data))
	else
		GamePulse._event:FireServer(eventName, data)
	end
end

return GamePulse
