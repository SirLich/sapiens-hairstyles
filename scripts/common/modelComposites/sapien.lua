--- SapiensHair: sapien.lua
---
--- This is a special kind of "shadow" which is really just a copy/pasted source file, 
--- with all exposed functions redirected using the shadowing system.
--- This is considered very bad style.
--- @author SirLich


local mjm = mjrequire "common/mjm"
local rng = mjrequire "common/randomNumberGenerator"
local sapienConstants = mjrequire "common/sapienConstants"
local sapienInventory = mjrequire "common/sapienInventory"

local modelComposite_shadow = {}

local skinMaterials = {
    "skinDarkest",
    "skinDarker",
    "skinDark",
    "skin",
    "skinLight",
    "skinLighter",
    "skinLightest",
}

local hairMaterials = {
	"hairDarkest",
	"hairDarker",
	"hair",
	"hairRed",
	"hairBlond",
}

local eyebrowsMaterials = {
	"eyebrowsDarkest",
	"eyebrowsDarker",
	"eyebrows",
	"eyebrowsRed",
	"eyebrowsBlond",
}

local eyeMaterials = {
	"eyeBallDarkBrown",
	"eyeBallLightBrown",
	"eyeBall",
    "eyeBallBlue",
}


local eyelashesMaterials = {
	"eyelashesDarkest",
	"eyelashesDarker",
	"eyelashes",
	"eyelashesRed",
	"eyelashesBlond",
}

local eyelashesLongMaterials = {
	"eyelashesDarkestLong",
	"eyelashesDarkerLong",
	"eyelashesLong",
	"eyelashesRedLong",
	"eyelashesBlondLong",
}


local standardCloakMaterials = {
	cloak = "clothes",
	cloakFur = "clothingFur",
	cloakFurShort = "clothingFurShort",
}


local mammothCloakMaterials = {
	cloak = "clothesMammoth",
	cloakFur = "clothingMammothFur",
	cloakFurShort = "clothingMammothFurShort",
}


local femaleIndex = 1
local maleIndex = 2

local bodyPaths = {
    [sapienConstants.lifeStages.child.index] = {
        [maleIndex] = {
            base = "boyBody",
            count = 1,
        },
        [femaleIndex] = {
            base = "girlBody",
            count = 1,
        }
    },
    [sapienConstants.lifeStages.adult.index] = {
        [maleIndex] = {
            base = "manBody",
            count = 1,
        },
        [femaleIndex] = {
            customFunction = function(sharedState)
                if sharedState.pregnant then
                    return "womanBodyPregnant1.glb"
                elseif sharedState.hasBaby then
                    return "womanBodyWithBaby1.glb"
                else
                    return "womanBody1.glb"
                end
            end
        }
    },
}


local headPaths = {
    [sapienConstants.lifeStages.child.index] = {
        [maleIndex] = {
            base = "boyHead",
            count = 1,
        },
        [femaleIndex] = {
            base = "girlHead",
            count = 1,
        }
    },
    [sapienConstants.lifeStages.adult.index] = {
        [maleIndex] = {
            base = "manHead",
            count = 1,
        },
        [femaleIndex] = {
            base = "womanHead",
            count = 1,
        }
    },
}


local hairPaths = {
    [sapienConstants.lifeStages.child.index] = {
        [maleIndex] = {
            base = "boyHair",
            count = 1,
        },
        [femaleIndex] = {
            base = "girlHair",
            count = 1,
        }
    },
    [sapienConstants.lifeStages.adult.index] = {
        [maleIndex] = {
            base = "manHair",
            count = 5,
            hasNilOption = true,
        },
        [femaleIndex] = {
            base = "womanHair",
            count = 7,
        }
    },
}

local beardPaths = {
    [sapienConstants.lifeStages.adult.index] = {
        [maleIndex] = {
            base = "manBeard",
            count = 7,
        },
    },
}

bodyPaths[sapienConstants.lifeStages.elder.index] = bodyPaths[sapienConstants.lifeStages.adult.index]
headPaths[sapienConstants.lifeStages.elder.index] = headPaths[sapienConstants.lifeStages.adult.index]
hairPaths[sapienConstants.lifeStages.elder.index] = hairPaths[sapienConstants.lifeStages.adult.index]
beardPaths[sapienConstants.lifeStages.elder.index] = beardPaths[sapienConstants.lifeStages.adult.index]

local basePath = "composite/sapien/"


local function generateRemap(sharedState, materialRemap, hash, sapienID)
    local skinColorIndex = math.floor(((sharedState.skinColorFraction - 0.3) / 0.4) * 7)
    skinColorIndex = mjm.clamp(skinColorIndex + 1, 1, 7)

    materialRemap.skin = skinMaterials[skinColorIndex]
    hash = hash .. "s" .. mj:tostring(skinColorIndex)

    local hairColorIndex = mjm.clamp(sharedState.hairColorGene, 1, #hairMaterials)
    local eyeColorIndex = mjm.clamp(sharedState.eyeColorGene or 4, 1, #eyeMaterials)

    if skinColorIndex < 3 then
        materialRemap.mouth = "mouthDarker"
        hairColorIndex = math.min(hairColorIndex, 2)
        if skinColorIndex == 1 then
            hairColorIndex = 1
            eyeColorIndex = math.min(eyeColorIndex, 3)
        end
    elseif skinColorIndex <= 5 then
        if hairColorIndex >= 5 then
            hairColorIndex = 2
        end
    else
        materialRemap.mouth = "mouthLighter"
    end
    
    materialRemap.hair = hairMaterials[hairColorIndex]
    materialRemap.eyebrows = eyebrowsMaterials[hairColorIndex]
    materialRemap.eyelashes = eyelashesMaterials[hairColorIndex]
    materialRemap.eyelashesLong = eyelashesLongMaterials[hairColorIndex]
    hash = hash .. "h" .. mj:tostring(hairColorIndex)
    
    materialRemap.eyeBall = eyeMaterials[eyeColorIndex]
    hash = hash .. "e" .. mj:tostring(eyeColorIndex)


    local lifeStageIndex = sharedState.lifeStageIndex
    if lifeStageIndex == sapienConstants.lifeStages.elder.index then
        materialRemap.hair = "greyHair"
        hash = hash .. "g"
        
        materialRemap.eyelashes = "eyelashesGrey"
        materialRemap.eyelashesLong = "eyelashesGreyLong"
        materialRemap.eyebrows = "eyebrowsGrey"
    end

    return hash
end


function modelComposite_shadow:generate(object, gameObject)
    local sharedState = object.sharedState

    local hash = "sap"
    local genderIndex = maleIndex

    if sharedState.isFemale then
        genderIndex = femaleIndex
    end

    local randomIntOfffset = 15687

    local function getPath(paths, hashMarker)
        local byGender = paths[sharedState.lifeStageIndex]
        if byGender then
            local pathInfo = byGender[genderIndex]
            if pathInfo then
                if pathInfo.customFunction then
                    local fileName = pathInfo.customFunction(sharedState)
                    hash = hash .. "_" .. hashMarker .. fileName
                    return basePath .. fileName
                else
                    if pathInfo.count > 1 then 
                        randomIntOfffset = randomIntOfffset + 1
                        local offsetForNilOption = 0
                        if pathInfo.hasNilOption then
                            offsetForNilOption = 1
                        end
                        --mj:log("path generation:", object.uniqueID, " hash..hashMarker:", hash .. "_" .. hashMarker, " randomIntOfffset", randomIntOfffset, " pathInfo.count + offsetForNilOption:", pathInfo.count + offsetForNilOption)
                        local pathIndex = rng:integerForUniqueID(object.uniqueID, randomIntOfffset, pathInfo.count + offsetForNilOption) + 1
                        hash = hash .. "_" .. mj:tostring(genderIndex) .. "_" .. hashMarker .. mj:tostring(pathIndex)
                        --mj:log("pathIndex:", pathIndex)
                        if pathIndex > pathInfo.count then
                            return nil
                        end
                        return basePath .. pathInfo.base .. pathIndex .. ".glb"
                    else
                        hash = hash .. "_" .. mj:tostring(genderIndex) .. "_" .. hashMarker
                        return basePath .. pathInfo.base .. "1.glb"
                    end
                end
            end
        end
        return nil
    end

    local bodyPath = getPath(bodyPaths, "b")
    local headPath = getPath(headPaths, "h")
    local hairPath = getPath(hairPaths, "r")
    local beardPath = getPath(beardPaths, "f")

    --hairPath = "composite/sapien/womanHair7.glb"
    local cloakPath = nil--"composite/sapien/manCloak1.glb"

    local cloakType = nil
    local inventories = sharedState.inventories
    if inventories then
        local torsoInventory = inventories[sapienInventory.locations.torso.index]
        if torsoInventory then
            for i, gameObjectTypeIndex in ipairs(gameObject.clothingTypesByInventoryLocations[sapienInventory.locations.torso.index]) do
                local cloakCount = torsoInventory.countsByObjectType[gameObjectTypeIndex] or 0
                if cloakCount > 0 then
                    cloakType = gameObjectTypeIndex
                end
            end
        end
    end
    
    local materialRemap = {}

    if cloakType ~= nil then
        if sharedState.lifeStageIndex >= sapienConstants.lifeStages.adult.index then
            if sharedState.isFemale then
                if sharedState.pregnant then
                    cloakPath = "composite/sapien/womanCloak1Pregnant.glb"
                elseif sharedState.hasBaby then
                    cloakPath = "composite/sapien/womanCloak1WithBaby.glb"
                else
                    cloakPath = "composite/sapien/womanCloak1.glb"
                end
            else 
                cloakPath = "composite/sapien/manCloak1.glb"
            end
        else
            cloakPath = "composite/sapien/childCloak1.glb"
        end
        hash = hash .. "_c".. mj:tostring(cloakType)

        local function assignCloakRemaps(baseTable)
            for k,v in pairs(baseTable) do
                materialRemap[k] = v
            end
        end

        if cloakType == gameObject.types.mammothWoolskin.index then
            assignCloakRemaps(mammothCloakMaterials)
        else
            assignCloakRemaps(standardCloakMaterials)
        end

    end
    

    hash = generateRemap(sharedState, materialRemap, hash, object.uniqueID)

    --mj:log("object.uniqueID:", object.uniqueID, " hairPath:", hairPath, " hash:", hash)

    local result = {
        paths = {
            {
                path = bodyPath,
            },
            {
                path = headPath
            }
        },
        materialRemap = materialRemap,
    }

    if hairPath then
        table.insert(result.paths, {
            boneName = "head",
            path = hairPath
        })
    end

    if beardPath then
        table.insert(result.paths, {
            path = beardPath
        })
    end

    if cloakPath then
        table.insert(result.paths, {
            path = cloakPath
        })
    end

    result.hash = hash

    return result
end

--- MODDING START

function modelComposite_shadow:onload(modelComposite)
	modelComposite.generate = modelComposite_shadow.generate
end

--- MODDING END

return modelComposite_shadow