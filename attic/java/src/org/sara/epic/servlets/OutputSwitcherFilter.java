package org.sara.epic.servlets;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.ws.rs.core.HttpHeaders;

import org.sara.epic.utility.Logger;

public class OutputSwitcherFilter implements Filter {

	private static final String acceptParameterName = HttpHeaders.ACCEPT;

	@SuppressWarnings("unused")
	private static final String acceptHeaderName = HttpHeaders.ACCEPT;

	@SuppressWarnings("unused")
	private static final Logger log = new Logger(OutputSwitcherFilter.class);

	private String acceptParameterValue = null;

	public OutputSwitcherFilter() {
		super();
		// postpone initialization to init()
	}

	@Override
	public void init(FilterConfig filterConfig) throws ServletException {
		// initialize this filter (allocate resources)

		// make logging show filter name
		log.setDetail("[" + filterConfig.getFilterName() + "]");

		acceptParameterValue = filterConfig
				.getInitParameter(acceptParameterName);
		if (acceptParameterValue == null) {
			acceptParameterValue = filterConfig
					.getInitParameter(acceptParameterName.toLowerCase());
			if (acceptParameterValue != null) {
				log.info(
						"init",
						"use of param-name '"
								+ acceptParameterName.toLowerCase()
								+ "' deprecated, please use '"
								+ acceptParameterName + "' instead");
			}
		}

		if (acceptParameterValue == null) {
			throw new ServletException("parameter " + acceptParameterName
					+ " not set");
		}

		log.info("init", "parameter " + acceptParameterName + ": '"
				+ acceptParameterValue + "'");
	}

	@Override
	public void destroy() {
		// clean up resources
	}

	@Override
	public void doFilter(ServletRequest request, ServletResponse response,
			FilterChain chain) throws IOException, ServletException {
		/*
		 * 1. Examine the request
		 */
		if (!(request instanceof HttpServletRequest && response instanceof HttpServletResponse)) {
			log.info("doFilter(", request.getClass().getName() + ", "
					+ response.getClass().getName() + "): not HTTP");
			chain.doFilter(request, response);
			return;
		}
		HttpServletRequest httpReq = (HttpServletRequest) request;

		// HttpServletResponse httpResp = (HttpServletResponse) response;
		// log.info("doFilter(", httpReq.getClass().getName() + ", "
		// + httpResp.getClass().getName() + ")");
		// log.info("doFilter", "pathInfo='" + httpReq.getPathInfo() + "'");

		// for (@SuppressWarnings("unchecked")
		// Enumeration<String> acceptHeaders = httpReq
		// .getHeaders(acceptHeaderName); acceptHeaders.hasMoreElements();) {
		// log.info("doFilter", "old header " + acceptHeaderName + ": "
		// + acceptHeaders.nextElement());
		// }

		/*
		 * 2. Optionally wrap the request object with a custom implementation to
		 * filter content or headers for input filtering
		 */
		ReplacedAcceptHeaderRequest wrappedRequest = new ReplacedAcceptHeaderRequest(
				httpReq, acceptParameterValue);

		// for (@SuppressWarnings("unchecked")
		// Enumeration<String> acceptHeaders = wrappedRequest
		// .getHeaders(acceptHeaderName); acceptHeaders.hasMoreElements();) {
		// log.info("doFilter", "new header " + acceptHeaderName + ": "
		// + acceptHeaders.nextElement());
		// }

		/*
		 * 3. Optionally wrap the response object with a custom implementation
		 * to filter content or headers for output filtering
		 */

		/*
		 * 4. invoke the next entity in the chain using the FilterChain object
		 * (chain.doFilter()),
		 */
		chain.doFilter(wrappedRequest, response);

		/*
		 * 5. Directly set headers on the response after invocation of the next
		 * entity in the filter chain.
		 */
	}
}
