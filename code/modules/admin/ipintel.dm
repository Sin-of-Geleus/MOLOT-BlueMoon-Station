/* // BLUEMOON EDIT:START IPINTEL FROM TG
/datum/ipintel
	var/ip
	var/intel = 0
	var/cache = FALSE
	var/cacheminutesago = 0
	var/cachedate = ""
	var/cacherealtime = 0

/datum/ipintel/New()
	cachedate = SQLtime()
	cacherealtime = world.realtime

/datum/ipintel/proc/is_valid()
	. = FALSE
	if (intel < 0)
		return
	if (intel <= CONFIG_GET(number/ipintel_rating_bad))
		if (world.realtime < cacherealtime + (CONFIG_GET(number/ipintel_save_good) * 60 * 60 * 10))
			return TRUE
	else
		if (world.realtime < cacherealtime + (CONFIG_GET(number/ipintel_save_bad) * 60 * 60 * 10))
			return TRUE

/proc/get_ip_intel(ip, bypasscache = FALSE, updatecache = TRUE)
	var/datum/ipintel/res = new()
	res.ip = ip
	. = res
	if (!ip || !CONFIG_GET(string/ipintel_email) || !SSipintel.enabled)
		return
	if (!bypasscache)
		var/datum/ipintel/cachedintel = SSipintel.cache[ip]
		if (cachedintel?.is_valid())
			cachedintel.cache = TRUE
			return cachedintel

		if(SSdbcore.Connect())
			var/rating_bad = CONFIG_GET(number/ipintel_rating_bad)
			var/datum/db_query/query_get_ip_intel = SSdbcore.NewQuery({"
				SELECT date, intel, TIMESTAMPDIFF(MINUTE,date,NOW())
				FROM [format_table_name("ipintel")]
				WHERE
					ip = INET_ATON(':ip')
					AND ((
							intel < :rating_bad
							AND
							date + INTERVAL :save_good HOUR > NOW()
						) OR (
							intel >= :rating_bad
							AND
							date + INTERVAL :save_bad HOUR > NOW()
					))
			"}, list("ip" = ip, "rating_bad" = rating_bad, "save_good" = CONFIG_GET(number/ipintel_save_good), "save_bad" = CONFIG_GET(number/ipintel_save_bad)))
			if(!query_get_ip_intel.Execute())
				qdel(query_get_ip_intel)
				return
			if (query_get_ip_intel.NextRow())
				res.cache = TRUE
				res.cachedate = query_get_ip_intel.item[1]
				res.intel = text2num(query_get_ip_intel.item[2])
				res.cacheminutesago = text2num(query_get_ip_intel.item[3])
				res.cacherealtime = world.realtime - (text2num(query_get_ip_intel.item[3])*10*60)
				SSipintel.cache[ip] = res
				qdel(query_get_ip_intel)
				return
			qdel(query_get_ip_intel)
	res.intel = ip_intel_query(ip)
	if (updatecache && res.intel >= 0)
		SSipintel.cache[ip] = res
		if(SSdbcore.Connect())
			var/datum/db_query/query_add_ip_intel = SSdbcore.NewQuery(
				"INSERT INTO [format_table_name("ipintel")] (ip, intel) VALUES (INET_ATON(:ip), :intel) ON DUPLICATE KEY UPDATE intel = VALUES(intel), date = NOW()",
				list("ip" = ip, "intel" = res.intel)
			)
			query_add_ip_intel.Execute()
			qdel(query_add_ip_intel)


/proc/ip_intel_query(ip, retryed=0)
	. = -1 //default
	if (!ip)
		return
	if (SSipintel.throttle > world.timeofday)
		return
	if (!SSipintel.enabled)
		return

	var/list/http[] = world.Export("http://[CONFIG_GET(string/ipintel_domain)]/check.php?ip=[ip]&contact=[CONFIG_GET(string/ipintel_email)]&format=json&flags=f")

	if (http)
		var/status = text2num(http["STATUS"])

		if (status == 200)
			var/response = json_decode(file2text(http["CONTENT"]))
			if (response)
				if (response["status"] == "success")
					var/intelnum = text2num(response["result"])
					if (isnum(intelnum))
						return text2num(response["result"])
					else
						ipintel_handle_error("Bad intel from server: [response["result"]].", ip, retryed)
						if (!retryed)
							sleep(25)
							return .(ip, 1)
				else
					ipintel_handle_error("Bad response from server: [response["status"]].", ip, retryed)
					if (!retryed)
						sleep(25)
						return .(ip, 1)

		else if (status == 429)
			ipintel_handle_error("Error #429: We have exceeded the rate limit.", ip, 1)
			return
		else
			ipintel_handle_error("Unknown status code: [status].", ip, retryed)
			if (!retryed)
				sleep(25)
				return .(ip, 1)
	else
		ipintel_handle_error("Unable to connect to API.", ip, retryed)
		if (!retryed)
			sleep(25)
			return .(ip, 1)


/proc/ipintel_handle_error(error, ip, retryed)
	if (retryed)
		SSipintel.errors++
		error += " Could not check [ip]. Disabling IPINTEL for [SSipintel.errors] minute[( SSipintel.errors == 1 ? "" : "s" )]"
		SSipintel.throttle = world.timeofday + (10 * 120 * SSipintel.errors)
	else
		error += " Attempting retry on [ip]."
	log_ipintel(error)

/proc/log_ipintel(text)
	log_game("IPINTEL: [text]")
	debug_admins("IPINTEL: [text]")
*/ // BLUEMOON EDIT:END IPINTEL FROM TG

// BLUEMOON EDIT:START IPINTEL FROM TG
GLOBAL_DATUM_INIT(ipintel_manager, /datum/ipintel_manager, new())

/datum/ipintel_manager
	var/throttle = 0
	var/errors = 0

	var/list/cache = list()

// Represents an IP intel holder datum
/datum/ipintel
	/// The IP being checked
	var/ip
	/// The current rating, 0-1 float.
	var/intel = 0
	/// Whether this was loaded from the cache or not
	var/cache = FALSE
	/// How many minutes ago it was cached
	var/cacheminutesago = 0
	/// The date it was cached
	var/cachedate = ""
	/// The real time it was cached
	var/cacherealtime = 0

/datum/ipintel/New()
	cachedate = SQLtime()
	cacherealtime = world.realtime

/datum/ipintel/proc/is_valid()
	. = FALSE
	if(intel < 0)
		return
	if(intel <= CONFIG_GET(number/bad_rating))
		if(world.realtime < cacherealtime + (CONFIG_GET(number/hours_save_good) HOURS))
			return TRUE
	else
		if(world.realtime < cacherealtime + (CONFIG_GET(number/hours_save_bad) HOURS))
			return TRUE



/**
  * Get IP intel
  *
  * Performs a lookup of the rating for an IP provided
  *
  * Arguments:
  * * ip - The IP to lookup
  * * bypasscache - Do we want to bypass the DB cache?
  * * updatecache - Do we want to update the DB cache?
  */
/datum/ipintel_manager/proc/get_ip_intel(ip, bypasscache = FALSE, updatecache = TRUE)
	var/datum/ipintel/res = new()
	res.ip = ip
	. = res
	if(!ip || !CONFIG_GET(string/contact_email) || !CONFIG_GET(flag/ipintel_enabled))
		return
	if(!bypasscache)
		var/datum/ipintel/cachedintel = cache[ip]
		if(cachedintel && cachedintel.is_valid())
			cachedintel.cache = TRUE
			return cachedintel

		if(SSdbcore.IsConnected())
			var/datum/db_query/query_get_ip_intel = SSdbcore.NewQuery({"
				SELECT date, intel, TIMESTAMPDIFF(MINUTE,date,NOW())
				FROM ipintel
				WHERE
					ip = INET_ATON(:ip)
					AND ((
							intel < :rating_bad
							AND
							date + INTERVAL :save_good HOUR > NOW()
						) OR (
							intel >= :rating_bad
							AND
							date + INTERVAL :save_bad HOUR > NOW()
					))
				"}, list(
					"ip" = ip,
					"rating_bad" = CONFIG_GET(number/bad_rating),
					"save_good" = CONFIG_GET(number/hours_save_good),
					"save_bad" = CONFIG_GET(number/hours_save_bad),
				))
			if(!query_get_ip_intel.warn_execute())
				qdel(query_get_ip_intel)
				return
			if(query_get_ip_intel.NextRow())
				res.cache = TRUE
				res.cachedate = query_get_ip_intel.item[1]
				res.intel = text2num(query_get_ip_intel.item[2])
				res.cacheminutesago = text2num(query_get_ip_intel.item[3])
				res.cacherealtime = world.realtime - (text2num(query_get_ip_intel.item[3])*10*60)
				cache[ip] = res
				qdel(query_get_ip_intel)
				return
			qdel(query_get_ip_intel)
	res.intel = ip_intel_query(ip)
	if(updatecache && res.intel >= 0)
		cache[ip] = res
		if(SSdbcore.IsConnected())
			var/datum/db_query/query_add_ip_intel = SSdbcore.NewQuery({"
				INSERT INTO ipintel (ip, intel) VALUES (INET_ATON(:ip), :intel)
				ON DUPLICATE KEY UPDATE intel = VALUES(intel), date = NOW()"},
				list(
					"ip" = ip,
					"intel" = res.intel
				)
			)
			query_add_ip_intel.warn_execute()
			qdel(query_add_ip_intel)



/**
  * Performs the remote IPintel lookup
  *
  *
  *
  * Arguments:
  * * ip - The IP to lookup
  * * retried - Was this attempt retried?
  */
/datum/ipintel_manager/proc/ip_intel_query(ip, retried = FALSE)
	. = -1 //default
	if(!ip)
		return
	if(throttle > world.timeofday)
		return

	// Do not refactor this to use SShttp, because that requires the subsystem to be firing for requests to be made, and this will be triggered before the MC has finished loading
	var/list/http[] = HTTPGet("http://[CONFIG_GET(string/ipintel_domain)]/check.php?ip=[ip]&contact=[CONFIG_GET(string/contact_email)]&format=json&flags=b")

	if(http)
		var/status = text2num(http["STATUS"])

		if(status == 200)
			var/response = json_decode(http["CONTENT"])
			if(response)
				if(response["status"] == "success")
					var/intelnum = text2num(response["result"])
					if(isnum(intelnum))
						return text2num(response["result"])
					else
						ipintel_handle_error("Bad intel from server: [response["result"]].", ip, retried)
						if(!retried)
							sleep(25)
							return .(ip, 1)
				else
					ipintel_handle_error("Bad response from server: [response["status"]].", ip, retried)
					if(!retried)
						sleep(25)
						return .(ip, 1)

		else if(status == 429)
			ipintel_handle_error("Error #429: We have exceeded the rate limit.", ip, 1)
			return
		else
			ipintel_handle_error("Unknown status code: [status].", ip, retried)
			if(!retried)
				sleep(25)
				return .(ip, 1)
	else
		ipintel_handle_error("Unable to connect to API.", ip, retried)
		if(!retried)
			sleep(25)
			return .(ip, 1)



/**
  * Error handler
  *
  * Handles an IP intel error, also throttling the susbystem if required
  *
  * Arguments:
  * * error - The error description
  * * ip - The IP that was tried
  * * retried - Was this on a retried attempt
  */
/datum/ipintel_manager/proc/ipintel_handle_error(error, ip, retried)
	if(retried)
		errors++
		error += " Could not check [ip]. Disabling IPINTEL for [errors] minute[(errors == 1 ? "" : "s")]"
		throttle = world.timeofday + (2 * errors MINUTES)
	else
		error += " Attempting retry on [ip]."
	log_ipintel(error)



/**
  * Logs an IPintel error
  *
  * Pretty self explanatory. Logs errors regarding ipintel.
  *
  * Arguments:
  * * text - Argument 1
  */
/datum/ipintel_manager/proc/log_ipintel(text)
	log_game("IPINTEL: [text]")
	log_access("IPINTEL: [text]")



/**
  * IPIntel Ban Checker
  *
  * Checks if a user is banned due to IPintel. It will check configuration, DB, whitelist checks, and more
  *
  * Arguments:
  * * t_ckey - The ckey to check
  * * t_ip - The IP to check
  */
/datum/ipintel_manager/proc/ipintel_is_banned(t_ckey, t_ip)
	if(!CONFIG_GET(string/contact_email))
		return FALSE
	if(!CONFIG_GET(flag/ipintel_enabled))
		return FALSE
	if(!CONFIG_GET(flag/whitelist_mode))
		return FALSE
	if(!SSdbcore.IsConnected())
		return FALSE
	if(!ipintel_badip_check(t_ip))
		return FALSE
	if(vpn_whitelist_check(t_ckey))
		return FALSE
	return TRUE



/**
  * IP Rating Checker
  *
  * Checks if a provided IP passes the config threshold for denial
  *
  * Arguments:
  * * target_ip - The IP to check
  */
/datum/ipintel_manager/proc/ipintel_badip_check(target_ip)
	var/rating_bad = CONFIG_GET(number/bad_rating)
	if(!rating_bad)
		log_access("ipintel_badip_check reports misconfigured rating_bad directive")
		return FALSE
	var/valid_hours = CONFIG_GET(number/hours_save_bad)
	if(!valid_hours)
		log_access("ipintel_badip_check reports misconfigured ipintel_save_bad directive")
		return FALSE
	var/datum/db_query/query_get_ip_intel = SSdbcore.NewQuery({"
		SELECT * FROM ipintel WHERE ip = INET_ATON(:target_ip)
		AND intel >= :rating_bad AND (date + INTERVAL :valid_hours HOUR) > NOW()"},
		list(
			"target_ip" = target_ip,
			"rating_bad" = rating_bad,
			"valid_hours" = valid_hours
		)
	)
	if(!query_get_ip_intel.warn_execute())
		log_access("ipintel_badip_check reports failed query execution")
		qdel(query_get_ip_intel)
		return FALSE
	if(!query_get_ip_intel.NextRow())
		qdel(query_get_ip_intel)
		return FALSE
	qdel(query_get_ip_intel)
	return TRUE



/**
  * VPN whitelist checker
  *
  * Checks if a ckey is whitelisted to be using a VPN against the DB
  *
  * Arguments:
  * * target_ckey - The ckey to check
  */
/datum/ipintel_manager/proc/vpn_whitelist_check(target_ckey)
	if(!CONFIG_GET(flag/whitelist_mode))
		return FALSE
	var/datum/db_query/query_whitelist_check = SSdbcore.NewQuery("SELECT * FROM vpn_whitelist WHERE ckey=:ckey", list(
		"ckey" = target_ckey
	))
	if(!query_whitelist_check.warn_execute())
		qdel(query_whitelist_check)
		return FALSE
	if(query_whitelist_check.NextRow())
		qdel(query_whitelist_check)
		return TRUE // At least one row in the whitelist names their ckey. That means they are whitelisted.
	qdel(query_whitelist_check)
	return FALSE



/**
  * VPN whitelist adder
  *
  * Adds a ckey to the VPN whitelist. Asks the admin to also provide a link to their request.
  *
  * Arguments:
  * * target_ckey - The ckey to whitelist
  */
/datum/ipintel_manager/proc/vpn_whitelist_add(target_ckey)
	var/reason_string = input(usr, "Enter link to the URL of their whitelist request on the forum.","Reason required") as message|null
	if(!reason_string)
		return FALSE
	var/datum/db_query/query_whitelist_add = SSdbcore.NewQuery("INSERT INTO vpn_whitelist (ckey,reason) VALUES (:targetckey, :reason)", list(
		"targetckey" = target_ckey,
		"reason" = reason_string
	))
	if(!query_whitelist_add.warn_execute())
		qdel(query_whitelist_add)
		return FALSE
	qdel(query_whitelist_add)
	return TRUE



/**
  * VPN whitelist remover
  *
  * Removes a ckey from the VPN whitelist. Pretty simple.
  *
  * Arguments:
  * * target_ckey - The ckey to remove
  */
/datum/ipintel_manager/proc/vpn_whitelist_remove(target_ckey)
	var/datum/db_query/query_whitelist_remove = SSdbcore.NewQuery("DELETE FROM vpn_whitelist WHERE ckey=:targetckey", list(
		"targetckey" = target_ckey
	))
	if(!query_whitelist_remove.warn_execute())
		qdel(query_whitelist_remove)
		return FALSE
	qdel(query_whitelist_remove)
	return TRUE



/**
  * VPN whitelist panel
  *
  * Doesnt actually open a panel, this is just a verb to handle the rest of the whitelist operations
  *
  * Arguments:
  * * target_ckey - The ckey to add/remove
  */
/datum/ipintel_manager/proc/vpn_whitelist_panel(target_ckey as text)
	if(!check_rights(R_ADMIN))
		return
	if(!target_ckey)
		return
	var/is_already_whitelisted = vpn_whitelist_check(target_ckey)
	if(is_already_whitelisted)
		var/confirm = alert("[target_ckey] is already whitelisted. Remove them?", "Confirm Removal", "No", "Yes")
		if(!confirm || confirm != "Yes")
			to_chat(usr, "VPN whitelist alteration cancelled.")
			return
		else if(vpn_whitelist_remove(target_ckey))
			to_chat(usr, "[target_ckey] was removed from the VPN whitelist.")
		else
			to_chat(usr, "VPN whitelist unchanged.")
	else
		if(vpn_whitelist_add(target_ckey))
			to_chat(usr, "[target_ckey] was added to the VPN whitelist.")
		else
			to_chat(usr, "VPN whitelist unchanged.")

/datum/admins/proc/vpn_whitelist()
	set category = "Admin"
	set name = "VPN Ckey Whitelist"
	if(!check_rights(R_BAN))
		return
	var/key = stripped_input(usr, "Enter ckey to add/remove, or leave blank to cancel:", "VPN Whitelist add/remove", max_length=32)
	if(key)
		GLOB.ipintel_manager.vpn_whitelist_panel(key)
// BLUEMOON EDIT:END IPINTEL FROM TG
