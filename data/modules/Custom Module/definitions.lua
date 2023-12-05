local P = {}
definitions = P -- package name

-- P.VERSION = "2.2" -- initial version
-- P.VERSION = "3.0" -- fix setup file issue
-- P.VERSION = "3.1" -- fix setup file issue
-- P.VERSION = "3.2" -- add datarefs, TO weight, weather TAF and remove rounding the weights
-- P.VERSION = "3.3" -- fix taf,metart format issue, create missing folder at start ( YANSH cache, FMS folder) 
-- P.VERSION = "3.4" -- fix issue on folder checking on windows
-- P.VERSION = "3.5" -- fix issue on prf file with wrong variable type
-- P.VERSION = "3.6" -- add setting to have the 'magic square' visible or not
-- P.VERSION = "3.7" -- do not populate the plan fuel if option is disable or engine running add setting to disable populating the RESERVE item in the FMC
-- P.VERSION = "3.8" -- clear the scratchpad before uploading, use the max cruise altitude instead of the initial altitude, display now also the flight number and the landing weight
-- P.VERSION = "3.9" -- add VR borders display option,  fetch/uplink OFP button can be assign to as key, b737x files are not downloaded if  not B738 aircraft
P.VERSION = "3.9"

----------------------------------------------
-- DO NOT TOUCH BELOW
----------------------------------------------
P.OSSEPARATOR = "/"
if sasl.getOS() == 'Windows' then
    P.OSSEPARATOR = '\\'
end

P.APPNAMEPREFIX = sasl.getProjectName()

P.XPOUTPUTPATH = sasl.getXPlanePath() .. P.OSSEPARATOR .. "Output" .. P.OSSEPARATOR
P.XPCACHESPATH = P.XPOUTPUTPATH .. "caches" .. P.OSSEPARATOR
P.YANSHCACHESPATH = P.XPOUTPUTPATH .. "caches" .. P.OSSEPARATOR .. P.APPNAMEPREFIX .. ".cache".. P.OSSEPARATOR 
P.XPFMSPATH = P.XPOUTPUTPATH .. "FMS plans" .. P.OSSEPARATOR
P.XPFMSPATHEXIST = false
P.XPRESSOURCESPATH = sasl.getXPlanePath() .. P.OSSEPARATOR .. "Resources" .. P.OSSEPARATOR
P.GITHUBURL = "https://raw.githubusercontent.com/olivierbutler/YANSH/main/data/modules/configuration/version.ini" 
P.SIMBRIEFURL = "https://www.simbrief.com/api/xml.fetcher.php?username=%s"
P.SIMBRIEFOFPURL = "https://www.simbrief.com/system/briefing.fmsdl.php?formatget=flightplans/"
P.AWVXURL = "https://avwx.rest/api/metar/%s?token=%s&reporting=false&format=xml&filter=sanitized"
P.AWVXTAFURL = "https://avwx.rest/api/taf/%s?token=%s&reporting=false&format=xml&filter=sanitized"
P.APPNAMEPREFIXLONG = "Yet ANother Simbrief Helper"
P.OFPSUFFIX = "01"
P.ZIBOFILE = "b738x"

P.closeXHeight = 25
P.closeXWidth = P.closeXHeight
P.bannerHeight = P.closeXHeight
P.buttonHeight = P.closeXHeight
P.checkBoxHeight = 15
P.checkBoxWidth = P.checkBoxHeight
P.linePaddingBottom = 8
P.lineHeight = 15
P.backgroundColor = {0, 0, 0, 0.553}
P.bannerBackgroundColor = P.backgroundColor
P.closeBackgroundColor = P.bannerBackgroundColor
P.textColor = {0.8, 0.8, 0.8, 1}
P.textColorHtml = "#FFFFFFFF"
P.bannerTextColor = P.textColor
P.activeButtonColor = {0.9, 0.9, 0.9, 1.0}
P.disableButtonColor = {0.5, 0.5, 0.5, 0.5}
P.buttonColor = {0, 0, 0, 1}
P.wFont = sasl.gl.loadFont("DejaVuSansMono.ttf")
P.wFontSize = 13
P.cursor = {
    x = -8,
    y = -25,
    width = 32,
    height = 32,
    shape = sasl.gl.loadImage("yansh-cur.png"),
    hideOSCursor = true
}
P.inputBackgroundColor = P.buttonColor
P.activeInputText = P.activeButtonColor
P.disableInputText = P.disableButtonColor
return definitions
