--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local GamePulseEvent = require(script.Parent.GamePulseEvent)
local Utility = require(script.Parent.Utility)
local cryptography = require(script.Parent.cryptography)

local GamePulseClient = {}
GamePulseClient._configured = false
GamePulseClient._apiKey = nil :: string?
GamePulseClient._endpointUrl = nil :: string?
GamePulseClient._serverStart = nil :: DateTime?
GamePulseClient._serverEnded = false
GamePulseClient._started = false

local DEFAULT_ENDPOINT_URL = "http://localhost:3000/vacuum"

local playerJoinTimes: { [number]: number } = {}

local function getSHA256(input: string): (string, buffer)
	return cryptography.Hashing.SHA2.SHA256(buffer.fromstring(input))
end

local function onSessionEnd(userId: number, endTime: number)
	local joinTime = playerJoinTimes[userId]
	local sessionDuration = endTime - joinTime

	GamePulseClient.Send(GamePulseEvent.new("session_end", {
		player_id = getSHA256(tostring(userId)),
		duration_seconds = string.format("%.2f", sessionDuration / 1000),
	}))

	playerJoinTimes[userId] = nil
end

function GamePulseClient.Configure(apiKey: string, endpointUrl: string?)
	assert(apiKey, "[GamePulseClient] API key is required for configuration.")

	if endpointUrl == nil then
		warn("[GamePulseClient] No endpoint URL provided. Using default: " .. DEFAULT_ENDPOINT_URL)
	end

	GamePulseClient._configured = true
	GamePulseClient._apiKey = apiKey
	GamePulseClient._endpointUrl = endpointUrl or DEFAULT_ENDPOINT_URL
end

function GamePulseClient.Start()
	if not GamePulseClient._configured then
		warn("[GamePulseClient] Start called before Configure. Please configure first.")
		return
	end

	if GamePulseClient._started then
		warn("[GamePulseClient] Start called more than once. Ignoring.")
		return
	end

	GamePulseClient._started = true

	GamePulseClient._serverStart = DateTime.now().UnixTimestampMillis
	GamePulseClient.Send(GamePulseEvent.new("server_start"))

	for _, player in Players:GetPlayers() do
		GamePulseClient.OnPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(GamePulseClient.OnPlayerAdded)
	Players.PlayerRemoving:Connect(GamePulseClient.OnPlayerRemoved)
	game:BindToClose(GamePulseClient.OnGameClose)
end

function GamePulseClient.OnPlayerAdded(player: Player)
	playerJoinTimes[player.UserId] = DateTime.now().UnixTimestampMillis

	GamePulseClient.Send(GamePulseEvent.new("session_start", {
		player_id = getSHA256(tostring(player.UserId)),
	}))
end

function GamePulseClient.OnPlayerRemoved(player: Player)
	onSessionEnd(player.UserId, DateTime.now().UnixTimestampMillis)
end

function GamePulseClient.OnGameClose()
	if GamePulseClient._serverEnded or not GamePulseClient._serverStart then
		return
	end

	GamePulseClient._serverEnded = true

	local currentTime = DateTime.now().UnixTimestampMillis
	local duration = currentTime - GamePulseClient._serverStart
	GamePulseClient.Send(GamePulseEvent.new("server_end", {
		duration_seconds = string.format("%.2f", duration / 1000),
	}))

	for userId, joinTime in playerJoinTimes do
		onSessionEnd(userId, currentTime)
	end
end

function GamePulseClient.Send(event: GamePulseEvent.GamePulseEvent)
	local json = HttpService:JSONEncode({
		api_key = GamePulseClient._apiKey,
		events = { Utility.objectToSnakeCase(event) },
	})
	HttpService:PostAsync(GamePulseClient._endpointUrl, json, Enum.HttpContentType.ApplicationJson, false)
end

return GamePulseClient
