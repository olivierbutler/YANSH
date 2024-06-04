# YANSH Yet ANother Simbrief Helper
This plugins upload Simbrief OFP to Zibo's B738 FMC (formely Simbrief Helper Enh lua script)

### what new ?
1. the simbrief flight plan files ( .fms and .xml) are also
    downloaded in the X-plane "Output/FMS plans" folder.

    i.e flight from LFPO to DAAG : files LFPODAAG01.fms and
    LFPODAAG01.xml are downloaded in the X-plane "Output/FMS plans"
    folder.

    On native XP B737 or Zibo B737, while programming the FMC , the
    CO-ROUTE item can be populated with LFPODAAG01.

    On Zibo B737 RC5.2+:  b738x.fms and b738x.xml files are automatically downloaded, making the 'FLT PLAN REQUEST' and other 'UPLINK' features available.

    On Zibo B737, on DES page / forecast : the uplink button can be used
    to get the wind datas (only if the OFP **layout is LIDO**)
    
2. On the script window some datas are added
    - Warning if the OFP is older than 2 hours
    - the FMS CO-ROUTE name ( needed to program the FMC)
    - the Alternate fuel quantity
    - the Reserve + Alternate fuel quantity
    
3. YANSH displays updated METAR along your flight.
    - No registration needed
    - ~~- go to avwx.rest and register for free~~
    - ~~- get you own API token at the page account.avwx.rest/tokens~~
    - ~~- then paste in the YANSH's setup window~~
    - At any time METARs can be updated by clicking on the "Refresh Metar" button

4. Field of View angle keeper
    The Field of View angle (FoV) is a global setting of X-plane. This
    value may needed to be different for each aircraft.
    
    YANSH stores your own setting for each plane and
    recall it automatically at each new flight.

5. Program the FMC automatically (Zibo B737 only)
Once the OFP is retrieved, YANSH will program the FMC automatically

This plugin pulls your OFP and flight plan from your Simbrief and put it inside your Simulator as a nice floating window (very useful for VR).
The idea is to get the most relevant data required for your flight plan to feed the FMC and prepare your aircraft (fuel and weighs)

### How it works?
Using Simbrief API, this script pulls your flight plan and save it as an XML file that then is been parsed. All you need to provide is your Simbrief username.
You can open it from the FlyWithLua macros menu. You can also assign a button or key to open it.
You need to enter your Simbrief username and then press the button "Fetch data"

#### Requirements
The latest version of Xp11 or Xp12 ( Windows, Mac/Intel/Arm, Linux).

#### Installation
Just uncompress YANSH_3.x.zip file in your Resources/plugins folder.

#### Upgrade
Remove the previous YANSH folder from the Resources/plugins folder.
Proceed to the installation step

#### Migration from Simbrief Helper Enh
- Existing Simbrief Help Enh settings will be automaticaly migrated to YANSH
- Recommanded : remove the simbrief_helper.lua file from the "XPFOLDER"/Resources/plugins/FlyWithLua/Scripts folder

#### Help?
https://forums.x-plane.org/index.php?/files/file/86783-yansh-yet-another-simbrief-helper/


#### Credits
1. Original script by Alexander Garzon (https://forums.x-plane.org/index.php?/forums/topic/201318-simbrief-helper/)
2. xml2lua module by Manoel Campos (https://github.com/manoelcampos/xml2lua)
3. json module by rxi (https://github.com/rxi/json.lua)

#### History
- 3.13 QNH is displayed in hPA and inHg (useful for old aircraft), SASL update to v3.17, YANSH can now be upgraded with SkunkCrafts Updater Standalone client 
- 3.12 Fix Regression 'Paste' Button was not working anymore
- 3.11 Fix TOC Temp OTA value on FMC ( TOC Temp ISA was pushed instead )
- 3.10 Replace avwx service by aviationweather.gov (no registration needed)
- 3.9 Add VR borders display option,  fetch/uplink OFP button can be assign to as key, b737x files are not downloaded if not B738 aircraft
- 3.8 Clear the scratchpad before uploading, use the max cruise altitude instead of the initial altitude, display now also the flight number and the landing weight
- 3.7 Fix issue with uplink FMC while engines are running, add setting to populate or not the RESERVES value,  and add support for new uplink features on Zibo Xp12 RC5.2+ (b738x.fms and b738x.xml automatically downloaded) All features of YANSH are still compatible with Zibo Xp12 RC5.2+
- 3.6 Add setting to have the 'magic square' visible or not
- 3.5 Fix issue on prf file with wrong variable type
- 3.4 Fix issue on folder checking on windows
- 3.3 Fix taf,metar format issue, create missing folders at start ( YANSH cache, FMS folder)
- 3.2 Add datarefs, TO weight, weather TAF and remove rounding the weights
- 3.1 Fix setup file issue
- 3.0 Change name to YANSH from Simbrief Helper Enh, change from lua script to SASL plugin
- 2.2 Update modules to latest version of xml2Lua and improve logging
- 2.1 Add automatic FMC programing