适用于CS1.6版本的僵尸瘟疫插件ZombiePlague(僵尸感染&恶灵模式):

安装方法:

1.下载安装metamod和amxmodx(链接https://www.amxmodx.org/downloads.php), 版本为1.82或更高, 详细方法详见https://wiki.alliedmods.net/Installing_AMX_Mod_X_Manually

2.下载本插件全部内容并覆盖至你的游戏文件夹cstrike下;

3.将amxmodx/configs/plugins-zp50_ammopacks.ini文件重命名为plugins.ini(请自行备份原plugins.ini文件)

注: 如果服务器已经安装ZP5.0.8插件, 则不需要重新覆盖ZP自带配置文件(除plugins-zp50_ammopacks.ini与disabled-zp50_money.ini外, 相同名称配置文件可跳过, 只是配置文件可跳过!!!), 因为本次升级重新编写了多个原始ZP插件, 所以插件同名需要覆盖安装!!!.

版本: v5.0.8 with update 1

日志:

1.新增恶灵附身模式

2.新增开局倒计时

3.修复ZP自带zp50_ambience_sounds.amxx插件读取错误问题

4.新增恶灵模式手电筒特效

5.新增注册僵尸、复仇、幸存、恶灵等种类音效接口(例如爆头、脚步、爪子、idle等...)

6.新增开局音效与倒计时音效和文字(可自行设置每个模式的倒计时音效与文字)

7.禁用引擎自带击退功能, 只使用ZP的击退功能

新增服务器指令:

1.ghost_mod_flashlight: 是否激活手电筒特效(1打开,0关闭)

2.ghost_mod_flashlight_show_all: 是否在所有模式中激活手电筒特效(1打开,0关闭)

3.zp_ghost_chance: 调整恶灵模式出现的几率(1或者更大的整数值，值越大几率越低)

4.zp_ghost_min_players: 幽灵模式最少玩家数量

5.zp_ghost_show_hud: 幽灵模式是否展示HUD信息

6.zp_ghost_allow_respawn: 幽灵模式是否允许重生

7.zp_ghost_respawn_after_last_human: 最后一个人类离开时重生玩家

8.zp_ghost_first_hp_multiplier: 第一个母体恶灵的生命值倍数

9.zp_ghost_sounds: 恶灵局是否播放背景音效(1打开,0关闭)

10.zp_no_engine_knockback_zombie: 僵尸禁用引擎自带击退功能,只使用ZP击退功能

11.zp_no_engine_knockback_nemesis: 复仇之神禁用引擎自带击退功能,只使用ZP击退功能

12.zp_no_engine_knockback_ghost: 恶灵禁用引擎自带击退功能,只使用ZP击退功能

新增配置文件:

1.addons/amxmodx/configs/zombieplague_mod_ghost.ini(幽灵模式配置文件)

2.addons/amxmodx/configs/zp_ghostclasses.ini(经典幽灵属性配置文件)

3.amxmodx/data/lang/zombie_plague_mod_ghost.txt(幽灵模式翻译文件)

4.amxmodx/data/lang/zombie_plague_mod_ghost_classic.txt(经典幽灵类型翻译文件)
