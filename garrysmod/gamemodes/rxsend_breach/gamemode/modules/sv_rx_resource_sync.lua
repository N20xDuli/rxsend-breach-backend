-- Collection 3811157151 expanded to its downloadable child items.
-- Collection IDs are not downloadable Workshop items.
-- Exclude 2819475665: FPS Booster scripts; no gamemode resource references.
local collectionItems = {
    "3567876064",
    "3567891498",
    "3567892302",
    "3567892878",
    "3567889831",
    "3567888612",
    "3567893759",
    "3567899380",
    "3580198545",
    "893244794",
    "657241323",
    "1819166858",
    "2304089398",
    "1344177917",
    "2100566379",
    "2101039441",
    "2101041416",
    "2101049192",
    "2101131804",
    "2101184542",
    "2101211621",
    "3688433314",
    "3122878422",
}

-- Verified public resource replacements and local additions.
local supplementalContent = {
    "3814627193", -- legacy-weapons
    "3814629409", -- legacy-map
    "3814631087", -- legacy-scp
    "3814631720", -- legacy-faces
    "3814632544", -- custom-content
    "3814634552", -- legacy-client
    "3814636915", -- legacy-items
}

local added = {}
for _, list in ipairs({collectionItems, supplementalContent}) do
    for _, workshopID in ipairs(list) do
        if not added[workshopID] then
            added[workshopID] = true
            resource.AddWorkshop(workshopID)
        end
    end
end
