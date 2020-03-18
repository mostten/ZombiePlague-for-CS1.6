适用于CS1.6版本的僵尸瘟疫插件(僵尸感染&恶灵模式):

安装方法: 详细安装方法同https://forums.alliedmods.net/showthread.php?t=72505, 如果服务器已经安装ZP5.0.8插件, 则不需要重新配置ZP自带配置文件(相同名称配置文件可跳过), 因为本次升级重新编写了多个原始ZP插件, 所以插件同名需要覆盖安装. 

版本: v5.0.8 with update 1

日志:
1.新增恶灵附身模式
2.新增开局倒计时
3.修复ZP自带zp50_ambience_sounds.amxx插件读取错误问题
4.新增恶灵模式手电筒特效

新增服务器指令:
1.ghost_mod_flashlight: 是否激活手电筒特效(1打开,0关闭)
2.ghost_mod_flashlight_show_all: 是否在所有模式中激活手电筒特效(1打开,0关闭)
3.ghost_mod_countdown: 是否激活幽灵模式开局倒计时(1打开,0关闭)
4.other_mod_countdown: 是否激活其他模式开局倒计时(1打开,0关闭)

新增配置文件:
1.addons/amxmodx/configs/zombieplague_mod_ghost.ini(幽灵模式配置文件)
2.addons/amxmodx/configs/zp_ghostclasses.ini(经典幽灵属性配置文件)
3.amxmodx/data/lang/zombie_plague_mod_ghost.txt(幽灵模式翻译文件)
4.amxmodx/data/lang/zombie_plague_mod_ghost_classic.txt(经典幽灵类型翻译文件)
