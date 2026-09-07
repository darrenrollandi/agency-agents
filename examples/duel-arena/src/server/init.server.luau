--!strict
-- Server entry point. Bootstraps Services in dependency order (P1+):
-- DataService → ProgressionService → MatchmakingService → DuelService → CombatService
-- → AbilityService → MonetisationService → AnalyticsService.
print("[Server] Duel Arena booted")
