--!strict
-- RateLimiter: per-key token bucket. The clock is passed in so tests are deterministic.
local RateLimiter = {}
RateLimiter.__index = RateLimiter

type Bucket = { tokens: number, last: number }

export type RateLimiter = typeof(setmetatable(
	{} :: { _rate: number, _burst: number, _buckets: { [any]: Bucket } },
	RateLimiter
))

-- `burst` is how many actions may land at once; defaults to one second's worth (minimum 1).
function RateLimiter.new(ratePerSecond: number, burst: number?): RateLimiter
	return setmetatable({
		_rate = ratePerSecond,
		_burst = burst or math.max(1, math.ceil(ratePerSecond)),
		_buckets = {},
	}, RateLimiter)
end

-- True (and one token consumed) if `key` may act at time `now`; false if it is over its limit.
function RateLimiter.allow(self: RateLimiter, key: any, now: number): boolean
	local bucket = self._buckets[key]
	if not bucket then
		bucket = { tokens = self._burst, last = now }
		self._buckets[key] = bucket
	end
	bucket.tokens = math.min(self._burst, bucket.tokens + (now - bucket.last) * self._rate)
	bucket.last = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

-- Drop state for a key (player left).
function RateLimiter.forget(self: RateLimiter, key: any)
	self._buckets[key] = nil
end

return RateLimiter
