package org.sara.epic.utility;

import java.util.logging.Level;

public class Logger {

	private static java.util.logging.Logger log;
	private String detail = "";

	public Logger(Class<?> clazz) {
		this(clazz, null);
	}

	public Logger(Class<?> clazz, String detail) {
		log = java.util.logging.Logger.getLogger(clazz.getName());
		this.setDetail(detail);
	}

	private StringBuilder getLead(String caller) {
		StringBuilder lead = new StringBuilder();
		if (!(detail == null || detail.length() == 0)) {
			lead.append(detail).append(" ");
		}
		if (!(caller == null || caller.length() == 0)) {
			lead.append(caller);
			if (!caller.endsWith("(")) {
				lead.append("(): ");
			}
		}
		return lead;
	}

	private String fmtMag(String caller, String msg) {
		return getLead(caller).append(msg).toString();
	}

	/**
	 * Logs an error line.
	 * 
	 * @param caller
	 *            acceptHeaderName of calling method -- if ends with '(', no
	 *            separator glue ("(): ") is inserted
	 * @param msg
	 *            the line to log
	 */
	public void error(String caller, String msg) {
		log.log(Level.SEVERE, fmtMag(caller, msg));
	}

	public void error(String caller, String msg, Throwable e) {
		log.log(Level.SEVERE, fmtMag(caller, msg), e);
	}

	/**
	 * Logs an info line.
	 * 
	 * @param caller
	 *            acceptHeaderName of calling method -- if ends with '(', no
	 *            separator glue ("(): ") is inserted
	 * @param msg
	 *            the line to log
	 */
	public void info(String caller, String msg) {
		log.log(Level.INFO, fmtMag(caller, msg));
	}

	public String getDetail() {
		return detail;
	}

	public void setDetail(String detail) {
		this.detail = detail;
	}

}
