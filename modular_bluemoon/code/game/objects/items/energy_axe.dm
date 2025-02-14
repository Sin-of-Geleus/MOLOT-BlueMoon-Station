// Energy fire axes, for DS-2

/obj/item/fireaxe/energy
	icon_state = "energy_axe0"
	icon = 'modular_bluemoon/icons/obj/items_and_weapons.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/energyaxe_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/energyaxe_righthand.dmi'
	name = "energy fire axe"
	desc = "You aren't quite sure if this counts as a fire axe anymore, but it sure is fancy! A tag hangs off of it reading: 'properly of the Gorlex Marauders'"
	armour_penetration = 35

/obj/item/fireaxe/energy/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=10, force_wielded=30, icon_wielded="energy_axe1", wieldsound='sound/weapons/saberon.ogg', unwieldsound='sound/weapons/saberoff.ogg')

/obj/item/fireaxe/update_icon_state()
	icon_state = "energy_axe0"

/obj/item/fireaxe/energy/on_wield(obj/item/source, mob/living/carbon/user)
	wielded = TRUE
	hitsound = 'sound/weapons/blade1.ogg'
	START_PROCESSING(SSobj, src)
	set_light(3, l_color = COLOR_SOFT_RED)

/obj/item/fireaxe/energy/on_unwield(obj/item/source, mob/living/carbon/user)
	wielded = FALSE
	hitsound = 'sound/weapons/bladeslice.ogg'
	STOP_PROCESSING(SSobj, src)
	set_light(0)
