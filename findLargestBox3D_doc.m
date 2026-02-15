%% |FINDLARGESTBOX3D| Examples
% The function <https://www.mathworks.com/matlabcentral/fileexchange/######
% |findLargestBox3D|> finds the maximum-volume axis-aligned cuboid
% within a 3D logical mask using an exact slab-collapse algorithm.
% The function accepts input as a logical 3D array or as three index vectors
% for row, column, and page coordinates. This document demonstrates the
% different input formats and output arguments with practical examples.
%
%% Basic Usage: Logical 3D Array
% |findLargestBox3D| accepts a 3D logical array where TRUE indicates
% usable voxels and FALSE indicates blocked voxels. The function returns
% the bounding box corners of the largest rectangular cuboid consisting
% entirely of TRUE voxels.
% The output |bbox| is a 3x2 matrix [r1,r2; c1,c2; p1,p2] where
%
% * r1 and r2 are the first and last row indices,
% * c1 and c2 are the first and last column indices, and
% * p1 and p2 are the first and last page indices.
%
% The largest box spans from voxel (r1,c1,p1) to voxel (r2,c2,p2) inclusive:
mask = false(9,9,9);
mask(2:3, 2:5, 2:4) = true;  % 2x4x3 box (volume 24)
mask(3:5, 3:7, 3:6) = true;  % 3x5x4 box (volume 60)
bbox = findLargestBox3D(mask)
%% Input Index Vectors
% Instead of providing a 3D array, you can supply three vectors containing
% the row, column, and page indices of usable voxels. This is particularly
% useful when working with the output of |ind2sub| or when you already have
% coordinate data.
% In general this format provides memory savings compared to a full array.
[vxr, vxc, vxp] = ind2sub(size(mask), find(mask));
bbox = findLargestBox3D(vxr, vxc, vxp)
%% 2nd Output: Volume
% The second output returns the volume of the largest box in voxels:
[~, volume] = findLargestBox3D(mask)
%% 3rd Output: Information Structure
% The third output |info| provides data about the function execution:
[~, ~, info] = findLargestBox3D(mask)
%% 3rd Output: Box Substructure
% If a cuboid is found then the |info.box| substructure provides
% comprehensive geometric information about the cuboid.
% The |corners| field gives fractional coordinates (voxel centers are at
% integer coordinates, so corners are offset by 0.5). The |center| field
% indicates where the diagonals of the cuboid intersect.
% The |area| field gives the total surface area.
info.box
%% Empty or No Valid Box
% If the input contains no usable voxels (e.g. all FALSE), the function
% returns an empty |bbox| and zero volume:
mask = false(5,5,5);  % all blocked voxels
[bbox, volume] = findLargestBox3D(mask)
%% Slab Dimension Selection
% The algorithm automatically chooses the smallest dimension for slab
% iteration to minimize computational cost. For a tall thin volume the
% rows become the slab dimension, while for a wide flat volume the pages
% become the slab dimension:
mask1 = false(9,99,99);
mask1(2:8, 5:45, 5:45) = true; % dim 1 narrow
[~, ~, info1] = findLargestBox3D(mask1);
info1.slabDimension

mask2 = false(99,99,9);
mask2(5:45, 5:45, 2:8) = true; % dim 3 narrow
[~, ~, info2] = findLargestBox3D(mask2);
info2.slabDimension
%% Complex Pattern Example
% A more complex mask demonstrating the algorithm finding the optimal box
% among multiple irregular 3D regions:
mask = false(15,15,15);
mask(2:4, 2:6, 2:5) = true;    % 3x5x4 box (volume 60)
mask(6:10, 8:14, 8:12) = true; % 5x7x5 box (volume 175)
mask(11:13, 2:4, 11:13) = true; % 3x3x3 box (volume 27)
[bbox, volume] = findLargestBox3D(mask)
%% L-Shaped Region
% For non-convex regions the function finds the largest box that fits
% within the available space:
mask = false(10,10,10);
mask(2:8, 2:4, 2:8) = true;   % Vertical part of L
mask(2:4, 2:8, 2:8) = true;   % Horizontal part of L
[bbox, volume] = findLargestBox3D(mask)
%% Practical Application: 3D Space Planning
% A typical use case is finding the largest rectangular volume in a 3D
% space with obstacles, such as warehouse storage or 3D bin packing:
mask = false(30,40,25);
mask(5:25, 5:35, 5:20) = true;             % Available storage space
mask(12:14, 15:18, 5:20) = false;          % Column 1
mask(18:20, 25:28, 5:20) = false;          % Column 2
mask(8:11, 10:13, 12:15) = false;          % Existing item
[bbox, volume, info] = findLargestBox3D(mask);
fprintf('Largest available box: %dx%dx%d voxels (volume %d)\n', ...
    info.box.height, info.box.width, info.box.depth, volume)
%% Efficiency of Indices and Logical Arrays
% The function accepts either a logical 3D array or index vectors. Using
% index vectors avoids creating large 3D arrays in memory and processes
% coordinates directly without materializing the full mask.
%
% Note that runtime is heavily dependent on the data density, the number
% of boxes, the provided data type, and the dimensions. There is no simple
% way to predict which format will require the least memory or runtime.
%
% For example, a 999x999x999 mask with a small usable region:
mask = false(999,999,999);
mask(123,456,789) = true;
mask(44:55, 44:66, 44:77) = true;
[bboxL, volumeL, infoL] = findLargestBox3D(mask);

[vxr, vxc, vxp] = ind2sub(size(mask), find(mask));
[bboxI, volumeI, infoI] = findLargestBox3D(vxr, vxc, vxp);

[vxr, vxc, vxp] = ndgrid(44:55, 44:66, 44:77);
vxr = [vxr(:);123];
vxc = [vxc(:);456];
vxp = [vxp(:);789];
[bboxJ, volumeJ, infoJ] = findLargestBox3D(vxr, vxc, vxp);

isequal(bboxL,bboxI,bboxJ)
isequal(volumeL,volumeI,volumeJ)

fprintf('%9.6f seconds for %s\n',...
	infoL.timeTotal, 'logical array',...
	infoI.timeTotal, 'indices (from logical array)',...
	infoJ.timeTotal, 'indices (from ndgrid)')
%% Dependency on |findLargestBox2D|
% The 3D function requires |findLargestBox2D| to analyze each 2D slab.
% Make sure |findLargestBox2D.m| is on your MATLAB path. The |info|
% structure reports how much time was spent in the 2D function:
mask = false(20,20,20);
mask(5:15, 6:16, 7:17) = true;
[~, ~, info] = findLargestBox3D(mask);
fprintf('%.0f%% of runtime is the 2D function',100*info.time2DFun./info.timeTotal);