<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page isErrorPage="true" import="java.io.*"%>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>EPIC Error</title>
</head>
<body>
	<h1>EPIC Error</h1>
	<p>An error occurred while processing your request. This is a
		problem in the EPIC software, not your fault.</p>
	<p>We are sorry but do not have a solution for now.</p>
	<hr />
	<h2>Programmer information:</h2>
	<h3>Exception:</h3>
	(<%=exception.getClass().getName()%>) "<%=exception.getLocalizedMessage()%>"
	<%
		if (exception.getCause() != null) {
	%>
	<h3>Cause:</h3>
	<%=exception.getCause().getClass().getName()%>
	<%
		}
	%>
</body>
</html>