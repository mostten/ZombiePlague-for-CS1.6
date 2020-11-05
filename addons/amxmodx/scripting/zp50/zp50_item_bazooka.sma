#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <fun>
#include <cstrike>
#include <zp50_core>
#include <zp50_class_nemesis>

#define PLUGIN "[ZP] Bazooka"
#define VERSION "1.6"
#define AUTHOR "Mostten"

// Time between can witch to next mode(Thanks to Nihilanth)
#define SWITCH_TIME 0.5
#define TASK_SEEK_CATCH 100
#define ID_TASK_SEEK_CATCH (taskid - TASK_SEEK_CATCH)
#define TASK_RELOAD 200
#define ID_TASK_RELOAD (taskid - TASK_RELOAD)
#define WEAPONKEY 500001

#define WEAP_LINUX_XTRA_OFF 4
#define m_fKnown 44
#define m_flNextPrimaryAttack 46
#define m_flTimeWeaponIdle 48
#define m_iClip 51
#define m_fInReload 54
#define PLAYER_LINUX_XTRA_OFF 5
#define m_flNextAttack 83
#define ENG_NULLENT -1
#define USE_STOPPED 0
#define OFFSET_WEAPONOWNER 41
#define OFFSET_LINUX_WEAPONS 4 // weapon offsets are only 4 steps higher on Linux
#define PDATA_SAFE 2
#define OFFSET_ACTIVE_ITEM 373

new static const PRIMARY_WEAPONS_BIT_SUM =(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);

new static const mrocket[] = "models/rpgrocket.mdl";
new static const mrpg_w[] = "models/w_rpg.mdl";
new static const mrpg_v[] = "models/v_rpg.mdl";
new static const mrpg_p[] = "models/p_rpg.mdl";

new static const sfire[] = "weapons/rocketfire1.wav";
new static const sfly[] = "zombie_plague/predator/weapons/nuke_fly.wav";
new static const shit[] = "weapons/mortarhit.wav";
new static const spickup[] = "items/gunpickup2.wav";
new static const sselect[] = "common/wpn_select.wav";

new static const bazooka_wid = CSW_AWP;
new static const bazooka_wclass[] = "weapon_awp";
new static const bazooka_wtruncated[] = "awp";
new static const bazooka_wmodel[] = "models/w_awp.mdl"
new static const rocket_class[] = "rpgrocket";
new static const bazooka_truncated[] = "bazooka";
new static info_target;

// Cvars
new pcvar_delay, pcvar_maxdmg, pcvar_radius, pcvar_speed;
new pcvar_speed_homing, pcvar_speed_camera;
new pcvar_clip, pcvar_ammo, pcvar_drop;
new pcvar_switch_mode;

// Sprites
new rocketsmoke, white, explosion, bazsmoke;

// Messages
new gmsgScreenshake, gmsgBarTime

enum FireMode{
    FireMode_Normal,
    FireMode_Follow,
    FireMode_Camera
};

enum UserInfo{
    UserInfo_ID = 0,
    UserInfo_Rocket,
    UserInfo_Clip,
    FireMode:UserInfo_FireMode,
    bool:UserInfo_HasBazooka,
    Float:UserInfo_LastShoot,
    Float:UserInfo_SwitchTime
};

new g_MaxPlayers;
new g_orig_event_bazooka;
new Array:g_UserInfos = Invalid_Array;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    // Cvars
    pcvar_delay = register_cvar("zp_bazooka_delay", "10");
    pcvar_maxdmg = register_cvar("zp_bazooka_damage", "100");
    pcvar_radius = register_cvar("zp_bazooka_radius", "250");
    pcvar_speed = register_cvar("zp_bazooka_speed", "800");
    pcvar_speed_homing = register_cvar("zp_bazooka_homing_speed", "350");
    pcvar_speed_camera = register_cvar("zp_bazooka_camera_speed", "300");
    pcvar_clip = register_cvar("zp_bazooka_clip", "1");
    pcvar_ammo = register_cvar("zp_bazooka_ammo", "100");
    pcvar_drop = register_cvar("zp_bazooka_drop", "0");
    pcvar_switch_mode = register_cvar("zp_bazooka_mode", "0");
    
    register_event("CurWeapon","CurrentWeapon","be","1=1");
    
    RegisterHam(Ham_Item_AddToPlayer, bazooka_wclass, "fw_bazooka_AddToPlayer");
    RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1);
    RegisterHam(Ham_Item_Deploy, bazooka_wclass, "fw_Item_Deploy_Post", 1);
    RegisterHam(Ham_Weapon_PrimaryAttack, bazooka_wclass, "fw_bazooka_PrimaryAttack");
    RegisterHam(Ham_Weapon_SecondaryAttack, bazooka_wclass, "fw_bazooka_SecondaryAttack");
    RegisterHam(Ham_Item_PostFrame, bazooka_wclass, "fw_bazooka_ItemPostFrame");
    RegisterHam(Ham_Weapon_Reload, bazooka_wclass, "fw_bazooka_Reload");
    RegisterHam(Ham_Weapon_Reload, bazooka_wclass, "fw_bazooka_Reload_Post", 1);
    
    register_forward(FM_SetModel, "fw_SetModel");
    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
    register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
    
    gmsgScreenshake = get_user_msgid("ScreenShake");
    gmsgBarTime = get_user_msgid("BarTime");
    register_message(get_user_msgid("DeathMsg"), "message_death");
    
    g_MaxPlayers = get_maxplayers();
    info_target = engfunc(EngFunc_AllocString, "info_target");
}

public plugin_precache()
{
    precache_model(mrocket);        
 
    precache_model(mrpg_w);
    precache_model(mrpg_v);
    precache_model(mrpg_p);
 
    precache_sound(sfire);
    precache_sound(sfly);
    precache_sound(shit);
    precache_sound(spickup);
    precache_sound(sselect);
    
    rocketsmoke = precache_model("sprites/smoke.spr");
    white = precache_model("sprites/white.spr");
    explosion = precache_model("sprites/fexplo.spr");
    bazsmoke  = precache_model("sprites/steam1.spr");
    
    register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1);
}

public zp_fw_nemesis_init_post(id, classid)
{
    GiveBazooka(id);
}

public zp_fw_core_cure(id, attacker)
{
    RemoveBazooka(id);
}

public fw_PrecacheEvent_Post(type, const name[])
{
    if(equal("events/awp.sc", name))
    {
        g_orig_event_bazooka = get_orig_retval();
        return FMRES_HANDLED;
    }
    return FMRES_IGNORED;
}

public CurrentWeapon(id)
{
    ReplaceWeaponModels(id, read_data(2));
}

public fw_bazooka_AddToPlayer(bazooka, id)
{
    if(!pev_valid(bazooka) || !is_user_connected(id))
        return HAM_IGNORED;
    if(entity_get_int(bazooka, EV_INT_impulse) == WEAPONKEY)
    {
        SetUserInfo(id, UserInfo_HasBazooka, true);
        entity_set_int(bazooka, EV_INT_impulse, 0);
        return HAM_HANDLED;
    }
    return HAM_IGNORED;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
    if(use_type == USE_STOPPED && is_user_connected(caller))
        ReplaceWeaponModels(caller, get_user_weapon(caller));
}

public fw_Item_Deploy_Post(weapon)
{
    ReplaceWeaponModels(GetWeaponOwner(weapon), cs_get_weapon_id(weapon));
}

public fw_bazooka_PrimaryAttack(weapon)
{
    new owner = GetWeaponOwner(weapon);
    
    if(!IsUserHasBazooka(owner)){return HAM_IGNORED;}
    
    if(!IsUserCanShoot(owner)){return HAM_SUPERCEDE;}
    
    PlayWeaponAnimation(owner, 3);
    
    if(RocketFire(owner))
    {
        new iClip = get_pdata_int(weapon, m_iClip, WEAP_LINUX_XTRA_OFF) - 1;
        set_pdata_int(weapon, m_iClip, (iClip > 0)?iClip:0, WEAP_LINUX_XTRA_OFF);
    }
    return HAM_SUPERCEDE;
}

public fw_bazooka_SecondaryAttack(weapon)
{
    new owner = GetWeaponOwner(weapon);
    
    if(!IsUserHasBazooka(owner)){return HAM_IGNORED;}
    
    new Float:switchtime;
    if(!GetUserInfo(owner, UserInfo_SwitchTime, switchtime)){return HAM_SUPERCEDE;}
    
    if((get_gametime() - switchtime) < SWITCH_TIME){return HAM_SUPERCEDE;}
    
    SwitchUserFireMode(owner);
    
    return HAM_SUPERCEDE;
}

public fw_bazooka_ItemPostFrame(weapon)
{
    new owner = pev(weapon, pev_owner);
    if(!is_user_connected(owner)){return HAM_IGNORED;}
    
    if(!IsUserHasBazooka(owner)){return HAM_IGNORED;}
    
    new Float:flNextAttack = get_pdata_float(owner, m_flNextAttack, PLAYER_LINUX_XTRA_OFF);
    new iBpAmmo = cs_get_user_bpammo(owner, bazooka_wid);
    new iClip = get_pdata_int(weapon, m_iClip, WEAP_LINUX_XTRA_OFF);
    new fInReload = get_pdata_int(weapon, m_fInReload, WEAP_LINUX_XTRA_OFF);
    
    if(fInReload && flNextAttack <= 0.0)
    {
        new j = min(get_pcvar_num(pcvar_clip) - iClip, iBpAmmo);
        set_pdata_int(weapon, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF);
        cs_set_user_bpammo(owner, bazooka_wid, iBpAmmo-j);
        
        fInReload = 0;
        set_pdata_int(weapon, m_fInReload, fInReload, WEAP_LINUX_XTRA_OFF);
    }
    return HAM_IGNORED;
}

public fw_bazooka_Reload(weapon)
{
    new owner = pev(weapon, pev_owner);
    if(!is_user_connected(owner)){return HAM_IGNORED;}
    
    if(!IsUserHasBazooka(owner)){return HAM_IGNORED;}
    
    SetUserInfo(owner, UserInfo_Clip, -1);
    new iBpAmmo = cs_get_user_bpammo(owner, bazooka_wid);
    new iClip = get_pdata_int(weapon, m_iClip, WEAP_LINUX_XTRA_OFF)
    
    if(iBpAmmo <= 0){return HAM_SUPERCEDE;}
    if(iClip >= get_pcvar_num(pcvar_clip)){return HAM_SUPERCEDE;}
    
    SetUserInfo(owner, UserInfo_Clip, iClip);
    return HAM_IGNORED;
}

public fw_bazooka_Reload_Post(weapon) {
    new owner = pev(weapon, pev_owner)
    if(!is_user_connected(owner)){return HAM_IGNORED;}
    
    if(!IsUserHasBazooka(owner)){return HAM_IGNORED;}
    
    new clip = -1;
    if(GetUserInfo(owner, UserInfo_Clip, clip)
    || clip == -1){return HAM_IGNORED;}
    
    new Float:reloadtime = get_pcvar_float(pcvar_delay);
    set_pdata_int(weapon, m_iClip, clip, WEAP_LINUX_XTRA_OFF);
    set_pdata_float(weapon, m_flTimeWeaponIdle, reloadtime, WEAP_LINUX_XTRA_OFF);
    set_pdata_float(owner, m_flNextAttack, reloadtime, PLAYER_LINUX_XTRA_OFF);
    set_pdata_int(weapon, m_fInReload, 1, WEAP_LINUX_XTRA_OFF);
    
    PlayWeaponAnimation(owner, 2);
    
    return HAM_IGNORED;
}

// Ham Rocket Touch Forward
public fw_RocketTouch(rocket, toucher)
{
    if(!pev_valid(rocket)){return HAM_IGNORED;}
    
    new iEndOrigin[3], Float:fEndOrigin[3];
    pev(rocket, pev_origin, fEndOrigin);
    iEndOrigin[0] = floatround(fEndOrigin[0]);
    iEndOrigin[1] = floatround(fEndOrigin[1]);
    iEndOrigin[2] = floatround(fEndOrigin[2]);
    
    emit_sound(rocket, CHAN_WEAPON, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    emit_sound(rocket, CHAN_VOICE, shit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    
    CreateExplosion(iEndOrigin);
    CreateSmoke(iEndOrigin);
    CreateExpandsCylinder(iEndOrigin);
    
    new maxdamage = get_pcvar_num(pcvar_maxdmg);
    new damageradius = get_pcvar_num(pcvar_radius);
    
    new owner = pev(rocket, pev_owner);
    if(!IsValidUser(owner))
    {
        RemoveRocket(rocket);
        return HAM_IGNORED;
    }
    
    new targetpos[3], distance, damage;
    for(new target = 1; target <= g_MaxPlayers; target++)
    {
        if(!is_user_connected(target)
        || !is_user_alive(target)
        || zp_core_is_zombie(target)){continue;}
        
        get_user_origin(target, targetpos);
        
        distance = get_distance(targetpos, iEndOrigin);
        if(distance <= damageradius)
        {
            MakerScreenShake(target);
            damage = maxdamage - floatround(floatmul(float(maxdamage), floatdiv(float(distance), float(damageradius))));
            TakeDamage(target, rocket, owner, damage*1.0, DMG_BLAST);
        }
    }
    RemoveRocket(rocket);
    
    return HAM_HANDLED;
}

// Ham Rocket Think Forward
public fw_RocketThink(rocket)
{
    if(!pev_valid(rocket))
    {
        RemoveRocket(rocket);
        return HAM_IGNORED;
    }
    
    new owner = pev(rocket, pev_owner);
    if(!IsValidUser(owner))
    {
        RemoveRocket(rocket);
        return HAM_IGNORED;
    }
    
    new Float:velocity[3], Float:angles[3];
    VelocityByAim(owner, GetBazookaConfigSpeed(owner), velocity);
    
    entity_get_vector(owner, EV_VEC_v_angle, angles);
    entity_set_vector(rocket, EV_VEC_velocity, velocity);
    entity_set_vector(rocket, EV_VEC_angles, angles);
    entity_set_float(rocket, EV_FL_nextthink, get_gametime() + 0.1);
    
    return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
    if(!pev_valid(entity)){return FMRES_IGNORED;}
    
    new classname[32];
    entity_get_string(entity, EV_SZ_classname, classname, charsmax(classname))
    if(!equal(classname, "weaponbox")){return FMRES_IGNORED;}
    
    new owner = pev(entity, pev_owner);
    if(equal(model, bazooka_wmodel))
    {
        new iStoredSVDID = find_ent_by_owner(ENG_NULLENT, bazooka_wclass, entity);
        if(!pev_valid(iStoredSVDID)){return FMRES_IGNORED;}
        
        if(IsUserHasBazooka(owner))
        {
            entity_set_int(iStoredSVDID, EV_INT_impulse, WEAPONKEY);
            SetUserInfo(owner, UserInfo_HasBazooka, false);
            
            if(get_pcvar_num(pcvar_drop)){engfunc(EngFunc_SetModel, entity, mrpg_w);}
            else{remove_entity(entity);}
            
            return FMRES_SUPERCEDE;
        }
    }
    return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, SendWeapons, CD_Handle)
{
  if(!is_user_alive(id)
  ||(get_user_weapon(id) != bazooka_wid)
  || !IsUserHasBazooka(id)){return FMRES_IGNORED;}
  
  set_cd(CD_Handle, CD_flNextAttack, halflife_time() + 0.001);
  
  return FMRES_HANDLED;
}

public message_death(msg_id, msg_dest, msg_entity)
{
    new weapon[32];
    new attacker = get_msg_arg_int(1);
    get_msg_arg_string(4, weapon, charsmax(weapon));
    
    if(IsUserHasBazooka(attacker)
    && equal(weapon, bazooka_wtruncated))
        set_msg_arg_string(4, bazooka_truncated);
    
    return PLUGIN_CONTINUE;
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
    if((eventid != g_orig_event_bazooka)){return FMRES_IGNORED;}
    if(!(1 <= invoker <= g_MaxPlayers)){return FMRES_IGNORED;}
    
    playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
    
    return FMRES_SUPERCEDE;
}

InitArrays()
{
    if(g_UserInfos == Invalid_Array)
        g_UserInfos = ArrayCreate(_:UserInfo, 1);
}

GetUserInfos(const id, info[_:UserInfo])
{
    if(g_UserInfos == Invalid_Array){return -1;}
    
    new count = ArraySize(g_UserInfos);
    if(count <= 0){return -1;}
    
    new temp[_:UserInfo];
    for(new i = 0; i < count; i++)
    {
        ArrayGetArray(g_UserInfos, i, temp);
        if(temp[_:UserInfo_ID] == id)
        {
            for(new t = 0; t < _:UserInfo; t++)
                info[t] = temp[t];
            return i;
        }
    }
    return -1;
}

bool:GetUserInfo(const id, const UserInfo:type, &any:output)
{
    new info[_:UserInfo];
    new index = GetUserInfos(id, info);
    
    if(index < 0){return false;}
    
    output = info[_:type];
    return true;
}

SetUserInfo(const id, const UserInfo:type, const any:value)
{
    InitArrays();
    
    new info[_:UserInfo];
    new index = GetUserInfos(id, info);
    
    if(index < 0)
    {
        info[_:UserInfo_ID] = id;
        info[_:type] = value;
        index = ArrayPushArray(g_UserInfos, info);
    }
    else
    {
        info[_:type] = value;
        ArraySetArray(g_UserInfos, index, info);
    }
    
    return index;
}

bool:IsUserHasBazooka(const id)
{
    new bool:has = false;
    return(GetUserInfo(id, UserInfo_HasBazooka, has) && has);
}

bool:IsUserCanShoot(const id)
{
    new Float:lastshoot;
    return (GetUserInfo(id, UserInfo_LastShoot, lastshoot) && ((get_gametime() - lastshoot) >= get_pcvar_float(pcvar_delay)));
}

bool:IsValidUser(const id)
{
    return(0 < id <= g_MaxPlayers && is_user_connected(id));
}

RemoveRocket(const rocket)
{
    new removed = 0;
    if(g_UserInfos == Invalid_Array){return removed;}
    
    new count = ArraySize(g_UserInfos);
    if(count <= 0){return removed;}
    
    new info[_:UserInfo];
    for(new i = 0; i < count; i++)
    {
        ArrayGetArray(g_UserInfos, i, info);
        if(info[_:UserInfo_Rocket] == rocket)
        {
            if(pev_valid(rocket)){remove_entity(rocket);}
            if(IsValidUser(info[_:UserInfo_ID])){attach_view(info[_:UserInfo_ID], info[_:UserInfo_ID]);}
            
            info[_:UserInfo_Rocket] = -1;
            ArraySetArray(g_UserInfos, i, info);
            
            removed++;
        }
    }
    return removed;
}

FireMode:GetUserFireMode(const id)
{
    new FireMode:mode = FireMode_Normal;
    GetUserInfo(id, UserInfo_FireMode, mode);
    return mode;
}

FireMode:SwitchUserFireMode(const id)
{
    new FireMode:mode = FireMode_Normal;
    if(get_pcvar_num(pcvar_switch_mode))
    {
        mode = GetUserFireMode(id);
        switch(mode)
        {
            case FireMode_Follow:
            {
                mode = FireMode_Camera;
                client_print(id, print_center, "Camera fire mode");
            }
            case FireMode_Camera:
            {
                mode = FireMode_Normal;
                client_print(id, print_center, "Normal fire mode");
            }
            default:
            {
                mode = FireMode_Follow;
                client_print(id, print_center, "Homing fire mode");
            }
        }
    }
    emit_sound(id, CHAN_ITEM, sselect, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    SetUserInfo(id, UserInfo_FireMode, mode);
    SetUserInfo(id, UserInfo_SwitchTime, get_gametime());
    
    return mode;
}

GetWeaponOwner(const weapon)
{
    return get_pdata_cbase(weapon, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

ReplaceWeaponModels(const id, const weaponid)
{
    if(weaponid == bazooka_wid && IsUserHasBazooka(id))
    {
        set_pev(id, pev_viewmodel2, mrpg_v);
        set_pev(id, pev_weaponmodel2, mrpg_p);
    }
}

PlayWeaponAnimation(const id, const sequence)
{
    set_pev(id, pev_weaponanim, sequence);
    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
    write_byte(sequence);
    write_byte(pev(id, pev_body));
    message_end();
}

GiveBazooka(const id)
{
    DropUserWeapons(id, 1);
    new iWep2 = give_item(id, bazooka_wclass);
    if(iWep2 > 0)
    {
        cs_set_weapon_ammo(iWep2, get_pcvar_num(pcvar_clip));
        cs_set_user_bpammo(id, bazooka_wid, get_pcvar_num(pcvar_ammo));
    }
    
    SetUserInfo(id, UserInfo_HasBazooka, true);
    
    emit_sound(id, CHAN_WEAPON, spickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

RemoveBazooka(const id)
{
    if(IsUserHasBazooka(id)){StripUserWeapon(id, bazooka_wclass);}
    SetUserInfo(id, UserInfo_HasBazooka, false);
}

DropUserWeapons(const id, const dropwhat)
{
    static weapons[32], num, i, weaponid;
    num = 0;
    get_user_weapons(id, weapons, num);
    for(i = 0; i < num; i++)
    {
        weaponid = weapons[i];
        if(dropwhat == 1 &&((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
        {
            static wname[32];
            get_weaponname(weaponid, wname, sizeof wname - 1);
            engclient_cmd(id, "drop", wname);
        }
    }
}

StripUserWeapon(const id, const stripwhat[])
{
    // Get user weapons
    new weapons[32], num_weapons, index, weaponid;
    get_user_weapons(id, weapons, num_weapons);
    
    // Loop through them and drop primaries or secondaries
    for(index = 0; index < num_weapons; index++)
    {
        // Prevent re-indexing the array
        weaponid = weapons[index];
        
        if(weaponid)
        {
            // Get weapon name
            new wname[32];
            get_weaponname(weaponid, wname, charsmax(wname))
            
            if(equal(wname, stripwhat))
            {
                // Strip weapon and remove bpammo
                StripWeapon(id, wname);
                cs_set_user_bpammo(id, weaponid, 0);
            }
        }
    }
}

StripWeapon(const index, const weapon[])
{
    // Get weapon id
    new weaponid = get_weaponid(weapon);
    if(!weaponid)
        return false;
    
    // Get weapon entity
    new weapon_ent = FindEntByOwner(-1, weapon, index);
    if(!weapon_ent)
        return false;
    
    // If it's the current weapon, retire first
    new current_weapon_ent = GetUserCurrentWeapon(index);
    new current_weapon = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1;
    if(current_weapon == weaponid)
        ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent);
    
    // Remove weapon from player
    if(!ExecuteHamB(Ham_RemovePlayerItem, index, weapon_ent))
        return false;
    
    // Kill weapon entity and fix pev_weapons bitsum
    ExecuteHamB(Ham_Item_Kill, weapon_ent);
    set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid));
    return true;
}

// Find entity by its owner(from fakemeta_util)
FindEntByOwner(entity, const classname[], const owner)
{
    while((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)){ /* keep looping */ }
    return entity;
}

// Get User Current Weapon Entity
GetUserCurrentWeapon(const id)
{
    // Prevent server crash if entity's private data not initalized
    if(pev_valid(id) != PDATA_SAFE)
        return -1;
    
    return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}

CreateExplosion(const origin[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_SPRITE);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 128);
    write_short(explosion);
    write_byte(60);
    write_byte(255);
    message_end();
}

CreateSmoke(const origin[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_SMOKE);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 256);
    write_short(bazsmoke);
    write_byte(125);
    write_byte(5);
    message_end();
}

CreateExpandsCylinder(const origin[3])
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMCYLINDER);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 320);
    write_short(white);
    write_byte(0);
    write_byte(0);
    write_byte(16);
    write_byte(128);
    write_byte(0);
    write_byte(255);
    write_byte(255);
    write_byte(192);
    write_byte(128);
    write_byte(0);
    message_end();
}

CreateTailFire(const attachment)
{
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(attachment); //entity:attachment to follow
    write_short(rocketsmoke); //sprite index
    write_byte(50); //life in 0.1's
    write_byte(3); //line width in 0.1's
    write_byte(255); //red
    write_byte(255); //green
    write_byte(255); //blue
    write_byte(255); //brightness
    message_end();
}

MakerScreenShake(const id)
{
    message_begin(MSG_ONE, gmsgScreenshake, {0,0,0}, id);
    write_short(1<<14);
    write_short(1<<14);
    write_short(1<<14);
    message_end();
}

CreateRocketEnt(const owner, const Float:origin[3], const Float:angle[3], const Float:velocity[3])
{
    new ent = engfunc(EngFunc_CreateNamedEntity, info_target);
    
    if(!pev_valid(ent)){return -1;}
    
    set_pev(ent, pev_classname, rocket_class);
    engfunc(EngFunc_SetModel, ent, mrocket);
    set_pev(ent, pev_mins, {-1.0, -1.0, -1.0});
    set_pev(ent, pev_maxs, {1.0, 1.0, 1.0});
    engfunc(EngFunc_SetOrigin, ent, origin);
    set_pev(ent, pev_angles, angle);

    set_pev(ent, pev_solid, SOLID_BBOX);
    set_pev(ent, pev_movetype, MOVETYPE_FLY);
    set_pev(ent, pev_owner, owner);
    
    set_pev(ent, pev_velocity, velocity);
    entity_set_int(ent, EV_INT_effects, entity_get_int(ent, EV_INT_effects) | EF_BRIGHTLIGHT);
    
    emit_sound(ent, CHAN_WEAPON, sfire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    emit_sound(ent, CHAN_VOICE, sfly, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    
    CreateTailFire(ent);
    
    return ent;
}

TakeDamage(const victim, const inflictor, const attacker, const Float:damage, const damagetype)
{
    new Float:health;
    new m_bitsDamageType = 76;
    pev(victim, pev_health, health);

    health -= damage;

    if(health <= 0.0)
    {
        ExecuteHamB(Ham_Killed, victim, attacker, 0);
        return;
    }

    set_pev(victim, pev_health, health);
    set_pev(victim, pev_dmg_take, damage);
    set_pdata_int(victim, m_bitsDamageType, damagetype);
    set_pev(victim, pev_dmg_inflictor, inflictor);
}

LaunchPush(const id, const velamount)
{
    static Float:flNewVelocity[3], Float:flCurrentVelocity[3];
    
    velocity_by_aim(id, -velamount, flNewVelocity);
    
    get_user_velocity(id, flCurrentVelocity);
    xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity);
    
    set_user_velocity(id, flNewVelocity);
}

ProgressStatus(const id, const duration)
{
    message_begin(MSG_ONE, gmsgBarTime, _, id);
    write_short(duration);
    message_end();
}

public TaskBazookaReload(taskid)
{
    if(!IsValidUser(ID_TASK_RELOAD) || !is_user_alive(ID_TASK_RELOAD) || !IsUserHasBazooka(ID_TASK_RELOAD)){return;}
    
    if(get_user_weapon(ID_TASK_RELOAD) == bazooka_wid)
    {
        ReplaceWeaponModels(ID_TASK_RELOAD, bazooka_wid);
        
        client_print(ID_TASK_RELOAD, print_center, "Bazooka reloaded!");
        emit_sound(ID_TASK_RELOAD, CHAN_WEAPON, spickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
}

public TaskBazookaFollow(taskid) 
{
    if(!pev_valid(ID_TASK_SEEK_CATCH))
    {
        remove_task(taskid);
        return;
    }
    
    static classname[32];
    pev(ID_TASK_SEEK_CATCH, pev_classname, classname, charsmax(classname)); 
    if(!equal(classname, rocket_class))
    {
        remove_task(taskid);
        return;
    }
    
    new target = -1;
    new Float:shortest_distance = 500.0;
    new Float:porigin[3], Float:rorigin[3], Float:distance;
    new owner = pev(ID_TASK_SEEK_CATCH, pev_owner);
    pev(ID_TASK_SEEK_CATCH, pev_origin, rorigin);
    for(new id = 1; id <= g_MaxPlayers; id++)
    {
        if(id == owner
        || !is_user_connected(id)
        || !is_user_alive(id)){continue;}
        
        pev(id, pev_origin, porigin);
        
        distance = get_distance_f(porigin, rorigin);
        
        if(distance <= shortest_distance)
        {
            shortest_distance = distance;
            target = id;
        }
    }
    if(IsValidUser(target))
        entity_set_follow(ID_TASK_SEEK_CATCH, target, 250.0);
}

bool:entity_set_follow(const entity, const target, const Float:speed) 
{
    if(!pev_valid(entity) || !pev_valid(target)){return false;}

    new Float:entity_origin[3], Float:target_origin[3];
    pev(entity, pev_origin, entity_origin);
    pev(target, pev_origin, target_origin);

    new Float:diff[3];
    diff[0] = target_origin[0] - entity_origin[0];
    diff[1] = target_origin[1] - entity_origin[1];
    diff[2] = target_origin[2] - entity_origin[2];
 
    new Float:length = floatsqroot(floatpower(diff[0], 2.0) + floatpower(diff[1], 2.0) + floatpower(diff[2], 2.0));
    
    new Float:velocity[3];
    velocity[0] = diff[0] *(speed / length);
    velocity[1] = diff[1] *(speed / length);
    velocity[2] = diff[2] *(speed / length);
 
    set_pev(entity, pev_velocity, velocity);

    return true;
}

bool:RocketFire(const id)
{
    if(!is_user_alive(id)){return false;}
    
    new rocket = -1;
    if(GetUserInfo(id, UserInfo_Rocket, rocket) && pev_valid(rocket))
    {
        RemoveRocket(rocket);
        rocket = -1;
    }
    
    engclient_cmd(id, bazooka_wclass);
 
    new Float:origin[3], Float:angle[3], Float:velocity[3];
    pev(id, pev_origin, origin);
    pev(id, pev_angles, angle);
    
    velocity_by_aim(id, GetBazookaConfigSpeed(id), velocity);
    rocket = CreateRocketEnt(id, origin, angle, velocity);
    
    if(!pev_valid(rocket)){return false;}
    SetUserInfo(id, UserInfo_Rocket, rocket);
    
    entity_set_float(rocket, EV_FL_nextthink, get_gametime() + 0.1);
    RegisterHamFromEntity(Ham_Touch, rocket, "fw_RocketTouch");
    RegisterHamFromEntity(Ham_Think, rocket, "fw_RocketThink");
    
    SetUserInfo(id, UserInfo_LastShoot, get_gametime());
    if(!task_exists(id + TASK_RELOAD))
        set_task(get_pcvar_float(pcvar_delay), "TaskBazookaReload", id + TASK_RELOAD);
    
    switch(GetUserFireMode(id))
    {
        case FireMode_Follow:
        {
            if(task_exists(rocket + TASK_SEEK_CATCH)){remove_task(rocket + TASK_SEEK_CATCH);}
            set_task(0.5, "TaskBazookaFollow", rocket + TASK_SEEK_CATCH, _, _, "b");
        }
        case FireMode_Camera:
        {
            entity_set_int(rocket, EV_INT_rendermode, 1);
            attach_view(id, rocket);
        }
    }
    
    
    LaunchPush(id, 130);
    ProgressStatus(id, get_pcvar_num(pcvar_delay));
    
    return true;
}

GetBazookaConfigSpeed(const id)
{
    new speed = 500;
    switch(GetUserFireMode(id))
    {
        case FireMode_Normal:{speed = get_pcvar_num(pcvar_speed);}
        case FireMode_Follow:{speed = get_pcvar_num(pcvar_speed_homing);}
        case FireMode_Camera:{speed = get_pcvar_num(pcvar_speed_camera);}
    }
    return speed;
}
