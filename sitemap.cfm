	<cfset ini_root="http://www.example.com/machblog" />
	<cfset ini_startPage="index.cfm" />
	<cfset ini_levelMax=3 />
	<cfset ini_sitemap="http://www.example.com/sitemap.xml" />

	<cfinvoke component="example.path.to.cfc._sitemap" method="sitemap" returnvariable="qry_sitemap" root="#ini_root#" url="#ini_startPage#" depthMax="#ini_levelMax#">
	<cfinvoke component="example.path.to.cfc._sitemap" method="indexIt" returnvariable="qry_sitemapIndex" root="#ini_root#" query="#qry_sitemap#">
	<cfinvoke component="example.path.to.cfc._sitemap" method="googleSitemap" returnvariable="sitemap" root="#ini_root#" query="#qry_sitemap#">
	<cfinvoke component="example.path.to.cfc._sitemap" method="submitSitemap" url="#ini_sitemap#" returnvariable="qry_sitemap" >
	<cfinvoke component="example.path.to.cfc._sitemap" method="validateSitemap" url="#ini_sitemap#" returnvariable="pageResult" >
	
	<cffile
    action = "write"
    file = "C:\PHYSICAL\PATH_TO\sitemap.xml"
    output = "#sitemap#"
    addNewLine = "no"
    charset = "utf-8">
	
	<cfcontent type="text/xml" reset="Yes" /> <cfoutput>#pageResult#</cfoutput>
