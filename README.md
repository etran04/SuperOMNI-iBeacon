# SuperOMNI-iBeacon
Integrate iBeacons with HKWireless SDK in order to ultimately create "Follow Me Audio"

WORK IN PROGRESS
---------------

(Written in Objective C in this moment of time)

Terms used: 
SuperOmni - Omni 10 with embedded iBeacon (courtesy of Kevin) 
SmartThings - Omni 20 near my desk with an Gimbal iBeacon near it 

Currently the functionality of this application are:
<br> 1) Able to start wake up from sleep and start playing music when in 'Near' or 'Immediate' vicinity of either speakers. 
<br> 2) When 'Far', volume of associated speaker will drop to 0. 

Currently implementing and working on:
<br>1) Linear Interpolation Algorithm - Smoothing out the gathered RSSI values from a set 
  and using that as a more accurate date value to adjust the volume of the speaker accordingly.
<br>2) Figuring out what initial volume would be best to start at.
