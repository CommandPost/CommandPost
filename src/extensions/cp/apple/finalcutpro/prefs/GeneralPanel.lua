--- === cp.apple.finalcutpro.prefs.GeneralPanel ===
---
--- General Panel Module.

local require = require

local log				    = require("hs.logger").new("GeneralPanel")

local tools                 = require("cp.tools")

local just					= require("cp.just")

local Panel                 = require("cp.apple.finalcutpro.prefs.Panel")


local GeneralPanel = {}
GeneralPanel.mt = setmetatable({}, Panel.mt)
GeneralPanel.mt.__index = GeneralPanel.mt

--- cp.apple.finalcutpro.prefs.GeneralPanel.new(preferencesDialog) -> GeneralPanel
--- Constructor
--- Creates a new `GeneralPanel` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `GeneralPanel` object.
function GeneralPanel.new(preferencesDialog)
    local o = Panel.new(preferencesDialog, "PEGeneralPreferenceName", GeneralPanel.mt)

    return o
end

--- cp.apple.finalcutpro.prefs.GeneralPanel:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function GeneralPanel.mt:parent()
    return self._parent
end

--- cp.apple.finalcutpro.prefs.GeneralPanel:show() -> self
--- Function
--- Shows the General Preferences Panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function GeneralPanel.mt:show()
    local parent = self:parent()
    -- show the parent.
    if parent:show():isShowing() then
        -- get the toolbar UI
        local panel = just.doUntil(function() return self:UI() end)
        if panel then
            panel:doPress()
            just.doUntil(function() return self:isShowing() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.prefs.GeneralPanel:hide() -> self
--- Function
--- Hides the General Preferences Panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function GeneralPanel.mt:hide()
    return self:parent():hide()
end

--- cp.apple.finalcutpro.prefs.GeneralPanel.TIME_DISPLAY -> table
--- Constant
--- The time display options.
GeneralPanel.mt.TIME_DISPLAY = {
    ["HH:MM:SS:FF Subframes"] = "62706c6973743030d4010203040506b0b1582476657273696f6e58246f626a65637473592461726368697665725424746f7012000186a0af101707081c2c373f464b4e54575d616670757b80849ba1a5ab55246e756c6cda090a0b0c0d0e0f101112131415161718131a15135f10125054464d696e696d756d54696d65636f64655f1011505446466f726d6174446570757469657359505446466f726d61745f1011505446416c6c6f77734e656761746976655f101950544644656661756c744f626a65637450726f746f747970655624636c6173735c5054464e696c53796d626f6c5f101d4e5350726f54696d65636f6465466f726d617474657256657273696f6e5f101c505446534d505445537472696e67496e746572707265746174696f6e5f10125054464d6178696d756d54696d65636f64658000800210000980128016800010048000d81d1e1f0e202122232425262728292a2b5f10315f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e466565744672616d65735f102e5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e5365636f6e64735f10305f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e4261727342656174735f102a5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e484d535f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e417564696f5f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e534d5054455f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e566964656f800f800b800d80118005800980038007d62d2e2f300e311633151635165f101550535446446973706c6179735375626672616d65735f101950535446446973706c617973517561727465724672616d65735f10254e5350726f534d50544554696d65636f6465466f726d617444657075747956657273696f6e5f101150535446446973706c617973486f7572735f1015505354464861733234486f7572526f6c6c6f766572090809800409d238393a3b5a24636c6173736e616d655824636c61737365735f101b4c4b534d50544554696d65636f6465466f726d6174446570757479a33c3d3e5f101b4c4b534d50544554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479584e534f626a656374d44041420e434415455f1018504854465365636f6e6473446563696d616c506c616365735f1015504854464861733234486f7572526f6c6c6f7665725f10234e5350726f484d5354696d65636f6465466f726d617444657075747956657273696f6e100210018006d2383947485f10194c4b484d5354696d65636f6465466f726d6174446570757479a3494a3e5f10194c4b484d5354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d24c0e154d5f10294e5350726f4f6e6544566964656f54696d65636f6465466f726d617444657075747956657273696f6e8008d238394f505f101f4c4b4f6e6544566964656f54696d65636f6465466f726d6174446570757479a45152533e5f101f4c4b4f6e6544566964656f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2550e15565f10294e5350726f4f6e6544417564696f54696d65636f6465466f726d617444657075747956657273696f6e800ad2383958595f101f4c4b4f6e6544417564696f54696d65636f6465466f726d6174446570757479a45a5b5c3e5f101f4c4b4f6e6544417564696f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d35e5f0e4315605f1018505454465365636f6e6473446563696d616c506c616365735f10284e5350726f4f6e654454696d6554696d65636f6465466f726d617444657075747956657273696f6e800cd2383962635f101e4c4b4f6e654454696d6554696d65636f6465466f726d6174446570757479a364653e5f101e4c4b4f6e654454696d6554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d6670e68696a6b336d16156f445f101b504d544649734469766973696f6e734669656c6444726f707065645f101d504d5446446973706c6179734469766973696f6e73416e645469636b735f10284e5350726f4d6561737572656454696d65636f6465466f726d617444657075747956657273696f6e5f1016504d54464265617473446563696d616c506c616365735d504d5446536570617261746f7208800e091003d2383971725f101e4c4b4d6561737572656454696d65636f6465466f726d6174446570757479a373743e5f101e4c4b4d6561737572656454696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d47677780e1544337a5f10224e5350726f464654696d65636f6465466f726d617444657075747956657273696f6e5d50465446536570617261746f725f101950465446446973706c617973517561727465724672616d6573088010d238397c7d5f10184c4b464654696d65636f6465466f726d6174446570757479a37e7f3e5f10184c4b464654696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2383981825f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6ea2833e5f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6edf101185868788898a8b8c0e8d8e8f9091929394151a9595434396449715439844991a15335f101e4e5350726f566964656f54696d65636f646546696754696d6556616c75655f102d4e5350726f457874656e64656454696d65636f646554696d655369676e617475726544656e6f6d696e61746f725f101e4e5350726f566964656f54696d65636f646546696754696d655363616c655f101e4e5350726f566964656f54696d65636f646546696754696d65466c6167735f10194e5350726f566964656f54696d65636f646556657273696f6e5f101c4e5350726f457874656e64656454696d65636f646556657273696f6e5f101a4e5350726f457874656e64656454696d65636f646554656d706f5f101d4e5350726f457874656e64656454696d65636f646546696c6d547970655f101e4e5350726f566964656f54696d65636f646546696754696d6545706f63685f10144e5350726f54696d65636f646556657273696f6e5f10254e5350726f566964656f54696d65636f6465437573746f6d566964656f4d6f6465496e666f5f101b4e5350726f54696d65636f6465417564696f4672616d65526174655f10164e5350726f566964656f54696d65636f64654d6f64655f102b4e5350726f457874656e64656454696d65636f646554696d655369676e61747572654e756d657261746f725f101f4e5350726f54696d65636f646553657175656e636550686173654672616d655f101c4e5350726f566964656f54696d65636f64655573655365636f6e6473100123405e00000000000080158013100608d30e9c9d9e9fa05f102b5f4e5350726f437573746f6d566964656f4d6f6465496e666f50726566657272656454696d655363616c655f10225f4e5350726f437573746f6d566964656f4d6f6465496e666f4672616d655261746580141000230000000000000000d23839a2a35f10165f4c4b437573746f6d566964656f4d6f6465496e666fa2a43e5f10165f4c4b437573746f6d566964656f4d6f6465496e666fd23839a6a75f10124c4b457874656e64656454696d65636f6465a4a8a9aa3e5f10124c4b457874656e64656454696d65636f64655a4c4b54696d65636f64655f100f4c4b566964656f54696d65636f6465d23839acad5f10134c4b54696d65636f6465466f726d6174746572a3aeaf3e5f10134c4b54696d65636f6465466f726d61747465725b4e53466f726d61747465725f100f4e534b657965644172636869766572d1b2b354726f6f74800100080011001a0023002d0032003700510057006c00810095009f00b300cf00d600e30103012201370139013b013d013e014001420144014601480159018d01be01f1021e024d027c02ab02ad02af02b102b302b502b702b902bb02c802e002fc03240338035003510352035303550356035b0366036f038d039103af03be03c703d003eb04030429042b042d042f0434045004540470047f048404b004b204b704d904de050005230532053705630565056a058c059105b305d605e505ec0607063206340639065a065e067f068e069b06b906d90704071d072b072c072e072f073107360757075b077c078b079407b907c707e307e407e607eb0806080a08250834083908600863088a08af08d0090009210942095e097d099a09ba09db09f20a1a0a380a510a7f0aa10ac00ac20acb0acd0acf0ad10ad20ad90b070b2c0b2e0b300b390b3e0b570b5a0b730b780b8d0b920ba70bb20bc40bc90bdf0be30bf90c050c170c1a0c1f000000000000020100000000000000b400000000000000000000000000000c21",
    ["HH:MM:SS:FF"] = "62706c6973743030d4010203040506b0b1582476657273696f6e58246f626a65637473592461726368697665725424746f7012000186a0af101707081c2c373f464b4e54575d616670757b80849ba1a5ab55246e756c6cda090a0b0c0d0e0f101112131415161718131a15135f10125054464d696e696d756d54696d65636f64655f1011505446466f726d6174446570757469657359505446466f726d61745f1011505446416c6c6f77734e656761746976655f101950544644656661756c744f626a65637450726f746f747970655624636c6173735c5054464e696c53796d626f6c5f101d4e5350726f54696d65636f6465466f726d617474657256657273696f6e5f101c505446534d505445537472696e67496e746572707265746174696f6e5f10125054464d6178696d756d54696d65636f64658000800210000980128016800010048000d81d1e1f0e202122232425262728292a2b5f10315f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e466565744672616d65735f102e5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e5365636f6e64735f10305f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e4261727342656174735f102a5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e484d535f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e417564696f5f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e534d5054455f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e566964656f800f800b800d80118005800980038007d62d2e2f300e313232151635165f101550535446446973706c6179735375626672616d65735f101950535446446973706c617973517561727465724672616d65735f10254e5350726f534d50544554696d65636f6465466f726d617444657075747956657273696f6e5f101150535446446973706c617973486f7572735f1015505354464861733234486f7572526f6c6c6f766572080809800409d238393a3b5a24636c6173736e616d655824636c61737365735f101b4c4b534d50544554696d65636f6465466f726d6174446570757479a33c3d3e5f101b4c4b534d50544554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479584e534f626a656374d44041420e434415455f1018504854465365636f6e6473446563696d616c506c616365735f1015504854464861733234486f7572526f6c6c6f7665725f10234e5350726f484d5354696d65636f6465466f726d617444657075747956657273696f6e100210018006d2383947485f10194c4b484d5354696d65636f6465466f726d6174446570757479a3494a3e5f10194c4b484d5354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d24c0e154d5f10294e5350726f4f6e6544566964656f54696d65636f6465466f726d617444657075747956657273696f6e8008d238394f505f101f4c4b4f6e6544566964656f54696d65636f6465466f726d6174446570757479a45152533e5f101f4c4b4f6e6544566964656f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2550e15565f10294e5350726f4f6e6544417564696f54696d65636f6465466f726d617444657075747956657273696f6e800ad2383958595f101f4c4b4f6e6544417564696f54696d65636f6465466f726d6174446570757479a45a5b5c3e5f101f4c4b4f6e6544417564696f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d35e5f0e4315605f1018505454465365636f6e6473446563696d616c506c616365735f10284e5350726f4f6e654454696d6554696d65636f6465466f726d617444657075747956657273696f6e800cd2383962635f101e4c4b4f6e654454696d6554696d65636f6465466f726d6174446570757479a364653e5f101e4c4b4f6e654454696d6554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d6670e68696a6b326d16156f445f101b504d544649734469766973696f6e734669656c6444726f707065645f101d504d5446446973706c6179734469766973696f6e73416e645469636b735f10284e5350726f4d6561737572656454696d65636f6465466f726d617444657075747956657273696f6e5f1016504d54464265617473446563696d616c506c616365735d504d5446536570617261746f7208800e091003d2383971725f101e4c4b4d6561737572656454696d65636f6465466f726d6174446570757479a373743e5f101e4c4b4d6561737572656454696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d47677780e1544327a5f10224e5350726f464654696d65636f6465466f726d617444657075747956657273696f6e5d50465446536570617261746f725f101950465446446973706c617973517561727465724672616d6573088010d238397c7d5f10184c4b464654696d65636f6465466f726d6174446570757479a37e7f3e5f10184c4b464654696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2383981825f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6ea2833e5f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6edf101185868788898a8b8c0e8d8e8f9091929394151a9595434396449715439844991a15325f101e4e5350726f566964656f54696d65636f646546696754696d6556616c75655f102d4e5350726f457874656e64656454696d65636f646554696d655369676e617475726544656e6f6d696e61746f725f101e4e5350726f566964656f54696d65636f646546696754696d655363616c655f101e4e5350726f566964656f54696d65636f646546696754696d65466c6167735f10194e5350726f566964656f54696d65636f646556657273696f6e5f101c4e5350726f457874656e64656454696d65636f646556657273696f6e5f101a4e5350726f457874656e64656454696d65636f646554656d706f5f101d4e5350726f457874656e64656454696d65636f646546696c6d547970655f101e4e5350726f566964656f54696d65636f646546696754696d6545706f63685f10144e5350726f54696d65636f646556657273696f6e5f10254e5350726f566964656f54696d65636f6465437573746f6d566964656f4d6f6465496e666f5f101b4e5350726f54696d65636f6465417564696f4672616d65526174655f10164e5350726f566964656f54696d65636f64654d6f64655f102b4e5350726f457874656e64656454696d65636f646554696d655369676e61747572654e756d657261746f725f101f4e5350726f54696d65636f646553657175656e636550686173654672616d655f101c4e5350726f566964656f54696d65636f64655573655365636f6e6473100123405e00000000000080158013100608d30e9c9d9e9fa05f102b5f4e5350726f437573746f6d566964656f4d6f6465496e666f50726566657272656454696d655363616c655f10225f4e5350726f437573746f6d566964656f4d6f6465496e666f4672616d655261746580141000230000000000000000d23839a2a35f10165f4c4b437573746f6d566964656f4d6f6465496e666fa2a43e5f10165f4c4b437573746f6d566964656f4d6f6465496e666fd23839a6a75f10124c4b457874656e64656454696d65636f6465a4a8a9aa3e5f10124c4b457874656e64656454696d65636f64655a4c4b54696d65636f64655f100f4c4b566964656f54696d65636f6465d23839acad5f10134c4b54696d65636f6465466f726d6174746572a3aeaf3e5f10134c4b54696d65636f6465466f726d61747465725b4e53466f726d61747465725f100f4e534b657965644172636869766572d1b2b354726f6f74800100080011001a0023002d0032003700510057006c00810095009f00b300cf00d600e30103012201370139013b013d013e014001420144014601480159018d01be01f1021e024d027c02ab02ad02af02b102b302b502b702b902bb02c802e002fc03240338035003510352035303550356035b0366036f038d039103af03be03c703d003eb04030429042b042d042f0434045004540470047f048404b004b204b704d904de050005230532053705630565056a058c059105b305d605e505ec0607063206340639065a065e067f068e069b06b906d90704071d072b072c072e072f073107360757075b077c078b079407b907c707e307e407e607eb0806080a08250834083908600863088a08af08d0090009210942095e097d099a09ba09db09f20a1a0a380a510a7f0aa10ac00ac20acb0acd0acf0ad10ad20ad90b070b2c0b2e0b300b390b3e0b570b5a0b730b780b8d0b920ba70bb20bc40bc90bdf0be30bf90c050c170c1a0c1f000000000000020100000000000000b400000000000000000000000000000c21",
    ["Frames"] = "62706c6973743030d4010203040506b0b1582476657273696f6e58246f626a65637473592461726368697665725424746f7012000186a0af101707081d2d3840464b4e54575d616670757b80849ba1a5ab55246e756c6cda090a0b0c0d0e0f101112131415161718131a1b135f10125054464d696e696d756d54696d65636f64655f1011505446466f726d6174446570757469657359505446466f726d61745f1011505446416c6c6f77734e656761746976655f101950544644656661756c744f626a65637450726f746f747970655624636c6173735c5054464e696c53796d626f6c5f101d4e5350726f54696d65636f6465466f726d617474657256657273696f6e5f101c505446534d505445537472696e67496e746572707265746174696f6e5f10125054464d6178696d756d54696d65636f646580008002100209801280168000100410008000d81e1f200e2122232425262728292a2b2c5f10315f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e466565744672616d65735f102e5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e5365636f6e64735f10305f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e4261727342656174735f102a5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e484d535f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e417564696f5f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e534d5054455f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e566964656f800f800b800d80118005800980038007d62e2f30310e3233331b1636165f101550535446446973706c6179735375626672616d65735f101950535446446973706c617973517561727465724672616d65735f10254e5350726f534d50544554696d65636f6465466f726d617444657075747956657273696f6e5f101150535446446973706c617973486f7572735f1015505354464861733234486f7572526f6c6c6f766572080809800409d2393a3b3c5a24636c6173736e616d655824636c61737365735f101b4c4b534d50544554696d65636f6465466f726d6174446570757479a33d3e3f5f101b4c4b534d50544554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479584e534f626a656374d44142430e15441b455f1018504854465365636f6e6473446563696d616c506c616365735f1015504854464861733234486f7572526f6c6c6f7665725f10234e5350726f484d5354696d65636f6465466f726d617444657075747956657273696f6e10018006d2393a47485f10194c4b484d5354696d65636f6465466f726d6174446570757479a3494a3f5f10194c4b484d5354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d24c0e1b4d5f10294e5350726f4f6e6544566964656f54696d65636f6465466f726d617444657075747956657273696f6e8008d2393a4f505f101f4c4b4f6e6544566964656f54696d65636f6465466f726d6174446570757479a45152533f5f101f4c4b4f6e6544566964656f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2550e1b565f10294e5350726f4f6e6544417564696f54696d65636f6465466f726d617444657075747956657273696f6e800ad2393a58595f101f4c4b4f6e6544417564696f54696d65636f6465466f726d6174446570757479a45a5b5c3f5f101f4c4b4f6e6544417564696f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d35e5f0e151b605f1018505454465365636f6e6473446563696d616c506c616365735f10284e5350726f4f6e654454696d6554696d65636f6465466f726d617444657075747956657273696f6e800cd2393a62635f101e4c4b4f6e654454696d6554696d65636f6465466f726d6174446570757479a364653f5f101e4c4b4f6e654454696d6554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d6670e68696a6b336d161b6f445f101b504d544649734469766973696f6e734669656c6444726f707065645f101d504d5446446973706c6179734469766973696f6e73416e645469636b735f10284e5350726f4d6561737572656454696d65636f6465466f726d617444657075747956657273696f6e5f1016504d54464265617473446563696d616c506c616365735d504d5446536570617261746f7208800e091003d2393a71725f101e4c4b4d6561737572656454696d65636f6465466f726d6174446570757479a373743f5f101e4c4b4d6561737572656454696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d47677780e1b44337a5f10224e5350726f464654696d65636f6465466f726d617444657075747956657273696f6e5d50465446536570617261746f725f101950465446446973706c617973517561727465724672616d6573088010d2393a7c7d5f10184c4b464654696d65636f6465466f726d6174446570757479a37e7f3f5f10184c4b464654696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2393a81825f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6ea2833f5f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6edf101185868788898a8b8c0e8d8e8f90919293941b1a959515159644971b159844991a1b335f101e4e5350726f566964656f54696d65636f646546696754696d6556616c75655f102d4e5350726f457874656e64656454696d65636f646554696d655369676e617475726544656e6f6d696e61746f725f101e4e5350726f566964656f54696d65636f646546696754696d655363616c655f101e4e5350726f566964656f54696d65636f646546696754696d65466c6167735f10194e5350726f566964656f54696d65636f646556657273696f6e5f101c4e5350726f457874656e64656454696d65636f646556657273696f6e5f101a4e5350726f457874656e64656454696d65636f646554656d706f5f101d4e5350726f457874656e64656454696d65636f646546696c6d547970655f101e4e5350726f566964656f54696d65636f646546696754696d6545706f63685f10144e5350726f54696d65636f646556657273696f6e5f10254e5350726f566964656f54696d65636f6465437573746f6d566964656f4d6f6465496e666f5f101b4e5350726f54696d65636f6465417564696f4672616d65526174655f10164e5350726f566964656f54696d65636f64654d6f64655f102b4e5350726f457874656e64656454696d65636f646554696d655369676e61747572654e756d657261746f725f101f4e5350726f54696d65636f646553657175656e636550686173654672616d655f101c4e5350726f566964656f54696d65636f64655573655365636f6e6473100123405e00000000000080158013100608d30e9c9d9e9fa05f102b5f4e5350726f437573746f6d566964656f4d6f6465496e666f50726566657272656454696d655363616c655f10225f4e5350726f437573746f6d566964656f4d6f6465496e666f4672616d655261746580141000230000000000000000d2393aa2a35f10165f4c4b437573746f6d566964656f4d6f6465496e666fa2a43f5f10165f4c4b437573746f6d566964656f4d6f6465496e666fd2393aa6a75f10124c4b457874656e64656454696d65636f6465a4a8a9aa3f5f10124c4b457874656e64656454696d65636f64655a4c4b54696d65636f64655f100f4c4b566964656f54696d65636f6465d2393aacad5f10134c4b54696d65636f6465466f726d6174746572a3aeaf3f5f10134c4b54696d65636f6465466f726d61747465725b4e53466f726d61747465725f100f4e534b657965644172636869766572d1b2b354726f6f74800100080011001a0023002d0032003700510057006c00810095009f00b300cf00d600e30103012201370139013b013d013e01400142014401460148014a015b018f01c001f30220024f027e02ad02af02b102b302b502b702b902bb02bd02ca02e202fe0326033a035203530354035503570358035d03680371038f039303b103c003c903d203ed0405042b042d042f0434045004540470047f048404b004b204b704d904de050005230532053705630565056a058c059105b305d605e505ec0607063206340639065a065e067f068e069b06b906d90704071d072b072c072e072f073107360757075b077c078b079407b907c707e307e407e607eb0806080a08250834083908600863088a08af08d0090009210942095e097d099a09ba09db09f20a1a0a380a510a7f0aa10ac00ac20acb0acd0acf0ad10ad20ad90b070b2c0b2e0b300b390b3e0b570b5a0b730b780b8d0b920ba70bb20bc40bc90bdf0be30bf90c050c170c1a0c1f000000000000020100000000000000b400000000000000000000000000000c21",
    ["Seconds"] = "62706c6973743030d4010203040506b0b1582476657273696f6e58246f626a65637473592461726368697665725424746f7012000186a0af101707081c2c373f464b4e54575d616670757b80849ba1a5ab55246e756c6cda090a0b0c0d0e0f10111213141516171813151a135f10125054464d696e696d756d54696d65636f64655f1011505446466f726d6174446570757469657359505446466f726d61745f1011505446416c6c6f77734e656761746976655f101950544644656661756c744f626a65637450726f746f747970655624636c6173735c5054464e696c53796d626f6c5f101d4e5350726f54696d65636f6465466f726d617474657256657273696f6e5f101c505446534d505445537472696e67496e746572707265746174696f6e5f10125054464d6178696d756d54696d65636f64658000800210040980128016800010008000d81d1e1f0e202122232425262728292a2b5f10315f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e466565744672616d65735f102e5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e5365636f6e64735f10305f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e4261727342656174735f102a5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e484d535f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e417564696f5f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e534d5054455f102c5f4e5350726f54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6e566964656f800f800b800d80118005800980038007d62d2e2f300e3132321a1635165f101550535446446973706c6179735375626672616d65735f101950535446446973706c617973517561727465724672616d65735f10254e5350726f534d50544554696d65636f6465466f726d617444657075747956657273696f6e5f101150535446446973706c617973486f7572735f1015505354464861733234486f7572526f6c6c6f766572080809800409d238393a3b5a24636c6173736e616d655824636c61737365735f101b4c4b534d50544554696d65636f6465466f726d6174446570757479a33c3d3e5f101b4c4b534d50544554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479584e534f626a656374d44041420e43441a455f1018504854465365636f6e6473446563696d616c506c616365735f1015504854464861733234486f7572526f6c6c6f7665725f10234e5350726f484d5354696d65636f6465466f726d617444657075747956657273696f6e100210018006d2383947485f10194c4b484d5354696d65636f6465466f726d6174446570757479a3494a3e5f10194c4b484d5354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d24c0e1a4d5f10294e5350726f4f6e6544566964656f54696d65636f6465466f726d617444657075747956657273696f6e8008d238394f505f101f4c4b4f6e6544566964656f54696d65636f6465466f726d6174446570757479a45152533e5f101f4c4b4f6e6544566964656f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2550e1a565f10294e5350726f4f6e6544417564696f54696d65636f6465466f726d617444657075747956657273696f6e800ad2383958595f101f4c4b4f6e6544417564696f54696d65636f6465466f726d6174446570757479a45a5b5c3e5f101f4c4b4f6e6544417564696f54696d65636f6465466f726d61744465707574795f10204c4b4f6e65444672616d657354696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d35e5f0e431a605f1018505454465365636f6e6473446563696d616c506c616365735f10284e5350726f4f6e654454696d6554696d65636f6465466f726d617444657075747956657273696f6e800cd2383962635f101e4c4b4f6e654454696d6554696d65636f6465466f726d6174446570757479a364653e5f101e4c4b4f6e654454696d6554696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d6670e68696a6b326d161a6f445f101b504d544649734469766973696f6e734669656c6444726f707065645f101d504d5446446973706c6179734469766973696f6e73416e645469636b735f10284e5350726f4d6561737572656454696d65636f6465466f726d617444657075747956657273696f6e5f1016504d54464265617473446563696d616c506c616365735d504d5446536570617261746f7208800e091003d2383971725f101e4c4b4d6561737572656454696d65636f6465466f726d6174446570757479a373743e5f101e4c4b4d6561737572656454696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d47677780e1a44327a5f10224e5350726f464654696d65636f6465466f726d617444657075747956657273696f6e5d50465446536570617261746f725f101950465446446973706c617973517561727465724672616d6573088010d238397c7d5f10184c4b464654696d65636f6465466f726d6174446570757479a37e7f3e5f10184c4b464654696d65636f6465466f726d61744465707574795e4c4b466f726d6174446570757479d2383981825f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6ea2833e5f10245f4c4b54696d65636f6465466f726d6174746572446570757479436f6c6c656374696f6edf101185868788898a8b8c0e8d8e8f90919293941a15959543439644971a43984499151a325f101e4e5350726f566964656f54696d65636f646546696754696d6556616c75655f102d4e5350726f457874656e64656454696d65636f646554696d655369676e617475726544656e6f6d696e61746f725f101e4e5350726f566964656f54696d65636f646546696754696d655363616c655f101e4e5350726f566964656f54696d65636f646546696754696d65466c6167735f10194e5350726f566964656f54696d65636f646556657273696f6e5f101c4e5350726f457874656e64656454696d65636f646556657273696f6e5f101a4e5350726f457874656e64656454696d65636f646554656d706f5f101d4e5350726f457874656e64656454696d65636f646546696c6d547970655f101e4e5350726f566964656f54696d65636f646546696754696d6545706f63685f10144e5350726f54696d65636f646556657273696f6e5f10254e5350726f566964656f54696d65636f6465437573746f6d566964656f4d6f6465496e666f5f101b4e5350726f54696d65636f6465417564696f4672616d65526174655f10164e5350726f566964656f54696d65636f64654d6f64655f102b4e5350726f457874656e64656454696d65636f646554696d655369676e61747572654e756d657261746f725f101f4e5350726f54696d65636f646553657175656e636550686173654672616d655f101c4e5350726f566964656f54696d65636f64655573655365636f6e6473100123405e00000000000080158013100608d30e9c9d9e9fa05f102b5f4e5350726f437573746f6d566964656f4d6f6465496e666f50726566657272656454696d655363616c655f10225f4e5350726f437573746f6d566964656f4d6f6465496e666f4672616d655261746580141000230000000000000000d23839a2a35f10165f4c4b437573746f6d566964656f4d6f6465496e666fa2a43e5f10165f4c4b437573746f6d566964656f4d6f6465496e666fd23839a6a75f10124c4b457874656e64656454696d65636f6465a4a8a9aa3e5f10124c4b457874656e64656454696d65636f64655a4c4b54696d65636f64655f100f4c4b566964656f54696d65636f6465d23839acad5f10134c4b54696d65636f6465466f726d6174746572a3aeaf3e5f10134c4b54696d65636f6465466f726d61747465725b4e53466f726d61747465725f100f4e534b657965644172636869766572d1b2b354726f6f74800100080011001a0023002d0032003700510057006c00810095009f00b300cf00d600e30103012201370139013b013d013e014001420144014601480159018d01be01f1021e024d027c02ab02ad02af02b102b302b502b702b902bb02c802e002fc03240338035003510352035303550356035b0366036f038d039103af03be03c703d003eb04030429042b042d042f0434045004540470047f048404b004b204b704d904de050005230532053705630565056a058c059105b305d605e505ec0607063206340639065a065e067f068e069b06b906d90704071d072b072c072e072f073107360757075b077c078b079407b907c707e307e407e607eb0806080a08250834083908600863088a08af08d0090009210942095e097d099a09ba09db09f20a1a0a380a510a7f0aa10ac00ac20acb0acd0acf0ad10ad20ad90b070b2c0b2e0b300b390b3e0b570b5a0b730b780b8d0b920ba70bb20bc40bc90bdf0be30bf90c050c170c1a0c1f000000000000020100000000000000b400000000000000000000000000000c21"
}

--- cp.apple.finalcutpro.prefs.GeneralPanel.timeDisplay([value]) -> string | nil
--- Function
--- Gets to sets the Time Display value.
---
--- Parameters:
---  * value - An optional value to set the Time Display.
---
--- Returns:
---  * The time display if successful, otherwise `nil` if an error occurs.
function GeneralPanel.mt.timeDisplay(value)
    if value then
        --------------------------------------------------------------------------------
        -- Setter:
        --------------------------------------------------------------------------------
        if tools.tableContains(GeneralPanel.mt.TIME_DISPLAY, value) then
            hs.execute("defaults write com.apple.FinalCut timeFormatLK -data " .. value)
            for i, v in pairs(GeneralPanel.mt.TIME_DISPLAY) do
                if value == v then
                    return i
                end
            end
        else
            log.ef("Invalid value for Time Display")
            return nil
        end
    else
        --------------------------------------------------------------------------------
        -- Getter:
        --------------------------------------------------------------------------------
        local output, executeStatus = hs.execute("defaults read com.apple.FinalCut timeFormatLK")
        if executeStatus and output then
            local length = string.len(output)
            if string.sub(output, 1, 1) == "<" and string.sub(output, length -1, length - 1 ) == ">" then
                local data = string.sub(output, 2, length - 2)
                data = string.gsub(data, " ", "")
                for i, v in pairs(GeneralPanel.mt.TIME_DISPLAY) do
                    if data == v then
                        return i
                    end
                end
            end
        end
        return nil
    end
end

return GeneralPanel
