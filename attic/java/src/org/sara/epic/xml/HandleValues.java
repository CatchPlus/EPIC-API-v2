package org.sara.epic.xml;

import java.util.Calendar;
import java.util.Iterator;

import javax.xml.bind.annotation.XmlRootElement;

import net.handle.hdllib.HandleValue;

import org.sara.epic.utility.Logger;

@XmlRootElement
public class HandleValues {

	/**
	 * The handle source.
	 */
	public String handle = null;

	/**
	 * the handle value (when resolved)
	 */
	public ValueSet value = null;

	/**
	 * time it took to resolve this handle (<code>0.0</code> means unknown)
	 */
	public double resolveSecs = 0.0;

	/**
	 * Time of resolving (approximate: plusminus {@link #resolveSecs}). May be
	 * <code>null</code> if resolve time is unknown.
	 * 
	 */
	public Calendar when = null;

	@SuppressWarnings("unused")
	private static final Logger log = new Logger(HandleValues.class);

	/**
	 * A no-arg default constructor is needed by JAXB.
	 */
	public HandleValues() {
		value = new ValueSet();
		// nothing to do
	}

	// Delegations:

	public boolean add(HandleValue handleValue) {
		return value.add(handleValue);
	}

	public Iterator<Value> iterator() {
		return value.iterator();
	}

	public boolean isEmpty() {
		return value.isEmpty();
	}

	public int size() {
		return value.size();
	}

}
