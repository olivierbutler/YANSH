local P = {}
definitions = P -- package name

-- P.VERSION = "2.2" -- initial version
-- P.VERSION = "3.0" -- fix setup file issue
P.VERSION = "3.1"

----------------------------------------------
-- DO NOT TOUCH BELOW
----------------------------------------------
P.OSSEPARATOR = "/"
if sasl.getOS() == 'Windows' then
    P.OSSEPARATOR = '\\'
end

P.XPOUTPUTPATH = sasl.getXPlanePath() .. P.OSSEPARATOR .. "Output" .. P.OSSEPARATOR
P.XPFMSPATH = P.XPOUTPUTPATH .. "FMS plans" .. P.OSSEPARATOR
P.XPRESSOURCESPATH = sasl.getXPlanePath() .. P.OSSEPARATOR .. "Resources" .. P.OSSEPARATOR
P.GITHUBURL = "https://raw.githubusercontent.com/olivierbutler/YANSH/main/data/modules/configuration/version.ini" 
P.SIMBRIEFURL = "https://www.simbrief.com/api/xml.fetcher.php?username=%s"
P.SIMBRIEFOFPURL = "https://www.simbrief.com/system/briefing.fmsdl.php?formatget=flightplans/"
P.AWVXURL = "https://avwx.rest/api/metar/%s?token=%s&reporting=false&format=xml&filter=raw"
P.APPNAMEPREFIX = sasl.getProjectName()
P.APPNAMEPREFIXLONG = "Yet ANother Simbrief Helper"
P.OFPSUFFIX = "01"

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
