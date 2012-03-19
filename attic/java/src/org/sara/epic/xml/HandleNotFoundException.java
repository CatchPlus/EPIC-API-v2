package org.sara.epic.xml;

public class HandleNotFoundException extends BadHandleException {

	private static final long serialVersionUID = -7854669826762653757L;

	public HandleNotFoundException(String pid) {
		super("Handle not found", pid);
	}

}
