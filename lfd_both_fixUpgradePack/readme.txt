Fixes upgrade packs pickup bug when there are 5+ survivors

-ChangeLog-
v1.4
-Remake code
-remove unuseful convar
-add timer to remove upgrade pack entity

v1.0
Original Post: https://forums.alliedmods.net/showthread.php?t=322824

-Convar-
cfg\sourcemod\lfd_both_fixUpgradePack.cfg
// Time in seconds to remove upgradepack after first use. (0=off)
upgrade_clear_time "100"

// Play sound when ammo already used
upgrade_denied_sound "1"

// Explosive ammo multiplier on pickup
upgrade_explosive_multi "1.0"

// Incendiary ammo multiplier on pickup
upgrade_incendiary_multi "1.0"
