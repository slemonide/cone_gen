local MIN_X = -30000
local MAX_X = 30000
local MIN_Z = -30000
local MAX_Z = 30000

local NUMBER_OF_MAXIMUMS = 100

maximums = {}

function generate_random_coordinate()
    return math.random() * (MAX_X - MIN_X) - (MAX_X - MIN_X) * 0.5
end

function generate_random_position()
    return {
            x = generate_random_coordinate() % 1000,
            y = generate_random_coordinate() % 50,
            z = generate_random_coordinate() % 1000
        }
end

function generate_maximums()
    -- generates a list of pos, which are maximums

    local rsf = {}

    for i = 0, NUMBER_OF_MAXIMUMS do
        table.insert(rsf, generate_random_position())
    end

    return rsf
end

cache = {}
function is_inside_the_cone(pos, cone_max)
    if (pos.y < cone_max.y - math.abs(cone_max.x - pos.x)
           and pos.y < cone_max.y - math.abs(cone_max.z - pos.z)) then
    
        if (not cache[pos.x]) then
            cache[pos.x] = {}
        end

        if (not cache[pos.x][pos.z]) then
            cache[pos.x][pos.z] = math.min(cone_max.y - math.abs(cone_max.x - pos.x), cone_max.y - math.abs(cone_max.z - pos.z))
        else
            minetest.chat_send_all("assert failed")
        end

        return true
    end
    
    return false
end

function is_underground(pos)
    -- checks if given pos is underground
    
    for i, v in pairs(maximums) do
        if ((cache[pos.x] and cache[pos.x][pos.z] and pos.y < cache[pos.x][pos.z]) or is_inside_the_cone(pos,v)) then
            return true
        end
    end

    return false
end

minetest.register_on_mapgen_init(function(mapgen_params)
    math.randomseed(mapgen_params.seed) -- produce the same world for the same seed

    maximums = generate_maximums()

    minetest.chat_send_all("done generating")
end)


minetest.set_mapgen_params({mgname="singlenode"})

minetest.register_on_generated(function(minp, maxp, seed)
    local c_stone = minetest.get_content_id("default:stone")
    local c_water = minetest.get_content_id("default:water_source")

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data()
    local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    local csize = vector.add(vector.subtract(maxp, minp), 1)
    local write = false

-- debug
    local t1 = os.clock()
    local geninfo = "[mg] generates..."
-- debug


    local index2d = 0
    for z = minp.z, maxp.z do
    for y = minp.y, maxp.y do
    for x = minp.x, maxp.x do
        index2d = (z - minp.z) * csize.x + (x - minp.x) + 1   
        local ivm = a:index(x, y, z)

        if is_underground({x=x, y= y, z=z}) then
            data[ivm] = c_stone
            write = true
        elseif y < 1 then
            data[ivm] = c_water
            write = true
        end
     end
     end
     end

    local t2 = os.clock()
    local calcdelay = string.format("%.2fs", t2 - t1)

    if write then
        vm:set_data(data)
        vm:set_lighting({day = 0, night = 0})
        vm:calc_lighting()
        vm:update_liquids()
        vm:write_to_map()
    end

    -- debug
    local t3 = os.clock()
    local geninfo = "[mg] done after ca.: "..calcdelay.." + "..string.format("%.2fs", t3 - t2).." = "..string.format("%.2fs", t3 - t1)
    minetest.chat_send_all(geninfo)
    print(geninfo)
    -- debug

end)