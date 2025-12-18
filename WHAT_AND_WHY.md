# Wait a Min' why do you need property XYZ??
this is just a doc for max of what i need from the ysws db and why:

## Approved Projects table
### Email
Emails are used to matchup with hca login email. email is used since the ysws db doesnt store slack ids.
### Github username
This is for the api mostly as malteds code depended on this and still does.
### Country
Country is needed for the stats pages / endpoints + for the main page.
### YSWS Name - Lookup
im just extracting the ysws's name from this field.
### Approved at
Required for the main landing page, and stats page.
### Playable URL
The projects demo url, self explanitory.
### Code url
self explanitory
### Description
The description of the ship which is used in the landing
### Hours Spents
The hours logged in the ysws db, im pretty sure this is all public info to the user anyways due to hackatime.
### Override Hours spent
The hours added on or deducted, this is also public to the user via there ysws im highly sure.
### Archive - Live URL
the shipper (or any user really) should be able to see archived versions of the site, these urls do not contain any private info + some better archival features then other sites.
### Archive - Code URL
same as above but this will let you re clone repositories which can be really usefull incase of accidental code loss etc.
### Repo - Star Count
Used to check if it should show a button for checking the viral stats on a project. 
### Screenshot
required on landing + im pretty sure people would love to see the screenshots they submitted for there projects
### YSWS Project Mentions - Searches
The orpheus engine checks to see if a project is viral, where it goes, what happens with it, does it mention hackclub? etc, this data towards the person who shipped it can be very helpful in themself finding out where there project goes without having to pay extra or setup anything extra.

This field grabs the mentioned searches id's for later usage..

## YSWS Project Mentions
### Found Project Mentions
This is just to grab the ID's of the links to where the project has been spotted

## YSWS Project Mention Searches
### Source
Which social media or site type did it find this on!
### Date
The date this was found or the article date.
### Headline 
the headline / title on the site or article if present.
### URL
The actual url this was found on! nothing private here basically js a link from the internet.