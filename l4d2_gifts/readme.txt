Drop gifts (touch gift to earn reward) when a special infected or a witch/tank killed by survivor.

-53 items that S.I. drops-
in scripting/l4d2_gifts.sp line 93~161
[code]
	{"grenade_launcher","榴彈發射器"},
	{"rifle_m60", "M60機關槍"},
	{"defibrillator","電擊器"},
	{"first_aid_kit","治療包"},
	{"pain_pills", "止痛藥丸"},
	{"adrenaline", "腎上腺素"},
	{"health_100", "生命值+100"},
	{"weapon_upgradepack_incendiary", "火焰包"},
	{"weapon_upgradepack_explosive","高爆彈"},
	{"molotov", "火瓶"},
	{"pipe_bomb", "土製炸彈"},
	{"vomitjar", "膽汁"},
	{"gascan","汽油"},
	{"propanetank", "瓦斯桶"},
	{"oxygentank", "氧氣罐"},
	{"fireworkcrate","煙火盒"},
	{"pistol","手槍"},
	{"pistol_magnum", "沙漠之鷹"},
	{"pumpshotgun", "木製霰彈槍"},
	{"shotgun_chrome", "鐵製霰彈槍"},
	{"smg", "機槍"},
	{"smg_silenced", "消音機槍"},
	{"smg_mp5","MP5衝鋒槍"},
	{"rifle", "步槍"},
	{"rifle_sg552", "SG552步槍"},
	{"rifle_ak47", "AK47"},
	{"rifle_desert","三連發步槍"},
	{"shotgun_spas","戰鬥霰彈槍"},
	{"autoshotgun", "連發霰彈槍"},
	{"hunting_rifle", "獵槍"},
	{"sniper_military", "軍用狙擊槍"},
	{"sniper_scout", "SCOUT狙擊槍"},
	{"sniper_awp", "AWP"},
	{"baseball_bat", "球棒"},
	{"chainsaw", "奪魂鋸"},
	{"cricket_bat", "板球拍"},
	{"crowbar", "鐵撬"},
	{"electric_guitar", "電吉他"},
	{"fireaxe", "斧頭"},
	{"frying_pan", "平底鍋"},
	{"katana", "武士刀"},
	{"machete", "開山刀"},
	{"tonfa", "警棍"},
	{"knife", "小刀"},
	{"golfclub", "高爾夫球棒"},
	{"pitchfork", "草叉"},
	{"shovel", "鐵鏟"},
	{"gnome", "小侏儒"},
	{"", "空(謝謝惠顧)"},
	{"laser_sight",	"雷射裝置"},
	{"incendiary_ammo",	"火焰子彈"},
	{"explosive_ammo",	"高爆子彈"},
	{"ammo","彈藥補給"}

-9 items that Tank/Witch drops-
	{"rifle_m60", "殲滅者 M60"},
	{"first_aid_kit","治療包"},
	{"defibrillator","電擊器"},
	{"pain_pills", "止痛藥丸"},
	{"adrenaline", "腎上腺素"},
	{"health_100", "生命值+100"},
	{"vomitjar", "膽汁"},
	{"grenade_launcher","榴彈發射器"},
	{"ammo","補給彈藥"}
[/code]

-Require-
1. Left 4 DHooks Direct: https://forums.alliedmods.net/showthread.php?p=2684862
2. To unlock all melee weapons in all campaigns, you MUST use the [Mission and Weapons - Info Editor]("https://forums.alliedmods.net/showthread.php?t=310586") plugin which supersedes the extension.

-ChangeLog-
v2.8
-Remake Code
-Remove rotation, and some static models
-Add L4D2 "The Last Stand" two melee: pitchfork、shovel
-Add All weapons、melee、items
-Add laser、firework crate、ammo、incendiary ammo、explosive_ammo
-Use left4dhooks instead
-Remove points
-Add glow flashing

v1.3.6.1
-original Post: https://forums.alliedmods.net/showthread.php?t=302731

-Convars-
cfg\sourcemod\l4d2_gifts.cfg
// Notify Server who pickes up gift, and what the gift reward is.
l4d2_gifts_announce "1"

// Chance (%) of infected drop special gift.
l4d2_gifts_chance "50"

// Chance (%) of tank and witch drop second special gift.
l4d2_gifts_chance2 "100"

// Enable gifts 0: Disable, 1: Enable
l4d2_gifts_enabled "1"

// How long the gift stay on ground (seconds)
l4d2_gifts_giflife "30"

// Maximum of gifts that all survivors can pick up per map [0 = Disabled]
l4d2_gifts_maxcollectMap "0"

// Maximum of gifts that all survivors can pick up per round [0 = Disabled]
l4d2_gifts_maxcollectRound "0"


-Command-
"sm_giftcollect", "View number of gifts collected"
"sm_giftc", "View number of gifts collected"
(Adm Only) "sm_gift", "Spawn a gift in your position"
(Adm Only) "sm_reloadgifts", " Reload the config file of gifts (data/l4d2_gifts.cfg)"
	
