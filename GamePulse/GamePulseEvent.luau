--!strict
local GamePulseEvent = {}
GamePulseEvent.__index = GamePulseEvent

type self = {
	eventType: string,
	capturedAt: string,
	data: any,
}

export type GamePulseEvent = typeof(setmetatable({} :: self, GamePulseEvent))

function GamePulseEvent.new(eventType: string, data: any): GamePulseEvent
	local self = setmetatable({} :: self, GamePulseEvent)
	self.eventType = eventType

	local dt: any = DateTime.now():ToUniversalTime()
	self.capturedAt = string.format(
		"%04d-%02d-%02dT%02d:%02d:%02d.%02d",
		dt.Year,
		dt.Month,
		dt.Day,
		dt.Hour,
		dt.Minute,
		dt.Second,
		dt.Millisecond // 10
	)
	self.data = data
	return self
end

return GamePulseEvent
