package org.sara.epic.servlets;

import java.security.Principal;
import java.util.Enumeration;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.SecurityContext;
import javax.ws.rs.core.UriInfo;

import org.sara.epic.utility.Logger;
import org.sara.epic.xml.EmptyHandleException;
import org.sara.epic.xml.EpicHandleResolver;
import org.sara.epic.xml.HandleValues;

import com.sun.jersey.api.provider.jaxb.XmlHeader;

/**
 * Servlet for .../NAs/
 */

@Path("/")
public class NAs {

	/**
	 * The (relative location of the styles heet
	 * 
	 * FIXME: how do I associate an external URL with the styles heet?
	 */
	private static final String STYLESHEET_LOCATION = "/epic/handle.xsl";

	/**
	 * The style sheet header
	 */
	private static final String STYLESHEET_HEADER = "<?xml-stylesheet type='text/xsl' href='"
			+ STYLESHEET_LOCATION + "' ?>";

	@SuppressWarnings("unused")
	private static final Logger log = new Logger(NAs.class);

	public NAs() {
		// nothing to do
	}

	@GET
	// Path: root only
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })
	@XmlHeader(STYLESHEET_HEADER)
	public HandleValues getNone( //
			@DefaultValue("") @QueryParam("prfx") String prfx, //
			@DefaultValue("") @QueryParam("lid") String lid, //
			@Context HttpServletRequest request, //
			@Context UriInfo ui) {
		return resolve(prfx, lid, ui, request);
	}

	@GET
	@Path("{prfx}")
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })
	@XmlHeader(STYLESHEET_HEADER)
	public HandleValues getPrfx(
			//
			@PathParam("prfx") String prfx, //
			@DefaultValue("") @QueryParam("lid") String lid,
			@Context HttpServletRequest request, //
			@Context UriInfo ui) {
		return resolve(prfx, lid, ui, request);
	}

	@GET
	@Path("{prfx}/{lid:.+}")
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })
	@XmlHeader(STYLESHEET_HEADER)
	public HandleValues getPrfxLid( //
			@PathParam("prfx") String prfx, //
			@PathParam("lid") String lid, //
			@Context HttpServletRequest request, //
			@Context SecurityContext security, //
			@Context UriInfo ui) {
		return resolve(prfx, lid, ui, request);
	}

	private HandleValues resolve(String prfx, String lid, UriInfo ui,
			HttpServletRequest request) {
		if (prfx == null || prfx.trim().length() == 0) {
			throw new EmptyHandleException();
		}
		if (lid == null || lid.trim().length() == 0) {
			throw new EmptyHandleException(prfx);
		}

		// TODO: check and sanitize tainted user input

		final String pid = prfx + "/" + lid;

		log.info("resolve(", pid + ", " + ui.getRequestUri().toString() + ")");
		for (@SuppressWarnings("unchecked")
		Enumeration<String> names = request.getAttributeNames(); names
				.hasMoreElements();) {
			String name = names.nextElement();
			log.info("resolve",
					"attr " + name + ": "
							+ request.getAttribute(name).toString());
		}
		log.info("resolve", "secure: " + request.isSecure());
		Principal userPrincipal = request.getUserPrincipal();
		if (userPrincipal == null) {
			log.info("resolve", "not authenticated");
		} else {
			log.info("resolve", "user: " + userPrincipal.getName());
		}

		return EpicHandleResolver.resolve(pid);
	}
}
