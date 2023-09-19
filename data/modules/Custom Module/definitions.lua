local P = {}
definitions = P -- package name

P.VERSION = "2.2"

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
P.GITHUBURL = "https://raw.githubusercontent.com/olivierbutler/simbriefHelperEnh/main/version.ini"
P.SIMBRIEFURL = "https://www.simbrief.com/api/xml.fetcher.php?username=%s"
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
P.backgroundColor = {1, 1, 1, 1}
P.bannerBackgroundColor = {1, 0, 1, 1}
P.closeBackgroundColor = {0, 0, 1, 1}
P.textColor = {0, 0, 1, 1}
P.textColorHtml = "#0000FFFF"
P.bannerTextColor = {0, 0, 1, 1} 
P.activeButtonColor = {0.9, 0.9, 0.9, 1.0}
P.disableButtonColor = {0.5, 0.5, 0.5, 0.5}
P.buttonColor = {0, 0.4, 0, 1}
P.wFont = sasl.gl.loadFont("DejaVuSansMono.ttf")
P.wFontSize = 13
P.cursor = {
    x = -8,
    y = -8,
    width = 16,
    height = 16,
    shape = sasl.gl.loadImage("yansh-cur.png"),
    hideOSCursor = true
}

return definitions


-- laminar/B738/electric/dc_bus1_status
-- laminar/B738/electric/main_bus