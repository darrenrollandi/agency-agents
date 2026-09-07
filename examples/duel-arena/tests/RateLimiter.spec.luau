--!strict
local RateLimiter = require(game:GetService("ReplicatedStorage").Shared.Util.RateLimiter)

type Assert = (actual: any, expected: any, label: string?) -> ()

return {
	["allows up to burst then refuses"] = function(assertEqual: Assert)
		local limiter = RateLimiter.new(2, 2)
		assertEqual(limiter:allow("k", 0), true, "first")
		assertEqual(limiter:allow("k", 0), true, "second")
		assertEqual(limiter:allow("k", 0), false, "third")
	end,

	["refills with time at ratePerSecond"] = function(assertEqual: Assert)
		local limiter = RateLimiter.new(2, 1)
		assertEqual(limiter:allow("k", 0), true, "t=0")
		assertEqual(limiter:allow("k", 0.25), false, "t=0.25 (half a token)")
		assertEqual(limiter:allow("k", 0.5), true, "t=0.5 (one token)")
		assertEqual(limiter:allow("k", 10), true, "t=10 capped at burst")
		assertEqual(limiter:allow("k", 10), false, "t=10 second call")
	end,

	["keys are independent and forget resets"] = function(assertEqual: Assert)
		local limiter = RateLimiter.new(1, 1)
		assertEqual(limiter:allow("a", 0), true, "a")
		assertEqual(limiter:allow("b", 0), true, "b")
		assertEqual(limiter:allow("a", 0), false, "a again")
		limiter:forget("a")
		assertEqual(limiter:allow("a", 0), true, "a after forget")
	end,
}
