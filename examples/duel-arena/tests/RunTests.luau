--!strict
-- Test entry point for pure-logic modules. Run from the Edit DataModel via MCP execute_luau:
--   require(game:GetService("ServerStorage").Tests.RunTests)()
-- Every ModuleScript in this folder named `*.spec` returns { [caseName] = function() ... end }.
-- A case passes when it returns without erroring. Do not test engine behaviour here.
local Tests = script.Parent

local function assertEqual(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(`{label or "value"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

return function(): boolean
	local passed, failed = 0, 0
	for _, child in Tests:GetChildren() do
		if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
			local cases = (require :: any)(child) :: { [string]: (typeof(assertEqual)) -> () }
			for caseName, case in cases do
				local ok, err = pcall(case, assertEqual)
				if ok then
					passed += 1
				else
					failed += 1
					warn(`[FAIL] {child.Name} / {caseName}: {err}`)
				end
			end
		end
	end
	print(`[Tests] {passed} passed, {failed} failed`)
	return failed == 0
end
