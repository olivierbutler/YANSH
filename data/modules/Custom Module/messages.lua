local P = {}
messages = P -- package name


local lang = get(globalProperty("sim/operation/prefs/misc/language")) + 1

local english = {
    NOUSERNAME = 'Simbrief username is not defined, please go to settings',
    SBUSERNAME = 'Simbrief username',
    UPDATEAVAILABLE = 'update available',
    UPLINKZIBO = "Upload the 737's FMC automaticaly after fetching the OFP (Zibo B737 only)",
    SETUP = 'Setup',
    AVWXNOTCONFIGURED = "AVWX is not configured: updated METARs are not available",
    FETCHING = 'Fetching',
    OFPTOOLDER = "Warning, this OFP is older than 2 hours",
    LIDOFORMAT1 = "(LIDO layout is prefered),",
    LIDOFORMAT2 = "FMC's UPLINK DATA (Wind forecasts) will not be available",
    SAVESETTINGS = "Save Settings",
    PASTE = "Paste",
    AVWXTOKEN = "Avwx token",
    DEBUGMODE = "Enable Debug Logging mode"
}

local french = {
    NOUSERNAME = "'Simbrief username' n'est pas configuré",
    SBUSERNAME = 'Simbrief username',
    UPDATEAVAILABLE = 'mise à jour disponible',
    UPLINKZIBO = "Upload automatiquement l'OFP dans le FMC du 737 (Zibo B737 uniquement)",
    SETUP = 'Réglages',
    AVWXNOTCONFIGURED = "AVWX n'est pas configuré: La mise à jour des METARs n'est pas disponible",
    FETCHING = 'Récupération',
    OFPTOOLDER = "Note, cet OFP date de plus de 2 heures",
    LIDOFORMAT1 = "(Le format LIDO est conseillé),",
    LIDOFORMAT2 = "FMC's UPLINK DATA (Prévisions des vents) ne sera pas disponible",
    SAVESETTINGS = "Enregistrer",
    PASTE = "Coller",
    AVWXTOKEN = "Avwx token",
    DEBUGMODE = "Activer le log en mode Debug"
}


local german = english
local russian = english
local italian = english
local castilan = english
local portuges = english
local japanese = english
local chinese = english

-- order in IMPORTANT
local translations = {
    english,
    french,
    german,
    russian,
    italian,
    castilan,
    portuges,
    japanese,
    chinese
}

P.translation = translations[lang]

return messages