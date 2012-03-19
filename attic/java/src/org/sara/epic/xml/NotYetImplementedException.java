package org.sara.epic.xml;

import javax.ws.rs.core.UriInfo;

import com.sun.jersey.api.NotFoundException;

public class NotYetImplementedException extends NotFoundException {

	private static final long serialVersionUID = -4748779669902763654L;

	public NotYetImplementedException(UriInfo ui) {
		this(ui.getRequestUri().toString());
	}

	public NotYetImplementedException(StringBuffer requestURL) {
		this(requestURL.toString());
	}

	public NotYetImplementedException(String requestURL) {
		super("Not yet implemented: " + requestURL);
	}

}
