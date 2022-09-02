Improves the AI behaviour of special infected

-Changelog-
v1.3
-Remake code
-Replace left4downtown with left4dhooks
-Compatibility support for SourceMod 1.11. Fixed various warnings.

-ConVar-
cfg/sourcemod/AI_HardSI.cfg
// If the charger has a target, it will not straight pounce if the target's aim on the horizontal axis is within this radius
ai_aim_offset_sensitivity_charger "20"

// If the hunter has a target, it will not straight pounce if the target's aim on the horizontal axis is within this radius
ai_aim_offset_sensitivity_hunter "30"

// Frequency(sec) at which the 'nb_assault' command is fired to make SI attack
ai_assault_reminder_interval "2"

// How close a charger will approach before charging
ai_charge_proximity "300"

// At what distance to start pouncing fast
ai_fast_pounce_proximity "1000"

// Charger will charge if its health drops to this level
ai_health_threshold_charger "300"

// How close a jockey will approach before it starts hopping
ai_hop_activation_proximity "500"

// Mean angle produced by Gaussian RNG
ai_pounce_angle_mean "10"

// One standard deviation from mean as produced by Gaussian RNG
ai_pounce_angle_std "20"

// Vertical angle to which AI hunter pounces will be restricted
ai_pounce_vertical_angle "7"

// Distance to nearest survivor at which hunter will consider pouncing straight
ai_straight_pounce_proximity "200"

// Flag to enable bhop facsimile on AI tanks
ai_tank_bhop "1"

// Flag to enable rocks on AI tanks
ai_tank_rock "1"

// How far in front of himself infected bot will check for a wall. Use '-1' to disable feature
ai_wall_detection_distance "-1"

-Command-
None