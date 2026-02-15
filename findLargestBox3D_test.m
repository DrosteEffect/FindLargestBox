function findLargestBox3D_test()
% Testcases for the function findLargestBox3D.
%
%% Dependencies %%
%
% * MATLAB R2009b or later.
% * findLargestBox3D.m and test_flb_fun.m
%
% See also FINDLARGESTBOX3D TEST_FLB_FUN
obj = test_flb_fun(@findLargestBox3D);
mainfun(obj) % count
obj.start()
mainfun(obj) % check
obj.finish()
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox3D_test
function mainfun(chk)
%
%% Edge Cases %%
%
% Empty array (0x0x0)
M = true(0,0,0);
chk.i(M).o([],0)
%
% Empty array (0xNxN)
M = true(0,5,5);
chk.i(M).o([],0)
%
% Empty array (Nx0xN)
M = true(5,0,5);
chk.i(M).o([],0)
%
% Empty array (NxNx0)
M = true(5,5,0);
chk.i(M).o([],0)
%
% All false (no valid voxels)
M = false(4,5,6);
chk.i(M).o([],0)
%
% All true (entire array is valid)
M = true(4,5,6);
chk.i(M).o([1,4;1,5;1,6],120)
%
% All true (cubic array)
M = true(3,3,3);
chk.i(M).o([1,3;1,3;1,3],27)
%
% Single element - true
M = true(1,1,1);
chk.i(M).o([1,1;1,1;1,1],1)
%
% Single element - false
M = false(1,1,1);
chk.i(M).o([],0)
%
% Single row (1xNxN)
M = true(1,7,5);
chk.i(M).o([1,1;1,7;1,5],35)
%
% Single column (Nx1xN)
M = true(6,1,5);
chk.i(M).o([1,6;1,1;1,5],30)
%
% Single page (NxNx1)
M = true(6,7,1);
chk.i(M).o([1,6;1,7;1,1],42)
%
% Thin rod (1x1xN)
M = true(1,1,10);
chk.i(M).o([1,1;1,1;1,10],10)
%
% Thin sheet (1xNxN)
M = true(1,5,8);
chk.i(M).o([1,1;1,5;1,8],40)
%
% Thin sheet (Nx1xN)
M = true(6,1,8);
chk.i(M).o([1,6;1,1;1,8],48)
%
% Single true voxel in larger array
M = false(5,5,5);
M(3,3,3) = true;
chk.i(M).o([3,3;3,3;3,3],1)
%
% Two separate true voxels (should find one)
M = false(5,5,5);
M(2,2,2) = true;
M(4,4,4) = true;
chk.i(M).o([2,2;2,2;2,2],1)
%
% Diagonal 3D pattern (each should be volume 1)
M = false(5,5,5);
for k = 1:5
    M(k,k,k) = true;
end
chk.i(M).o([1,1;1,1;1,1],1)
%
% Diagonal plane (should find 1x1x1)
M = false(5,5,5);
for k = 1:5
    M(k,k,:) = true;
end
chk.i(M).o([1,1;1,1;1,5],5)
%
%% Examples from Function Documentation %%
%
% Example from findLargestBox3D.m documentation
M = false(9,9,9);
M(2:3, 2:5, 2:4) = true;  % 2x4x3 box (volume 24)
M(3:5, 3:7, 3:6) = true;  % 3x5x4 box (volume 60)
chk.i(M).o([3,5;3,7;3,6],60)
%
%% Simple Geometric Patterns %%
%
% Single box in corner
M = false(8,8,8);
M(1:3, 1:4, 1:5) = true;
chk.i(M).o([1,3;1,4;1,5],60)
%
% Single box in center
M = false(10,10,10);
M(4:6, 3:7, 2:8) = true;
chk.i(M).o([4,6;3,7;2,8],105)
%
% Cube in corner
M = false(7,7,7);
M(1:4, 1:4, 1:4) = true;
chk.i(M).o([1,4;1,4;1,4],64)
%
% Cube in center
M = false(9,9,9);
M(3:5, 3:5, 3:5) = true;
chk.i(M).o([3,5;3,5;3,5],27)
%
%% Multiple Disjoint Boxes (Find Largest) %%
%
% Two boxes - should find larger
M = false(8,8,8);
M(1:2, 1:2, 1:3) = true;  % 2x2x3 = 12
M(5:7, 5:8, 5:7) = true;  % 3x4x3 = 36
chk.i(M).o([5,7;5,8;5,7],36)
%
% Three boxes of different sizes
M = false(12,12,12);
M(1:2, 1:3, 1:2) = true;  % 2x3x2 = 12
M(5:7, 5:9, 5:8) = true;  % 3x5x4 = 60
M(9:10, 9:11, 9:11) = true;  % 2x3x3 = 18
chk.i(M).o([5,7;5,9;5,8],60)
%
%% L-Shaped Regions in 3D %%
%
% L-shape (vertical + horizontal in one plane)
M = false(10,10,10);
M(2:8, 2:4, 2:8) = true;   % Vertical part
M(2:4, 2:8, 2:8) = true;   % Horizontal part
chk.i(M).o([2,4;2,8;2,8],147)
%
% 3D L-shape (three perpendicular arms)
M = false(10,10,10);
M(2:8, 2:3, 2:3) = true;   % Arm along rows
M(2:3, 2:8, 2:3) = true;   % Arm along columns
M(2:3, 2:3, 2:8) = true;   % Arm along pages
chk.i(M).o([2,3;2,3;2,8],28)
%
%% T-Shaped and Cross Patterns %%
%
% T-shape in 3D
M = false(9,9,9);
M(2:8, 4:6, 2:8) = true;   % Vertical bar
M(4:6, 2:8, 4:6) = true;   % Horizontal bar (top of T)
chk.i(M).o([2,8;4,6;2,8],147)
%
% Cross pattern (two perpendicular slabs)
M = false(11,11,11);
M(:, 5:7, :) = true;      % Vertical slab through middle
M(5:7, :, :) = true;      % Horizontal slab through middle
chk.i(M).o([1,11;5,7;1,11],363)
%
%% Nested Boxes %%
%
% Small box inside larger hollow box
M = true(10,10,10);
M(3:8, 3:8, 3:8) = false;  % Hollow out the center
M(5:6, 5:6, 5:6) = true;   % Small box in center
chk.i(M).o([1,2;1,10;1,10],200)
%
% Two concentric hollow boxes
M = true(12,12,12);
M(3:10, 3:10, 3:10) = false;
M(5:8, 5:8, 5:8) = true;
chk.i(M).o([1,2;1,12;1,12],288)
%
%% Hollow Structures %%
%
% Hollow cube (shell)
M = true(8,8,8);
M(2:7, 2:7, 2:7) = false;
chk.i(M).o([1,1;1,8;1,8],64)
%
% Tube along one axis
M = false(10,10,10);
M(2:9, 3:8, 3:8) = true;
M(4:7, 4:7, 4:7) = false;  % Hollow out center
chk.i(M).o([2,3;3,8;3,8],72)
%
%% Staircase/Stepped Structures %%
%
% Staircase increasing in all dimensions
M = false(8,8,8);
M(1:2, 1:2, 1:2) = true;
M(3:4, 3:4, 3:4) = true;
M(5:6, 5:6, 5:6) = true;
chk.i(M).o([1,2;1,2;1,2],8)
%
% Pyramid-like structure (largest at bottom)
M = false(10,10,10);
M(1:8, 1:8, 1:2) = true;
M(2:7, 2:7, 3:4) = true;
M(3:6, 3:6, 5:6) = true;
chk.i(M).o([2,7;2,7;1,4],144)
%
% Diagonal staircase
M = false(9,9,9);
M(1:3, 1:3, 1:3) = true;
M(3:5, 3:5, 3:5) = true;
M(5:7, 5:7, 5:7) = true;
chk.i(M).o([1,3;1,3;1,3],27)
%
%% Extended 2D Patterns to 3D %%
%
% Checkerboard pattern in one plane, extended through depth (fills everything)
M = false(6,6,6);
for i = 1:2:6
    for j = 1:2:6
        M(i:min(i+1,6), j:min(j+1,6), :) = true;
    end
end
chk.i(M).o([1,6;1,6;1,6],216)
%
% LeetCode 2D example extended to 3D (uniform depth)
M2D = logical([1,0,1,0,0; 1,0,1,1,1; 1,1,1,1,1; 1,0,0,1,0]);
M = repmat(M2D, [1,1,5]);  % Extend through 5 pages
chk.i(M).o([2,3;3,5;1,5],30)
%
% GeeksforGeeks 2D example extended to 3D
M2D = logical([0,1,1,0; 1,1,1,1; 1,1,1,1; 1,1,0,0]);
M = repmat(M2D, [1,1,7]);
chk.i(M).o([2,3;1,4;1,7],56)
%
%% Dense Array with Small Holes %%
%
% Dense array with scattered false voxels
M = true(7,7,7);
M(3,3,3) = false;
M(5,5,5) = false;
chk.i(M).o([1,4;1,7;4,7],112)
%
% Dense array with line of holes
M = true(8,8,8);
M(4,4,:) = false;  % Vertical hole
chk.i(M).o([1,8;5,8;1,8],256)
%
% Dense array with planar hole
M = true(9,9,9);
M(:,:,5) = false;  % One plane removed
chk.i(M).o([1,9;1,9;1,4],324)
%
%% Complex Overlapping Regions %%
%
% Two overlapping boxes
M = false(10,10,10);
M(2:5, 2:6, 2:5) = true;   % First box: 4x5x4 = 80
M(4:8, 4:9, 3:7) = true;   % Second box: 5x6x5 = 150
% Overlap creates larger connected region
chk.i(M).o([4,8;4,9;3,7],150)
%
% Three overlapping boxes creating large region
M = false(12,12,12);
M(2:7, 2:7, 2:7) = true;
M(5:10, 5:10, 2:7) = true;
M(2:7, 5:10, 5:10) = true;
chk.i(M).o([2,7;2,7;2,7],216)
%
%% Thin Walls and Partitions %%
%
% Room with wall (two chambers)
M = true(8,10,8);
M(4,3:8,:) = false;  % Wall dividing space
chk.i(M).o([5,8;1,10;1,8],320)
%
% Grid pattern (multiple walls)
M = true(10,10,10);
M(5,:,:) = false;  % Horizontal wall
M(:,5,:) = false;  % Vertical wall
chk.i(M).o([6,10;6,10;1,10],250)
%
%% Special Slab Dimension Test Cases %%
%
% Tall thin box (smallest dimension = rows)
M = false(3,20,20);
M(2,5:15,5:15) = true;
chk.i(M).o([2,2;5,15;5,15],121)
%
% Wide flat box (smallest dimension = columns)
M = false(20,3,20);
M(5:15,2,5:15) = true;
chk.i(M).o([5,15;2,2;5,15],121)
%
% Deep narrow box (smallest dimension = pages)
M = false(20,20,3);
M(5:15,5:15,2) = true;
chk.i(M).o([5,15;5,15;2,2],121)
%
%% Extreme Aspect Ratios %%
%
% Very long thin box
M = false(50,3,3);
M(10:40,2,2) = true;
chk.i(M).o([10,40;2,2;2,2],31)
%
% Very flat wide box
M = false(3,30,30);
M(2,5:25,5:25) = true;
chk.i(M).o([2,2;5,25;5,25],441)
%
%% Random-Looking Patterns %%
%
% Scattered voxels with one larger region
M = false(10,10,10);
M(2,2,2) = true;
M(5,8,3) = true;
M(7,3,9) = true;
M(4:7,4:8,4:7) = true;  % 4x5x4 = 80
M(9,9,9) = true;
chk.i(M).o([4,7;4,8;4,7],80)
%
%% Corner Cases for Index Input Format %%
%
% Test with indices instead of logical array
M = false(9,9,9);
M(3:5, 3:7, 3:6) = true;
[vxr, vxc, vxp] = ind2sub(size(M), find(M));
chk.i(vxr, vxc, vxp).o([3,5;3,7;3,6],60)
%
% Single voxel as indices
M = false(5,5,5);
M(3,3,3) = true;
[vxr, vxc, vxp] = ind2sub(size(M), find(M));
chk.i(vxr, vxc, vxp).o([3,3;3,3;3,3],1)
%
% Multiple disjoint regions as indices
M = false(10,10,10);
M(1:3, 1:3, 1:3) = true;   % 3x3x3 = 27
M(7:9, 7:9, 7:9) = true;   % 3x3x3 = 27
[vxr, vxc, vxp] = ind2sub(size(M), find(M));
chk.i(vxr, vxc, vxp).o([1,3;1,3;1,3],27)
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%mainfun
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license