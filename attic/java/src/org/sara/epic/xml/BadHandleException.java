package org.sara.epic.xml;

import com.sun.jersey.api.NotFoundException;

public class BadHandleException extends NotFoundException {

	private static final long serialVersionUID = -7854669826762653757L;

	private static final String DFLT_MSG = "Bad handle";

	private static final boolean cleanStack = true;

	public BadHandleException() {
		this(null);
	}

	public BadHandleException(String msg) {
		super(msg == null ? DFLT_MSG : msg);

		if (cleanStack) {
			setStackTrace(new StackTraceElement[] { new StackTraceElement("",
					"", "", 0) });
		}
	}

	public BadHandleException(String msg, String pid) {
		this((msg == null ? DFLT_MSG : msg) + ": '" + pid + "'");
	}

}
