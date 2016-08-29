<!---
	Name         : GoogleContactscfc
	Author       : Raymond Camden 
	Created      : 09/06/08
	Last Updated : 12/27/08
	History      : 
				 
TODO:
--->

<cfcomponent displayName="Google Contacts" hint="Interacts with the Google Contacts API" output="false" extends="base">

	<cfset variables.username = "">
				
	<cffunction name="init" access="public" returnType="GoogleContacts" output="false">
		<cfargument name="username" type="string" required="true" hint="Username">
		<cfargument name="password" type="string" required="true" hint="Password">
		<cfargument name="tzoffset" type="string" required="false" default="" hint="Timezone offset. Will default to system offset.">

		<!--- set up base defaults --->
		<cfset super.init(arguments.tzoffset)>
			
		<cfset getAuthCode(arguments.username,arguments.password,"camden-googlecontact-1.0","cp")>

		<cfset variables.username = arguments.username>

		<cfreturn this>
	</cffunction>

	<cffunction name="addContact" access="public" returnType="numeric" output="false" hint="Adds a contact.">
		<cfargument name="contact" type="Contact" required="true">
	</cffunction>
	
	<cffunction name="getContacts" access="public" returnType="struct" output="false" hint="Returns all the contacts for the user.">
		<cfargument name="max" type="numeric" required="false" default="999999" hint="Max number of contacts. Per Google's spec, we default to a super large value for all.">
		<cfargument name="start" type="numeric" required="false" default="1" hint="Starting value.">
		<cfargument name="group" type="string" required="false" hint="Filter to a group.">

		<cfset var getcontactsurl = "http://www.google.com/m8/feeds/contacts/#urlEncodedFormat(variables.username)#/full?max-results=#arguments.max#&start-index=#arguments.start#&v=2">
		<cfset var result = "">
		<cfset var conListXML = "">
		<cfset var numCons = 0>
		<cfset var x = "">
		<cfset var entry = "">
		<cfset var con = "">
		<cfset var y = "">
		<cfset var s = "">
		<cfset var sentry = "">
		<cfset var label = "">
		<cfset var a = "">
		<cfset var cons = arrayNew(1)>
		<cfset var finalResult = structNew()>
		
		<cfif structKeyExists(arguments, "group")>
			<cfset getcontactsurl = getcontactsurl & "&group=#urlEncodedFormat(arguments.group)#">
		</cfif>
			
		<cfhttp url="#getcontactsurl#" method="get" result="result">		
			<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
		</cfhttp>

		<cfif not result.responseheader.status_code is "200">
			<cfreturn finalResult>
		</cfif>
		
		<cfset conListXML = xmlParse(result.filecontent)>
		
		<cfif structKeyExists(conListXML.feed, "entry")>
			<cfset numCons = arrayLen(conListXML.feed.entry)>
		</cfif>
		
		<cfif structKeyExists(conListXML.feed, "openSearch:totalResults")>
			<cfset finalResult.totalContacts = conListXML.feed["openSearch:totalResults"].xmlText>
		<cfelse>
			<cfset finalResult.totalContacts = 0>
		</cfif>
		
		<cfloop index="x" from="1" to="#numCons#">
			<cfset entry = conListXML.feed.entry[x]>

			<cfset con = structNew()>
			<cfset con.id = listLast(entry.id.xmlText,"/")>
			<cfset con.updated = convertDate(entry.updated.xmltext, variables.tzoffset)>
			<cfset con.title = entry.title.xmlText>

			<!--- support multiple email addresses --->
			<cfset a = arrayNew(1)>
			<!--- this is a convenience key, i do this just for emails --->
			<cfset con.primaryemail = "">
			<cfif structKeyExists(entry, "gd:email")>					
					<cfloop index="y" from="1" to="#arrayLen(entry["gd:email"])#">
						<cfset sentry = entry["gd:email"][y]>
						<cfset s = structNew()>
						<!--- if no label, use the end of rel --->
						<cfif not structKeyExists(sentry.xmlAttributes,"label")>
							<cfset label = listLast(sentry.xmlAttributes.rel,"##")>
						<cfelse>
							<cfset label = sentry.xmlAttributes.label>
						</cfif>
						<cfset s.label = label>
													
						<cfset s.address = sentry.xmlAttributes.address>

						<cfif structKeyExists(sentry.xmlAttributes,"primary")>
							<cfset s.primary = sentry.xmlAttributes.primary>
							<cfset con.primaryemail = s.address>
						<cfelse>
							<cfset s.primary = false>
						</cfif>	
						<cfset arrayAppend(a, s)>						
					</cfloop>
				</cfif>
				<cfset con.email = a>

				<!--- support multiple IM networks --->
				<cfset a = arrayNew(1)>
				<cfif structKeyExists(entry, "gd:im")>
					<cfloop index="y" from="1" to="#arrayLen(entry["gd:im"])#">
						<cfset sentry = entry["gd:im"][y]>
						<cfset s = structNew()>
						<!--- if no label, use the end of rel --->
						<cfif not structKeyExists(sentry.xmlAttributes,"label")>
							<cfset label = listLast(sentry.xmlAttributes.rel,"##")>
						<cfelse>
							<cfset label = sentry.xmlAttributes.label>
						</cfif>
						<cfset s.label = label>
													
						<!--- protocal is the network, just get after # --->
						<cfset s.network  = listLast(sentry.xmlAttributes.protocol,"##")>
						<cfset s.address = sentry.xmlAttributes.address>
						<cfif structKeyExists(sentry.xmlAttributes,"primary")>
							<cfset s.primary = sentry.xmlAttributes.primary>
						<cfelse>
							<cfset s.primary = false>
						</cfif>	
						<cfset arrayAppend(a, s)>						
					</cfloop>
				</cfif>
				<cfset con.im = a>
				
				<!--- support multiple organizations --->
				<cfset a = arrayNew(1)>
				<cfif structKeyExists(entry, "gd:organization")>
					<cfloop index="y" from="1" to="#arrayLen(entry["gd:organization"])#">
						<cfset sentry = entry["gd:organization"][y]>
						<cfset s = structNew()>
	
						<!--- if no label, use the end of rel --->
						<cfif not structKeyExists(sentry.xmlAttributes,"label")>
							<cfset label = listLast(sentry.xmlAttributes.rel,"##")>
						<cfelse>
							<cfset label = sentry.xmlAttributes.label>
						</cfif>
						<cfset s.label = label>
						<cfif structKeyExists(sentry.xmlAttributes,"primary")>
							<cfset s.primary = sentry.xmlAttributes.primary>
						<cfelse>
							<cfset s.primary = false>
						</cfif>
						<cfif structKeyExists(sentry, "gd:orgName")>
							<cfset s.name = sentry["gd:orgName"].xmlText>
						</cfif>
						<cfif structKeyExists(sentry, "gd:orgTitle")>
							<cfset s.title = sentry["gd:orgTitle"].xmlText>
						</cfif>
						<cfset arrayAppend(a,s)>
					</cfloop>
				</cfif>
				<cfset con.organization = a>

				<!--- support multiple phones --->
				<cfset a = arrayNew(1)>
				<cfif structKeyExists(entry, "gd:phoneNumber")>
					<cfloop index="y" from="1" to="#arrayLen(entry["gd:phoneNumber"])#">
						<cfset sentry = entry["gd:phoneNumber"][y]>
						<cfset s = structNew()>
	
						<!--- if no label, use the end of rel --->
						<cfif not structKeyExists(sentry.xmlAttributes,"label")>
							<cfset label = listLast(sentry.xmlAttributes.rel,"##")>
						<cfelse>
							<cfset label = sentry.xmlAttributes.label>
						</cfif>
						<cfset s.label = label>
						<cfif structKeyExists(sentry.xmlAttributes,"primary")>
							<cfset s.primary = sentry.xmlAttributes.primary>
						<cfelse>
							<cfset s.primary = false>
						</cfif>
						<cfif structKeyExists(sentry.xmlAttributes,"uri")>
							<cfset s.uri = sentry.xmlAttributes.uri>
						<cfelse>
							<cfset s.uri = "">
						</cfif>
						<cfset s.number = sentry.xmlText>
						<cfset arrayAppend(a,s)>
					</cfloop>
				</cfif>
				<cfset con.phonenumber = a>

				<!--- support multiple addresses --->
				<cfset a = arrayNew(1)>
				<cfif structKeyExists(entry, "gd:postalAddress")>
					<cfloop index="y" from="1" to="#arrayLen(entry["gd:postalAddress"])#">
						<cfset sentry = entry["gd:postalAddress"][y]>
						<cfset s = structNew()>
	
						<!--- if no label, use the end of rel --->
						<cfif not structKeyExists(sentry.xmlAttributes,"label")>
							<cfset label = listLast(sentry.xmlAttributes.rel,"##")>
						<cfelse>
							<cfset label = sentry.xmlAttributes.label>
						</cfif>
						<cfset s.label = label>
						<cfif structKeyExists(sentry.xmlAttributes,"primary")>
							<cfset s.primary = sentry.xmlAttributes.primary>
						<cfelse>
							<cfset s.primary = false>
						</cfif>
						<cfset s.number = sentry.xmlText>
						<cfset arrayAppend(a,s)>
					</cfloop>
				</cfif>
				<cfset con.postalAddress = a>						

				<!--- support multiple groups --->
				<cfset a = arrayNew(1)>
				<cfif structKeyExists(entry, "gContact:groupMembershipInfo")>
					<cfloop index="y" from="1" to="#arrayLen(entry["gContact:groupMembershipInfo"])#">
						<cfset sentry = entry["gContact:groupMembershipInfo"][y]>
						<cfset s = structNew()>
						<cfset s.id = sentry.xmlAttributes.href>
						<cfset s.deleted = sentry.xmlAttributes.deleted>
						<cfset arrayAppend(a,s)>
					</cfloop>
				</cfif>
				<cfset con.groups = a>						
				
				<cfif structKeyExists(entry, "content")>
					<cfset con.content = entry.content.xmlText>
				<cfelse>
					<cfset con.content = "">
				</cfif>
			
				<!---<cfdump var="#con#"><cfdump var="#entry#"><cfabort>--->
				<cfset arrayAppend(cons, con)>
			</cfloop>
			<cfset finalResult.contacts = cons>
		
		<cfreturn finalResult>
	</cffunction>	

	<cffunction name="getGroups" access="public" returnType="struct" output="false" hint="Returns the contact groups.">
		<cfargument name="max" type="numeric" required="false" default="999999" hint="Max number of groups. Per Google's spec, we default to a super large value for all.">
		<cfargument name="start" type="numeric" required="false" default="1" hint="Starting value.">
		<cfset var getgroupsurl = "http://www.google.com/m8/feeds/groups/#urlEncodedFormat(variables.username)#/full?max-results=#arguments.max#&start-index=#arguments.start#&v=2">
	
		<cfset var result = "">
		<cfset var groupListXML = "">
		<cfset var numGroups = "0">
		<cfset var x = "">
		<cfset var group = "">
		<cfset var groups = arrayNew(1)>
		<cfset var entry = "">
		<cfset var finalResult = structNew()>
									
		<cfhttp url="#getgroupsurl#" method="get" result="result">		
			<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
		</cfhttp>

		<cfif not result.responseheader.status_code is "200">
			<cfreturn finalResult>
		</cfif>
		
		<cfset groupListXML = xmlParse(result.filecontent)>
		<cfif structKeyExists(groupListXML.feed, "entry")>
			<cfset numGroups = arrayLen(groupListXML.feed.entry)>
		</cfif>
		<cfif structKeyExists(groupListXML.feed, "openSearch:totalResults")>
			<cfset finalResult.totalGroups = groupListXML.feed["openSearch:totalResults"].xmlText>
		<cfelse>
			<cfset finalResult.totalGroups = 0>
		</cfif>
	
		<cfloop index="x" from="1" to="#numGroups#">
			<cfset entry = groupListXML.feed.entry[x]>
			<cfset group = structNew()>
			<cfset group.title = entry.title.xmlText>
			<cfset group.content = entry.content.xmlText>
			<cfset group.id = entry.id.xmlText>	
			<cfif structKeyExists(entry, "gd:deleted")>
				<cfset group.deleted = true>
			</cfif>
			<cfset arrayAppend(groups, group)>
		</cfloop>
		<cfset finalResult.groups = groups>
			
		<cfreturn finalResult> 
	</cffunction>
	
</cfcomponent>
