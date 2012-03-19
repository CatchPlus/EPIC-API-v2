package org.sara.epic.servlets;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.sara.epic.utility.Logger;

/**
 * Servlet for Not Yet Implemented pages
 */

public class NotYetImplemented extends HttpServlet {

	private static final long serialVersionUID = -6659042690162584751L;

	@SuppressWarnings("unused")
	private static final Logger log = new Logger(NotYetImplemented.class);

	public NotYetImplemented() {
		// nothing to do
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		resp.sendRedirect("/epic/NotYetImplemented.jsp?uri="
				+ req.getRequestURL().toString());
	}

}
