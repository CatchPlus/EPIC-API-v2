package org.sara.epic.servlets;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.ws.rs.core.HttpHeaders;

import org.sara.epic.utility.Logger;

public class ReplacedAcceptHeaderRequest extends HttpServletRequestWrapper {

	private static final String acceptHeaderName = HttpHeaders.ACCEPT;

	@SuppressWarnings("unused")
	private static final Logger log = new Logger(
			ReplacedAcceptHeaderRequest.class);

	private final String acceptHeaderValue;

	/**
	 * Utility constructor.
	 * 
	 * @param request
	 *            HttpServletRequest.
	 * @param acceptHeaderValue
	 *            value for replacement (<code>null</code> means delete header)
	 * @throws ServletException
	 */
	public ReplacedAcceptHeaderRequest(HttpServletRequest request,
			String acceptHeaderValue) throws ServletException {
		super(request);

		// make log show servlet
		log.setDetail(request.getServletPath());

		// check header value
		if (acceptHeaderValue == null) {
			throw new ServletException("null " + acceptHeaderName
					+ " header replacement");
		}
		if (acceptHeaderValue.trim().length() == 0) {
			throw new ServletException("empty " + acceptHeaderName
					+ " header replacement");
		}

		// store parameter
		this.acceptHeaderValue = acceptHeaderValue;

		log.info(this.getClass().getSimpleName(), "header [" + acceptHeaderName
				+ "] -> '" + this.acceptHeaderValue + "'");
	}

	@SuppressWarnings("rawtypes")
	@Override
	public Enumeration getHeaderNames() {
		List<String> newHeaderNames = new ArrayList<String>();
		Boolean isInOrig = false;

		// copy original header names
		Enumeration origHeaderNames = super.getHeaderNames();
		if (origHeaderNames != null) {
			while (origHeaderNames.hasMoreElements()) {
				String element = (String) origHeaderNames.nextElement();
				newHeaderNames.add(element);
				if (acceptHeaderName.equalsIgnoreCase(element)) {
					isInOrig = true;
				}
			}
		}

		// add Accept header if not already in there
		if (!isInOrig) {
			newHeaderNames.add(acceptHeaderName);
		}

		// done
		return Collections.enumeration(newHeaderNames);
	}

	@Override
	public String getHeader(String name) {
		if (acceptHeaderName.equalsIgnoreCase(name)) {
			/* header needs replacement: return substitute value */
			// log.info("getHeader(", name + "): substituting '" +
			// acceptHeaderValue + "'");
			return acceptHeaderValue;
		} else {
			/* header does not need replacement: return original value */
			return super.getHeader(name);
		}
	}

	@SuppressWarnings("rawtypes")
	@Override
	public Enumeration getHeaders(String name) {
		if (acceptHeaderName.equalsIgnoreCase(name)) {
			/* header needs replacement: return substitute value */
			// log.info("getHeaders(", name + "): substituting '" +
			// acceptHeaderValue + "'");
			return Collections.enumeration(Arrays
					.asList(new String[] { acceptHeaderValue }));
		} else {
			/* header does not need replacement: return original value */
			return super.getHeaders(name);
		}
	}
}