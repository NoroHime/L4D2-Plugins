Very Very loudly announces the predicted event of a player leaving the map and or life through height or drown.

-Changelog-
v4.0
-Remove <autoexecconfig>
-Remove <updater>

-Original Post: https://forums.alliedmods.net/showthread.php?t=336225

-Require-
sourcemod 1.11 or above, otherwise server would crash
left4dhooks: https://forums.alliedmods.net/showthread.php?p=2684862
multicolors: https://forums.alliedmods.net/showthread.php?t=247770

-ConVar-
cfg/sourcemod/l4d2_karma_kill.cfg
// Award a confirmed karma maker with a player_death event.
l4d2_karma_award_confirmed "1"

// Prefix for announcements. For colors, replace the side the slash points towards, example is /x04[/x05KarmaCharge/x03]
l4d2_karma_charge_prefix "TS"

// Damage to award on confirmed kills, or -1 to disable. Requires l4d2_karma_award_confirmed set to 1
l4d2_karma_damage_award_confirmed "300"

// Enable karma jumping. Karma jumping only registers on confirmed kills.
l4d2_karma_jump "1"

// Whether or not to enable bird charges, which are unlethal height charges.
l4d2_karma_kill_bird "1"

// If slowmode is 0, how long does it take for the next karma to freeze the entire map. Begins counting from the end of the previous freeze
l4d2_karma_kill_cooldown "0.0"

//  Turn Karma Kills on and off 
l4d2_karma_kill_enabled "1"

// Fixes this by disabling fall damage when carried: https://streamable.com/xuipb6
l4d2_karma_kill_no_fall_damage_on_carry "1"

// If you take more than 224 points of damage while incapacitated, you die.
l4d2_karma_kill_no_fall_damage_protect_from_incap "1"

//  0 - Entire Server gets slowed, 1 - Only Charger and Survivor do
l4d2_karma_kill_slowmode "0"

//  How slow Time gets. Hardwired to minimum 0.03 or the server crashes
l4d2_karma_kill_slowspeed "0.2"

//  How long does Time get slowed for the karma couple
l4d2_karma_kill_slowtime_on_couple "3.0"

//  How long does Time get slowed for the server
l4d2_karma_kill_slowtime_on_server "5.0"

// Whenever or not to make karma announce only happen upon death.
l4d2_karma_only_confirmed "0"

-Command-
None