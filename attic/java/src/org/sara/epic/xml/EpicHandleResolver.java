package org.sara.epic.xml;

import java.util.Calendar;
import java.util.TimeZone;

import net.handle.hdllib.HandleException;
import net.handle.hdllib.HandleResolver;
import net.handle.hdllib.HandleValue;
import net.handle.hdllib.Interface;

import org.sara.epic.utility.Logger;

/**
 * Resolve engine for handles.
 * 
 * Currently: one instance resolves all. May be OK if Tomcat creates different
 * environments with separate environments so that multiple instances will
 * resolve, one per thread.
 * 
 * If not, think of another implementation to allow multiple, long-lived,
 * resolver istances.
 * 
 * @author Markus.vanDijk@sara.nl
 */
public class EpicHandleResolver extends net.handle.hdllib.HandleResolver {

	@SuppressWarnings("unused")
	private static final Logger log = new Logger(EpicHandleResolver.class);

	private static final TimeZone UTC = TimeZone.getTimeZone("UTC");

	private static final EpicHandleResolver instance = new EpicHandleResolver();

	/**
	 * @return the single instance of the resolver
	 */
	public static EpicHandleResolver instance() {
		return instance;
	}

	/**
	 * Utility shortcut to
	 * <code>EpicHandleResolver.instance().resolveHandleValues(prfx + "/" + lid)</code>
	 * 
	 * @param prfx
	 *            handle's prefix (part before "/")
	 * @param lid
	 *            handle's local id (part after "/")
	 * @return resolved data
	 * 
	 * @see #resolveHandleValues(String)
	 */
	public static HandleValues resolve(String prfx, String lid) {
		return resolve(prfx + "/" + lid);
	}

	/**
	 * Utility shortcut to
	 * <code>EpicHandleResolver.instance().resolveHandleValues(pid)</code>
	 * 
	 * @param pid
	 *            handle to resolve
	 * @return resolved data
	 * 
	 * @see #resolveHandleValues(String)
	 */
	public static HandleValues resolve(String pid) {
		return instance().resolveHandleValues(pid);
	}

	private EpicHandleResolver() {
		super();

		/*
		 * If a client is behind a firewall [...] it would be best to set the
		 * preferred protocols to Interface.SP_HDL_TCP and Interface.SP_HDL_HTTP
		 * since the Interface.SP_HDL_UDP will probably just get blocked by
		 * firewalls and be a big waste of time.
		 */
		// disable UTP resolving
		super.setPreferredProtocols(new int[] { Interface.SP_HDL_TCP,
				Interface.SP_HDL_HTTP });

		// disable caching
		super.setCache(null);

		log.info("EpicHandleResolver", "Created EpicHandleResolver instance");
	}

	/**
	 * Resolves a handle and packs the result into a {@link HandleValues}
	 * object.
	 * 
	 * @param pid
	 *            handle to resolve
	 * @return resolved handle values or {@link HandleNotFoundException}
	 * 
	 * @see HandleResolver#resolveHandle(String)
	 */
	public HandleValues resolveHandleValues(String pid) {
		HandleValues value = new HandleValues();
		value.handle = pid;

		if (pid.startsWith("M")) {
			throw new BadHandleException("starts with 'M'", pid);
		}
		if (pid.startsWith("N")) {
			throw new RuntimeException("PID starts with 'N'");
		}

		Calendar startUTC = Calendar.getInstance(UTC);
		HandleValue handleValues[] = null;
		try {
			handleValues = super.resolveHandle(pid);
		} catch (HandleException e) {
			if (e.getCode() == HandleException.HANDLE_DOES_NOT_EXIST) {
				throw new HandleNotFoundException(pid);
			} else {
				log.error("resolveHandle(", pid + ")", e);
				throw new BadHandleException(e.getLocalizedMessage(), pid);
			}
		}
		Calendar endUTC = Calendar.getInstance(UTC);

		if (handleValues == null) {
			throw new BadHandleException("Handle resolves to null", pid);
		}

		for (HandleValue handleValue : handleValues) {
			value.add(handleValue);
		}
		if (value.isEmpty()) {
			log.info("resolveHandle(", pid + "): no values");
		}

		value.resolveSecs = (endUTC.getTimeInMillis() - startUTC
				.getTimeInMillis()) / 1000.0;
		value.when = endUTC;

		log.info("resolveHandle(", pid + ") took " + value.resolveSecs
				+ " secs");
		return value;
	}

}