Force change to next mission when current mission(final stage) end.

-ChangeLog-
v2.3
-Remake Code
-Translation Support
-Support L4D2 coop/versus/realism mode
-Support normal stage and final stage

v1.4
-Original Post: https://forums.alliedmods.net/showthread.php?t=81982

-Require-
1. Left 4 DHooks Direct: https://forums.alliedmods.net/showthread.php?t=321696

-ConVar-
cfg\sourcemod\sm_l4d_mapchanger.cfg
// After final rescue vehicle leaving, delay before force of changelevel in coop/realism. (0=off)
sm_l4d_fmc_ChDelayCOOP_final "10.0"

// Enables next mission to advertise to players.
sm_l4d_fmc_announce "1"

// Delay before versus mission change (float in sec).
sm_l4d_fmc_chdelayvs "1.0"

// Quantity of rounds (tries) events survivors wipe out before force of changelevel on final maps in coop/realism (0=off)
sm_l4d_fmc_crec_coop_final "2"

// Quantity of rounds (tries) events survivors wipe out before force of changelevel on non-final maps in coop/realism (0=off)
sm_l4d_fmc_crec_coop_map "2"

// Mission for change by default.
sm_l4d_fmc_def "c2m1_highway"
