local MIN_X = -30000
local MAX_X = 30000
local MIN_Z = -30000
local MAX_Z = 30000


function generateRandomWalkVector(min, max)
    local currentHeight = 0
    local val = {}

    local mode = math.random(4); -- mode of random walking, shifts probability distribution
    local modeAge = 10; -- mode age, when goes to zero, mode is reset

    for i=0, max do
        val[i] = currentHeight
        if (mode == 1) then
            currentHeight = currentHeight + math.random(-1,1)
        elseif (mode == 2) then
            if (math.random(3) == 1) then
                currentHeight = currentHeight + math.random(-1,1)
            else
                currentHeight = currentHeight
            end
        elseif (mode == 3) then
            if (math.random(3) == 1) then
                currentHeight = currentHeight + math.random(-1,1)
            else
                currentHeight = currentHeight + 1
            end
        elseif (mode == 4) then
            if (math.random(3) == 1) then
                currentHeight = currentHeight + math.random(-1,1)
            else
                currentHeight = currentHeight - 1
            end
        end
        modeAge = modeAge - 1;
        if (modeAge == 0) then
            mode = math.random(4)
            modeAge = 100
        end

        if (math.random(1000) == 1) then
            currentHeight = currentHeight + math.random(-100,100)
        end

    end
    currentHeight = 0
    for i=0, min,-1 do
        val[i] = currentHeight
        currentHeight = currentHeight + math.random(-1,1)
    end

    return val
end

minetest.register_on_mapgen_init(function(mapgen_params)
    xWalk = generateRandomWalkVector(MIN_X, MAX_X);
    zWalk = generateRandomWalkVector(MIN_Z, MAX_Z);
    xzWalk1 = generateRandomWalkVector(MIN_X, MAX_X);
    xzWalk2 = generateRandomWalkVector(MIN_Z, MAX_Z);
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

    local index2d = 0
    for z = minp.z, maxp.z do
    for y = minp.y, maxp.y do
    for x = minp.x, maxp.x do
        if xWalk[x] then
            index2d = (z - minp.z) * csize.x + (x - minp.x) + 1   
            local ivm = a:index(x, y, z)

            if y < (xWalk[x] + zWalk[z] + xzWalk1[x + z] + xzWalk2[x - z]) / 3 then
                data[ivm] = c_stone
                write = true
            elseif y < 1 then
                data[ivm] = c_water
                write = true
            end
         end
     end
     end
     end

    if write then
        vm:set_data(data)
        vm:set_lighting({day = 0, night = 0})
        vm:calc_lighting()
        vm:update_liquids()
        vm:write_to_map()
    end

end)