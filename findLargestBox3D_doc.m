%% |FINDLARGESTBOX3D| Examples
% The function <https://www.mathworks.com/matlabcentral/fileexchange/######
% |findLargestBox3D|> finds the maximum-volume axis-aligned cuboid(s)
% within a 3D boolean mask using an exact slab-collapse algorithm.
%
% The mask can be provided either as a 3D logical/numeric array, or as
% three vectors of voxel indices. Optional name-value arguments allow the
% user to specify the maximum number of matches, as well as limits on the
% cuboid height(s), width(s), depth(s), and volume(s).
%
% Internally, |findLargestBox3D| collapses along the smallest mask
% dimension and calls |findLargestBox2D| on each 2D slab footprint.
%
%% Basic Usage: 3D Array
%
% |findLargestBox3D| accepts a 3D logical or numeric array where
% |TRUE|/non-zero indicates usable voxels and |FALSE|/zero indicates
% blocked voxels. It returns the bounding box of the largest cuboid
% consisting entirely of |TRUE|/non-zero voxels.
mask = false(9,14,6);
mask(2:4, 2:8, 2:3) = true; % 3x7x2 = 42
bbox = findLargestBox3D(mask)
%% Output 1: |bbox| -- Bounding Box Indices
%
% The first output |bbox| is an *Nx6* matrix with one row per cuboid found.
% Its columns are |[r1, r2, c1, c2, p1, p2]|:
%
% * |r1|, |r2| -- the first and last *row* indices of the cuboid.
% * |c1|, |c2| -- the first and last *column* indices of the cuboid.
% * |p1|, |p2| -- the first and last *page* indices of the cuboid.
%
% The cuboid spans voxels |(r1,c1,p1)| to |(r2,c2,p2)| inclusive.
% When only one cuboid is found, |bbox| is a 1x6 row vector.
mask(5:7, 2:12, 2:4) = true; % 3x11x3 = 99
bbox = findLargestBox3D(mask)
%% Output 2: |dims| -- Cuboid Dimensions
%
% The second output |dims| is an *Nx3* matrix with columns
% |[height,width,depth]| giving the voxel dimensions of each cuboid found:
[bbox,dims] = findLargestBox3D(mask)
%% Output 3: |volume| -- Cuboid Volume
%
% The third output |volume| is a scalar equal to |height * width * depth|
% of all of the largest cuboid(s):
[bbox,dims,volume] = findLargestBox3D(mask)
%% Output 4: |info| -- Information Structure
%
% The fourth output |info| is a structure that captures geometry and
% execution metadata. It contains the following fields:
%
% * |info.options|        -- the resolved option values used.
% * |info.numBoxes|       -- the number of cuboids returned.
% * |info.inputFormat|    -- 'array' or 'indices'.
% * |info.slabDimension|  -- dimension used for slab iteration (1, 2, or 3).
% * |info.slabsProcessed| -- number of slab pairs processed.
% * |info.timeTotal|      -- total execution time in seconds.
% * |info.time2DFun|      -- time spent inside |findLargestBox2D|.
%
% When at least one cuboid is found, |info| contains the nested structure
% array |.box| with size Nx1, which has the following fields:
%
% * |info.box.indices|  -- |[r1,r2,c1,c2,p1,p2]| (same as one row of |bbox|).
% * |info.box.corners|  -- fractional voxel-edge coordinates:
%                         |[r1-0.5,r2+0.5,c1-0.5,c2+0.5,p1-0.5,p2+0.5]|.
% * |info.box.diagonal| -- diagonal length (in voxels, may be fractional).
% * |info.box.center|   -- where the diagonals meet (may be fractional).
% * |info.box.height|   -- the height in voxels.
% * |info.box.width|    -- the width in voxels.
% * |info.box.depth|    -- the depth in voxels.
% * |info.box.volume|   -- the volume in voxels.
% * |info.box.area|     -- the total surface area.
%
[~,~,~,info] = findLargestBox3D(mask)
info.box
%% Inputs 1, 2 & 3: Index Vectors
%
% Instead of a full 3D array, you can supply three vectors of row, column,
% and page indices of the usable voxels. This is convenient when working
% with the output of |find| and |ind2sub| and avoids constructing a large
% dense mask.
%
% All four output arguments are identical to the array-input form:
[vxR, vxC, vxP] = ind2sub(size(mask), find(mask));
[bbox,dims,volume] = findLargestBox3D(vxR, vxC, vxP)
%% Multiple Cuboids of Equal Largest Volume
%
% When multiple cuboids have the same largest volume then by default all
% *N* of them are returned. These cuboids may *overlap*!
% Output |bbox| will then have size *Nx6* (one row per cuboid), and
% |info.box| will be an *Nx1* struct array (one element per cuboid).
%
% Here the mask contains two cuboids both with volume=42:
mask = false(14,15,9);
mask(2:4, 2:8, 2:3) = true; % 3x7x2 = 42
mask(6:12, 10:12, 6:7) = true;  % 7x3x2 = 42
[bbox,dims,volume] = findLargestBox3D(mask)
%% Option |maxN| -- Limit Number of Results
%
% Use the |'maxN'| option to limit the number of cuboids returned.
% This is useful when you only need the first occurrence, or when memory
% usage from many duplicates is a concern.
%
% For example, setting |maxN=1| returns a maximum of one cuboid:
findLargestBox3D(mask, 'maxN',Inf) % default all
findLargestBox3D(mask, 'maxN',1)   % 1st cuboid only
%% Options |minVolume| and |maxVolume| -- Volume Constraints
%
% |'minVolume'| and |'maxVolume'| set inclusive bounds on the volume
% (in voxels) of returned cuboids. Note that cuboids may *overlap!*:
mask = false(16, 13, 9);
mask(2:3, 2:4, 2:8) = true; % 2x3x7 = 42
mask(5:7, 2:12, 2:4) = true; % 3x11x3 = 99
mask(9:15, 6:8, 2:4) = true; % 7x3x3 = 63
[bbox,~,volume] = findLargestBox3D(mask, 'maxVolume',46)
[bbox,~,volume] = findLargestBox3D(mask, 'minVolume',64)
%% Options |minHeight| and |maxHeight| -- Height Constraints
%
% |'minHeight'| and |'maxHeight'| restrict the number of rows the returned
% cuboid may span:
[~,dims,~] = findLargestBox3D(mask, 'maxHeight',4)
[~,dims,~] = findLargestBox3D(mask, 'minHeight',4)
%% Options |minWidth| and |maxWidth| -- Width Constraints
%
% |'minWidth'| and |'maxWidth'| restrict the number of columns the returned
% cuboid may span:
[~,dims,~] = findLargestBox3D(mask, 'maxWidth',8)
[~,dims,~] = findLargestBox3D(mask, 'minWidth',5)
%% Options |minDepth| and |maxDepth| -- Depth Constraints
%
% |'minDepth'| and |'maxDepth'| restrict the number of pages the returned
% cuboid may span:
[~,dims,~] = findLargestBox3D(mask, 'maxDepth',5)
[~,dims,~] = findLargestBox3D(mask, 'minDepth',4)
%% Option |display| -- Show Function Progress
%
% The |'display'| option accepts one of the following three values:
%
% * |'silent'| : no progress display.
% * |'waitbar'|: MATLAB progress bar, with estimated time remaining (ETR).
% * |'verbose'|: prints progress in the command window, with ETR.
%
%% Options as a Struct
%
% All options can equivalently be passed as a scalar struct whose field
% names match the option names (case-insensitive). This is convenient
% when you want to build options programmatically or share them across
% multiple calls:
opts = struct('maxN',1, 'minDepth',5);
findLargestBox3D(mask, opts)
%% Empty or No Valid Cuboid
%
% If the mask contains no usable voxels, or if no cuboid satisfies the
% active constraints, the function returns empty arrays for |bbox| and
% |dims|, zero for |volume|, and an |info| struct without |info.box| field:
[bbox,dims,volume] = findLargestBox3D(mask, 'minVolume',999)
%% Performance Comparison Across Input Formats
%
% The two input formats (logical/numeric array, index vectors) can differ
% substantially in memory use and runtime depending on mask size and
% density. There is no universally fastest format; the example below times
% both on a moderately sized volume that is safe to run interactively.
%
% Both formats must produce identical results -- verified with |isequal|:
sz = [99, 76, 42];
maskL = false(sz);
maskL(12:42, 12:42, 6:30) = true; % 31x31x25 = 24025
maskL(76, 42, 23) = true; % 1x1x1 = 1
%
[vxR, vxC, vxP] = ind2sub(sz, find(maskL));
%
[bboxL, dimsL, volL, infoL] = findLargestBox3D(maskL);
[bboxI, dimsI, volI, infoI] = findLargestBox3D(vxR, vxC, vxP);
%
isequal(bboxL,bboxI)
isequal(dimsL,dimsI)
isequal(volL,volI)
%
fprintf('%8.4f s  3D array\n',      infoL.timeTotal)
fprintf('%8.4f s  index vectors\n', infoI.timeTotal)
%% Dependency on |findLargestBox2D|
%
% The 3D function calls |findLargestBox2D| on each 2D slab footprint.
% Ensure |findLargestBox2D.m| is on your MATLAB path. The |info| structure
% reports how much time was spent calling |findLargestBox2D| as well as
% its own total running time:
mask = false(40, 50, 30);
mask(10:30, 15:40, 5:25) = true;
[~, ~, ~, info] = findLargestBox3D(mask);
info.time2DFun
info.timeTotal