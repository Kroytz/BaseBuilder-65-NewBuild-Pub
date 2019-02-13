#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>
#include <eg_boss>

#define WEAPONKEY	721

#define	DAMAGE_A	32.0	// 左键伤害
#define	DAMAGE_B	26.0	// 右键伤害
#define RE1		0.65	// 左键模式的后坐力
#define RE2		0.02	// 右键模式的后坐力

new const Fire_Sounds[][] = { "weapons/spsmg-1.wav", "weapons/spsmg-2.wav" }

#define V_MODEL "models/FAITH/v_spsmg.mdl"
#define P_MODEL "models/FAITH/p_spsmg.mdl"
#define W_MODEL "models/FAITH/w_spsmg.mdl"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new g_orig_event, g_IsInPrimaryAttack, g_fwBotForwardRegister, m_iShell
new Float:cl_pushangle[33][3]
new bool:g_Has_Spsmg[33], g_Clip[33] 

public plugin_init()
{
	register_plugin("爆炎蒸汽", "0.1", "TmNine")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")

	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1)

	RegisterHam(Ham_Item_AddToPlayer, "weapon_mac10", "HAM_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_mac10", "HAM_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "HAM_Weapon_PrimaryAttack_Pre")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "HAM_Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_mac10", "HAM_Item_PostFrame")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "HAM_TraceAttack")
	RegisterHam(Ham_TraceAttack, "func_breakable", "HAM_TraceAttack")
	RegisterHam(Ham_TraceAttack, "func_wall", "HAM_TraceAttack")
	RegisterHam(Ham_TraceAttack, "func_door", "HAM_TraceAttack")
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "HAM_TraceAttack")
	RegisterHam(Ham_TraceAttack, "func_plat", "HAM_TraceAttack")
	RegisterHam(Ham_TraceAttack, "func_rotating", "HAM_TraceAttack")
	//RegisterHam(Ham_Spawn, "player", "HAM_Spawn_Post", 1)

	register_clcmd(DEF_SPSMG_CODE, "Get_Weapon")
	register_clcmd("GiveAll_NewComen", "Get_Weapon_All")
}

public fw_BotForwardRegister_Post(iPlayer)
{
	if(!is_user_bot(iPlayer))
	return
	
	unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1)
	RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "HAM_TraceAttack")
}

public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_generic("sprites/weapon_spsmg.txt")
	precache_generic("sprites/FAITH/640hud124.spr")
	precache_generic("sprites/FAITH/640hud7.spr")
	m_iShell = engfunc(EngFunc_PrecacheModel, "models/pshell.mdl")
	for(new i = 0; i < sizeof Fire_Sounds; i++)
	precache_sound(Fire_Sounds[i])
	register_clcmd("weapon_spsmg", "weapon_hook")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_mac10")
    	return PLUGIN_HANDLED
}

public HAM_TraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(Attacker))
	return HAM_IGNORED

	new iEntity = get_pdata_cbase(Attacker, 373), Float:flDamage
	new iWeapon = fm_get_ent_from_user(Attacker, CSW_MAC10)
	if(iEntity <= 0)
	return HAM_IGNORED

	if (!g_Has_Spsmg[Attacker] || get_pdata_int(iEntity, 43, 4) != CSW_MAC10)
	return HAM_IGNORED
		
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)		
		
	if(!is_user_alive(Ent))
		Func_FakeHole(Attacker, flEnd, Ent)

	switch (pev(iWeapon, pev_iuser2))
	{
		case 1: flDamage = DAMAGE_B
		default: flDamage = DAMAGE_A
	}

	SetHamParamFloat(3, flDamage)
	return HAM_IGNORED	
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/mac10.sc", name))
	{
		g_orig_event = get_orig_retval()
	}
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
	return FMRES_IGNORED;
	
	static szClassName[33]
	pev(entity, pev_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
	return FMRES_IGNORED
	
	static iOwner
	
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_mac10.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = fm_find_ent_by_owner(-1, "weapon_mac10", entity)
	
		if(!pev_valid(iStoredAugID))
		return FMRES_IGNORED
	
		if(g_Has_Spsmg[iOwner])
		{
			set_pev(iStoredAugID, pev_impulse, WEAPONKEY)
			g_Has_Spsmg[iOwner] = false
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public Get_Weapon(id)
{
	drop_weapons(id, 1)
	new iEntity = fm_give_item(id, "weapon_mac10")
	if(iEntity > 0)
	{
		set_pdata_int(id, 382, 300)
		ExecuteHamB(Ham_Item_Deploy, iEntity)
		message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id)
		write_string("weapon_spsmg")
		write_byte(6)
		write_byte(100)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(13)
		write_byte(CSW_MAC10)
		write_byte(0)
		message_end() 
	}
	g_Has_Spsmg[id] = true
}

public Get_Weapon_All()
{
	for(new i=1;i<33;i++)
	{
		if(!zp_get_user_zombie(i) && is_user_alive(i)) Get_Weapon(i)
	}
}

public HAM_Item_AddToPlayer_Post(iEntity, id)
{
	if(pev_valid(iEntity) != 2)
	return
	
	if(pev(iEntity, pev_impulse) == WEAPONKEY)
	{
		g_Has_Spsmg[id] = true
		set_pev(iEntity, pev_impulse, 0)
	}

	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id)
	write_string(g_Has_Spsmg[id] == true? "weapon_spsmg" : "weapon_mac10")
	write_byte(6)
	write_byte(100)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(13)
	write_byte(CSW_MAC10)
	write_byte(0)
	message_end()
}

public HAM_Item_Deploy_Post(iEntity)
{
	new id = get_pdata_cbase(iEntity, 41, 4)

	if (!g_Has_Spsmg[id])
	return

	UTIL_PlayWeaponAnimation(id, 2)
	set_pdata_float(id, 83, 0.83, 5)
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, P_MODEL)
}

public CurrentWeapon(id)
{
	new iEntity = get_pdata_cbase(id, 373)
	if (iEntity <= 0)
	return
	
	if (g_Has_Spsmg[id] && get_pdata_int(iEntity, 43, 4) == CSW_MAC10)
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
	}
}

public fw_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer))
	return

	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return

	if (!g_Has_Spsmg[iPlayer] || get_pdata_int(iEntity, 43, 4) != CSW_MAC10)
	return
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
}

public HAM_Weapon_PrimaryAttack_Pre(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	if (!g_Has_Spsmg[iPlayer])
	return HAM_IGNORED
	
	g_IsInPrimaryAttack = 1
	pev(iPlayer, pev_punchangle, cl_pushangle[iPlayer])
	
	g_Clip[iPlayer] = get_pdata_int(iEntity, 51, 4)
	return HAM_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event) || !g_IsInPrimaryAttack)
	return FMRES_IGNORED

	if (!(1 <= invoker <= get_maxplayers()))
	return FMRES_IGNORED

	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public HAM_Weapon_PrimaryAttack_Post(iEntity)
{
	g_IsInPrimaryAttack = 0
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)

	if(g_Has_Spsmg[iPlayer])
	{
		if (!g_Clip[iPlayer])
		return

		new Float:push[3]
		pev(iPlayer, pev_punchangle, push)
		xs_vec_sub(push, cl_pushangle[iPlayer], push)
		xs_vec_mul_scalar(push, pev(iEntity, pev_iuser2) == 1? RE2:RE1, push)
		xs_vec_add(push, cl_pushangle[iPlayer], push)
		set_pev(iPlayer, pev_punchangle, push)
		emit_sound(iPlayer, CHAN_WEAPON, Fire_Sounds[pev(iEntity, pev_iuser2) == 1? 1:0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(iPlayer, pev(iEntity, pev_iuser2) == 1? 4:3)
		Eject_Shell(iPlayer, m_iShell, 0.0)
	}
}

public HAM_Item_PostFrame(iEntity) 
{
	new id = get_pdata_cbase(iEntity, 41, 4)

	if (!g_Has_Spsmg[id])
	return HAM_IGNORED

	new iClip = get_pdata_int(iEntity, 51, 4)
	if(is_user_in_zammo(id)) iClip = 2
	new userbut = pev(id, pev_button)

	if(userbut & IN_ATTACK2 && get_pdata_float(iEntity, 47) <= 0.0 && get_pdata_float(id, 83, 5) <= 0.0)
	{
		set_pev(iEntity, pev_iuser2, 1)

		userbut &= ~IN_ATTACK
		userbut &= ~IN_ATTACK2
		set_pev(id, pev_button, userbut)

		for(new i = 0; i < iClip; i++)
		{
			ExecuteHamB(Ham_Weapon_PrimaryAttack, iEntity)
		}
		set_pev(iEntity, pev_iuser2, 0)
	}
	return HAM_IGNORED
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
	return PLUGIN_CONTINUE

	new iEntity = get_pdata_cbase(iAttacker, 373)
	if(iEntity <= 0)
	return HAM_IGNORED

	if ((strcmp(szTruncatedWeapon, "mac10") && strcmp(szTruncatedWeapon, "knife")) || get_pdata_int(iEntity, 43, 4) != CSW_MAC10)
	return PLUGIN_CONTINUE

	if (!g_Has_Spsmg[iAttacker])
	return PLUGIN_CONTINUE

	set_msg_arg_string(4, "spsmg")

	return PLUGIN_CONTINUE
}

public Func_FakeHole(id, const Float:flEnd[3], iWall)
{
	if(iWall)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num(0, charsmax(GUNSHOT_DECALS))])
		write_short(iWall)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num(0, charsmax(GUNSHOT_DECALS))])
		message_end()
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	write_short(id)
	write_byte(GUNSHOT_DECALS[random_num(0, charsmax(GUNSHOT_DECALS))])
	message_end()
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock drop_weapons(iPlayer, Slot)
{
	new item = get_pdata_cbase(iPlayer, 367+Slot, 4)
	while(item > 0)
	{
		static classname[24]
		pev(item, pev_classname, classname, charsmax(classname))
		engclient_cmd(iPlayer, "drop", classname)
		item = get_pdata_cbase(item, 42, 5)
	}
	set_pdata_cbase(iPlayer, 367, -1, 4)
}

stock fm_give_item(iPlayer, const wEntity[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, wEntity))
	new Float:origin[3]
	pev(iPlayer, pev_origin, origin)
	set_pev(iEntity, pev_origin, origin)
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, iEntity)
	new save = pev(iEntity, pev_solid)
	dllfunc(DLLFunc_Touch, iEntity, iPlayer)
	if(pev(iEntity, pev_solid) != save)
	return iEntity
	engfunc(EngFunc_RemoveEntity, iEntity)
	return -1
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
{
	new strtype[11] = "classname", ent = index
	switch (jghgtype) {
		case 1: strtype = "target"
		case 2: strtype = "targetname"
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent
}

stock fm_get_ent_from_user(index, IsEnt=0)
{
	new iEntity = get_pdata_cbase(index, 373)
	
	if(IsEnt) return iEntity
	
	return get_pdata_int(iEntity, 43, 4)
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time)
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime()+Time)
}

stock client_printc(const id, const string[], {Float, Sql, Resul,_}:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg, sizeof msg - 1, string, 3);
	
	replace_all(msg,190,"\g","^4");
	replace_all(msg,190,"\y","^1");
	replace_all(msg,190,"\t","^3");
	
	if(id)
		players[0] = id;
	else
		get_players(players,count,"ch");
	
	new index;
	for (new i = 0 ; i < count ; i++)
	{
		index = players[i];
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"),_, index);
		write_byte(index);
		write_string(msg);
		message_end();  
	}  
}
