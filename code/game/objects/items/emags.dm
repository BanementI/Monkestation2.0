/* Emags
 * Contains:
 * EMAGS AND DOORMAGS
 */


/*
 * EMAG AND SUBTYPES
 */
/obj/item/card/emag
	desc = "It's a card with a magnetic strip attached to some circuitry."
	name = "cryptographic sequencer"
	icon_state = "emag"
	inhand_icon_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON
	slot_flags = ITEM_SLOT_ID
	worn_icon_state = "emag"
	var/prox_check = TRUE //If the emag requires you to be in range
	var/type_blacklist //List of types that require a specialized emag

/obj/item/card/emag/attack_self(mob/user) //for traitors with balls of plastitanium
	if(Adjacent(user))
		user.visible_message(span_notice("[user] shows you: [icon2html(src, viewers(user))] [name]."), span_notice("You show [src]."))
	add_fingerprint(user)

/obj/item/card/emag/bluespace
	name = "bluespace cryptographic sequencer"
	desc = "It's a blue card with a magnetic strip attached to some circuitry. It appears to have some sort of transmitter attached to it."
	color = rgb(40, 130, 255)
	prox_check = FALSE

/obj/item/card/emag/halloween
	name = "hack-o'-lantern"
	desc = "It's a pumpkin with a cryptographic sequencer sticking out."
	icon_state = "hack_o_lantern"

/obj/item/card/emagfake
	desc = "It's a card with a magnetic strip attached to some circuitry. Closer inspection shows that this card is a poorly made replica, with a \"Donk Co.\" logo stamped on the back."
	name = "cryptographic sequencer"
	icon_state = "emag"
	inhand_icon_state = "card-id"
	slot_flags = ITEM_SLOT_ID
	worn_icon_state = "emag"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'

/obj/item/card/emagfake/attack_self(mob/user) //for assistants with balls of plasteel
	if(Adjacent(user))
		user.visible_message(span_notice("[user] shows you: [icon2html(src, viewers(user))] [name]."), span_notice("You show [src]."))
	add_fingerprint(user)

/obj/item/card/emagfake/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if (!proximity_flag)
		return
	. |= AFTERATTACK_PROCESSED_ITEM
	playsound(src, 'sound/items/bikehorn.ogg', 50, TRUE)

/obj/item/card/emag/Initialize(mapload)
	. = ..()
	type_blacklist = list(typesof(/obj/machinery/door/airlock) + typesof(/obj/machinery/door/window/) +  typesof(/obj/machinery/door/firedoor) - typesof(/obj/machinery/door/window/tram/)) //list of all typepaths that require a specialized emag to hack.

/obj/item/card/emag/attack()
	return

/obj/item/card/emag/afterattack(atom/target, mob/user, proximity)
	. = ..()
	var/atom/A = target
	if(!proximity && prox_check)
		return
	. |= AFTERATTACK_PROCESSED_ITEM
	if(!can_emag(target, user))
		return
	// monkestation start: microwavable emags
	if(istype(target, /obj/machinery/microwave))
		return
	if (microwaved)
		if (microwaved_uses_left <= 0)
			to_chat(user, span_warning("the components [src] starts glowing a bright orange, before the capacitors erupt in a violent explosion!"))
			to_chat(user, span_notice("How this small thing could have had this large of an explosion is byond you."))
			A.emp_act(EMP_HEAVY)
			explosion(src, heavy_impact_range = 0, light_impact_range = 3)
			log_combat(user, A, "attempted to emag with microwaved emag, emag exploded")
			if(!QDELETED(src)) //to check if the explosion killed it before we try to delete it
				qdel(src)
			return .
		else
			A.emp_act(EMP_LIGHT)
		if (microwaved_uses_left == 1)
			desc += " The capacitors are leaking."
			to_chat(user, span_warning("the components on [src] start glowing a burning orange!"))
			to_chat(user, span_warning("[src] feels way too hot to hold in your hand, and you fumble it on to the floor."))
			user.dropItemToGround(src)
			icon_state = "[icon_state]_glow"
			src.visible_message(span_notice("[user] fumbles [src] and drops it on the ground, a glow fading from hot orange to dim red."))
		else
			flick("[icon_state]_spark", src)
			to_chat(user, span_warning(pick(list("[src] sparks in your hand!", "The components on [src] start glowing!",))))
		microwaved_uses_left--
		log_combat(user, A, "attempted to emag with microwaved emag")
	else
	// monkestation end
		log_combat(user, A, "attempted to emag")
		A.emag_act(user, src)

/obj/item/card/emag/proc/can_emag(atom/target, mob/user)
	for (var/subtypelist in type_blacklist)
		if (target.type in subtypelist)
			to_chat(user, span_warning("The [target] cannot be affected by the [src]! A more specialized hacking device is required."))
			return FALSE
	return TRUE

/*
 * DOORMAG
 */
/obj/item/card/emag/doorjack
	desc = "Commonly known as a \"doorjack\", this device is a specialized cryptographic sequencer specifically designed to override station airlock access codes. Uses self-refilling charges to hack airlocks."
	name = "airlock authentication override card"
	icon_state = "doorjack"
	worn_icon_state = "doorjack"
	var/type_whitelist //List of types
	var/charges = 3
	var/max_charges = 3
	var/list/charge_timers = list()
	var/charge_time = 1800 //three minutes

/obj/item/card/emag/doorjack/Initialize(mapload)
	. = ..()
	type_whitelist = list(typesof(/obj/machinery/door/airlock), typesof(/obj/machinery/door/window/), typesof(/obj/machinery/door/firedoor)) //list of all acceptable typepaths that this device can affect

/obj/item/card/emag/doorjack/proc/use_charge(mob/user)
	charges --
	to_chat(user, span_notice("You use [src]. It now has [charges] charge[charges == 1 ? "" : "s"] remaining."))
	charge_timers.Add(addtimer(CALLBACK(src, PROC_REF(recharge)), charge_time, TIMER_STOPPABLE))

/obj/item/card/emag/doorjack/proc/recharge(mob/user)
	charges = min(charges+1, max_charges)
	playsound(src,'sound/machines/twobeep.ogg',10,TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
	charge_timers.Remove(charge_timers[1])

/obj/item/card/emag/doorjack/examine(mob/user)
	. = ..()
	. += span_notice("It has [charges] charges remaining.")
	if (length(charge_timers))
		. += "[span_notice("<b>A small display on the back reads:")]</b>"
	for (var/i in 1 to length(charge_timers))
		var/timeleft = timeleft(charge_timers[i])
		var/loadingbar = num2loadingbar(timeleft/charge_time)
		. += span_notice("<b>CHARGE #[i]: [loadingbar] ([DisplayTimeText(timeleft)])</b>")

/obj/item/card/emag/doorjack/can_emag(atom/target, mob/user)
	if (charges <= 0)
		to_chat(user, span_warning("[src] is recharging!"))
		return FALSE
	for (var/list/subtypelist in type_whitelist)
		if (target.type in subtypelist)
			return TRUE
	to_chat(user, span_warning("[src] is unable to interface with this. It only seems to fit into airlock electronics."))
	return FALSE

/*
 * Battlecruiser Access
 */
/obj/item/card/emag/battlecruiser
	name = "battlecruiser coordinates upload card"
	desc = "An ominous card that contains the location of the station, and when applied to a communications console, \
	the ability to long-distance contact the Syndicate fleet."
	icon_state = "battlecruisercaller"
	worn_icon_state = "emag"
	///whether we have called the battlecruiser
	var/used = FALSE
	/// The battlecruiser team that the battlecruiser will get added to
	var/datum/team/battlecruiser/team

/obj/item/card/emag/battlecruiser/proc/use_charge(mob/user)
	used = TRUE
	to_chat(user, span_boldwarning("You use [src], and it interfaces with the communication console. No going back..."))

/obj/item/card/emag/battlecruiser/examine(mob/user)
	. = ..()
	. += span_notice("It can only be used on the communications console.")

/obj/item/card/emag/battlecruiser/can_emag(atom/target, mob/user)
	if(used)
		to_chat(user, span_warning("[src] is used up."))
		return FALSE
	if(!istype(target, /obj/machinery/computer/communications))
		to_chat(user, span_warning("[src] is unable to interface with this. It only seems to interface with the communication console."))
		return FALSE
	return TRUE
