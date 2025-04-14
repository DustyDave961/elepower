-- This is a crafter type machine base.
-- It accepts a recipe type registered beforehand.
-- see elepower_compat >> external.lua for explanation
-- shorten table ref
local epr = ele.external.ref
local efs = ele.formspec

-- Specialized formspec for crafters
function ele.formspec.get_crafter_formspec(craft_type, power, percent, pos,
                                           machine_name, state)
    local start, bx, by, mx = efs.begin(11.75, 10.45)
    local craftstats = elepm.craft.types[craft_type]
    local craft_reg_path = elepm.craft[craft_type]
    local input_size = craftstats.inputs
    local material_inputs = {}
    local mat_inputs_1 = "|"
    local mat_inputs_2 = "|"
    local mat_inputs_3 = "|"
    local formspec_inout_icon_tooltip
    local icon_def_slot_1 = minetest.registered_nodes[machine_name]
                                .ele_icon_material_1 or
                                "elepower_gui_icon_crafter_genmat_1.png"
    local icon_def_slot_2 = minetest.registered_nodes[machine_name]
                                .ele_icon_material_2 or
                                "elepower_gui_icon_crafter_genmat_2.png"
    local icon_def_slot_3 = minetest.registered_nodes[machine_name]
                                .ele_icon_material_3 or
                                "elepower_gui_icon_crafter_genmat_3.png"

    -- Start add icons and tooltips for input slots
    -- setting material name values to keys helps remove duplicates
    -- for cooking we have to retrieve from MT engine
    if craft_type == "cooking" then
        local sort_output = {}
        for name, def in pairs(minetest.registered_items) do
            local recipe = minetest.get_all_craft_recipes(name)

            if recipe ~= nil then
                for k, v in pairs(recipe) do
                    if v.method == "cooking" and v.output ~= "" then
                        local reg_name = v.items[1]
                        local description

                        if string.find(reg_name, "group") ~= nil then
                            description =
                                string.gsub(reg_name, "group:", "All ")
                        else
                            description =
                                minetest.registered_items[reg_name].description
                        end
                        -- remove any text on 2nd/3rd line
                        if string.find(description, "\n") then
                            description = string.split(description, "\n")
                            description = description[1]
                        end
                        material_inputs[description] = 1
                    end
                end
            end
        end
    else
        for _, craft_recipes in pairs(craft_reg_path) do
            for item_pos, item in pairs(craft_recipes.recipe) do
                for item_name, item_num in pairs(item) do
                    -- have to check all registered items
                    if minetest.registered_items[item_name] then
                        local description =
                            minetest.registered_items[item_name].description

                        -- remove any text on 2nd/3rd line
                        if string.find(description, "\n") then
                            description = string.split(description, "\n")
                            description = description[1]
                        end

                        material_inputs[description .. ":" .. item_pos] =
                            item_pos -- add a unique value to name
                    end
                end
            end
        end
    end

    -- reverse table so we can sort
    local material_in_sort = {}
    for k, v in pairs(material_inputs) do table.insert(material_in_sort, k) end
    table.sort(material_in_sort)

    for k, mat_desc in pairs(material_in_sort) do

        local mat_desc_r = string.gsub(mat_desc, ":(.*)", "") -- remove :1,:2,:3
        if mat_desc_r ~= "" then
            if material_inputs[mat_desc] == 1 then
                mat_inputs_1 = mat_inputs_1 .. "\n" .. mat_desc_r

            elseif material_inputs[mat_desc] == 2 then
                mat_inputs_2 = mat_inputs_2 .. "\n" .. mat_desc_r

            elseif material_inputs[mat_desc] == 3 then
                mat_inputs_3 = mat_inputs_3 .. "\n" .. mat_desc_r
            end
        end
    end
    mat_inputs_1 = string.gsub(mat_inputs_1, "|\n", "")
    mat_inputs_2 = string.gsub(mat_inputs_2, "|\n", "")
    mat_inputs_3 = string.gsub(mat_inputs_3, "|\n", "")

    -- adjust tooltip and layout depending on if we have 1/2/3 input slots
    if input_size == 1 then
        formspec_inout_icon_tooltip = "image[3.25,3.25;0.5,0.5;" ..
                                          icon_def_slot_1 .. "]" ..
                                          "tooltip[3,3;1,1;" .. mat_inputs_1 ..
                                          ";#30434c;#0399c6]" -- "tooltip[1.5,2.0;1,1;"..minetest.colorize("#0399c6",mat_inputs).."]"

    elseif input_size == 2 then
        formspec_inout_icon_tooltip = "image[2.25,3.25;0.5,0.5;" ..
                                          icon_def_slot_1 .. "]" ..
                                          "tooltip[2,3;1,1;" .. mat_inputs_1 ..
                                          ";#30434c;#0399c6]" ..
                                          "image[3.45,3.25;0.5,0.5;" ..
                                          icon_def_slot_2 .. "]" ..
                                          "tooltip[3.25,3;1,1;" .. mat_inputs_2 ..
                                          ";#30434c;#0399c6]"

    else
        formspec_inout_icon_tooltip = "image[2.25,3.25;0.5,0.5;" ..
                                          icon_def_slot_1 .. "]" ..
                                          "tooltip[2,3;1,1;" .. mat_inputs_1 ..
                                          ";#30434c;#0399c6]" ..
                                          "image[3.45,3.25;0.5,0.5;" ..
                                          icon_def_slot_2 .. "]" ..
                                          "tooltip[3.25,3;1,1;" .. mat_inputs_2 ..
                                          ";#30434c;#0399c6]" ..
                                          "image[4.7,3.25;0.5,0.5;" ..
                                          icon_def_slot_3 .. "]" ..
                                          "tooltip[4.5,3;1,1;" .. mat_inputs_3 ..
                                          ";#30434c;#0399c6]"
    end
    -- End add icons tooltips for in slots

    local gui_name = "gui_furnace_arrow"
    if craftstats.gui_name then gui_name = craftstats.gui_name end

    local bar = "image[6.125,2.125;1,1;" .. gui_name .. "_bg.png^[transformR270]"

    if percent ~= nil then
        bar =
            "image[6.125,2.125;1,1;" .. gui_name .. "_bg.png^[lowpart:" .. (percent) ..
                ":" .. gui_name .. "_fg.png^[transformR270]"
    end

    local in_width = input_size
    local in_height = 1

    for n = 2, 4 do
        if input_size % n == 0 and input_size ~= n then
            in_width = input_size / n
            in_height = input_size / n
        end
    end

    local y = 2.125
    local x = 3

    if in_height == 2 then
        y = 1
    elseif in_height >= 3 then
        y = 0.5
    end

    if in_width >= 2 then x = 2 end

    return start ..
               efs.power_meter_v2(power) ..
               efs.state_switcher(mx - 1, by, state) ..
               efs.list("context", "src", x, y, in_width, in_height) ..
               bar ..
               formspec_inout_icon_tooltip ..
               efs.list("context", "dst", 7.875, 1.5, 2, 2) ..
               epr.gui_player_inv() ..
               "listring[current_player;main]" ..
               "listring[context;src]" ..
               "listring[current_player;main]" ..
               "listring[context;dst]" ..
               "listring[current_player;main]"
end

-- Don't duplicate function for every single crafter node
local function crafter_timer(pos, elapsed)
    local refresh = false
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    -- tt_time = minetest.get_node_timer(pos)

    -- Specialized for universal crafter node
    local machine_node = minetest.get_node(pos).name
    local machine_def = minetest.registered_nodes[machine_node]

    -- If this is an active node, get the inactive version
    if machine_def.groups['ele_active'] == 1 then
        machine_node = machine_def.drop -- Reliable
        machine_def = minetest.registered_nodes[machine_node]
    end

    local capacity = ele.helpers.get_node_property(meta, pos, "capacity")
    local usage = ele.helpers.get_node_property(meta, pos, "usage")
    local storage = ele.helpers.get_node_property(meta, pos, "storage")
    local speed = ele.helpers.get_node_property(meta, pos, "craft_speed")
    local time = meta:get_int("src_time")
    local state = meta:get_int("state")
    local status = "Idle"

    local is_enabled = ele.helpers.state_enabled(meta, pos, state)
    local res_time = 0

    local get_formspec = machine_def.get_formspec or
                             ele.formspec.get_crafter_formspec

    local pow_buffer = {capacity = capacity, storage = storage, usage = 0}

    -- Default craft speed is 1
    if speed == 0 then speed = 1 end

    while true do
        if not is_enabled then
            time = 0
            status = "Off"
            break
        end

        local result = elepm.get_recipe(machine_def.craft_type,
                                        inv:get_list("src"))
        local power_operation = false

        -- Determine if there is enough power for this action
        res_time = result.time
        if result.time ~= 0 and pow_buffer.storage >= usage then
            power_operation = true
            pow_buffer.usage = usage
        end

        if result.time == 0 or not power_operation then
            ele.helpers.swap_node(pos, machine_node)

            if result.time == 0 then
                time = 0
                status = "Idle"
            else
                status = "Out of Power!"
            end

            break
        end

        refresh = true
        status = "Active"

        -- One step
        pow_buffer.storage = pow_buffer.storage - usage
        time = time + ele.helpers.round(speed * 10)

        if machine_def.ele_active_node then
            local active_node = machine_node .. "_active"
            if machine_def.ele_active_node ~= true then
                active_node = machine_def.ele_active_node
            end

            ele.helpers.swap_node(pos, active_node)
        end

        if time <= ele.helpers.round(result.time * 10) then break end

        local output = result.output
        if type(output) ~= "table" then output = {output} end
        local output_stacks = {}
        for _, o in ipairs(output) do
            table.insert(output_stacks, ItemStack(o))
        end

        local room_for_output = true
        inv:set_size("dst_tmp", inv:get_size("dst"))
        inv:set_list("dst_tmp", inv:get_list("dst"))

        for _, o in ipairs(output_stacks) do
            if not inv:room_for_item("dst_tmp", o) then
                room_for_output = false
                break
            end
            inv:add_item("dst_tmp", o)
        end

        if not room_for_output then
            ele.helpers.swap_node(pos, machine_node)
            time = ele.helpers.round(res_time * 10)
            status = "Output Full!"
            break
        end

        time = 0
        inv:set_list("src", result.new_input)
        inv:set_list("dst", inv:get_list("dst_tmp"))
        break
    end

    local pct = 0
    if res_time > 0 and time > 0 then
        pct = math.floor((time / ele.helpers.round(res_time * 10)) * 100)
    end

    meta:set_string("formspec",
                    get_formspec(machine_def.craft_type, pow_buffer, pct, pos,
                                 minetest.get_node(pos).name, state))
    meta:set_string("infotext",
                    ("%s %s"):format(machine_def.description, status) .. "\n" ..
                        ele.capacity_text(capacity, storage))

    meta:set_int("src_time", time)
    meta:set_int("storage", pow_buffer.storage)

    return refresh
end

function elepm.register_crafter(nodename, nodedef)
    local craft_type = nodedef.craft_type
    if not craft_type or not elepm.craft.types[craft_type] then return nil end

    if not nodedef.groups then nodedef.groups = {} end

    nodedef.groups["ele_machine"] = 1
    nodedef.groups["ele_user"] = 1
    nodedef.groups["tubedevice"] = 1
    nodedef.groups["tubedevice_receiver"] = 1

    nodedef.on_timer = crafter_timer

    -- Allow for custom formspec
    local get_formspec = ele.formspec.get_crafter_formspec
    if nodedef.get_formspec then get_formspec = nodedef.get_formspec end

    local sizes = elepm.craft.types[craft_type]
    nodedef.on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", sizes.inputs)
        inv:set_size("dst", 4)

        local storage = ele.helpers.get_node_property(meta, pos, "storage")
        local capacity = ele.helpers.get_node_property(meta, pos, "capacity")
        local pow_buffer = {capacity = capacity, storage = storage, usage = 0}
        meta:set_string("formspec", get_formspec(craft_type, pow_buffer, nil,
                                                 pos, nodename))
    end

    -- Upgradable
    nodedef.ele_upgrades = {
        machine_chip = {"craft_speed", "usage", "inrush"},
        capacitor = {"capacity"}
    }

    ele.register_machine(nodename, nodedef)
end
