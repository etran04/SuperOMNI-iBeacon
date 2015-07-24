# SuperOMNI-iBeacon
Integrate iBeacons with HKWireless SDK in order to ultimately create "Follow Me Audio"

WORK IN PROGRESS
---------------

(Written in Objective C in this moment in time)

Terms used: 
<br>SuperOmni - Omni 10 with embedded iBeacon (Major: 1010, Minor: 1)
<br>SmartThings - Omni 20 with RFDuino acting as iBeacon beside it (Major: 1100, Minor: 1) 

Almost all of iBeacon functionality with HK speakers are written in RWTItemsViewController.m.

Currently the functionality of this application are:
<br> 1) Able to start wake up from sleep and start playing music when in 'Near' or 'Immediate' vicinity of either speakers. 
<br> 2) When 'Far', volume of associated speaker will drop to 0. 
<br> 3) Implemented a linear regression algorithm. Current taking a set of k data points to calculate a more accurate rssi value to base the new volume off of. Polls for one second after, creating a new best fit line to approximate the next volume level. 

Currently implementing and working on:
<br>1) Figuring out what initial volume would be best to start at.
<br>2) Need to figure out how to associated each iBeacon to a speaker, rather than hardcoding each iBeacon (UUID, major, minor) to a particular speaker name. 
<br>3) Linear regression algorithm can still be spotty through depending on the environment we're in. 
<br>4) In the first k seconds, we need to approximate the best volume to start playing at, rather than wait the entire k seconds. 

HOW TO USE
-----------
<br> 1) Turn on iOS app 'SuperOMNI'
<br> 2) Press the '+' sign at the top right hand corner. 
<br> 3) Input name, uuid, major, and minor value of beacons. 
<br> 2) Walk into "Near" or "Immediate" vicinity
<br> 3) Wait approximately k seconds until song starts playing

<br> After that, you should be able to walk around and volume should change accordingly. 

FAQs 
------------
Q. What speaker is connected to which beacon? 
The code currently is hardcoded to speakers with names "SuperOmni" and "SmartThings".
If it is named "SuperOmni", it has to have Harman's UUID, Major: 1010, and Minor: 1.
If it is named "SmartThings", it has to have Harman's UUID, Major: 1100, and Minor: 1. 

Q. How do I name my speaker? 
Use the HK page app to name them. (only need to do this if you're connecting the speaker to a new network ) 
