--!strict
-- PurchaseLedger: pure helpers over a profile's PurchaseHistory (a list of receipt ids) so
-- ProcessReceipt is idempotent: a replayed receipt is recognised and never granted twice.
local PurchaseLedger = {}

function PurchaseLedger.has(history: { string }, purchaseId: string): boolean
	return table.find(history, purchaseId) ~= nil
end

-- Append a receipt id, dropping the oldest entries beyond `limit`. Returns false if already present.
function PurchaseLedger.record(history: { string }, purchaseId: string, limit: number): boolean
	if PurchaseLedger.has(history, purchaseId) then
		return false
	end
	table.insert(history, purchaseId)
	while #history > limit do
		table.remove(history, 1)
	end
	return true
end

return PurchaseLedger
