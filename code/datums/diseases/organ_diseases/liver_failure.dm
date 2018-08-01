/datum/ailment/disease/liver_failure
	name = "Liver Failure"
	scantype = "Medical Emergency"
	max_stages = 3
	spread = "The patient's liver is starting to fail"
	cure = "Organ Drugs Class 2"
	reagentcure = list("organ_drug2")
	recureprob = 10
	affected_species = list("Human")
	stage_prob = 1
	var/robo_restart = 0

/datum/ailment/disease/liver_failure/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return

	if (ishuman(affected_mob))
		var/mob/living/carbon/human/H = affected_mob
		
		if (!H.organHolder)
			H.cure_disease(D)
			return

		var/datum/organHolder/oH = H.organHolder
		if (!oH.liver)
			H.cure_disease(D)
			return

		//handle roboliver failuer. should do some stuff I guess
		// else if (oH.liver && oH.liver.robotic && !oH.heart.health > 0)

	switch (D.stage)
		if (1)
			if (prob(1) && prob(10))
				boutput(affected_mob, "<span style=\"color:blue\">You feel better.</span>")
				affected_mob.cure_disease(D)
				return
			if (prob(8)) affected_mob.emote(pick("pale", "shudder"))
			if (prob(5))
				boutput(affected_mob, "<span style=\"color:red\">Your abdomen area hurts!</span>")
		if (2)
			if (prob(1) && prob(10))
				boutput(affected_mob, "<span style=\"color:blue\">You feel better.</span>")
				affected_mob.resistances += src.type
				affected_mob.ailments -= src
				return
			if (prob(8)) affected_mob.emote(pick("pale", "groan"))
			if (prob(5))
				boutput(affected_mob, "<span style=\"color:red\">Your back aches terribly!</span>")
			if (prob(3))
				boutput(affected_mob, "<span style=\"color:red\">You feel excruciating pain in your upper-right adbomen!</span>")
				// oH.takeliver

			if (prob(5)) affected_mob.emote(pick("faint", "collapse", "groan"))
		if (3)
			if (prob(20)) 
					affected_mob.emote(pick("twitch", "groan"))
				if (ishuman(affected_mob))
					var/mob/living/carbon/human/H = affected_mob
					H.organHolder.take_organ_damage(3, "liver")
			affected_mob.take_tox_damage(1)
			affected_mob.updatehealth()
