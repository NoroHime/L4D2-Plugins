Voice Announce in centr text + create hat to Show Who is speaking.

-Require-
1. SM 1.10 or above
2. Meta 1.11 or above
3. Left 4 DHooks Direct: https://forums.alliedmods.net/showthread.php?p=2684862
4. ThirdPersonShoulder_Detect: https://forums.alliedmods.net/showthread.php?p=2529779
5. VoiceHook:
  * windows: https://github.com/fbef0102/L4D2-Server4Dead/blob/main/Windows%20Server%20Files/left4dead2/addons/sourcemod/extensions/voicehook.ext.dll
  * linux: https://github.com/fbef0102/L4D2-Server4Dead/blob/main/Linux%20Server%20Files/left4dead2/addons/sourcemod/extensions/voicehook.ext.so

-ChangeLog-
v1.7
-Remake code
-Detect Thirdpserson
-MIC Model hat on player's head (Only survivors can see)

v1.1
Original Post: https://forums.alliedmods.net/showpost.php?p=2671963&postcount=7

-Convar-
cfg\sourcemod\show_mic.cfg
// If 1, display hat on player's head if player is speaking
show_mic_center_hat_enable "1"

// If 1, display player speaking message in center text
show_mic_center_text_enable "0"

-Command-
None
