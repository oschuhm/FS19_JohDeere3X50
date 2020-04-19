-- Zylinder
-- Spezi für einfache Hydraulikzylinder oder Zylinder aller Arten
-- Ebenfalls sind einfache setDirections möglich

-- V2 Rotations die von einem Objekt ausgehend die Bewegung auf ein anderes übertragen sind nun auch möglich.
-- Damit kann man nun die komplette Animation einer Lenkung oder einer Heckhydraulik hierüber laufen lassen!

-- by modelleicher


zylinderV2 = {};

function zylinderV2.prerequisitesPresent(specializations)
	print("prerequisitesPresent is active");
    return true;
end;

-- new in FS19, you have to register yourself to functions otherwise they aren't called.
-- also, everything has the "on" prefix now (onLoad, onUpdate etc.)

-- registerEventListeners registeres listeners to base functions
-- its like appending to a function. It gets called when the base function is called.
-- its basically the same as it was previously with all the base-functions such as update and load and draw.
-- just that you have to register for them now it doesn't call them automcatically
function zylinderV2.registerEventListeners(vehicleType)
	--print("registerEventListeners called");
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", zylinderV2);
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", zylinderV2);
end;


function zylinderV2:onLoad(savegame)
	--print("onLoad loaded");
	
	-- also new in FS19.. Namespaces. So you do not have interference between different lua Scripts.
	-- its basically like using self.specName = {} table to store all your variables for that specialization in
	self.spec_zylinderV2 = {};  -- creating the table where all the variables are stored in
	local spec = self.spec_zylinderV2; -- this looks different to the example on the farmCon video. didn't work the other way though I assume mistake in their presentation
	-- from here on out its not self.spec_zylinderV2.zylinderCount for example (altough it should work too) its
	-- spec.zylinderCount instead

	local xmlFile = self.xmlFile;
	

    spec.zylinderCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.ZylinderV2.Zylinder#count"), 0);
    spec.zylinder = {};    
    if spec.zylinderCount ~= 0 then
        for i=1, spec.zylinderCount do
            local zyl = {};
            local path = string.format("vehicle.ZylinderV2.Zylinder.Zylinder%d", i);
            zyl.dir1 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#dir1"), self.i3dMappings);
            zyl.dir2 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#dir2"), self.i3dMappings);
            table.insert(spec.zylinder, zyl);
        end;
    end;
    
    spec.rotationsCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.ZylinderV2.Rotations#count"), 0);
    spec.rotations = {};
    if spec.rotationsCount ~= 0 then
        for i=1, spec.rotationsCount do
			--print("rotations count down");
            local rot = {};
            local path = string.format("vehicle.ZylinderV2.Rotations.Rotation%d", i);
            rot.index = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#node"), self.i3dMappings);
            rot.ref = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#ref"), self.i3dMappings);
			--print("index: "..rot.index);
			--print("ref: "..rot.ref);
            rot.addDegrees = Utils.getNoNil(getXMLFloat(xmlFile, path .. "#addDegrees"), 0.0);
            rot.rotAxis = string.lower(Utils.getNoNil(getXMLString(xmlFile, path .. "#rotAxis"), "x"));
            rot.getRotAxis = string.lower(Utils.getNoNil(getXMLString(xmlFile, path .. "#getRotAxis"), "y"));
            rot.lengthMultiplicator = Utils.getNoNil(getXMLFloat(xmlFile, path .. "#lengthMultiplicator"), 1);
            table.insert(spec.rotations, rot);
        end;
    end;
        
    spec.directionsCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.ZylinderV2.Directions#count"), 0);
    spec.directions = {};
    if spec.directionsCount ~= 0 then
        for i=1, spec.directionsCount do
            local dir = {};
            local path = string.format("vehicle.ZylinderV2.Directions.Direction%d", i);
            dir.index = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#node"), self.i3dMappings);
            dir.ref = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#ref"), self.i3dMappings);
            dir.doScaleBool = Utils.getNoNil(getXMLBool(xmlFile, path .. "#doScaleBool"));
            if dir.doScaleBool == true then
                dir.scaleRef = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, path .. "#scaleRef"), self.i3dMappings);            
                ax, ay, az = getWorldTranslation(dir.index);
                bx, by, bz = getWorldTranslation(dir.scaleRef);
                dir.scaleDistance = MathUtil.vector3Length(ax-bx, ay-by, az-bz);    
            end;
            table.insert(spec.directions, dir);
        end;
    end;
end;

function zylinderV2:onUpdate(dt) 

	--if firstTimeRun == nil then
		--DebugUtil.printTableRecursively(self.spec_motorized, "-" , 1, 1)
		--firstTimeRun = true;
	--end;

	
    if self:getIsActive() then 
		-- FS19 new, the spec namespace stuff is used here too of course
		local spec = self.spec_zylinderV2;
	
        if spec.zylinderCount ~= 0 and spec.zylinderCount ~= nil then
            for i=1, spec.zylinderCount do
                if spec.zylinder[i].dir1 ~= nil and spec.zylinder[i].dir2 ~= nil then
                local ax, ay, az = getWorldTranslation(spec.zylinder[i].dir1);
                local bx, by, bz = getWorldTranslation(spec.zylinder[i].dir2);
                x, y, z = worldDirectionToLocal(getParent(spec.zylinder[i].dir1), bx-ax, by-ay, bz-az);
                local upx, upy, upz = 0,1,0;
                if math.abs(y) > 0.99*MathUtil.vector3Length(x, y, z) then
                    upy = 0;
                    if y > 0 then
                        upy = 1;
                    else
                        upy = -1;
                    end;
                end;
                setDirection(spec.zylinder[i].dir1, x, y, z, upx, upy, upz);
                local ax2, ay2, az2 = getWorldTranslation(spec.zylinder[i].dir2);
                local bx2, by2, bz2 = getWorldTranslation(spec.zylinder[i].dir1);
                x2, y2, z2 = worldDirectionToLocal(getParent(spec.zylinder[i].dir2), bx2-ax2, by2-ay2, bz2-az2);
                local upx2, upy2, upz2 = 0,1,0;
                if math.abs(y2) > 0.99*MathUtil.vector3Length(x, y, z) then
                    upy2 = 0;
                    if y2 > 0 then
                        upy2 = 1;
                    else
                        upy2 = -1;
                    end;
                end;
                setDirection(spec.zylinder[i].dir2, x2, y2, z2, upx, upy, upz); 
                end;
            end;
        end;
        if spec.rotationsCount ~= 0 and spec.rotationsCount ~= nil then
            for i=1, spec.rotationsCount do
				--print("rotations count");
                if spec.rotations[i].index ~= nil and spec.rotations[i].ref ~= nil then
                    local rx, ry, rz = getRotation(spec.rotations[i].ref);
                    local rw = 0;
					--print(rx.." "..ry.." "..rz);
                    if spec.rotations[i].getRotAxis == "y" then -- ask first for y because it is the most used in this case (for performance reasons)
                        rw = ry*spec.rotations[i].lengthMultiplicator;
                    elseif spec.rotations[i].getRotAxis == "x" then
                        rw = rx*spec.rotations[i].lengthMultiplicator;
                    elseif spec.rotations[i].getRotAxis == "z" then
                        rw = rz*spec.rotations[i].lengthMultiplicator;
                    end;
                    if spec.rotations[i].rotAxis == "x" then -- ask first for x because it is the most used in this case(for performance reasons)
                        setRotation(spec.rotations[i].index, rw+math.rad(spec.rotations[i].addDegrees), 0, 0);
                    elseif spec.rotations[i].rotAxis == "y" then
                        setRotation(spec.rotations[i].index, 0, rw+math.rad(spec.rotations[i].addDegrees), 0);
                    elseif spec.rotations[i].rotAxis == "z" then
                        setRotation(spec.rotations[i].index, 0, 0, rw+math.rad(spec.rotations[i].addDegrees));
                    end;
                end;
            end;
        end;
        if spec.directionsCount ~= 0 and spec.directionsCount ~= nil then
            for i=1, spec.directionsCount do
                if spec.directions[i].index ~= nil and spec.directions[i].ref ~= nil then
                    local ax, ay, az = getWorldTranslation(spec.directions[i].index);
                    local bx, by, bz = getWorldTranslation(spec.directions[i].ref);
                    x, y, z = worldDirectionToLocal(getParent(spec.directions[i].index), bx-ax, by-ay, bz-az);
                    local upx, upy, upz = 0,1,0;
                    if math.abs(y) > 0.99*MathUtil.vector3Length(x, y, z) then
                        upy = 0;
                        if y > 0 then
                            upy = 1;
                        else
                            upy = -1;
                        end;
                    end;
                    setDirection(spec.directions[i].index, x, y, z, upx, upy, upz);
                    if spec.directions[i].doScaleBool == true and spec.directions[i].scaleRef ~= nil then
                        local distance = MathUtil.vector3Length(ax-bx, ay-by, az-bz);
                        local scaleX, scaleY, scaleZ = getScale(spec.directions[i].index);
                        local setScaleWert = scaleZ * (distance / spec.directions[i].scaleDistance);
                        setScale(spec.directions[i].index, 1, 1, setScaleWert);
                    end;
                end;
            end;
        end;
    end; 
end;
