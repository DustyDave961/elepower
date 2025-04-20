-- see elepower_compat >> external.lua for explanation
-- shorten table ref
local epi = ele.external.ing

-- *****************--
-- MACHINE RECIPES --
-- *****************--

--------------
-- Alloying --
--------------

local alloy_recipes = {
    {
        recipe = {
            "elepower_dynamics:iron_ingot", "elepower_dynamics:coal_dust 4"
        },
        output = "elepower_dynamics:steel_ingot"
    }, {
        recipe = {epi.copper_ingot .. " 2", epi.tin_ingot},
        output = epi.bronze_ingot .. " 3"
    }, {
        recipe = {
            "elepower_dynamics:iron_ingot 3", "elepower_dynamics:nickel_ingot"
        },
        output = "elepower_dynamics:invar_ingot 4"
    }, {
        recipe = {epi.gold_ingot .. " 2", "elepower_dynamics:invar_ingot"},
        output = "elepower_dynamics:electrum_ingot 3"
    }, {
        recipe = {"basic_materials:silicon", "elepower_dynamics:coal_dust 2"},
        output = "elepower_dynamics:silicon_wafer"
    }, {
        recipe = {epi.coal_lump, "elepower_dynamics:coal_dust 4"},
        output = "elepower_dynamics:graphite_ingot"
    }, {
        recipe = {
            "elepower_dynamics:silicon_wafer", "elepower_dynamics:gold_dust 4"
        },
        output = "elepower_dynamics:silicon_wafer_doped",
        time = 8
    }, {
        recipe = {epi.obsidian_glass, "elepower_dynamics:lead_ingot 4"},
        output = "elepower_dynamics:hardened_glass 4",
        time = 8
    }, {
        recipe = {epi.copper_ingot .. " 2", epi.silver_ingot},
        output = "basic_materials:brass_ingot 3",
        time = 8
    }, {
        recipe = {epi.bronze_ingot, "elepower_dynamics:steel_ingot 4"},
        output = "elepower_machines:heat_casing 4"
    }
}

-- Register alloy furnace recipes
for _, i in pairs(alloy_recipes) do
    elepm.register_craft({
        type = "alloy",
        recipe = i.recipe,
        output = i.output,
        time = i.time or 4
    })
end

--------------
-- Grinding --
--------------

local keywords = {ingot = 1, lump = 2, raw = 2, block = 9}
local ingot_map = {}
local block_map = {}
for mat, data in pairs(elepd.registered_dusts) do
    local kwfound = nil
    for keyword, count in pairs(keywords) do
        local found = ele.helpers.scan_item_list(mat, keyword)
        if found then
            if keyword == "_ingot" and not kwfound then
                kwfound = found
            elseif keyword == "_block" or keyword == "block" and
                not block_map[mat] then
                block_map[mat] = found
            end

            -- Grind recipe for material
            elepm.register_craft({
                type = "grind",
                recipe = {found},
                output = data.item .. " " .. count,
                time = count + 4
            })
        end
    end

    -- Add dust -> ingot smelting
    if kwfound then
        ingot_map[mat] = kwfound
        minetest.register_craft({
            type = "cooking",
            recipe = data.item,
            output = kwfound
        })
    end
end

-- Other recipes

local grinding_recipes = {
    {recipe = {epi.desert_sand .. " 4"}, output = "basic_materials:silicon"},
    {recipe = {epi.sand .. " 4"}, output = "basic_materials:silicon"},
    {recipe = {epi.cobble}, output = epi.gravel .. " 4"},
    {recipe = {epi.gravel}, output = epi.sand .. " 4"},
    {
        recipe = {"elepower_dynamics:graphite_ingot"},
        output = "elepower_dynamics:graphite_rod 3"
    },
    {recipe = {epi.mese}, output = epi.mese_crystal .. " 9"},
    {
        recipe = {epi.mese_crystal_fragment},
        output = "elepower_dynamics:mese_dust"
    }
}

if epi.flour ~= "" then
    table.insert(grinding_recipes, {
        recipe = { epi.wheat }, output = epi.flour .. " 2", time = 4
    })
end

-- Prevent duping in games without a discrete mese fragment
if epi.mese_crystal ~= epi.mese_crystal_fragment then
    table.insert(grinding_recipes, {
        recipe = { epi.mese_crystal }, output = epi.mese_crystal_fragment .. " 9"
    })
end

-- Register grind recipes
for _, i in pairs(grinding_recipes) do
    elepm.register_craft({
        type = "grind",
        recipe = i.recipe,
        output = i.output,
        time = i.time or 8
    })
end

-----------------
-- Compressing --
-----------------

for mat, ingot in pairs(ingot_map) do
    local plate = elepd.registered_plates[mat]
    local dust = elepd.registered_dusts[mat]

    if plate then
        elepm.register_craft({
            type = "compress",
            recipe = {ingot, ingot},
            output = plate.item .. " 2",
            time = 4
        })

        if dust then
            elepm.register_craft({
                type = "grind",
                recipe = {plate.item},
                output = dust.item,
                time = 6
            })
        end
    end
end

-- Detect sands
for name in pairs(minetest.registered_nodes) do
    if name:match("sand") and not name:match("sandstone") then
        local sand = name
        local sandstone = name .. "stone"
        if minetest.registered_nodes[sandstone] then
            elepm.register_craft({
                type = "compress",
                recipe = {sand .. " 2", sand .. " 2"},
                output = sandstone,
                time = 1
            })

            -- Also give a grinding recipe to get the sand back
            elepm.register_craft({
                type = "grind",
                recipe = {sandstone},
                output = sand .. " 4",
                time = 5
            })

            -- Find block as well
            local ssblock = sandstone .. "_block"
            if minetest.registered_nodes[ssblock] then
                elepm.register_craft({
                    type = "compress",
                    recipe = {sandstone .. " 2", sandstone .. " 2"},
                    output = ssblock,
                    time = 1
                })
            end
        end
    end
end

local compressor_recipes = {
    {
        recipe = {
            "elepower_dynamics:viridisium_block 4",
            "elepower_dynamics:viridisium_block 4"
        },
        output = "elepower_dynamics:xycrone_lump",
        time = 20
    }, {
        recipe = {
            "elepower_dynamics:coal_dust 2", "elepower_dynamics:coal_dust 2"
        },
        output = "elepower_dynamics:carbon_fiber",
        time = 2
    }, {
        recipe = {
            "elepower_dynamics:carbon_fiber 2",
            "elepower_dynamics:carbon_fiber 2"
        },
        output = "elepower_dynamics:carbon_sheet",
        time = 2
    }
}

-- Prevent duping in games without a discrete mese fragment
if epi.mese_crystal ~= epi.mese_crystal_fragment then
    table.insert(compressor_recipes, {
        recipe = {
            epi.mese_crystal_fragment .. " 4", epi.mese_crystal_fragment .. " 4"
        },
        output = epi.mese_crystal,
        time = 2
    })

    table.insert(compressor_recipes, {
        recipe = {epi.mese_crystal .. " 4", epi.mese_crystal .. " 4"},
        output = epi.mese,
        time = 2
    })
end

-- Register compressor recipes
for _, i in pairs(compressor_recipes) do
    elepm.register_craft({
        type = "compress",
        recipe = i.recipe,
        output = i.output,
        time = i.time or 1
    })
end

-------------
-- Sawmill --
-------------

-- Register all logs as sawable, if we can find a planks version
minetest.after(0.2, function()
    local wood_nodes = {}
    for name in pairs(minetest.registered_nodes) do
        if ele.helpers.get_item_group(name, "wood") then
            wood_nodes[#wood_nodes + 1] = name
        end
    end

    -- Begin making associations
    -- Get crafting recipe for all woods
    local assoc = {}
    for _, wood in ipairs(wood_nodes) do
        local recipes = minetest.get_all_craft_recipes(wood)
        if recipes then
            for _, recipe in ipairs(recipes) do
                if recipe.items and #recipe.items == 1 then
                    assoc[recipe.items[1]] = wood
                end
            end
        end
    end

    -- Register sawmill craft
    for tree, wood in pairs(assoc) do
        elepm.register_craft({
            type = "saw",
            recipe = {tree},
            output = {wood .. " 6", "elepower_dynamics:wood_dust"},
            time = 8
        })
    end
end)

---------------
-- Soldering --
---------------

local soldering_recipes = {
    {
        recipe = {
            "elepower_dynamics:silicon_wafer_doped", "elepower_dynamics:chip 4",
            "elepower_dynamics:lead_ingot 2"
        },
        output = "elepower_dynamics:microcontroller",
        time = 8
    }, {
        recipe = {
            epi.copper_ingot .. " 4", "elepower_dynamics:microcontroller 4",
            "elepower_dynamics:electrum_ingot 2"
        },
        output = "elepower_dynamics:soc",
        time = 28
    }, {
        recipe = {
            "elepower_dynamics:microcontroller",
            "elepower_dynamics:control_circuit", "elepower_dynamics:capacitor 5"
        },
        output = "elepower_dynamics:micro_circuit",
        time = 18
    }, {
        recipe = {
            "elepower_dynamics:chip 8",
            "elepower_dynamics:integrated_circuit 2",
            "elepower_dynamics:capacitor 4"
        },
        output = "elepower_dynamics:control_circuit",
        time = 20
    }, {
        recipe = {
            "elepower_dynamics:wound_copper_coil 4",
            "elepower_dynamics:wound_silver_coil 2",
            "basic_materials:copper_wire"
        },
        output = "elepower_dynamics:induction_coil",
        time = 16
    }, {
        recipe = {
            "elepower_dynamics:induction_coil 4", "basic_materials:copper_wire",
            "elepower_dynamics:zinc_dust 2"
        },
        output = "elepower_dynamics:induction_coil_advanced",
        time = 18
    }, {
        recipe = {
            "elepower_machines:power_cell_0",
            "elepower_machines:hardened_capacitor 2",
            "elepower_dynamics:invar_plate 8"
        },
        output = "elepower_machines:hardened_power_cell_0",
        time = 18
    }, {
        recipe = {
            "elepower_machines:hardened_power_cell_0",
            "elepower_machines:reinforced_capacitor 2",
            "elepower_dynamics:electrum_plate 8"
        },
        output = "elepower_machines:reinforced_power_cell_0",
        time = 20
    }, {
        recipe = {
            "elepower_machines:reinforced_power_cell_0",
            "elepower_machines:resonant_capacitor 2",
            "elepower_dynamics:viridisium_plate 8"
        },
        output = "elepower_machines:resonant_power_cell_0",
        time = 22
    }, {
        recipe = {
            "elepower_machines:resonant_power_cell_0",
            "elepower_machines:super_capacitor 2",
            "elepower_dynamics:xycrone_lump"
        },
        output = "elepower_machines:super_power_cell_0",
        time = 24
    }, {
        recipe = {
            "elepower_dynamics:integrated_circuit",
            "elepower_dynamics:induction_coil 2", "elepower_dynamics:soc"
        },
        output = "elepower_machines:upgrade_speed",
        time = 16
    }, {
        recipe = {
            "elepower_dynamics:integrated_circuit",
            "elepower_machines:hardened_capacitor 2", "elepower_dynamics:soc"
        },
        output = "elepower_machines:upgrade_efficiency",
        time = 16
    }, {
        recipe = {
            "elepower_machines:upgrade_efficiency",
            "elepower_machines:resonant_capacitor 2", "elepower_dynamics:soc"
        },
        output = "elepower_machines:upgrade_efficiency_2",
        time = 16
    }
}

-- Register solderer recipes
for _, i in pairs(soldering_recipes) do
    elepm.register_craft({
        type = "solder",
        recipe = i.recipe,
        output = i.output,
        time = i.time or 4
    })
end

-------------
-- Canning --
-------------

-- ******************--
-- CRAFTING RECIPES --
-- ******************--

-- Capacitors
minetest.register_craft({
    output = "elepower_machines:hardened_capacitor",
    recipe = {
        {
            "basic_materials:plastic_sheet", "basic_materials:plastic_sheet",
            "basic_materials:plastic_sheet"
        }, {
            "elepower_dynamics:invar_plate", epi.mese_crystal,
            "elepower_dynamics:invar_plate"
        }, {
            "elepower_dynamics:invar_plate", "elepower_dynamics:capacitor",
            "elepower_dynamics:invar_plate"
        }
    }
})

minetest.register_craft({
    output = "elepower_machines:reinforced_capacitor",
    recipe = {
        {
            "elepower_dynamics:invar_plate", "elepower_dynamics:invar_plate",
            "elepower_dynamics:invar_plate"
        }, {
            "elepower_dynamics:electrum_plate", epi.mese_crystal,
            "elepower_dynamics:electrum_plate"
        }, {
            "elepower_dynamics:electrum_plate",
            "elepower_machines:hardened_capacitor",
            "elepower_dynamics:electrum_plate"
        }
    }
})

minetest.register_craft({
    output = "elepower_machines:resonant_capacitor",
    recipe = {
        {
            "elepower_dynamics:electrum_plate",
            "elepower_dynamics:electrum_plate",
            "elepower_dynamics:electrum_plate"
        }, {
            "elepower_dynamics:viridisium_plate", epi.mese_crystal,
            "elepower_dynamics:viridisium_plate"
        }, {
            "elepower_dynamics:viridisium_plate",
            "elepower_machines:reinforced_capacitor",
            "elepower_dynamics:viridisium_plate"
        }
    }
})

minetest.register_craft({
    output = "elepower_machines:super_capacitor",
    recipe = {
        {
            "elepower_dynamics:viridisium_plate",
            "elepower_dynamics:viridisium_plate",
            "elepower_dynamics:viridisium_plate"
        }, {
            "elepower_dynamics:viridisium_plate",
            "elepower_dynamics:xycrone_lump",
            "elepower_dynamics:viridisium_plate"
        }, {
            "elepower_dynamics:xycrone_lump",
            "elepower_machines:resonant_capacitor",
            "elepower_dynamics:xycrone_lump"
        }
    }
})

minetest.register_craft({
    output = "elepower_machines:heavy_filter",
    recipe = {
        {
            "elepower_dynamics:steel_plate", "fluid_transfer:fluid_duct",
            "elepower_dynamics:steel_plate"
        }, {
            "basic_materials:silicon", "elepower_dynamics:servo_valve",
            "basic_materials:silicon"
        }, {
            "elepower_dynamics:carbon_sheet", "fluid_transfer:fluid_duct",
            "elepower_dynamics:carbon_sheet"
        }
    }
})

minetest.register_craft({
    output = "elepower_machines:opaque_duct_roll",
    recipe = {
        {
            "elepower_dynamics:opaque_duct", "elepower_dynamics:opaque_duct",
            "elepower_dynamics:opaque_duct"
        }, {
            "elepower_dynamics:opaque_duct", "basic_materials:motor",
            "elepower_dynamics:opaque_duct"
        }, {
            "elepower_dynamics:opaque_duct", "elepower_dynamics:opaque_duct",
            "elepower_dynamics:opaque_duct"
        }
    }
})

minetest.register_craft({
    output = "elepower_machines:wind_turbine_blade",
    recipe = {
        {"", epi.group_wood, epi.group_wood},
        {epi.group_stick, epi.group_wood, epi.group_wood},
        {epi.group_stick, epi.group_stick, ""}
    }
})

minetest.register_craft({
    output = "elepower_machines:wind_turbine_blades",
    recipe = {
        {
            "elepower_machines:wind_turbine_blade",
            "elepower_machines:wind_turbine_blade",
            "elepower_machines:wind_turbine_blade"
        }, {
            "elepower_machines:wind_turbine_blade", epi.group_wood,
            "elepower_machines:wind_turbine_blade"
        }, {
            "elepower_machines:wind_turbine_blade",
            "elepower_machines:wind_turbine_blade",
            "elepower_machines:wind_turbine_blade"
        }
    }
})

-- Nodes

-- Coal-fired Alloy Furnace
minetest.register_craft({
    output = "elepower_machines:coal_alloy_furnace",
    recipe = {
        {epi.brick, epi.brick, epi.brick},
        {epi.furnace, epi.coal_lump, epi.furnace},
        {epi.brick, epi.brick, epi.brick}
    }
})

-- Grindstone
minetest.register_craft({
    output = "elepower_machines:grindstone",
    recipe = {
        {epi.group_stone, epi.group_stone, epi.group_stone},
        {epi.flint, epi.flint, epi.flint}, {epi.cobble, epi.cobble, epi.cobble}
    }
})

minetest.register_craft({
    output = "elepower_machines:crank",
    recipe = {
        {epi.group_stick, epi.group_stick, epi.group_stick},
        {"", "", epi.group_stick}, {"", "", epi.group_stick}
    }
})

-- Machine block
minetest.register_craft({
    output = "elepower_machines:machine_block",
    recipe = {
        {
            "elepower_dynamics:steel_ingot", epi.glass,
            "elepower_dynamics:steel_ingot"
        }, {epi.glass, "elepower_dynamics:brass_gear", epi.glass}, {
            "elepower_dynamics:steel_ingot", "basic_materials:motor",
            "elepower_dynamics:steel_ingot"
        }
    }
})

-- Generator
minetest.register_craft({
    output = "elepower_machines:generator",
    recipe = {
        {"", "elepower_dynamics:steel_ingot", ""}, {
            "elepower_dynamics:steel_ingot", "elepower_machines:machine_block",
            "elepower_dynamics:steel_ingot"
        }, {
            "elepower_dynamics:wound_copper_coil", epi.coal_lump,
            "elepower_dynamics:wound_copper_coil"
        }
    }
})

-- Liquid Fuel Combustion Generator
minetest.register_craft({
    output = "elepower_machines:fuel_burner",
    recipe = {
        {
            "elepower_dynamics:wound_copper_coil",
            "elepower_dynamics:integrated_circuit",
            "elepower_dynamics:wound_copper_coil"
        }, {epi.brick, "elepower_dynamics:portable_tank", epi.brick}, {
            "elepower_dynamics:servo_valve", "elepower_machines:generator",
            "elepower_dynamics:servo_valve"
        }
    }
})

-- Alloy Furnace
minetest.register_craft({
    output = "elepower_machines:alloy_furnace",
    recipe = {
        {"", "elepower_dynamics:integrated_circuit", ""}, {
            "elepower_dynamics:wound_copper_coil",
            "basic_materials:heating_element",
            "elepower_dynamics:wound_copper_coil"
        }, {epi.brick, "elepower_machines:machine_block", epi.brick}
    }
})

-- Solderer
minetest.register_craft({
    output = "elepower_machines:solderer",
    recipe = {
        {"", "elepower_dynamics:integrated_circuit", ""}, {
            "elepower_dynamics:chip", "elepower_machines:machine_block",
            "elepower_dynamics:chip"
        }, {
            "elepower_dynamics:invar_gear",
            "elepower_dynamics:wound_copper_coil",
            "elepower_dynamics:invar_gear"
        }
    }
})

-- Furnace
minetest.register_craft({
    output = "elepower_machines:furnace",
    recipe = {
        {"", "elepower_dynamics:integrated_circuit", ""}, {
            "elepower_dynamics:wound_copper_coil",
            "basic_materials:heating_element",
            "elepower_dynamics:wound_copper_coil"
        }, {epi.clay_brick, "elepower_machines:machine_block", epi.clay_brick}
    }
})

-- Pulverizer
minetest.register_craft({
    output = "elepower_machines:pulverizer",
    recipe = {
        {"", "elepower_dynamics:integrated_circuit", ""},
        {epi.flint, "elepower_machines:machine_block", epi.flint}, {
            "elepower_dynamics:wound_copper_coil",
            "elepower_dynamics:lead_gear", "elepower_dynamics:wound_copper_coil"
        }
    }
})

-- Sawmill
minetest.register_craft({
    output = "elepower_machines:sawmill",
    recipe = {
        {"", "elepower_dynamics:integrated_circuit", ""}, {
            "elepower_dynamics:steel_gear", "elepower_machines:machine_block",
            "elepower_dynamics:steel_gear"
        }, {
            "elepower_dynamics:lead_ingot", "elepower_dynamics:diamond_gear",
            "elepower_dynamics:lead_ingot"
        }
    }
})

-- Power Cell
minetest.register_craft({
    output = "elepower_machines:power_cell_0",
    recipe = {
        {
            "elepower_dynamics:lead_ingot", "elepower_dynamics:control_circuit",
            "elepower_dynamics:lead_ingot"
        }, {
            "elepower_dynamics:wound_copper_coil",
            "elepower_machines:machine_block",
            "elepower_dynamics:wound_copper_coil"
        }, {
            "elepower_dynamics:lead_ingot", "elepower_dynamics:battery",
            "elepower_dynamics:lead_ingot"
        }
    }
})

-- Water Accumulator
minetest.register_craft({
    output = "elepower_machines:accumulator",
    recipe = {
        {"", "fluid_transfer:fluid_duct", ""},
        {epi.glass, "elepower_machines:machine_block", epi.glass}, {
            "elepower_dynamics:steel_gear", "elepower_dynamics:servo_valve",
            "elepower_dynamics:steel_gear"
        }
    }
})

-- Lava Cooler
minetest.register_craft({
    output = "elepower_machines:lava_cooler",
    recipe = {
        {
            "bucket:bucket_water", "elepower_dynamics:control_circuit",
            "bucket:bucket_lava"
        }, {
            "fluid_transfer:fluid_duct", "elepower_machines:machine_block",
            "fluid_transfer:fluid_duct"
        }, {
            "elepower_dynamics:servo_valve", "elepower_dynamics:tin_gear",
            "elepower_dynamics:servo_valve"
        }
    },
    replacements = {
        {"bucket:bucket_water", "bucket:bucket_empty"},
        {"bucket:bucket_lava", "bucket:bucket_empty"}
    }
})

-- Lava Generator
minetest.register_craft({
    output = "elepower_machines:lava_generator",
    recipe = {
        {
            "elepower_dynamics:wound_silver_coil",
            "elepower_dynamics:control_circuit",
            "elepower_dynamics:wound_silver_coil"
        }, {epi.brick, "elepower_machines:machine_block", epi.brick}, {
            "elepower_dynamics:invar_gear", "elepower_dynamics:servo_valve",
            "elepower_dynamics:invar_gear"
        }
    }
})

-- Compressor Piston
minetest.register_craft({
    output = "elepower_machines:compressor_piston",
    recipe = {
        {"", "elepower_dynamics:steel_ingot", ""},
        {"", "elepower_dynamics:steel_ingot", ""},
        {epi.bronze_ingot, epi.bronze_ingot, epi.bronze_ingot}
    }
})

minetest.register_craft({
    output = "elepower_machines:compressor_piston",
    recipe = {
        {"", "elepower_dynamics:steel_ingot", ""},
        {"", "elepower_dynamics:steel_ingot", ""},
        {"", "elepower_dynamics:bronze_plate", ""}
    }
})

-- Compressor
minetest.register_craft({
    output = "elepower_machines:compressor",
    recipe = {
        {
            "elepower_dynamics:integrated_circuit",
            "elepower_machines:compressor_piston",
            "elepower_dynamics:wound_copper_coil"
        }, {
            "elepower_dynamics:steel_gear", "elepower_machines:machine_block",
            "elepower_dynamics:steel_gear"
        }, {
            "elepower_dynamics:steel_ingot",
            "elepower_machines:compressor_piston",
            "elepower_dynamics:steel_ingot"
        }
    }
})

-- Turbine blades
minetest.register_craft({
    output = "elepower_machines:turbine_blades",
    recipe = {
        {
            "elepower_dynamics:steel_plate", "elepower_dynamics:steel_plate",
            "elepower_dynamics:steel_plate"
        }, {
            "elepower_dynamics:steel_plate", "elepower_dynamics:steel_ingot",
            "elepower_dynamics:steel_plate"
        }, {
            "elepower_dynamics:steel_plate", "elepower_dynamics:steel_plate",
            "elepower_dynamics:steel_plate"
        }
    }
})

-- Steam Turbine
minetest.register_craft({
    output = "elepower_machines:steam_turbine",
    recipe = {
        {
            "elepower_dynamics:induction_coil",
            "elepower_machines:turbine_blades",
            "elepower_dynamics:induction_coil"
        }, {
            "elepower_dynamics:steel_plate", "elepower_machines:machine_block",
            "elepower_dynamics:steel_plate"
        }, {
            "elepower_dynamics:invar_gear", "elepower_machines:turbine_blades",
            "elepower_dynamics:invar_gear"
        }
    }
})

-- Canning Machine
minetest.register_craft({
    output = "elepower_machines:canning_machine",
    recipe = {
        {
            "elepower_dynamics:wound_copper_coil",
            "elepower_machines:compressor_piston",
            "elepower_dynamics:wound_copper_coil"
        }, {
            "elepower_dynamics:tin_can", "elepower_machines:machine_block",
            "elepower_dynamics:tin_can"
        }, {
            "elepower_dynamics:steel_gear", "elepower_dynamics:tin_gear",
            "elepower_dynamics:steel_gear"
        }
    }
})

-- Bucketer
minetest.register_craft({
    output = "elepower_machines:bucketer",
    recipe = {
        {"", "elepower_dynamics:portable_tank", ""}, {
            "elepower_dynamics:tin_can", "elepower_machines:machine_block",
            "elepower_dynamics:tin_can"
        }, {
            "elepower_dynamics:servo_valve", "elepower_dynamics:tin_gear",
            "elepower_dynamics:servo_valve"
        }
    }
})

-- Electrolyzer
minetest.register_craft({
    output = "elepower_machines:electrolyzer",
    recipe = {
        {
            "elepower_dynamics:copper_plate",
            "elepower_dynamics:integrated_circuit",
            "elepower_dynamics:zinc_plate"
        }, {
            "bucket:bucket_empty", "elepower_machines:machine_block",
            "elepower_dynamics:gas_container"
        }, {
            "elepower_dynamics:servo_valve",
            "elepower_dynamics:wound_copper_coil",
            "elepower_dynamics:servo_valve"
        }
    }
})

-- Advanced Machine Block
minetest.register_craft({
    output = "elepower_machines:advanced_machine_block 4",
    recipe = {
        {
            "elepower_dynamics:electrum_plate",
            "elepower_dynamics:induction_coil_advanced",
            "elepower_dynamics:electrum_plate"
        }, {
            "elepower_dynamics:brass_plate", "elepower_machines:heat_casing",
            "elepower_dynamics:brass_plate"
        }, {
            "elepower_dynamics:electrum_plate",
            "elepower_dynamics:induction_coil_advanced",
            "elepower_dynamics:electrum_plate"
        }
    }
})

-- Pump
minetest.register_craft({
    output = "elepower_machines:pump",
    recipe = {
        {
            "elepower_dynamics:lead_gear",
            "elepower_dynamics:integrated_circuit",
            "elepower_dynamics:lead_gear"
        }, {
            "bucket:bucket_empty", "elepower_machines:machine_block",
            "bucket:bucket_empty"
        }, {
            "elepower_dynamics:electrum_plate",
            "elepower_machines:opaque_duct_roll",
            "elepower_dynamics:electrum_plate"
        }
    }
})

-- Wind Turbine
minetest.register_craft({
    output = "elepower_machines:wind_turbine",
    recipe = {
        {
            "elepower_dynamics:wound_copper_coil",
            "elepower_machines:turbine_blades",
            "elepower_dynamics:wound_copper_coil"
        }, {
            "elepower_dynamics:steel_plate", "elepower_machines:machine_block",
            "elepower_dynamics:steel_plate"
        }, {
            "elepower_dynamics:invar_gear", "elepower_dynamics:steel_plate",
            "elepower_dynamics:invar_gear"
        }
    }
})

-- Evaporizer
minetest.register_craft({
    output = "elepower_machines:evaporator",
    recipe = {
        {
            "elepower_dynamics:steel_plate", epi.steel_block,
            "elepower_dynamics:steel_plate"
        }, {
            "elepower_dynamics:steel_plate", "elepower_machines:machine_block",
            "elepower_dynamics:steel_plate"
        }, {
            "elepower_dynamics:induction_coil", "elepower_dynamics:zinc_plate",
            "elepower_dynamics:induction_coil"
        }
    }
})

-- PCB Plant
minetest.register_craft({
    output = "elepower_machines:pcb_plant",
    recipe = {
        {"", "elepower_dynamics:integrated_circuit", ""}, {
            "elepower_dynamics:chip", "elepower_machines:machine_block",
            "elepower_dynamics:chip"
        }, {
            "elepower_dynamics:servo_valve", "elepower_dynamics:uv_bulb",
            "elepower_dynamics:bronze_gear"
        }
    }
})
