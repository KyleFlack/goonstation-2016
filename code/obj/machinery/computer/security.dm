

/obj/machinery/computer/security
	name = "Security Cameras"
	icon_state = "security"
	var/obj/machinery/camera/current = null
	var/list/obj/machinery/camera/favorites = list()
	var/const/favorites_Max = 5

	var/network = "SS13"
	var/maplevel = 1
	desc = "A computer that allows one to connect to a security camera network and view camera images."

	//This might not be needed. I thought that the proc should be on the computer instead of the mob switching, but maybe not
	proc/switchCamera(var/mob/living/user, var/obj/machinery/camera/C)
		if (!C)
			user.machine = null
			user.set_eye(null)
			return 0
			
		if (stat == 2 || C.network != src.network) return 0

		// ok, we're alive, camera is acceptable and in our network...
//AAAAAAAAAAAADDDDDDDDD BBAAAAAAAACK		// camera_overlay_check(C) //Add static if the camera is disabled

		// src.machine = src
		src.current = C
		user.set_eye(C)
		return 1

	//moved out of global to only be used in sec computers
	proc/move_security_camera(/*n,*/direct,var/mob/living/carbon/user)
		if(!user) return

		//pretty sure this should never happen since I'm adding the first camera found to be the current, but just in cases
		if (!src.current)
			boutput(user, "<span style=\"color:red\">No current active camera. Select a camera as an origin point.</span>")
			return


		// if(user.classic_move)
		var/obj/machinery/camera/closest = src.current
		if(closest)
			//do
			if(direct & NORTH)
				closest = closest.c_north
			else if(direct & SOUTH)
				closest = closest.c_south
			if(direct & EAST)
				closest = closest.c_east
			else if(direct & WEST)
				closest = closest.c_west
			//while(closest && !closest.status) //Skip disabled cameras - THIS NEEDS TO BE BETTER (static overlay imo)
		else
			closest = getCameraMove(user, direct) //Ok, let's do this then.

		if(!closest)
			return

		// user.tracker.cease_track()
		switchCamera(user, closest)
		// user.switchCamera(closest)		//from original

/obj/machinery/computer/security/wooden_tv
	name = "Security Cameras"
	icon_state = "security_det"

	small
		name = "Television"
		desc = "These channels seem to mostly be about robuddies. What is this, some kind of reality show?"
		network = "Zeta"
		icon_state = "security_tv"

		power_change()
			return

// -------------------- VR --------------------
/obj/machinery/computer/security/wooden_tv/small/virtual
	desc = "It's making you feel kinda twitchy for some reason."
	icon = 'icons/effects/VR.dmi'
// --------------------------------------------

/obj/machinery/computer/security/telescreen
	name = "Telescreen"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "telescreen"
	network = "thunder"
	density = 0

	power_change()
		return

/obj/machinery/computer/security/attack_hand(var/mob/user as mob)
	if (stat & (NOPOWER|BROKEN))
		return

	user.machine = src
	user.unlock_medal("Peeping Tom", 1)

	var/list/L = list()
	var/bool = 1
	for (var/obj/machinery/camera/C in machines)
		if (bool)
			src.current = C
			bool = 0
		L.Add(C)

	L = camera_sort(L)

	var/cameras_list 
	for (var/obj/machinery/camera/C in L)
		if (C.network == src.network)
			. = "[C.c_tag][C.status ? null : " (Deactivated)"]"
			// Don't draw if it's in favorites
			if (C in favorites)
				continue
			//the display:none is a holdover from another way I was trying to handle moving shit. might move back or not
			// &#128190; is save symbol
			cameras_list += \
{"<tr>
<td><a href='byond://?src=\ref[src];camera=\ref[C]' style='display:block;'>[.]</a></td> <td class='save'>&#128190;</td>
</tr>
"}

	var/script = 	{"
	<script type='text/javascript'>
	function filterTable() {
		var input, filter, table, tr, td, i, txtValue;
		input = document.getElementById('searchbar');
		filter = input.value.toUpperCase();
		table = document.getElementById("cameraList");
		tr = table.getElementsByTagName("tr");

		// Loop through all table rows, and hide those who don't match the search query
		for (i = 0; i < tr.length; i++) {
			td = tr\[i\].getElementsByTagName("td")\[0\];
			if (td) {
				txtValue = td.textContent || td.innerText;
				if (txtValue.toUpperCase().indexOf(filter) > -1) {
					tr\[i\].style.display = "";
				} else {
					tr\[i\].style.display = "none";
				}
			} 
		}
	}


	</script>

	<script type='text/javascript' src='[resource("js/jquery.min.js")]'></script>
	<script type='text/javascript'>

	$(document).delegate('button', 'keydown', function(e) {
		var keyId = e.which;
		window.location='byond://?src=\ref[src];move='+keyId;
		e.preventDefault();
		
	 });

	//for these just add a save link to those list items

	$("td").click(function(e) {
	  //check which list it's in. adding/removing
	  if ($(this).parent().parent().attr("class") == "save") {
	    var savedUL = document.getElementById("savedCameras");
	    var li = $(this).parent();
	    $(this).html('Remove');
	    li.appendTo(savedUL);

	    // make topic call from a href
	    var href = li.find('a').attr('href');
	    var re = /.*camera=(.*)$/g;
	    var cameraID = re.exec(href)\[1\];


	    window.location='byond://?src=\ref[src];save='+cameraID;

	  } else if($(this).parent().parent().attr("class") == "remove") {
	  //Removing shit
	    var savedUL = document.getElementById("cameraList");
	    var li = $(this).parent();
	    $(this).html('&#128190');
	    li.appendTo(savedUL);

	    var href = li.find('a').attr('href');
	    var re = /.*camera=(.*)$/g;
	    var cameraID = re.exec(href)\[1\];


	    window.location='byond://?src=\ref[src];remove='+cameraID;
		}
  
});

	</script>

	<style>
		ul{
			list-style-type: none;
			margin: 0;
			padding: 0;
		}

	</style>
	"}

	var/fav_cameras
	for (var/obj/machinery/camera/C in favorites)
		if (C.network == src.network)
			. = "[C.c_tag][C.status ? null : " (Deactivated)"]"

			fav_cameras += \
			{"<tr>
			<td><a href='byond://?src=\ref[src];camera=\ref[C]' style='display:block;'>[.]</a></td> <td class='remove'>Remove</td>
			</tr>"}

	var/dat = {"[script]
	<body>
		<button type='button' autofocus id='movementButton'> Keyboard Movement Mode</button>
		<p>Favorite Cameras: </p>
		<table id='savedCameras'>
			[fav_cameras]
		</table>


		<input type='text' id='searchbar' onkeyup='filterTable()' placeholder='Search for cameras..'>
		<table id='cameraList'>
			[cameras_list]
		</table>
	</body>"}

	// user << output(null, "camera_console.camlist")
	// user << output("<a href='byond://?src=\ref[src];thing=1' style='display:block;'><div>Movement Mode</div></a>", "camera_console.camlist")
	// var/table = "<table id='cameraList'>"

	// user << output(dat, "camera_console.camlist")

	// user << browse(dat, "window=camera_console.camlist;size=400x500")
	user.Browse(dat, "window=security_camera_computer;title=Security Cameras")

	// user << browse(dat, "window=camera_console;size=400x500")
	// onclose(user, "camera_console", src)
	// winset(user, "camera_console.exitbutton", "command=\".windowclose \ref[src]\"")
	onclose(user, "security_camera_computer")
	winshow(user, "security_camera_computer", 1)


/obj/machinery/computer/security/Topic(href, href_list)
	if (!usr)
		return

	if (href_list["close"])
		usr.set_eye(null)
		winshow(usr, "security_camera_computer", 0)
		// winshow(usr, "movement_camera", 0)

		return

	else if (href_list["camera"])
		var/obj/machinery/camera/C = locate(href_list["camera"])
		if (!istype(C, /obj/machinery/camera))
			return

		if ((!istype(usr, /mob/living/silicon/ai)) && (get_dist(usr, src) > 1 || usr.machine != src || !usr.sight_check(1) || !( C.status )))
			usr.set_eye(null)
			winshow(usr, "security_camera_computer", 0)
			return

		else
			src.current = C
			usr.set_eye(C)
			use_power(50)

	else if (href_list["save"])
		var/obj/machinery/camera/C = locate(href_list["save"])

		if (!istype(usr, /mob/living/silicon/ai) && (get_dist(usr, src) > 1 || usr.machine != src || !usr.sight_check(1)))
			usr.set_eye(null)
			winshow(usr, "security_camera_computer", 0)
			return

		if (C && favorites.len < favorites_Max)
			favorites += C
	else if (href_list["remove"])
		var/obj/machinery/camera/C = locate(href_list["save"])

		if (!istype(usr, /mob/living/silicon/ai) && (get_dist(usr, src) > 1 || usr.machine != src || !usr.sight_check(1)))
			usr.set_eye(null)
			winshow(usr, "security_camera_computer", 0)
			return

		if (C)
			favorites -= C

	//using arrowkeys/wasd/ijkl to move from camera to camera
	else if (href_list["move"])

		if (!istype(usr, /mob/living/silicon/ai) && (get_dist(usr, src) > 1 || usr.machine != src || !usr.sight_check(1)))
			usr.set_eye(null)
			winshow(usr, "security_camera_computer", 0)
			return

		var/direction = href_list["move"]
		world << direction
		switch (direction)
			if ("37")
				//W
				direction = WEST

			if ("38")
				//N
				direction = NORTH
			if ("39")
				//S
				direction = EAST

			if ("40")
				//E
				direction = SOUTH
			else
				direction = NORTH

		move_security_camera(direction,usr)

	// else if (href_list["thing"])
	// 	make_movement_screen()

// /obj/machinery/computer/security/proc/make_movement_screen()
// 	var/js = {"
// 		<html>
// <body>

// <p id="p1">Hello World!</p>

// 	<script type='text/javascript' src='[resource("js/jquery.min.js")]'></script>
// 	<script type='text/javascript'>

// 	$(document).ready(function() {
// 	  $(document).keydown(function(event){
// 	        var keyId = event.which;
// 	        document.getElementById("p1").innerHTML = keyId;
// 	        window.location='byond://?src=\ref[src];move='+keyId;
// 	      });
	      
// 	 });
// 	</script>

// </body>
// </html>"}
	
// 	usr << browse(js,"window=movement_camera;size=333x615")


/obj/machinery/computer/security/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/screwdriver))
		playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
		if(do_after(user, 20))
			if (src.stat & BROKEN)
				boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
				var/obj/computerframe/A = new /obj/computerframe( src.loc )
				if(src.material) A.setMaterial(src.material)
				new /obj/item/raw_material/shard/glass( src.loc )
				var/obj/item/circuitboard/security/M = new /obj/item/circuitboard/security( A )
				for (var/obj/C in src)
					C.set_loc(src.loc)
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				qdel(src)
			else
				boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
				var/obj/computerframe/A = new /obj/computerframe( src.loc )
				if(src.material) A.setMaterial(src.material)
				var/obj/item/circuitboard/security/M = new /obj/item/circuitboard/security( A )
				for (var/obj/C in src)
					C.set_loc(src.loc)
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				qdel(src)
	else
		src.attack_hand(user)
	return

proc/getr(col)
	return hex2num( copytext(col, 2,4))

proc/getg(col)
	return hex2num( copytext(col, 4,6))

proc/getb(col)
	return hex2num( copytext(col, 6))
