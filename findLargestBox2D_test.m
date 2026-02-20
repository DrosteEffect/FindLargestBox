function findLargestBox2D_test()
% Quick sanity check of the findLargestBox test class.
%
%% Dependencies %%
%
% * MATLAB R2009b or later.
% * findLargestBox2D.m and test_flb_fun.m
%
% See also FINDLARGESTBOX2D TEST_FLB_FUN
obj = test_flb_fun(@findLargestBox2D);
mainfun(obj) % count
obj.start()
mainfun(obj) % check
obj.finish()
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox2D_test
function mainfun(chk)
%
%% Edge Cases %%
%
% Empty logical (0x0)
M = logical([]);
chk.i(M).o([],[],0)
%
% Empty numeric (0x0)
chk.i([]).o([],[],0)
%
% Empty index (0x0)
chk.i([],[]).o([],[],0)
%
% Empty logical (0xN)
M = false(0,5);
chk.i(M).o([],[],0)
%
% Empty logical (Nx0)
M = false(5,0);
chk.i(M).o([],[],0)
%
% All false (no valid pixels)
M = false(4,5);
chk.i(M).o([],[],0)
%
% All true (entire matrix is valid)
M = true(4,5);
chk.i(M).o([1,4,1,5],[4,5],20)
%
% All true (square matrix)
M = true(3,3);
chk.i(M).o([1,3,1,3],[3,3],9)
%
% All true (large square)
M = true(10,10);
chk.i(M).o([1,10,1,10],[10,10],100)
%
% Single element - true
M = true(1,1);
chk.i(M).o([1,1,1,1],[1,1],1)
%
% Single element - false
M = false(1,1);
chk.i(M).o([],[],0)
%
% Single row - all true
M = true(1,7);
chk.i(M).o([1,1,1,7],[1,7],7)
%
% Single row - partial true
M = [0,1,1,1,0,1,0];
chk.i(M).o([1,1,2,4],[1,3],3)
%
% Single row - alternating
M = [1,0,1,0,1,0,1];
chk.i(M).o([1,1,1,1;1,1,3,3;1,1,5,5;1,1,7,7],[1,1;1,1;1,1;1,1],1)
%
% Single column - all true
M = true(6,1);
chk.i(M).o([1,6,1,1],[6,1],6)
%
% Single column - partial true
M = [0;1;1;1;0;1;0];
chk.i(M).o([2,4,1,1],[3,1],3)
%
% Single column - alternating
M = [1;0;1;0;1;0;1];
chk.i(M).o([1,1,1,1;3,3,1,1;5,5,1,1;7,7,1,1],[1,1;1,1;1,1;1,1],1)
%
% Single true pixel in larger matrix
M = false(5,5);
M(3,3) = true;
chk.i(M).o([3,3,3,3],[1,1],1)
%
% Two separate true pixels (should find both)
M = false(5,5);
M(2,2) = true;
M(4,4) = true;
chk.i(M).o([2,2,2,2;4,4,4,4],[1,1;1,1],1)
%
% Four corners only
M = false(5,5);
M(1,1) = true;
M(1,5) = true;
M(5,1) = true;
M(5,5) = true;
chk.i(M).o([1,1,1,1;1,1,5,5;5,5,1,1;5,5,5,5],[1,1;1,1;1,1;1,1],1)
%
% Diagonal pattern (each should be area 1)
M = eye(5);
chk.i(M).o([1,1,1,1;2,2,2,2;3,3,3,3;4,4,4,4;5,5,5,5],[1,1;1,1;1,1;1,1;1,1],1)
%
% Anti-diagonal pattern
M = fliplr(eye(5));
chk.i(M).o([1,1,5,5;2,2,4,4;3,3,3,3;4,4,2,2;5,5,1,1],[1,1;1,1;1,1;1,1;1,1],1)
%
%% maxArea Candidate-Set Bug %%
%
% A 10x5 all-true block. With maxArea=24, the constrained optimum is
% 6x4=24 (eH=6, eW=floor(24/6)=4). However, Hcands = unique([Hmax=10;
% floor(24/Wmax)=floor(24/5)=4; sqM=4; sqM+1=5]) = [4,5,10], which
% does NOT include eH=6. The buggy code finds effA=20 (from 4x5 or 5x4)
% and returns bbox=[1,4,1,5], dims=[4,5], area=20.
% The correct answer is bbox=[1,6,1,4], dims=[6,4], area=24.
M = true(10,5);
chk.i(M,'maxArea',24,'maxN',1).o([1,6,1,4],[6,4],24)
% Strictly targets the flush block: tall block at right edge
M = false(10, 10);
M(1:10, 6:10) = true; % 10x5 block, bars drain via flush
chk.i(M,'maxArea',24,'maxN',1).o([1,6,6,9],[6,4],24)
%
%% Simple Geometric Shapes %%
%
% Rectangle in corner
M = false(8,10);
M(1:3,1:5) = true;
chk.i(M).o([1,3,1,5],[3,5],15)
%
% Rectangle in center
M = false(10,12);
M(3:6,4:9) = true;
chk.i(M).o([3,6,4,9],[4,6],24)
%
% Square in corner
M = false(8,8);
M(1:4,1:4) = true;
chk.i(M).o([1,4,1,4],[4,4],16)
%
% Square in center
M = false(9,9);
M(3:6,3:6) = true;
chk.i(M).o([3,6,3,6],[4,4],16)
%
% Wide rectangle (wider than tall)
M = false(5,15);
M(2:4,3:13) = true;
chk.i(M).o([2,4,3,13],[3,11],33)
%
% Tall rectangle (taller than wide)
M = false(15,5);
M(3:13,2:4) = true;
chk.i(M).o([3,13,2,4],[11,3],33)
%
%% L-Shaped Patterns %%
%
% L-shape (vertical + horizontal)
M = false(5,5);
M(1:3,1) = true;
M(3,1:3) = true;
chk.i(M).o([1,3,1,1;3,3,1,3],[3,1;1,3],3)
%
% Large L-shape
M = false(10,10);
M(1:8,1:2) = true;   % Vertical part
M(6:8,1:6) = true;   % Horizontal part
chk.i(M).o([6,8,1,6],[3,6],18)
%
% Inverted L
M = false(8,8);
M(1:2,1:6) = true;   % Top horizontal
M(1:5,5:6) = true;   % Right vertical
chk.i(M).o([1,2,1,6],[2,6],12)
%
% Rotated L
M = false(7,7);
M(1:5,1:2) = true;
M(1:2,1:5) = true;
chk.i(M).o([1,2,1,5;1,5,1,2],[2,5;5,2],10)
%
%% T-Shaped and Cross Patterns %%
%
% T-shape
M = false(7,7);
M(1:2,2:6) = true;   % Top bar
M(1:5,3:5) = true;   % Vertical stem
chk.i(M).o([1,5,3,5],[5,3],15)
%
% Cross/Plus pattern
M = false(9,9);
M(4:6,:) = true;     % Horizontal bar
M(:,4:6) = true;     % Vertical bar
chk.i(M).o([4,6,1,9;1,9,4,6],[3,9;9,3],27)
%
% Offset cross
M = false(11,11);
M(3:5,:) = true;
M(:,7:9) = true;
chk.i(M).o([3,5,1,11;1,11,7,9],[3,11;11,3],33)
%
%% Internet-Found Test Cases %%
%
% LeetCode Problem 85 - Maximal Rectangle
% <https://leetcode.com/problems/maximal-rectangle/description/>
M = [1,0,1,0,0; 1,0,1,1,1; 1,1,1,1,1; 1,0,0,1,0];
chk.i(M).o([2,3,3,5],[2,3],6)
%
% GeeksforGeeks Example
% <https://www.geeksforgeeks.org/maximum-size-rectangle-binary-sub-matrix-1s/>
M = [0,1,1,0; 1,1,1,1; 1,1,1,1; 1,1,0,0];
chk.i(M).o([2,3,1,4],[2,4],8)
%
% InterviewBit Example
% <https://www.interviewbit.com/problems/max-rectangle-in-binary-matrix/>
M = [1,1,1; 0,1,1; 1,0,0];
chk.i(M).o([1,2,2,3],[2,2],4)
%
% LeetCode Example 2 - Different configuration
M = logical([0,1; 1,0]);
chk.i(M).o([1,1,2,2;2,2,1,1],[1,1;1,1],1)
%
% Medium/Python Example 1
M = [1,0,0,0; 1,0,1,1; 1,0,1,1; 0,1,0,0];
chk.i(M).o([2,3,3,4],[2,2],4)
%
%% Histogram-Based Patterns %%
%
% Histogram example (wide rectangle)
M = [1,1,1,1,1,1; 0,1,1,1,1,0; 0,0,1,1,0,0];
chk.i(M).o([1,2,2,5],[2,4],8)
%
% Tall histogram
M = [0,1,0; 0,1,0; 0,1,0; 0,1,0; 0,1,0];
chk.i(M).o([1,5,2,2],[5,1],5)
%
% Mountain-shaped histogram
M = [0,0,1,0,0; 0,1,1,1,0; 1,1,1,1,1];
chk.i(M).o([2,3,2,4],[2,3],6)
%
% Valley-shaped histogram
M = [1,1,1,1,1; 0,1,1,1,0; 0,0,1,0,0];
chk.i(M).o([1,2,2,4],[2,3],6)
%
% Increasing histogram
M = false(6,6);
for k = 1:6
    M(7-k:6,k) = true;
end
chk.i(M).o([3,6,4,6;4,6,3,6],[4,3;3,4],12)
%
% Decreasing histogram
M = false(6,6);
for k = 1:6
    M(1:k,k) = true;
end
chk.i(M).o([1,3,3,6;1,4,4,6],[3,4;4,3],12)
%
%% Multiple Rectangles (Find Largest) %%
%
% Two rectangles - should find larger
M = false(6,8);
M(1:2,1:3) = true;  % 2x3 = 6
M(4:6,5:8) = true;  % 3x4 = 12
chk.i(M).o([4,6,5,8],[3,4],12)
%
% Three rectangles of different sizes
M = false(10,12);
M(1:2,1:2) = true;   % 2x2 = 4
M(4:7,4:9) = true;   % 4x6 = 24
M(8:9,10:12) = true; % 2x3 = 6
chk.i(M).o([4,7,4,9],[4,6],24)
%
% Many small rectangles vs one large
M = false(10,10);
for k = 1:2:9
    M(k,k) = true;  % 1x1 rectangles
end
M(3:7,3:7) = true;  % 5x5 = 25
chk.i(M).o([3,7,3,7],[5,5],25)
%
%% Staircase Patterns %%
%
% Asending staircase
M = [1,1,1,0,0; 0,1,1,1,0; 0,0,1,1,1; 0,0,0,1,1];
chk.i(M).o([1,2,2,3;2,3,3,4;3,4,4,5],[2,2;2,2;2,2],4)
%
% Descending staircase
M = [0,0,0,1,1; 0,0,1,1,1; 0,1,1,1,0; 1,1,1,0,0];
chk.i(M).o([1,2,4,5;2,3,3,4;3,4,2,3],[2,2;2,2;2,2],4)
%
% Double staircase (ascending and descending)
M = [1,1,0,0,1,1; 0,1,1,1,1,0; 0,0,1,1,0,0];
chk.i(M).o([2,2,2,5;2,3,3,4],[1,4;2,2],4)
%
% Pyramid staircase
M = false(7,13);
M(1,6:8) = true;
M(2,5:9) = true;
M(3,4:10) = true;
M(4,3:11) = true;
M(5,2:12) = true;
M(6,1:13) = true;
M(7,1:13) = true;
chk.i(M).o([4,7,3,11],[4,9],36)
%
%% Checkerboard and Regular Patterns %%
%
% Checkerboard pattern (only 1x1 boxes available)
M = [1,0,1,0; 0,1,0,1; 1,0,1,0; 0,1,0,1];
chk.i(M).o([1,1,1,1;1,1,3,3;2,2,2,2;2,2,4,4;3,3,1,1;3,3,3,3;4,4,2,2;4,4,4,4],[1,1;1,1;1,1;1,1;1,1;1,1;1,1;1,1],1)
%
% Checkerboard with 2x2 squares (actually fills entire matrix)
M = false(8,8);
for i = 1:2:8
    for j = 1:2:8
        M(i:i+1,j:j+1) = true;
    end
end
chk.i(M).o([1,8,1,8],[8,8],64)
%
% Striped pattern (vertical)
M = repmat([1,0,1,0,1,0],5,1);
chk.i(M).o([1,5,1,1;1,5,3,3;1,5,5,5],[5,1;5,1;5,1],5)
%
% Striped pattern (horizontal)
M = repmat([1;0;1;0;1;0],1,8);
chk.i(M).o([1,1,1,8;3,3,1,8;5,5,1,8],[1,8;1,8;1,8],8)
%
% Grid pattern
M = true(10,10);
M(5,:) = false;  % Horizontal line
M(:,5) = false;  % Vertical line
chk.i(M).o([6,10,6,10],[5,5],25)
%
%% Dense Matrix with Holes %%
%
% Dense matrix with small hole
M = true(5,5);
M(3,3) = false;
chk.i(M).o([1,2,1,5;1,5,1,2;1,5,4,5;4,5,1,5],[2,5;5,2;5,2;2,5],10)
%
% Dense matrix with line hole (horizontal)
M = true(7,7);
M(4,:) = false;
chk.i(M).o([1,3,1,7;5,7,1,7],[3,7;3,7],21)
%
% Dense matrix with line hole (vertical)
M = true(7,7);
M(:,4) = false;
chk.i(M).o([1,7,1,3;1,7,5,7],[7,3;7,3],21)
%
% Dense matrix with cross hole
M = true(9,9);
M(5,:) = false;
M(:,5) = false;
chk.i(M).o([1,4,1,4;1,4,6,9;6,9,1,4;6,9,6,9],[4,4;4,4;4,4;4,4],16)
%
% Dense matrix with diagonal hole
M = ~eye(8);
chk.i(M).o([1,4,5,8;5,8,1,4],[4,4;4,4],16)
%
% Dense matrix with border holes
M = true(8,8);
M(1,:) = false;
M(8,:) = false;
M(:,1) = false;
M(:,8) = false;
chk.i(M).o([2,7,2,7],[6,6],36)
%
%% U-Shaped and C-Shaped Patterns %%
%
% U-shape
M = false(7,7);
M(1:6,1:2) = true;   % Left arm
M(1:6,6:7) = true;   % Right arm
M(5:6,1:7) = true;   % Bottom
chk.i(M).o([5,6,1,7],[2,7],14)
%
% C-shape
M = false(9,9);
M(2:8,2:3) = true;   % Left vertical
M(2:3,2:8) = true;   % Top horizontal
M(7:8,2:8) = true;   % Bottom horizontal
chk.i(M).o([2,3,2,8;2,8,2,3;7,8,2,8],[2,7;7,2;2,7],14)
%
% Rotated U
M = false(7,7);
M(1:2,1:7) = true;   % Top
M(1:6,1:2) = true;   % Left
M(1:6,6:7) = true;   % Right
chk.i(M).o([1,2,1,7],[2,7],14)
%
%% Nested Rectangles %%
%
% Rectangle with hole (donut)
M = true(8,10);
M(3:6,3:8) = false;
chk.i(M).o([1,2,1,10;7,8,1,10],[2,10;2,10],20)
%
% Double nested rectangles
M = true(11,11);
M(3:9,3:9) = false;
M(5:7,5:7) = true;
chk.i(M).o([1,2,1,11;1,11,1,2;1,11,10,11;10,11,1,11],[2,11;11,2;11,2;2,11],22)
%
% Triple nested
M = true(13,13);
M(3:11,3:11) = false;
M(5:9,5:9) = true;
M(6:8,6:8) = false;
chk.i(M).o([1,2,1,13;1,13,1,2;1,13,12,13;12,13,1,13],[2,13;13,2;13,2;2,13],26)
%
%% Diagonal and Rotated Patterns %%
%
% Diagonal band
M = false(10,10);
for k = 1:10
    if k <= 7
        M(k,k:k+3) = true;
    end
end
chk.i(M).o([1,2,2,4;1,3,3,4;2,3,3,5;2,4,4,5;3,4,4,6;3,5,5,6;4,5,5,7;4,6,6,7;5,6,6,8;5,7,7,8;6,7,7,9],[2,3;3,2;2,3;3,2;2,3;3,2;2,3;3,2;2,3;3,2;2,3],6)
%
% Anti-diagonal band
M = false(10,10);
for k = 1:10
    if k <= 7
        M(k,11-k-3:11-k) = true;
    end
end
chk.i(M).o([1,2,7,9;1,3,7,8;2,3,6,8;2,4,6,7;3,4,5,7;3,5,5,6;4,5,4,6;4,6,4,5;5,6,3,5;5,7,3,4;6,7,2,4],[2,3;3,2;2,3;3,2;2,3;3,2;2,3;3,2;2,3;3,2;2,3],6)
%
% Diamond pattern
M = false(9,9);
M(1,5) = true;
M(2,4:6) = true;
M(3,3:7) = true;
M(4,2:8) = true;
M(5,1:9) = true;
M(6,2:8) = true;
M(7,3:7) = true;
M(8,4:6) = true;
M(9,5) = true;
chk.i(M).o([3,7,3,7],[5,5],25)
%
%% Corner Cases and Boundary Conditions %%
%
% Rectangle touching all edges
M = false(6,8);
M(1,:) = true;
M(6,:) = true;
M(:,1) = true;
M(:,8) = true;
chk.i(M).o([1,1,1,8;6,6,1,8],[1,8;1,8],8)
%
% Rectangle in each corner
M = false(10,10);
M(1:2,1:2) = true;
M(1:2,9:10) = true;
M(9:10,1:2) = true;
M(9:10,9:10) = true;
chk.i(M).o([1,2,1,2;1,2,9,10;9,10,1,2;9,10,9,10],[2,2;2,2;2,2;2,2],4)
%
% Single pixel in each quadrant
M = false(9,9);
M(2,2) = true;
M(2,8) = true;
M(8,2) = true;
M(8,8) = true;
chk.i(M).o([2,2,2,2;2,2,8,8;8,8,2,2;8,8,8,8],[1,1;1,1;1,1;1,1],1)
%
%% Sparse Patterns %%
%
% Very sparse (few true pixels)
M = false(20,20);
M(5:7,8:12) = true;
chk.i(M).o([5,7,8,12],[3,5],15)
%
% Scattered small rectangles
M = false(15,15);
M(2:3,2:4) = true;   % 2x3 = 6
M(6:7,6:7) = true;   % 2x2 = 4
M(10:14,10:13) = true; % 5x4 = 20
chk.i(M).o([10,14,10,13],[5,4],20)
%
%% Complex Overlapping Regions %%
%
% Two overlapping rectangles
M = false(8,10);
M(2:5,2:6) = true;   % First rectangle
M(4:7,5:9) = true;   % Overlapping rectangle
chk.i(M).o([2,5,2,6;4,7,5,9],[4,5;4,5],20)
%
% Three overlapping rectangles creating one large region
M = false(10,10);
M(2:6,2:6) = true; % 5x5
M(4:8,4:8) = true; % 5x5
M(6:9,1:5) = true; % 4x5
chk.i(M).o([2,8,2,6;4,8,2,8],[7,5;5,7],35)
%
% Star pattern (cross of overlapping bars)
M = false(11,11);
M(5:7,:) = true;     % Horizontal
M(:,5:7) = true;     % Vertical
chk.i(M).o([5,7,1,11;1,11,5,7],[3,11;11,3],33)
%
%% Extreme Aspect Ratios %%
%
% Very wide rectangle
M = false(2,99);
M(1,10:40) = true;
chk.i(M).o([1,1,10,40],[1,31],31)
%
% Very tall rectangle
M = false(99,2);
M(10:40,1) = true;
chk.i(M).o([10,40,1,1],[31,1],31)
%
% Ultra-wide
M = false(1,99);
M(1,20:80) = true;
chk.i(M).o([1,1,20,80],[1,61],61)
%
%% Index Input Format Tests %%
%
% Test with indices instead of logical matrix
M = [1,0,1,1,1; 1,1,1,1,1; 1,0,0,1,0];
[pxr, pxc] = find(M);
chk.i(pxr, pxc).o([1,2,3,5],[2,3],6)
%
% Single pixel as indices
M = false(5,5);
M(3,3) = true;
[pxr, pxc] = find(M);
chk.i(pxr, pxc).o([3,3,3,3],[1,1],1)
%
% Large matrix as indices
M = false(20,20);
M(5:15,7:17) = true;
[pxr, pxc] = find(M);
chk.i(pxr, pxc).o([5,15,7,17],[11,11],121)
%
% Sparse matrix input
M = sparse(false(100,100));
M(45:55,45:60) = true;
[pxr, pxc] = find(M);
chk.i(pxr, pxc).o([45,55,45,60],[11,16],176)
%
% Multiple disjoint regions as indices
M = false(12,12);
M(2:4,2:5) = true;   % 3x4 = 12
M(7:10,8:11) = true; % 4x4 = 16
[pxr, pxc] = find(M);
chk.i(pxr, pxc).o([7,10,8,11],[4,4],16)
%
%% Optional Arguments %%
%
% Reference matrix: single 5x4=20 block at rows 2-6, cols 2-5 in a 7x7 matrix.
% Used for most constraint tests below.
M = false(7,7);
M(2:6,2:5) = true;
%
%% Options passed as a scalar struct %%
%
% Struct with multiple fields
opts = struct('maxHeight',4,'maxN',1);
chk.i(M,opts).o([2,5,2,5],[4,4],16)
%
%% maxN option %%
%
% Two equal-area blocks: left 2x4=8, right 2x4=8, separated by a gap.
% Without maxN both are returned; maxN limits how many.
M = false(2,10);
M(1:2,1:4)  = true;   % Left block:  rows 1-2, cols 1-4  (2x4=8)
M(1:2,7:10) = true;   % Right block: rows 1-2, cols 7-10 (2x4=8)
%
% maxN=1: only the first (left) rectangle is returned
chk.i(M,'maxN',1).o([1,2,1,4],[2,4],8)
%
% maxN=2: both equal-area rectangles are returned (left then right)
chk.i(M,'maxN',2).o([1,2,1,4; 1,2,7,10],[2,4; 2,4],8)
%
%% minArea option %%
%
% Reference matrix: M = false(7,7), M(2:6,2:5)=true  (5x4=20)
M = false(7,7);
M(2:6,2:5) = true;
%
% minArea=10: 20 >= 10, result unchanged
chk.i(M,'minArea',19).o([2,6,2,5],[5,4],20)
%
% minArea=20: 20 == 20, result unchanged (boundary value)
chk.i(M,'minArea',20).o([2,6,2,5],[5,4],20)
%
% minArea=21: 20 < 21, no qualifying rectangle found
chk.i(M,'minArea',21).o([],[],0)
%
%% maxArea option %%
%
% maxArea=19: 5x4=20 excluded; best shape fitting within 19 is 4x4=16.
%   Bar h=5,w=4: Hmax=5, Wmax=4. Best (H=4,W=4)=16 <= 19. Result at [2,5,2,5].
chk.i(M,'maxArea',19,'maxN',1).o([2,5,2,5],[4,4],16)
%
% maxArea=15: best shape is 5x3=15. Result at [2,6,2,4] (leftmost position).
%   Bar h=5,w=4: Hmax=5, W capped at floor(15/5)=3. Shape (5,3)=15. dC=0 -> c1=2.
chk.i(M,'maxArea',15,'maxN',1).o([2,6,2,4],[5,3],15)
%
% maxArea=12: best shape achieves 12. Shapes (3,4) and (4,3) both give 12.
%   Shape (3,4) is tried first (lower eH), dR=0 gives r1=2,c1=2 -> [2,4,2,5].
chk.i(M,'maxArea',12,'maxN',1).o([2,4,2,5],[3,4],12)
%
%% minHeight option %%
%
% minHeight=5: block height is 5 >= 5, result unchanged
chk.i(M,'minHeight',5).o([2,6,2,5],[5,4],20)
%
% minHeight=6: block height is 5 < 6, no qualifying rectangle found
chk.i(M,'minHeight',6).o([],[],0)
%
%% maxHeight option %%
%
% maxHeight=5: block height is 5 <= 5, result unchanged
chk.i(M,'maxHeight',5).o([2,6,2,5],[5,4],20)
%
% maxHeight=4: height capped at 4; best is 4x4=16 at topmost position [2,5,2,5].
%   Bar h=5,w=4: Hmax=4, Wmax=4. Shape (4,4)=16. dR=0 -> r1=2.
chk.i(M,'maxHeight',4,'maxN',1).o([2,5,2,5],[4,4],16)
%
% maxHeight=3: height capped at 3; best is 3x4=12 at topmost position [2,4,2,5].
chk.i(M,'maxHeight',3,'maxN',1).o([2,4,2,5],[3,4],12)
%
%% minWidth option %%
%
% minWidth=4: block width is 4 >= 4, result unchanged
chk.i(M,'minWidth',4).o([2,6,2,5],[5,4],20)
%
% minWidth=5: block width is 4 < 5, no qualifying rectangle found
chk.i(M,'minWidth',5).o([],[],0)
%
%% maxWidth option %%
%
% maxWidth=4: block width is 4 <= 4, result unchanged
chk.i(M,'maxWidth',4).o([2,6,2,5],[5,4],20)
%
% maxWidth=3: width capped at 3; best is 5x3=15 at leftmost position [2,6,2,4].
%   Bar h=5,w=4: Wmax=3. Shape (5,3)=15. dC=0 -> c1=2.
chk.i(M,'maxWidth',3,'maxN',1).o([2,6,2,4],[5,3],15)
%
% maxWidth=2: width capped at 2; best is 5x2=10 at leftmost position [2,6,2,3].
chk.i(M,'maxWidth',2,'maxN',1).o([2,6,2,3],[5,2],10)
%
%% Combined constraints %%
%
% minHeight+maxHeight together: only heights 3 to 4 are valid.
%   Best is 4x4=16 (height=4 is within [3,4]).
chk.i(M,'minHeight',3,'maxHeight',4,'maxN',1).o([2,5,2,5],[4,4],16)
%
% minWidth+maxWidth together: only widths 2 to 3 are valid.
%   Best is 5x3=15 (width=3 is within [2,3]).
chk.i(M,'minWidth',2,'maxWidth',3,'maxN',1).o([2,6,2,4],[5,3],15)
%
% minArea+maxArea range: area must be in [12,15].
%   5x4=20 excluded (>15); 5x3=15 qualifies and is the best.
chk.i(M,'minArea',12,'maxArea',15,'maxN',1).o([2,6,2,4],[5,3],15)
%
% Height and width constraints together:
%   maxHeight=3 forces h<=3; maxWidth=3 forces w<=3.
%   Best: 3x3=9 at topmost-leftmost position [2,4,2,4].
chk.i(M,'maxHeight',3,'maxWidth',3,'maxN',1).o([2,4,2,4],[3,3],9)
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
