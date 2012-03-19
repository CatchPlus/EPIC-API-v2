package org.sara.epic.xml;

import javax.xml.bind.annotation.XmlAttribute;

import net.handle.hdllib.HandleValue;

/**
 * 
 * @author Markus.vanDijk@sara.nl
 * 
 */
public class Value {

	@XmlAttribute
	public int idx;

	public String type;

	public String data;

	private String date;

	public Value() {
		// JAXB needs a no-arg default constructor.
	}

	public Value(HandleValue hv) {
		idx = hv.getIndex();
		type = hv.getTypeAsString();
		date = hv.getNicerTimestampAsString();
		data = hv.getDataAsString();
	}

	@Override
	public String toString() {
		return "[" + idx + "]{type=" + type + " date=" + date + " data=" + data
				+ "}";
	}

}