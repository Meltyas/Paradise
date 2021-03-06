/proc/attempt_initiate_surgery(obj/item/I, mob/living/M, mob/user, var/override )
	if(istype(M))
		var/mob/living/carbon/human/H
		var/obj/item/organ/external/affecting
		var/selected_zone = user.zone_sel.selecting

		if(istype(M, /mob/living/carbon/human))
			H = M
			affecting = H.get_organ(check_zone(selected_zone))

		if(can_operate(M) || isslime(M))	//if they're prone or a slime
			var/datum/surgery/current_surgery
			for(var/datum/surgery/S in M.surgeries)
				if(S.location == selected_zone)
					current_surgery = S

			if(!current_surgery)
				var/list/all_surgeries = surgeries_list.Copy()
				var/list/available_surgeries = list()

				for(var/datum/surgery/S in all_surgeries)
					if(!S.possible_locs.Find(selected_zone))
						continue
					if(affecting && S.requires_organic_bodypart && affecting.is_robotic())
						continue
					if(!S.can_start(user, M))
						continue

					for(var/path in S.allowed_mob)
						if(istype(M, path))
							// If there are multiple surgeries with the same name,
							// prepare to cry
							available_surgeries[S.name] = S
							break

				if(override)
					var/datum/surgery/S
					if(istype(I,/obj/item/robot_parts))
						S = available_surgeries["Apply Robotic Prosthetic"]
					if(istype(I,/obj/item/organ/external))
						var/obj/item/organ/external/E = I
						if(E.is_robotic())
							S = available_surgeries["Synthetic Limb Reattachment"]
					if(S)
						var/datum/surgery/procedure = new S.type
						if(procedure)
							procedure.location = selected_zone
							M.surgeries += procedure
							procedure.organ_ref = affecting
							procedure.next_step(user, M)

				else
					var/P = input("Begin which procedure?", "Surgery", null, null) as null|anything in available_surgeries
					if(P && user && user.Adjacent(M) && (I in user))
						var/datum/surgery/S = available_surgeries[P]
						var/datum/surgery/procedure = new S.type
						if(procedure)
							procedure.location = selected_zone
							M.surgeries += procedure
							procedure.organ_ref = affecting
							user.visible_message("[user] prepares to operate on [M]'s [parse_zone(selected_zone)].", \
							"<span class='notice'>You prepare to operate on [M]'s [parse_zone(selected_zone)].</span>")

			else if(!current_surgery.step_in_progress)
				if(current_surgery.status == 1 )
					M.surgeries -= current_surgery
					to_chat(user, "You stop the surgery.")
					qdel(current_surgery)
				else if(istype(user.get_inactive_hand(), /obj/item/cautery) && current_surgery.can_cancel)
					M.surgeries -= current_surgery
					user.visible_message("[user] mends the incision on [M]'s [parse_zone(selected_zone)] with the [I] .", \
						"<span class='notice'>You mend the incision on [M]'s [parse_zone(selected_zone)].</span>")
					if(affecting)
						affecting.open = 0
						affecting.germ_level = 0
					qdel(current_surgery)
				else if(current_surgery.can_cancel)
					to_chat(user, "<span class='warning'>You need to hold a cautery in inactive hand to stop [M]'s surgery!</span>")


			return 1
	return 0

/proc/get_pain_modifier(mob/living/carbon/human/M) //returns modfier to make surgery harder if patient is conscious and feels pain
	if(M.stat) //stat=0 if CONSCIOUS, 1=UNCONSCIOUS and 2=DEAD. Operating on dead people is easy, too. Just sleeping won't work, though.
		return 1
	if(NO_PAIN in M.dna.species.species_traits)//if you don't feel pain, you can hold still
		return 1
	if(M.reagents.has_reagent("hydrocodone"))//really good pain killer
		return 0.99
	if(M.reagents.has_reagent("morphine"))//Just as effective as Hydrocodone, but has an addiction chance
		return 0.99
	if(M.drunk >= 80)//really damn drunk
		return 0.95
	if(M.drunk >= 40)//pretty drunk
		return 0.9
	if(M.reagents.has_reagent("sal_acid")) //it's better than nothing, as far as painkillers go.
		return 0.85
	if(M.drunk >= 15)//a little drunk
		return 0.85
	return 0.8 //20% failure chance

/proc/get_location_modifier(mob/M)
	var/turf/T = get_turf(M)
	if(locate(/obj/machinery/optable, T))
		return 1
	else if(locate(/obj/structure/table, T))
		return 0.8
	else if(locate(/obj/structure/stool/bed, T))
		return 0.7
	else
		return 0.5

// Called when a limb containing this object is placed back on a body
/atom/movable/proc/attempt_become_organ(obj/item/organ/external/parent,mob/living/carbon/human/H)
	return 0
