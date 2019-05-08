/obj/item/shipcomponent/sensor
	name = "Standard Sensor System"
	desc = "Advanced scanning system for ships."
	power_used = 20
	system = "Sensors"
	var/ships = 0
	var/list/obj/shiplist = list()
	var/list/obj/whos_tracking_me = list()
	var/lifeforms = 0
	var/list/lifelist = list()
	var/seekrange = 30
	var/sight = SEE_SELF
	var/see_in_dark = SEE_DARK_HUMAN + 3
	var/see_invisible = 2
	var/scanning = 0
	var/atom/tracking_target = null
	var/const/SENSOR_REFRESH_RATE = 5
	icon_state = "sensor"

	mob_deactivate(mob/M as mob)
		M.sight &= ~SEE_TURFS
		M.sight &= ~SEE_MOBS
		M.sight &= ~SEE_OBJS
		M.see_in_dark = initial(M.see_in_dark)
		M.see_invisible = 0
		end_tracking()

		//stop the tracking for people who ar lookinug at you
		for (var/obj/O in whos_tracking_me)
			var/obj/machinery/vehicle/pod = O
			if (istype(pod))
				if (pod.sensors)
					pod.sensors.tracking_target = null

		scanning = 0

	opencomputer(mob/user as mob)
		if(user.loc != src.ship)
			return
		user.machine = src

		var/dat = "<B>[src] Console</B><BR><HR><BR>"
		if(src.active)

			dat += build_html_gps_form(src)

			dat += {"<HR><BR><A href='?src=\ref[src];scan=1'>Scan Area</A>"}
			if (src.tracking_target)
				dat += {"<BR>Currently Tracking: [src.tracking_target.name] 
				<a href=\"byond://?src=\ref[src];stop_tracking=1\">Stop Tracking</a>"}
			dat += {"<HR><B>[ships] Ships Detected:</B><BR>"}
			if(shiplist.len)
				for(var/obj/ship in shiplist)
					dat += {"<HR> | <a href=\"byond://?src=\ref[src];tracking_ship=\ref[ship]\">[ship.name]</a> "}

			dat += {"<HR>[lifeforms] Lifeforms Detected:</B><BR>"}
			if(lifelist.len)
				for(var/lifename in lifelist)
					dat += {"[lifename] | "}
		else
			dat += {"<B><span style=\"color:red\">SYSTEM OFFLINE</span></B>"}
		user << browse(dat, "window=ship_sensor")
		onclose(user, "ship_sensor")
		return

//Doing nothing with the Z-level value right now.
	proc/obtain_target_from_coords(href_list)
	//The default Z coordinate given. Just use current Z-Level where the object is. Pods won't
		#define DEFAULT_Z_VALUE -1		
		scanning = 1
		if (href_list["dest_cords"])
			tracking_target = null
			var/x = text2num(href_list["x"])
			var/y = text2num(href_list["y"])
			var/z = text2num(href_list["z"])
			if (!x || !y || !z)
				boutput(usr, "<span style=\"color:red\">Bad Topc call, if you see this something has gone wrong. And it's probably YOUR FAULT!</span>")
				return
			//Using -1 as the default value
			if (z == DEFAULT_Z_VALUE)
				if (src.loc)
					z = src.loc.z

			boutput(usr, "<span style=\"color:blue\">Attempting to pinpoint: <b>X</b>: [x], <b>Y</b>: [y], Z</b>: [z]</span>")
			playsound(ship.loc, "sound/machines/signal.ogg", 50, 0)
			sleep(10)
			var/turf/T = locate(x,y,z) 

			//Set located turf to be the tracking_target
			if (isturf(T))
				src.tracking_target = T
				boutput(usr, "<span style=\"color:blue\">Now tracking: <b>X</b>: [T.x], <b>Y</b>: [T.y], Z</b>: [T.z]</span>")
				scanning = 0		//remove this if we want to force the user to manually stop tracking before trying to track something else
				begin_tracking(1)
		sleep(10)
		scanning = 0
		#undef DEFAULT_Z_VALUE

	Topic(href, href_list)
		if(usr.stat || usr.restrained())
			return

		if (usr.loc == ship)
			usr.machine = src
			if (href_list["scan"] && !scanning)
				scan(usr)

			if (href_list["tracking_ship"] && !scanning)
				obtain_tracking_target(locate(href_list["tracking_ship"]))
			if (href_list["stop_tracking"])
				end_tracking()
			if(href_list["getcords"])
				boutput(usr, "<span style=\"color:blue\">Located at: <b>X</b>: [src.ship.x], <b>Y</b>: [src.ship.y]</span>")
			if(href_list["dest_cords"] && !scanning)
				obtain_target_from_coords(href_list)

			src.add_fingerprint(usr)
			for(var/mob/M in ship)
				if ((M.client && M.machine == src))
					src.opencomputer(M)
		else
			usr << browse(null, "window=ship_sensor")
			return
		return

	//If our target is a turf from the GPS coordinate picker. Our range will be much higher
	proc/begin_tracking(var/gps_coord=0)
		if (src.tracking_target)
			var/obj/machinery/vehicle/target_pod = src.tracking_target
			if (istype(target_pod))
				var/obj/item/shipcomponent/sensor/sensor = target_pod.sensors
				if (istype(sensor))
					sensor.whos_tracking_me |= src
					target_pod.myhud.sensor_lock.icon_state = "master-caution-s" //master-caution
					target_pod.myhud.sensor_lock.mouse_opacity = 1

		src.ship.myhud.tracking.icon_state = "dots-s"
		track_target(gps_coord)

	//nulls the tracking target, sets the hud object to turn off end center on the ship and updates the dilaogue
	proc/end_tracking()
		if (src.tracking_target)
			var/obj/machinery/vehicle/target_pod = src.tracking_target
			if (istype(target_pod))
				var/obj/item/shipcomponent/sensor/sensor = target_pod.sensors
				if (istype(sensor))
					sensor.whos_tracking_me -= src
					if (islist(sensor.whos_tracking_me) && sensor.whos_tracking_me.len == 0)
						target_pod.myhud.sensor_lock.icon_state = "off" //master-caution
						target_pod.myhud.sensor_lock.mouse_opacity = 0

		src.tracking_target = null
		src.ship.myhud.tracking.dir = 1
		animate(src.ship.myhud.tracking, transform = null, time = SENSOR_REFRESH_RATE, loop = 0)

		src.ship.myhud.tracking.icon_state = "off"
		src.updateDialog()

	//Tracking loop
	proc/track_target(var/gps_coord)
		var/cur_dist = 0

		while (src.tracking_target && src.ship.myhud && src.ship.myhud.tracking)
			cur_dist = get_dist(src,src.tracking_target)
			//change position and icon dir based on direction to target. And make sure it's using the dots.
			if (cur_dist <= seekrange)
				// src.dir = get_dir(ship, src.tracking_target)
				src.ship.myhud.tracking.icon_state = "dots-s"
				animate_tracking_hud(src.ship.myhud.tracking, src.tracking_target)

			//If the target is out of seek range, move to top and change to lost state
			else 
				src.ship.myhud.tracking.icon_state = "lost"
				//if we're twice as far out or off the z-level, lose the signal
				//If it's a static gps target from the coordinate picker, we can track from 10x away
				if ((cur_dist > seekrange*2) || (gps_coord && cur_dist > seekrange*10))
					end_tracking()
					for(var/mob/M in ship)
						boutput(M, "<span style=\"color:red\">Tracking signal lost.</span>")
					playsound(src.loc, "sound/machines/whistlebeep.ogg", 50, 1)
					break;

			sleep(10)

		if (src.tracking_target)
			src.ship.myhud.tracking.icon_state = "off"

	//Arguments: A should be the tracking HuD dots, target is the sensor's tracking_target
	//Turns the sprite around
	proc/animate_tracking_hud(var/atom/A, var/atom/target)
		if (!istype(A) || !istype(target))
			return		
		var/ang = get_angle(src.ship, target)
		//Was maybe thinking about having it get further out or something the further the target is, but no.
		//var/dist = get_dist(src.ship, target)
		//var/number = round(ang/(45-(50-dist)))*(45-(50-dist))		
		var/matrix/M = matrix()
		M = M.Turn(ang)
		M = M.Translate(32 * sin(ang),32 * cos(ang))
		
		animate(A, transform = M, time = 10, loop = 0)

	//arguments: O is the target to track. If O is within sensor range after .1 seconds, it is tracked by the sensor
	proc/obtain_tracking_target(var/obj/O)
		if (!O)
			return 
		scanning = 1
		src.tracking_target = O
		boutput(usr, "<span style=\"color:blue\">Attempting to pinpoint energy source...</span>")
		playsound(ship.loc, "sound/machines/signal.ogg", 50, 0)
		sleep(10)
		if (src.tracking_target && get_dist(src,src.tracking_target) <= seekrange)
			scanning = 0		//remove this if we want to force the user to manually stop tracking before trying to track something else
			boutput(usr, "<span style=\"color:blue\">Tracking target: [src.tracking_target.name]</span>")
			spawn(0)		//Doing this to redraw the scanner window after the topic call that uses this fires.
				begin_tracking(0)
		else
			boutput(usr, "<span style=\"color:blue\">Unable to locate target.</span>")
		src.updateDialog()
		scanning = 0

	//For use by clicking a pod to target them, instantly add them as your tracking target
	proc/quick_obtain_target(var/obj/machinery/vehicle/O)
		if (!O)
			return 
		src.tracking_target = O
		boutput(usr, "<span style=\"color:blue\">Tracking target: [src.tracking_target.name]</span>")
		spawn(0)
			begin_tracking(0)
		src.updateDialog()


	proc/dir_name(var/direction)
		switch (direction)
			if (1)
				return "north"
			if (2)
				return "south"
			if (4)
				return "east"
			if (8)
				return "west"
			if (5)
				return "northeast"
			if (6)
				return "southeast"
			if (9)
				return "northwest"
			if (10)
				return "southwest"

	proc/scan(mob/user as mob)
		scanning = 1
		lifeforms = 0
		ships = 0
		lifelist = list()
		shiplist = list()
		playsound(ship.loc, "sound/machines/signal.ogg", 50, 0)
		ship.visible_message("<b>[ship] begins a sensor sweep of the area.</b>")
		boutput(usr, "<span style=\"color:blue\">Scanning...</span>")
		sleep(30)
		boutput(usr, "<span style=\"color:blue\">Scan complete.</span>")
		for (var/mob/living/C in range(src.seekrange,ship.loc))
			if(C.stat != 2)
				lifeforms++
				lifelist += C.name
		for (var/obj/critter/C in range(src.seekrange,ship.loc))
			if(C.alive && !istype(C,/obj/critter/gunbot))
				lifeforms++
				lifelist += C.name
		for (var/obj/npc/C in range(src.seekrange,ship.loc))
			if(C.alive)
				lifeforms++
				lifelist += C.name
		for (var/obj/machinery/vehicle/V in range(src.seekrange,ship.loc))
			if(V != ship)
				ships++
				shiplist[V] = "[dir_name(get_dir(ship, V))]"
		for (var/obj/critter/gunbot/drone/V in range(src.seekrange,ship.loc))
			ships++
			shiplist[V] ="[dir_name(get_dir(ship, V))]"
		src.updateDialog()
		sleep(10)
		scanning = 0
		return

//Sends topic call with "dest_cords" and "X", "Y", "Z" as params
proc/build_html_gps_form(var/atom/A, var/show_Z=0)
	return {"
		<A href='byond://?src=\ref[A];getcords=1'>Get Local Coordinates</A><BR>
		<div id=topDiv>
			<button id='getCords' style='width:100%;' onClick=\"window.location.href = 'byond://?src=\ref[A];getcords=1';\">Get Local Coordinates</button><BR>
			<button id='dest' style='width:100%;' onClick='(showInput())' >Select Destination</button><BR>
		</div>
		<div style='display:none' id = 'destInput'>
				X Coordinate: <input id='idX'  type='number' min='0' max='500' name='X' value='0'><br>
				Y Coordinate: <input id='idY' type='number' min='0' max='500' name='Y' value='0'><br>
				<div[show_Z ? "" : " style='display: none;'"]>
					Z Coordinate: <input id='idZ' type='number' name='Z' value='[show_Z ? "0" : "-1"]'><br>
				</div>

				<button onclick='send()'>Enter</button>
		</div>
		<script>
			function showInput() {
			  var x = document.getElementById('destInput');
			  if (x.style.display === 'none') {
			    x.style.display = 'block';
			  } else {
			    x.style.display = 'none';
			  }
			}

			function send() {
				var x = document.getElementById('idX').value;
				var y = document.getElementById('idY').value;
				var z = document.getElementById('idZ').value;

				window.location='byond://?src=\ref[A];dest_cords=1;x='+x+';y='+y+';z='+z;

			}
		</script>

		"}

/obj/item/shipcomponent/sensor/ecto
	name = "Ecto-Sensor 900"
	desc = "The number one choice for reasearchers of the supernatural."
	see_invisible = 15
	power_used = 40

/obj/item/shipcomponent/sensor/mining
	name = "Conclave A-1984 Sensor System"
	desc = "Advanced geological meson scanners for ships."
	sight = SEE_TURFS
	power_used = 35

	scan(mob/user as mob)
		..()
		mining_scan(get_turf(user), user, 6)