An improved version of the MultiTanks plugin originally created by Red Alex.

-ChangeLog-
v2.1
- ProdigySim's method for indirectly getting signatures added, created the whole code for indirectly getting signatures so the plugin can now withstand most updates to L4D2!
(Thanks to Shadowysn: https://forums.alliedmods.net/showthread.php?t=320849 and ProdigySim: https://github.com/ProdigySim/DirectInfectedSpawn)
-Signature fix for December 1, 2020 update. (Credit to Shadowysn: https://forums.alliedmods.net/showthread.php?t=320849)
-Signature fix for December 8, 2020 update. (Credit to Shadowysn: https://forums.alliedmods.net/showthread.php?t=320849)
-Remake Code
-Replace Left 4 Downtown 2 extension with Lef4dhooks extension

v1.4
-original Post: https://forums.alliedmods.net/showthread.php?p=2567007

-Require-
1. Left 4 DHooks Direct: https://forums.alliedmods.net/showthread.php?p=2684862

-ConVar-
cfg\sourcemod\multitanks_a.cfg
// Enable/Disable Announcements when tank spawns.
multitanks_announce "0"

// Total Count Of Tanks In First Wave Finales
multitanks_count_coop_1stwave "1"

// Total Count Of Tanks In Second Wave Finales
multitanks_count_coop_2ndwave "1"

// Total Count Of Tanks In Finale Escapes
multitanks_count_coop_escape "1"

// Total Count Of Tanks In Finale Maps
multitanks_count_coop_finale "1"

// Total Count Of Tanks In Regular Maps
multitanks_count_coop_regular "1"

// Total Count Of Tanks (Scavenge)
multitanks_count_scavenge "2"

// Total Count Of Tanks (Survival)
multitanks_count_survival "2"

// Total Count Of Tanks In First Wave Finales (Versus)
multitanks_count_versus_1stwave "2"

// Total Count Of Tanks In Second Wave Finales (Versus)
multitanks_count_versus_2ndwave "2"

// Total Count Of Tanks In Finale Escapes (Versus)
multitanks_count_versus_escape "2"

// Total Count Of Tanks In Finale Maps (Versus)
multitanks_count_versus_finale "2"

// Total Count Of Tanks In Regular Maps (Versus)
multitanks_count_versus_regular "2"

// Enable/Disable Tank HUD Display
multitanks_display "0"

// Health Of Tanks In First Wave Finales, 0=off.
multitanks_health_coop_1stwave "0"

// Health Of Tanks In Second Wave Finales, 0=off.
multitanks_health_coop_2ndwave "0"

// Health Of Tanks In Finale Escapes, 0=off.
multitanks_health_coop_escape "0"

// Health Of Tanks In Finale Maps, 0=off.
multitanks_health_coop_finale "0"

// Health Of Tanks In Regular Maps, 0=off.
multitanks_health_coop_regular "0"

// Health Of Tanks (Scavenge), 0=off.
multitanks_health_scavenge "0"

// Health Of Tanks (Survival), 0=off.
multitanks_health_survival "0"

// Health Of Tanks In First Wave Finales (Versus), 0=off.
multitanks_health_versus_1stwave "12500"

// Health Of Tanks In Second Wave Finales (Versus), 0=off.
multitanks_health_versus_2ndwave "15000"

// Health Of Tanks In Finale Escapes (Versus), 0=off.
multitanks_health_versus_escape "20000"

// Health Of Tanks In Finale Maps (Versus), 0=off.
multitanks_health_versus_finale "10000"

// Health Of Tanks In Regular Maps (Versus), 0=off.
multitanks_health_versus_regular "8000"

// Enable/Disable Plugin.
multitanks_on "1"

// Delay Of Spawning Tanks In Finale Escapes
multitanks_spawn_delay_escape "2.5"

// Delay Of Spawning Tanks
multitanks_spawn_delay_regular "5.0"


