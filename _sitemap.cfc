<!---
	Sitemap 1.1
	@description:
		Spider to create site navigation tree in query format or xml google sitemap format.
	@author:
		merlinox
	@project site: http://googlesitemapxmlgenerator.riaforge.org/
	@dateLastMod:
		1.4 - 2007/09/08
			 Added MSN to pinging
			 Added XML Validation Results against www.w3.org
		1.3 - 2007/09/05
			 Added a submitting sitemap.xml pinging function for Yahoo, Google, and Ask.
			 Updated the sitemap protocal and made sure the xml validates
		1.2 - 2006/07/11
			insertion of the title it of the page in the xml of the contents
		1.1 - 2006/01/30
			modernization of the script of analysis to the aim to before analyze to all link the first page
then the below pages
		1.0 - 2006/01/27
 --->

<cfcomponent>
	<cfprocessingdirective pageencoding="UTF-8">

	<cffunction access="private" name="scan" output="false" returntype="any" description="
		Scan page and extract all html link (<a href=""..."" ...>...</a>)
		">
		<cfargument name="root" required="yes" type="string" hint="Root of analyzed site: http + domain + path (es.: http://www.example.com/site1/page)">
		<cfargument name="url" required="yes" type="string" hint="Start page of site (es.: index.cfm)">
		<cfargument name="depth" required="yes" type="numeric" hint="Click number (depth) of the page from start page">

		<!--- local variables --->
		<cfset var reg="<a [^>]*href=""([^""]+)""[^>]*>">
		<cfset var res="">
		<cfset var rootTmp="">
		<cfset var text="">
		<cfset var link="">
		<cfset var temp="">
		<cfset var levelNew = depth + 1>
		<cfset var startPos=0>
		<cfset var qry_insert="">
		<cfset var qry_update="">
		<cfset var qry_check="">

		<!--- verify of path syntax. if wrong it repairs it --->
		<cfif (root is not "") and (right(root,1) is not "/") and (left(url,1) is not "/")>
			<cfset rootTmp = root & "/">
		<cfelse>
			<cfset rootTmp = root>
		</cfif>

		<cftry>
			<cfhttp url="#rootTmp##url#"></cfhttp>
			<cfset text=cfhttp.FileContent>
			<cfcatch>
				<!--- scan wrong --->
				<cfset registro=registro & rootTmp & " - " & depth & " - " & "<b>lettura fallita</b><br>">
				<cfreturn>
			</cfcatch>
		</cftry>
		<cfset registro=registro & "<br>">

		<!---  verify if page is indexable --->
		<cfif text contains "<noindex>">
			<cfreturn>
		</cfif>

		<!--- set page checked on result query (remove it from memory query and create new one checked) --->
		<cfquery name="qry_pageList" dbtype="query">
			SELECT *
			FROM qry_pageList
			WHERE page<>'#url#'
		</cfquery>
		<cfset temp=queryAddRow(qry_pageList)>
		<cfset temp=querySetCell(qry_pageList,"page",url)>
		<cfset temp=querySetCell(qry_pageList,"depth",depth)>
		<cfset temp=querySetCell(qry_pageList,"analyzed",1)>

		<!--- search all matches (link) with regular expression and save them on result query --->
		<cfloop condition="true">
			<!--- search match --->
			<cfset res=REFindNoCase(reg,text,startPos,true)>
			<cfif res.pos[1] is 0>
				<!--- noone --->
				<cfreturn>
			<cfelse>
				<!--- search link and saves match on temp variables --->
				<cfset startPos = res.pos[1] + res.len[1]>
				<cfset link= mid(text,res.pos[2],res.len[2])>
				<!--- se il link è senza il nome della pagina, lo aggiungo --->
				<cfif left(link,1) is "?">
					<cfset link = url & link>
				</cfif>
			</cfif>

			<!--- save page if doesn't still exist --->
			<cfquery name="qry_check" dbtype="query">
				SELECT *
				FROM qry_pageList
				WHERE page = '#link#'
			</cfquery>
			<cfif qry_check.recordCount is 0>
				<cfif 	(len(link) gt 5) and
						(link does not contain "://") and
						(link does not contain "mailto:") and
						(link does not contain "javascript:") >

					<!--- sava match --->
					<cfif 	not (right(link,4) is ".pdf" OR
							right(link,4) is ".doc" OR
							right(link,4) is ".xls" OR
							right(link,4) is ".doc" OR
							right(link,4) is ".txt")>
						<cfset temp=queryAddRow(qry_pageList)>
						<cfset temp=querySetCell(qry_pageList,"page",link)>
						<cfset temp=querySetCell(qry_pageList,"depth",levelNew)>
						<cfset temp=querySetCell(qry_pageList,"analyzed",0)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>

	<!--- cerco links --->
	<cffunction access="remote" name="sitemap" output="true" returntype="query" description="
		Start spider to scan all pages from start page
		to all link reachable with *depthMax* click number
		">
		<cfargument name="root" required="yes" type="string" hint="Root of analyzed site: http + domain + path (es.: http://www.example.com/site1/page)">
		<cfargument name="url" required="yes" type="string" hint="Start page of site (es.: index.cfm)">
		<cfargument name="depthMax" required="yes" type="numeric" hint="Max click number (depth) of the page from start page">

		<!--- regular exprezzion --->
		<cfset var reg="<a [^>]*href=""([^""]+)""[^>]*>">

		<!--- local variables --->
		<cfset var temp="">
		<cfset var qry_root="">
		<cfset var qry_cerca="">
		<cfset var depth=0>

		<!--- algorith registry --->
		<cfset registro="">

		<!--- result query creation --->
		<cfset qry_pageList=queryNew("page,depth,analyzed","VarChar,Integer,Bit")>

		<!--- insert root on result query (not analyzed) --->
		<cfset temp=queryAddRow(qry_pageList)>
		<cfset temp=querySetCell(qry_pageList,"page",url)>
		<cfset temp=querySetCell(qry_pageList,"depth",0)>
		<cfset temp=querySetCell(qry_pageList,"analyzed",0)>

		<cfset registro=registro & "<h3>Inizio scansione</h3>">

		<!--- start spider scan (loop since depth less then depthMax) --->
		<cfloop condition="depth lt depthMax">

			<!--- load scannable pages --->
			<cfquery name="qry_cerca" dbtype="query">
			SELECT *
			FROM qry_pageList
			WHERE analyzed=0
			</cfquery>

			<!--- start page scan --->
			<cfloop query="qry_cerca">
				<cfset registro=registro & root & " - " & page & " - " & depth & " - ">
				<cfset temp=scan(root,page,depth,indexIt)>
			</cfloop>

			<!--- depth increment --->
			<cfset depth=depth+1>
		</cfloop>

		<cfreturn qry_pageList>
	</cffunction>

	<cffunction name="googleSitemap" access="remote" output="true" description="
		Google Sitemap Creation from sitemap result query
		Page who called ""googleSitemap"" functon may prepend:
			<cfcontent type=""text/xml; charset=UTF-8"">
		">
		<cfargument name="query" required="yes" type="query" hint="Result query: it needs ""page"" data column">
		<cfargument name="root" required="yes" type="string" hint="Root of analyzed site: http + domain + path (es.: http://www.example.com/site1/page)">
		<cfset var qry_view="">

		<!--- build sitemap xml --->
		<cfquery name="qry_view" dbtype="query">
			SELECT *
			FROM query
			ORDER BY depth
		</cfquery>

		<cfsavecontent variable="sitemap">
		<cfoutput><?xml version="1.0" encoding="UTF-8" ?>
		<urlset
      xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
            http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
		<cfloop query="qry_view"><url>
		<loc>#root#/#replace(page,'&','&amp;',"all")#</loc>
		<changefreq>daily</changefreq>
		<priority>0.5</priority>
		</url>
		</cfloop></urlset></cfoutput>
		</cfsavecontent>

		<cfreturn sitemap>
	</cffunction>

	<cffunction name="indexIt" access="remote" output="false" description="
	Spider who builds query with pages name and all texts in plain/text format
	starting from navigation tree query (page column)
	Result query may insert on a verity collection to create search engine data source
	">
		<cfargument name="root" required="yes" type="string" hint="Root of analyzed site: http + domain + path (es.: http://www.example.com/site1/page)">
		<cfargument name="query" required="yes" type="query" hint="Result query: it needs ""page"" data column">
		<cfargument name="maxrows" required="no" type="numeric" default="500" hint="Max number of indexed pages">

		<cfset var date=now()>
		<cfset var pagine="">
		<cfset var qry_indice = QueryNew("date, page, text, titleS") >
		<cfset var i=1>
		<cfset var text="">
		<cfset var tmp="">

		<cfloop query="query" startrow="1" endrow="#maxrows#">
			<!--- verify of path syntax. if wrong it repairs it --->
			<cfif (root is not "") and (right(root,1) is not "/") and (left(page,1) is not "/")>
				<cfset rootTmp = root & "/">
			<cfelse>
				<cfset rootTmp = root>
			</cfif>

			<!--- load page contents --->
			<cfif findNoCase("?",page) gt 0>
				<cfset pageTmp = page & "&debug=false">
			<cfelse>
				<cfset pageTmp = page & "?debug=false">
			</cfif>
			<cfhttp url="#rootTmp##pageTmp#"></cfhttp>
			<cfset text=cfhttp.FileContent>
			<cfif cfhttp.errorDetail is "">
				<!--- rewrite title appending variable --->
				<cfset temp=ReFindNoCase("<title>(.*)</title>",text,1,true)>
				<!--- check if some occurence exist --->
				<cfif isDefined("temp.len") and temp.len[1] gt 0>
					<cfset titleS=mid(text,temp.pos[2],temp.len[2])>
				<cfelse>
					<cfset titleS="">
				</cfif>

				<!--- remove comment head & script tags --->
				<cfset text=ReReplaceNoCase(text, "<head>.*</head>","","all")>
				<cfset text=ReReplaceNoCase(text, "<script>.*</script>","","all")>

				<!--- remove html tags --->
				<cfset text=ReReplaceNoCase(text, "<[^>]*>", "", "ALL")>

				<!--- result query building --->
				<cfset temp = QueryAddRow(qry_indice)>
				<cfset temp = QuerySetCell(qry_indice,"date",date)>
				<cfset temp = QuerySetCell(qry_indice,"page",page)>
				<cfset temp = QuerySetCell(qry_indice,"text",text)>
				<cfset temp = QuerySetCell(qry_indice,"titleS",titleS)>
			</cfif>
		</cfloop>

		<cfreturn qry_indice>
	</cffunction>
	<cffunction name="submitSitemap" access="remote" output="false" description="
	Submits sitemap.xml to Ask.com, Google, and Yahoo
	">
		<cfargument name="url" required="yes" type="string" hint="Location of sitemap.xml (es.: http://www.domain.com/sitemap.xml)">
		<!--- Ask.com --->
		<cfhttp url="http://submissions.ask.com/ping?sitemap=#urlencodedformat(url, "utf-8")#" >
		<!--- Google --->
		<cfhttp url="http://www.google.com/webmasters/sitemaps/ping?sitemap=#urlencodedformat(url, "utf-8")#">
		<!--- Yahoo --->
		<cfhttp url="http://search.yahooapis.com/SiteExplorerService/V1/updateNotification?appid=YahooDemo&url=#url#">
		<!--- MSN (moreover.com for inclusion within the MSN Content Search)--->
		<cfhttp url="http://api.moreover.com/ping?u=#url#">
	</cffunction>
	
		<cffunction name="validateSitemap" access="remote" output="false" description="
	XML Validation Results against www.w3.org
	">
		<cfargument name="url" required="yes" type="string" hint="Location of sitemap.xml (es.: http://www.domain.com/sitemap.xml)">
		<cfset errorMessage = "No Errors with sitemap.xml Validation">
		<!--- w3.org --->
		<cfhttp url="http://www.w3.org/2001/03/webdata/xsv?docAddrs=#urlencodedformat(url, "utf-8")#&warnings=on&keepGoing=on&style=xsl##" result="pageResult">
		
		<cfif pageResult.FileContent contains (de('schemaErrors="0"'))>
			<cfset errorMessage = "No schema-validity error">
		</cfif>
		
		<cfif pageResult.FileContent contains (de('instanceErrors="0"'))>
			<cfset errorMessage = "">
		</cfif>
		
		<cfif pageResult.FileContent contains (de('outcome="success"'))>
			<cfset errorMessage = "Attempt to load a schema document failed">
		</cfif>
		
		<cfreturn errorMessage>
		</cffunction>
</cfcomponent>

