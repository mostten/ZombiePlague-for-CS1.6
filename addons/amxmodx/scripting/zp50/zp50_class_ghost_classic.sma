/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Ghost: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <cs_ham_bots_api>
#include <zp50_class_ghost>
#include <zp50_colorchat>
#include <zp50_zombie_sounds>

#define MAXPLAYERS 32
#define SOUND_MAX_LENGTH 64

// Classic Ghost Attributes
new const ghostclass1_name[] = "Classic Ghost"
new const ghostclass1_info[] = "=Evil Within="
new const ghostclass1_models[][] = { "zp_ghost" }
new const ghostclass1_clawmodels[][] = { "models/zombie_plague/zp_ghost/v_knife_ghost.mdl" }
const ghostclass1_health = 200
const Float:ghostclass1_speed = 0.75
const Float:ghostclass1_gravity = 1.0
const Float:ghostclass1_knockback = 1.0
const bool:ghostclass1_infection = true;
const Float:intervalPrimaryAttack = 0.5
const Float:intervalSecondaryAttack = 0.8
const Float:damagePrimaryAttack = 15.0
const Float:damageSecondaryAttack = 25.0

new g_GhostClassID
new g_Visible[MAXPLAYERS+1]
new Float:g_VisibleNextDownTime[MAXPLAYERS+1]
new bool:g_FlashlightTurrnon[MAXPLAYERS+1]
new g_Stuck[MAXPLAYERS+1]

// Ghost sounds
new const sound_ghost_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_ghost_die[][] = { "zombie_plague/ghost/zbs_death_female_1.wav" }
new const sound_ghost_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_ghost_miss_slash[][] = { "zombie_plague/ghost/claw/zombie_ghost_midslash01.wav" , "zombie_plague/ghost/claw/zombie_ghost_midslash02.wav" }
new const sound_ghost_miss_wall[][] = { "zombie_plague/ghost/claw/zombie_ghost_draw.wav" }
new const sound_ghost_hit_normal[][] = { "zombie_plague/ghost/claw/zombie_hit1.wav" , "zombie_plague/ghost/claw/zombie_hit2.wav" , "zombie_plague/ghost/claw/zombie_hit3.wav" , "zombie_plague/ghost/claw/zombie_hit4.wav" }
new const sound_ghost_hit_stab[][] = { "zombie_plague/ghost/claw/zombie_ghost_stab.wav" , "zombie_plague/ghost/claw/zombie_ghost_stabmiss.wav" }
new const sound_ghost_idle[][] = { "zombie_plague/ghost/ambience/zombie_ghost_idle01.wav" , "zombie_plague/ghost/ambience/zombie_ghost_idle02.wav" }
new const sound_ghost_idle_last[][] = { "zombie_plague/ghost/ambience/zombie_ghost_idle03.wav" }


new const Float:size[][3] = {
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
}

public plugin_init()
{
	// 注册翻译文件
	register_dictionary("zombie_plague_mod_ghost_classic.txt")
	
	// hook切换武器Q按键
	register_clcmd("lastinv", "hook_inv")
	
	register_message(get_user_msgid("Flashlight"), "MSG_Flashlight")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink_Pre")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	
	set_task(0.1,"checkstuck",0,"",0,"b")
}

public plugin_precache()
{
	register_plugin("[ZP] Class: Ghost: Classic", ZP_VERSION_STRING, "Mostten")
	
	new index
	
	g_GhostClassID = zp_class_ghost_register(ghostclass1_name, ghostclass1_info, ghostclass1_health, ghostclass1_speed, ghostclass1_gravity, ghostclass1_infection, intervalPrimaryAttack, intervalSecondaryAttack, damagePrimaryAttack, damageSecondaryAttack)
	zp_class_ghost_register_kb(g_GhostClassID, ghostclass1_knockback)
	for (index = 0; index < sizeof ghostclass1_models; index++)
		zp_class_ghost_register_model(g_GhostClassID, ghostclass1_models[index])
	for (index = 0; index < sizeof ghostclass1_clawmodels; index++)
		zp_class_ghost_register_claw(g_GhostClassID, ghostclass1_clawmodels[index])
	
	sounds_precache();
}

sounds_precache()
{
	// Ghost sounds
	new index;
	for (index = 0; index < sizeof sound_ghost_pain; index++)
		zp_ghost_register_sound(g_GhostClassID, sound_ghost_pain[index]);
	for (index = 0; index < sizeof sound_ghost_die; index++)
		zp_ghost_register_sound(g_GhostClassID, _, sound_ghost_die[index]);
	for (index = 0; index < sizeof sound_ghost_fall; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, sound_ghost_fall[index]);
	for (index = 0; index < sizeof sound_ghost_miss_slash; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, _, sound_ghost_miss_slash[index]);
	for (index = 0; index < sizeof sound_ghost_miss_wall; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, _, _, sound_ghost_miss_wall[index]);
	for (index = 0; index < sizeof sound_ghost_hit_normal; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, _, _, _, sound_ghost_hit_normal[index]);
	for (index = 0; index < sizeof sound_ghost_hit_stab; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, _, _, _, _, sound_ghost_hit_stab[index]);
	for (index = 0; index < sizeof sound_ghost_idle; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, _, _, _, _, _, sound_ghost_idle[index]);
	for (index = 0; index < sizeof sound_ghost_idle_last; index++)
		zp_ghost_register_sound(g_GhostClassID, _, _, _, _, _, _, _, _, sound_ghost_idle_last[index]);
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(client)
{
	g_FlashlightTurrnon[client] = (is_user_connected(client) && is_user_bot(client));
}

//判断是不是开启了手电筒
public MSG_Flashlight(msg_id, msg_dest, client)
{
	if(is_user_alive(client))
	{
		if(get_msg_arg_int(1))
		{
			g_FlashlightTurrnon[client] = true;
		}
		else
		{
			set_msg_arg_int(1, get_msg_argtype(1), 0);
			g_FlashlightTurrnon[client] = false;
		}
	}
	
	return PLUGIN_CONTINUE
}

//切换武器Q键激活此方法
public hook_inv(client)
{
	if(zp_class_ghost_get_current(client) != g_GhostClassID)
		return PLUGIN_CONTINUE
	if(is_user_alive(client) && zp_class_ghost_get(client))
	{
		if(get_user_noclip(client) == 0)
		{
			set_user_noclip(client, 1)
			zp_colored_print(client, "%L", client, "WALKMOD_FLY")
		}
		else
		{
			set_user_noclip(client, 0)
			zp_colored_print(client, "%L", client, "WALKMOD_NORMAL")
		}
		
		return HAM_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public fw_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet) 
{
	if(!is_user_alive(ent) || !is_user_alive(host) || zp_class_ghost_get(host))
		return FMRES_IGNORED;
	if(player && host != ent)
	{
		if(zp_class_ghost_get(ent) && zp_class_ghost_get_current(ent) == g_GhostClassID)
		{
			set_es(es, ES_RenderMode, kRenderTransAlpha)
			set_es(es, ES_RenderAmt, get_user_visible(ent));
		}
	}
	return FMRES_IGNORED
}

public fw_PlayerPreThink_Pre(client)
{
	if(!is_user_connected(client) || !is_user_alive(client))
		return;
	
	if(!zp_class_ghost_get(client) || zp_class_ghost_get_current(client) != g_GhostClassID)
	{
		user_visible_showmax(client);
		return;
	}
	
	if(AnyoneFlashBatShootTarget(client))
	{
		user_visible_showmax(client);
	}
	else
	{
		user_visible_down_bytime(client, 60, 0.07);
	}
}

bool:get_user_flashlight(client)
{
	return g_FlashlightTurrnon[client];
}

set_user_visible(client, level)
{
	g_Visible[client] = level;
}

get_user_visible(client)
{
	return g_Visible[client];
}

user_visible_showmax(client)
{
	set_user_visible(client, 255);
}

user_visible_down(client, down = 60)
{
	new level = get_user_visible(client);
	if(level >= down)
	{
		level -= down;
	}
	else
	{
		level = 0;
	}
	set_user_visible(client, level);
}

user_visible_down_bytime(client, down = 60, Float:interval = 0.07)
{
	new Float:current = get_gametime();
	if(current >= g_VisibleNextDownTime[client])
	{
		user_visible_down(client, down);
		g_VisibleNextDownTime[client] = current + interval;
	}
}

bool:AnyoneFlashBatShootTarget(target)
{
	for(new client = 1; client < get_maxplayers(); client++)
	{
		if(is_user_connected(client) && is_user_alive(client) && get_user_flashlight(client) && !zp_class_ghost_get(client) && !zp_core_is_zombie(client) && IsFlashBatShootTarget(client, target))
			return true;
	}
	return false;
}

bool:IsFlashBatShootTarget(client, target){
	static iAim[3], Float:fAim[3], Float:fOrigin[3], Float:fVec[3]
	static Float:fLimitsDist, Float:fLimitsTheta
	get_user_origin(client, iAim, 3)
	IVecFVec(iAim, fAim)
	static Float:vecViewOfs[3]
	pev(client, pev_origin, fOrigin)
	pev(client, pev_view_ofs, vecViewOfs)
	xs_vec_add(fOrigin, vecViewOfs, fOrigin)
	for(new i;i<3;++i) fVec[i] = fAim[i] - fOrigin[i]

	if(target == client) return false
	static Float:fGhost[3], Float:VecP2G[3], Float:fDistanceP2G, Float:fDistanceVec
	pev(target, pev_origin, fGhost)
	for(new i;i<3;++i) VecP2G[i] = fGhost[i] - fOrigin[i]
	fDistanceP2G = vector_length(VecP2G); fDistanceVec = vector_length(fVec)
	static Float:fDot, Float:theta, Float:fDistanceG2F
	fDot = xs_vec_dot(fVec, VecP2G)
	theta = acos(fDot/(fDistanceVec*fDistanceP2G))
	fDistanceG2F = fDistanceP2G * asin(theta)

	static Float:fFootpoint[3], Float:fDistP2F, Float:fRate, Float:fZoffset
	fDistP2F = floatsqroot(fDistanceP2G*fDistanceP2G+fDistanceG2F*fDistanceG2F)
	fRate = fDistP2F/fDistanceVec
	for(new i;i<3;++i) fFootpoint[i] = fOrigin[i] + fVec[i] * fRate
	fZoffset = floatabs(fFootpoint[2]-fGhost[2])

	if(fDistanceP2G<60.0){
		if(fZoffset>15.0){
			fLimitsDist = 46.0; fLimitsTheta = 0.9
		}else{
			fLimitsDist = 36.0; fLimitsTheta = 0.6
		}
	}
	else if(fDistanceP2G<100.0){
		fLimitsDist = 41.0; fLimitsTheta = 0.4
	}
	else if(fDistanceP2G<200.0){
		if(fZoffset>36.0){
			fLimitsDist = 49.0; fLimitsTheta = 0.18
		}else{
			fLimitsDist = 43.0; fLimitsTheta = 0.24
		}
	}
	else if(fDistanceP2G<300.0){
		if(fZoffset>22.0){
			fLimitsDist = 49.0; fLimitsTheta = 0.18
		}else{
			fLimitsDist = 30.2; fLimitsTheta = 0.11
		}
	}
	else if(fDistanceP2G<500.0){
		if(fZoffset>20.0){
			fLimitsDist = 46.0; fLimitsTheta = 0.11
		}else{
			fLimitsDist = 30.0; fLimitsTheta = 0.07
		}
	}
	else{
		fLimitsDist = 46.6; fLimitsTheta = 0.14
	}
	return (0.0<fDistanceG2F<=fLimitsDist && theta<fLimitsTheta)
}

bool:is_hull_vacant(const Float:origin[3], hull,id) {
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
		return true
	
	return false
}

public checkstuck() 
{
	static players[MAXPLAYERS], pnum, player
	get_players(players, pnum)
	static Float:origin[3]
	static Float:mins[3], hull
	static Float:vec[3]
	static o,i
	for(i=0; i<pnum; i++){
		player = players[i]
		if (is_user_connected(player) && is_user_alive(player))
		{
			pev(player, pev_origin, origin)
			hull = pev(player, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
			if (!is_hull_vacant(origin, hull,player) && !(pev(player,pev_solid) & SOLID_NOT) && !get_user_noclip(player) && zp_class_ghost_get(player))
			{
				++g_Stuck[player]
				if(g_Stuck[player] >= 1)
				{
					pev(player, pev_mins, mins)
					vec[2] = origin[2]
					for (o=0; o < sizeof size; ++o) {
						vec[0] = origin[0] - mins[0] * size[o][0]
						vec[1] = origin[1] - mins[1] * size[o][1]
						vec[2] = origin[2] - mins[2] * size[o][2]
						if (is_hull_vacant(vec, hull,player))
						{
							engfunc(EngFunc_SetOrigin, player, vec)
							o = sizeof size
						}
					}
				}
			}
			else
			{
				g_Stuck[player] = 0
			}
		}
	}
}

Float:acos(Float:value)
{
	return floatacos(value, radian);
}

Float:asin(Float:value)
{
	return floatasin(value, radian);
}