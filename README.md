# SuperOMNI-iBeacon
Integrate iBeacons with HKWireless SDK in order to ultimately create "Follow Me Audio"

WORK IN PROGRESS
---------------

(Written in Objective C in this moment in time)

Terms used: 
<br>SuperOmni - Omni 10 with embedded iBeacon
<br>SmartThings - Omni 20 near my desk with an Gimbal iBeacon near it 

Currently the functionality of this application are:
<br> 1) Able to start wake up from sleep and start playing music when in 'Near' or 'Immediate' vicinity of either speakers. 
<br> 2) When 'Far', volume of associated speaker will drop to 0. 
<br> 3) Implemented a linear regression algorithm. Current taking a set of k data points to calculate a more accurate rssi value to base the new volume off of. Polls for one second after, creating a new best fit line to approximate the next volume level. 

Currently implementing and working on:
<br>2) Figuring out what initial volume would be best to start at.
