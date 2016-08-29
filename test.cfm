<!---
	To run this test, you must edit the username and password.
	You would also need to edit the ID in the group test.
--->
<cfapplication name="gContacts">

<cfset url.reinit = 1>	
<cfif not structKeyExists(application, "gContacts") or structKeyExists(url, "reinit")>
	<cfset application.gContacts = createObject("component", "GoogleContacts").init("myusername","mypassword")>
</cfif>

<cfset contacts = application.gContacts.getContacts(max=4,start=1)>
<cfdump var="#contacts#" label="Contacts" expand="true">	

<cfset contacts = application.gContacts.getContacts(max=4,start=1,group='somegroupid')>
<cfdump var="#contacts#" label="Contacts for one group" expand="true">	
	
<cfset groups = application.gContacts.getGroups()>
<cfdump var="#groups#" label="Groups">