<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="handleValues">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
				<link href="/epic/handle.css" rel="stylesheet" type="text/css" />
				<title>EPIC Handle resolve</title>
			</head>
			<body>
				<h1>EPIC Handle resolve</h1>
				<h3>
					Handle:
				</h3>
				<p>
					<span class="handle">
						<xsl:value-of select="handle" />
					</span>
				</p>
				<h3>Values:</h3>
				<table class="handle-values">
					<thead>
						<tr>
							<th class="handle-value-index">index</th>
							<th>type</th>
							<th>data</th>
						</tr>
					</thead>
					<tbody>
						<xsl:for-each select="value">
							<tr>
								<td class="handle-value-index">
									<xsl:value-of select="@idx" />
								</td>
								<td>
									<xsl:value-of select="type" />
								</td>
								<td>
									<pre class="handle-data">
										<xsl:value-of select="data" />
									</pre>
								</td>
							</tr>
						</xsl:for-each>
					</tbody>
				</table>
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>