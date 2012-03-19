package org.sara.epic.xml;

public class EmptyHandleException extends BadHandleException {

	private static final long serialVersionUID = -7854669826762653757L;

	public EmptyHandleException() {
		super("Empty handle");
	}

	public EmptyHandleException(String prfx) {
		super("Handle not prefix/localID", prfx);
	}

}
