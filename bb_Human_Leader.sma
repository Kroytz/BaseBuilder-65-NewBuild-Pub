#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fun>
#include <zombieplague>
#include <eG>

//new bool:bIsLeader[33]

public plugin_init()
{
	register_plugin("[BB] Extra: Human Leader", "1.0", "EmeraldGhost")
	
	register_srvcmd("bb_random_leader", "random_leader")
	register_clcmd("so9sadbbld", "become_leader")
}

public plugin_precache()
{
	precache_model("models/player/gyr_leon/gyr_leon.mdl")
}

public random_leader()
{
	new wjsl = get_playersnum(0)
	if(wjsl < 2) return PLUGIN_HANDLED

	new id = random_num(1, 32)
	if(!zp_get_user_zombie(id) && is_user_alive(id)) become_leader(id)
	else random_leader()
}

public become_leader(id)
{
	new sid[33]
	get_user_name(id,sid,32)
	
	client_printc(0, "\y[\gLeader\y] \t%s \y被选为本回合 \gLeader\y, 请带领人类走向胜利吧!", sid)
	
	// Model Set
	zp_override_user_model(id, "gyr_leon")
	
	// Give Weapons
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	give_item(id, "weapon_m249")
	cs_set_user_bpammo(id, CSW_M249, 999)
	give_item(id, "weapon_elite")
	cs_set_user_bpammo(id, CSW_ELITE, 999)
	
	// Grenades
	give_item(id, "weapon_hegrenade")
	cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
	give_item(id, "weapon_flashbang")
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
	
	// Kelvar & Health
	set_user_health(id, 150)
	give_item(id, "item_assaultsuit");
	cs_set_user_armor(id, 150, CS_ARMOR_VESTHELM);
}