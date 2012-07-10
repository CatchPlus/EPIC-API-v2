EPIC Web Service API Definition
===============================
    Copyright: © 2009-2011 SARA Computing and Networking Services
      License: Creative Commons Attribution - Share Alike 3.0 Unported
       Status: Draft
      Version: 0.7
      Authors: Pieter van Beek, SARA
               Eric Auer, MPI Nijmegen
               Hennie Brugman, Meertens Instituut

Abstract
--------
This document proposes a common interface for RESTful web service implementations (simply called "the interface" or "the API" hereafter) built around the Handle System. `TODO @Hennie: complete this abstract. -PieterB`

Introduction
------------
`TODO: @Hennie: introductie -PieterB`

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).

This document describes a [RESTful](http://portal.acm.org/citation.cfm?id=932295) web service, using the [HTTP/1.1](http://tools.ietf.org/html/rfc2616) application protocol. The API strictly adheres to the rules of safety and idempotence laid out in §9.1 of [RFC2616](http://tools.ietf.org/html/rfc2616): GET is guaranteed to be both safe and idempotent; PUT and DELETE are idempotent, but not safe; POST is neither safe nor idempotent. Extension "POE" offers a method to circumvent the non-idempotence of the POST method.

### Glossary
For clarity end brevity, some terms in this document have a very specific meaning:

**the API:** the Application Programming Interface laid out in this document  
**server, implementation:** an implementation of the API  
**implementor:** an entity that builds an implementation the API  
**(service) provider:** an organisation or person that operates a server as a service  
**client:** a piece of software that interacts with a server using the API  
**user:** an organisation or person that operates a client

Representation
--------------
[JSON](http://www.json.org/) was chosen as the primary representation of resources, that all servers MUST be able to produce and consume. Implementations may, however, be able to produce and consume more than one representation of a resource. Servers MAY be able to produce and consume additional representations, like [XML](http://www.w3.org/TR/2008/REC-xml-20081126/) or DER-encoded [ASN.1](http://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One). In order to promote interoperability, implementors SHOULD publish additional representations in extension documents as explained below. This document defines one additional representations: [XHTML](http://www.w3.org/TR/xhtml1).

In order to promote consistency between representations and implementations, this paragraph contains three sections:

1.  **Atomic Types** describes a set of simple atomic types that can be composed into more complex data structures.

2.  **JSON representations** describes the way in which the atomic types are to be represented in JSON.

3.  **Abstract Data Model** describes the complete data model of the service, in terms of atomic types.

### Abstract Types
The following abstract types are used in the remainder of this document:

**object:** an unordered set of **string**→**value**-pairs with unique **strings**.  
**value:** an **object, list, string, blob** or **number.**  
**list:** an unordered list of **values.**  
**string:** a sequence of zero or more Unicode characters.  
**blob:** a sequence of octets.  
**number:** a signed integer. Servers SHOULD support infinitely large integers. Servers MUST support 64-bit signed integers from ­–2<sup>63</sup> to 2<sup>63</sup>–1 inclusive.  

Extensions defining additional abstract types MUST specify how these types are represented in various representational formats defined in this document and registered extensions. `Or should extension just restrict themselves to these abstract types? ––PieterB 2012/02/20`

### JSON Representation
This API uses JSON as the primary exchange format. All implementations MUST be able to produce and consume JSON.

Representation of the atomic types is as follows:

<table>
<tr><th>Atomic type</th><th>Representation in JSON</th></tr>
<tr><th>string</th><td>JSON string:<pre>"¡Holá!"</pre></td></tr>
<tr><th>blob</th><td>JSON string, containing the octet stream in <a href="http://tools.ietf.org/html/rfc4648">base64-encoded</a> form:<pre>"SGVsbG8gd29ybGQh"</pre></td></tr>
<tr><th>number</th><td>JSON number:<pre>-42</pre></td></tr>
<tr><th>list</th><td>JSON array:<pre>[ "¡Holá!", "SGVsbG8gd29ybGQh", -42 ]</pre></td></tr>
<tr><th>object</th><td>JSON object:<pre>{
  "Grüße" : "¡Holá!",
  "data?" : "SGVsbG8gd29ybGQh",
  "number": -42,
  "list"  : [ "¡Holá!", "SGVsbG8gd29ybGQh", -42 ]
}</pre></td></tr>
<tr><th>collection</th><td>JSON object. The index keys are pct-encoded if required, so they conform to the form <code>segment-nz</code> as defined in <a href="http://tools.ietf.org/html/rfc3986#section-3.3">section 3.3 of RFC3986</a>:<pre>{
  "Gr%C3%BC%C3%9Fe": "¡Holá!",
  "data%3F"        : "SGVsbG8gd29ybGQh"
}</pre></td></tr>
</table>

For compatibility with a broad range of clients, implementations are encouraged to support the unofficial MIME-type `application/x-json` as an equivalent alternative to the officially IANA-registered MIME-type `text/json`.

### XHTML Representation
Implementations are encouraged to produce [XHTML 1.0](http://www.w3.org/TR/xhtml1/).

Representation of the atomic types is as follows:

<table>
<tr><th>Atomic type</th><th>Representation in JSON</th></tr>
<tr><th>string</th><td>XML PCDATA or CDATA:<pre>Dr. Jekyll &amp;amp; Mr. Hyde
&lt;![CDATA[ if (a &lt; b &amp;&amp; a &lt; 0) a = b; ]]&gt;</pre></td></tr>
<tr><th>blob</th><td>XML PCDATA or CDATA, containing the octet stream in <a href="http://tools.ietf.org/html/rfc4648">base64-encoded</a> form:<pre>SGVsbG8gd29ybGQh</pre></td></tr>
<tr><th>number</th><td>XML PCDATA or CDATA with a text representation of the number:<pre>-42</pre></td></tr>
<tr><th>list</th><td>An XHTML unordered list:<pre>&lt;ul&gt;
  &lt;li&gt;¡Holá!&lt;/li&gt;
  &lt;li&gt;SGVsbG8gd29ybGQh&lt;/li&gt;
  &lt;li&gt;-42&lt;/li&gt;
&lt;/ul&gt;</pre></td></tr>
<tr><th>list of objects with<br/>equal key-sets</th><td>XHTML table:<pre>TODO</pre></td></tr>
<tr><th>object</th><td>TODO</td></tr>
<tr><th>collection of objects</th><td>TODO</td></tr>
<tr><th>collection of collections</th><td>TODO</td></tr>
</table>

Abstract Data Model
-------------------

**collection:** an unordered set of **string**→**resource**-pairs, with unique **strings**. See also the section on _Resource Collections_ below.  
**resource:** a **collection** or an **value.**  

Everything in this paragraph follows directly from [RFC3651](http://tools.ietf.org/html/rfc3651). It's only mentioned here for clarity, consistency and brevity in the remainder of this document.

### From [§2 of RFC3651](http://tools.ietf.org/html/rfc3651#section-2)

**naming-authority:**
a **string** consisting of dot-seperated substrings of any Unicode character except dot '.' or slash '/'.

**local-name:**
a **string** of Unicode characters.

**handle:**
a **string** consisting of a **naming-authority,** a slash “/”, and a **local-name.** See §2 of RFC3651 for the syntax and semantics of a **handle** and its parts.

Recent versions of the Handle System provide the possibility of Template Handles. Naming Authorities that use Template Handles must define a Template Delimiter Character for their namespace, which divides handles into a base part and an extension part. CNRI suggests the use of the at-sign "@" as Template Delimiter Character. `TODO This may no longer be accurate --Pieter van Beek 2012-02-09`

### From [§3.1 of RFC3651](http://tools.ietf.org/html/rfc3651#section-3.1)

**handle-value-set:**
a **collection** with the following members:

*   `values/`: a **collection** of **handle values,** indexed by the handle values' idx-member.
*   `handle`: (if applicable) the **handle** that references this **value set.**

Extensions may define additional members.

**value reference:**
a pointer to a Handle Value: a string consisting of the string representation of a non-negative number, a ':' character, and a **handle**. See §3 of RFC3651 for more information about **value references.**

### handle value
a **collection** with at least the following members:

* `type`: A **string** consisting of a dot "." separated list of strings of any unicode character except ".". Specifies the data type of member `data`.
* `data`: a **blob.**
Additionally, the following members MAY exist:

* `idx`: a positive number that specifies the unique index of this Handle Value within its Value Set.
* `ttl`: a number that specifies the Time-To- Live of the value record. A positive value defines the time to live in terms of seconds since 00:00:00 UTC, January 1st 1970. A negative value specifies the time to live in terms of the number of seconds elapsed since the value was obtained.
* `timestamp`: a number that records the last time this Handle Value was updated at the server. The field contains elapsed time since 00:00:00 UTC, January 1970 in milliseconds.
* `refs`: a list of references to other Handle Values.
* `parsed/`: depends on the value of type: by default, `parsed/` is unset. However, some of the pre-defined handle types are represented (in the Handle System) as a binary encoded structured value. In these cases, `parsed/` MUST contain a decoded representation of the structured value. In particular:
  * if type == "HS_VLIST", then `parsed/` contains a collection of references as described in §3.2.7 of RFC3651.
    * if a reference points to a Handle Value controlled by the server, then it's indexed by URIref.
    * otherwise, it's indexed by URI `http://hdl.handle.net/«handle»?index=«idx»`
  * if `type == "10320/loc"`, then parsed/ contains a collection with the following members (see 10320/loc for details):
    * `chooseby`: (optional) a list of strings. Defaults to ["locatt","country","weighted"] when omitted.
    * `locations/`: a collection of the following members, indexed by href, URI-escaped as explained in section NamingAuthorities and Suffixes in Path Segments:
      * `href`:  a URI.
      * `weight` (optional): a number.
      * `...`: type string: any other attributes of the <location/> element, if present.
    * `...`: type string: other attributes (unescaped) of the <locations/> element, if present.
  * other Handle Value Types (if not hidden by the server) such as HS_SITE, HS_PUBKEY, HS_SECKEY and HS_SERV MUST have decoded representations as well.

Extensions may define additional members.

The Handle System comes with its own authorization scheme. Services which do not respect this scheme SHOULD NOT relay any Handle Values or other information related to this scheme, such as HS_ADMIN values or the <permission> bit-mask described in §3.1 of RFC3651. Services which do respect the native Handle System authorization scheme SHOULD implement Extension 1.

Multistatus
-----------
`Iets over multipart/mixed for returning multiple statuses. -Pieter van Beek 10/25/11 11:30 AM`

`Iets over batch operaties, waarvoor ze wel en niet bedoeld zijn, alternatieven, usecases  -Pieter van Beek 2/3/11 4:28 PM`

This data type is only of importance to clients and servers that wish to use batch-wise operations which may affect multiple resources. In response to an HTTP-request that triggers such an operation, the server MUST respond with HTTP/1.1 207 Multistatus, and return a representation of a multistatus object, explaining which resources were affected and/or which errors occured. If an operation is defined as being atomic, and errors occur for some URIs targeted by the request, then the operation must fail entirely. Resources which failed to be affected because other resources failed to be affected within the same atomic request MUST fail with status HTTP/1.1 424 Failed Dependency as defined in [RFC4918](http://tools.ietf.org/html/rfc4918).

A **multistatus** is a **list** of **collections** with the following members:

* `baseuri`: (optional) the base **URIref** to be used when interpreting the URIrefs in member href. Normally, this is the URI of the resource that spawned the asynchronous process.
* `href`: a **list** of one or more **URIrefs** which have been affected by the operation.
* `status`: a **number:** the HTTP/1.1 status code returned by the resource(s) in `href`.
* `error`: (optional) a **list** of pre-defined error condition **strings**, specifying the error(s) that occured during processing, if any.
* `responsedescription`: (optional) a human-readable **string**, describing what happened.
* `location`: (optional, implies only one entry in `href`) the `Location:` response header that was returned by the one resource in `href`.

Those familiar with WebDAV will recognise the structure of an XML <multistatus/>-element as described in §13 of [RFC4918](http://tools.ietf.org/html/rfc4918).

### Example
The clients submit the following batch request, which should affect multiple resources:

    POST /NAs/10/handles/
    Host: example.com
    Content-Type: application/json
    ...
    
    [ { "handle" : "handleOne",
        "values/": { "1": { "type": "URL",
                            "data": "http://www.example.com" } } },
      { "handle" : "handleTwo",
        "values/": { "1": { "type": "URL",
                            "data": "http://mail.example.com" } } } ]
The clients wants to affect two handles, with local names "handleOne" and "handleTwo" respectively. The server supports atomic batch operations, and replies responds as follows:

    HTTP/1.1 207 Multistatus
    Content-Type: application/json
    ...
    
    [ { "href"  : "handleOne",
        "status": 403 },       /* HTTP/1.1 403 Forbidden */
      { "href"  : "handleTwo",
        "status": 424 } ]      /* HTTP/1.1 424 Failed Dependency */
For some reasen, the client didn't have permission to create/update the value set at `/NAs/10/handles/handleOne`. As a result, the resource at `/NAs/10/handles/handleOne` was unaffected as well, because the operation was defined as atomic.

Core API, Extensions and Representations
----------------------------------------
This document aims at defining an API that can be widely adopted. This implies fulfilling some conflicting demands. The API has to be complete enough to be usable by a wide variety of users, but also simple to implement, so that multiple implementations can and will coexist. The API must be extensible, allowing features to vary between implementations, serving particular user groups. Still, the API must guarantee a level of uniformity which allows easy migration between implementations.

To fulfill these demands, this document merely defines a _Core API_, which explicitly leaves room for functional _extensions_ and extra _representations_.

The **Core API** is the part of the API that all providers must implement. In other words, clients which restrict themselves to the Core API are guaranteed to be interoperable between implementations.

**Extensions** allow for extra, optional functionality. Our hope is that implementors will collaboratively define such API Extensions whenever they —otherwise independently— implement similar bits of additional functionality, thus enhancing compatibility between service providers.

**Representations** are extra resource representations supported by the service, in addition to the obligatory JSON representation. Servers may support these representations in HTTP/1.1 request bodies, response bodies, or both. For example, while JSON is commonly used in both request bodies and response bodies, the `application/xhtml+xml` data format is normally only used in response bodies, while the `application/x-www-form-urlencoded` format is normally only used in request bodies.

Core API
--------

### URI Space Overview

The service roughly consists of the following URI space:<!--┃┗┣━-->

    «root»/
    ┣━discovery/
    ┗━NAs
      ┗━«NAsegment»/
        ┣━handles/
        ┃ ┗━«LNsegment»/
        ┃   ┗━...
        ┣━profiles/
        ┃ ┗━«profile»
        ┣━status/
        ┃ ┗━«id»
        ┗━templator

The text below specifies the GET, PUT, POST and DELETE methods available per URI.

### Resource Collections
Within the service's hierarchical URI space, many resources are collections of other resources, like a _directory_ or _folder_. Such a container resource is represented by an unordered set of **URIref→value**-pairs called a **collection**.

`Meer uitleg, meer voorbeeldjes -Pieter van Beek 2/3/11 4:41 PM`  `Mention the slash as separator -Pieter van Beek 10/25/11 11:00 AM`

If the **URIref** in such a **URIref→value**-pair is a relative-ref as defined in §4.2 of [RFC3986], then it is relative (with decreasing precedence as per §14.14 of [RFC2616] and §5.1 of [RFC3986]) to:

*   in a nested **collection** (ie. a **collection** that is part of a **URIref→collection**-pair within a parent **collection**): the **URIref** by which the nested **collection** is indexed within its parent **collection**;
*   the **URIref** in the `Content-Location:` HTTP/1.1 response header
*   the request URI.

#### Request Depth

When performing a GET request on a resource **collection**, the user may specify an optional `Depth:` request header, specified in §10.2 of [RFC4918]. The value of this header is interpreted as follows:
*   `"0"`: unused
*   `"1"`: return the **collection**, with the value in each **URIref→value**-pair reduced to a "display name"-string, for example an unescaped version of the referring **URIref**.
*   `"infinity"`: return the **collection**, including all child **collections**, recursively, _ad infinitum_.

For all URIs, the default request depth is `"1"`, unless otherwise specified. Servers NEED NOT support all request depths on all URIs. In particular, servers need not support `Depth: infinity` on high-level **collections**, as this may generate a very large response.

#### Trailing slashes

Container resources have a trailing slash at the end of their (canonical) URIs. If the client accidentally omits this trailing slash, the server MUST do one of the following:

*   Respond as if the trailing slash were present, but with an additional `Content-Location:` response header, pointing to the correct URI. This is the prefered response, but it may cause problems with relative URIs in some web browsers that don't interpret the `Content-Location:` header, thus assuming the wrong base URI for the entity.
*   Respond with status `HTTP/1.1 301 Moved Permanently`, asking the client to resubmit the request to the correct URI. This is what `mod_dir` does in the Apache HTTP server.

### NamingAuthorities and Suffixes in Path Segments

The URI space of this web service uses Handle NamingAuthorities and suffixes as URI path segments. According to [RFC3651], these NamingAuthorities and suffixes consist of UTF-8 encoded strings of printable Unicode characters, while [RFC2396] and its successor [RFC3986] allow only the following ASCII characters in a path segment:

    "A"-"Z" | "a"-"z" | "0"-"9" |
    "-" | "." | "_" | "~" | "!" | "$" | "'" | "*" | "&" |
    "(" | ")" | ":" | "+" | "=" | "," | ";" | "@"

Therefore, all other octets must be percent-encoded as explained in §2.1 of [RFC3986]. For example, a space character (ASCII character 32 in decimal notation, or 20 in hexadecimal notation) must be encoded as `"%20"` in path segments.

For maximum compatibility, clients SHOULD also escape the `";"` character, because it has a special meaning in the (now obsolete) [RFC2396]. Servers SHOULD allow unescaped `";"` characters.

### «root»/
All URIs share some root, determined by the service provider, eg. `https://example.com/epic_web_service/`
*   `GET` SHOULD return a collection.  
    `Uitleg, voorbeeldje. Misschien alle collections -Pieter van Beek 2/3/11 4:41 PM`

### «root»/NAs/
*   `GET` returns a collection of all NamingAuthorities hosted by this web service, indexed by `«NAsegment»/`. For example:

        { "10574/" : "10574",
          "H%A4%C3ndel/" : "Händel" }

### «root»/NAs/«NAsegment»/
*   `GET` SHOULD return a collection.

### «root»/NAs/«NAsegment»/handles/
*   `GET`  
    Returns a collection of Handles indexed by `«LNsegment»/`, optionally filtered by the parameters below:
    *   Parameter `m_<TYPE>=«search_string»`: search string must match the Handle Value exactly;
    *   Parameter `w_<TYPE>=«search_string»`: search strings are treated as wildcards, with the following meta-characters:
        *   `'*'`: matches zero or more octets;
        *   `'_'`: matches exactly one octet;
        *   `'~'`: escape character. For example, to match any value with a literal asterisk, you should use wildcard string `"*~**"`.
    *   Parameter `r_<TYPE>=«search_string»`: search strings are treated as a [PCRE]. Providers NEED NOT implement this parameter.
    *   `<TYPE>` specifies which metadata field value(s) to match. If <TYPE> ends with a `'.'` character, then this is treated as explained in §3.2.1 of [RFC3652].
    *   If multiple search strings are specified, the intersection of all search results is returned (ie. the search strings are combined using a logical AND)

### «root»/NAs/«NAsegment»/handles/«LNsegment»/
*   `GET` Returns a Handle. The server SHOULD provide `Last-Modified:` and `ETag:` response headers.
This resource, and all its child-resources, have a default `Depth:` HTTP header value of `"infinity"`.
*   `PUT` Submits a Handle.
    *   To assert that no handle yet exists at this URI, the `If-None-Match: *` HTTP request header can be used as per §14.26 of [RFC2616].  
    *   To assert that a handle yet exists at this URI, the `If-Match: *` HTTP request header can be used as per §14.24 of [RFC2616].
*   `DELETE` Deletes the handle.
*   `POST` Accepts a Value Set which MUST NOT contain a handle member.
    *   In this case, the `«LNsegment»` is interpreted as a suffix template. A suffix template is a suffix containing exactly one unescaped `'*'` character. This character will be replaced with a unique string by the server, resulting in a new and unique handle. The `'~'` character serves as escape character. So a literal string `"*~"` must be escaped as `"~*~~"`.
    *   Creates a new handle with the provided metadata. An `HTTP/1.1 201 Created` status is returned upon success, with the location of the new resource in the `Location:` response header. The new handle is returned in an `X-Handle:` response header, encoded as per [RFC5987] if necessary.

This URI points to a Handle, which is of type **collection**. Each member of this collection has its own **URIref**, and therefore its own URI within the service's namespace. This document doesn't describe these URIs in further detail. In general, all these URIs SHOULD support the GET, PUT and DELETE methods.

### «root»/NAs/«NAsegment»/status/
The Core API itself doesn't include any asynchronous operations, but it does provide a framework for such operations, which can be used by extensions.

Whenever a request cannot be handled synchronously, the server MUST respond with an HTTP/1.1 202 Accepted status response, create a new "status resource", and return the URI of this resource in the Location: response header. The .../status/ resource is intended as the container for such status resources.

Since a new status resource is created for each asynchronous request, this request is neither safe nor idempotent. This means that methods GET, PUT and DELETE are excluded from asynchronous handling. Therefore, only POST requests MAY be handled asynchronously.

### «root»/NAs/«NAsegment»/status/«id»
A status resource, resulting from an asynchronous operation.

*   `GET`  
    Returns one of the following:

        *   HTTP/1.1 503 Service Unavailable, indicating that the asynchronous request hasn't yet been handled. Servers SHOULD return a Retry-After: response header.

        *   HTTP/1.1 404 Not Found or HTTP/1.1 410 Gone, indicating that the operation has finished, and the client already deleted the status resource.

        *   Any other response must be interpreted as if it were the response to the original POST request that initiated the asynchronous process.

    *   In this latter case, one status code is of special interest, especially to batch processes:

        *   `HTTP/1.1 207 Multi-Status` can be used if the processing affected multiple resources. The response body MUST contain either an XML-document as per §13 of [RFC4918], or a multistatus (eg. in [JSON] format), subject to content negotiation.

*   `DELETE`  
    Deletes the status resource.

Extensions
==========

Method Spoofing
---------------

The service allows users to use the HTTP/1.1 POST method instead of all other HTTP/1.1 methods, by specifying a `_method` query parameter in the request URI. Method spoofing is commonly used in the following cases:

1.  To perform HTTP/1.1 GET requests where the total length of all query parameters is too long to fit into a URI. Although there are no theoretical limits to the length of a URI, in practice many clients and servers have practical limits, often as small as 64k bytes.
2.  To perform any method, other than GET or POST, from within a browser. Unfortunately, most modern browsers only support the HTTP/1.1 GET and POST methods. So in order to DELETE a resource from within a browser (which is a perfectly reasonable use case), the request will have to be spoofed.
3. To perform any method, other than GET or POST, from behind a firewall that only allows GET and POST requests.

### Examples
The following two HTTP/1.1 requests are semantically identical:

    DELETE /some_resource HTTP/1.1
    Host: handle.sara.nl
    Date: Mon, 09 Sep 2008 08:17:35 GMT
<!---->

    POST /some_resource?_method=DELETE HTTP/1.1
    Host: handle.sara.nl
    Date: Mon, 09 Sep 2008 08:17:35 GMT
    Content-Length: 0
In XHTML, this request could be interfaced with a “delete button”, like this:

    <form action="/some_resource?_method=DELETE" method="post">
        <input type="submit" value="Delete some_resource"/> 
    </form>
If you spoof an HTTP/1.1 GET method, and the MIME type of the request body is `application/x-www-form-urlencoded`, then query parameters of the request body are treated as if they are “GET parameters”. For example, the following two HTTP/1.1 requests are semantically identical:

    GET /some_resource?param=value HTTP/1.1
    Host: topos.grid.sara.nl
    Date: Mon, 09 Sep 2008 08:17:35 GMT
<!---->

    POST /some_resource?_method=GET HTTP/1.1
    Host: topos.grid.sara.nl
    Date: Mon, 09 Sep 2008 08:17:35 GMT
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 11
    
    param=value

Header Spoofing
---------------

The service allows the user to pass HTTP/1.1 headers as query parameters. This is done to allow any kind of request from within a browser. This feature is provided strictly as a workaround for current web-browser limitations.  
To specify an HTTP/1.1 header as a query parameter:

1.  replace all dashes "-" in the header name by underscores "_";
2.  convert all characters in the header name to lowercase;
3.  prepend the header name with "\_http\_".

### Examples
The following two HTTP/1.1 requests are semantically identical:

    PUT /some_resource HTTP/1.1
    Host: handle.sara.nl
    Date: Mon, 09 Sep 2008 08:17:35 GMT
    If-None-Match: *
    ...
<!---->
    PUT /some_resource?_http_if_none_match=* HTTP/1.1
    Host: handle.sara.nl
    Date: Mon, 09 Sep 2008 08:17:35 GMT
    ...
Note how the `If-None-Match` header is specified as a query parameter in the second case.

POST-Once-Exactly
-----------------

The POST method is neither safe nor idempotent. This poses a problem to the client: if an HTTP-request from the client is not answered by a (correct) HTTP-response from the server, the client has no way to determine if the request processed successfully or not. To circumvent this limitation, server implementations are encouraged to implement POST-Once-Exactly [POE][].

<!--References-->
[RFC5987]: http://tools.ietf.org/html/rfc5987 "Character Set and Language Encoding for Hypertext Transfer Protocol (HTTP) Header Field Parameters"
[POE]: http://tools.ietf.org/html/draft-nottingham-http-poe-00 "POST Once Exactly (POE)"

