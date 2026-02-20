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
%% Edge Cases: Empty Arrays %%
%
% Empty array (0x0x0)
M = nan(0,0,0);
chk.i(M).o([],[],0)
%
% Empty array (0xNxN)
M = nan(0,5,5);
chk.i(M).o([],[],0)
%
% Empty array (Nx0xN)
M = nan(5,0,5);
chk.i(M).o([],[],0)
%
% Empty array (NxNx0)
M = nan(5,5,0);
chk.i(M).o([],[],0)
%
% Empty indices
chk.i([],[],[]).o([],[],0)
%
%% Edge Cases: All-False / All-True %%
%
% All false (no valid voxels)
M = false(4,5,6);
chk.i(M).o([],[],0)
%
% All true - rectangular cuboid: h=4, w=5, d=6, vol=120.
% iszV=[4,5,6]: idm=1 (rows are smallest).  Slab iterates rows.
% Permuted space: jszR=5 (cols), jszC=6 (pages), jszP=4 (rows/slab).
% Full-thickness AND = true(5,6). findLargestBox2D -> [1,5,1,6], area=30.
% bestBox (perm) = [1,5, 1,6, 1,4].
% invPerm=[3,1,2]: pos1<-pos3=[1,4], pos2<-pos1=[1,5], pos3<-pos2=[1,6].
% Final bbox = [1,4, 1,5, 1,6] = [r1,r2, c1,c2, p1,p2]. dims=[4,5,6].
M = true(4,5,6);
chk.i(M).o([1,4,1,5,1,6],[4,5,6],120)
%
% All true - cubic: h=w=d=3, vol=27
M = true(3,3,3);
chk.i(M).o([1,3,1,3,1,3],[3,3,3],27)
%
% All true - 1xNxN thin sheet (smallest dim = rows, h=1)
M = true(1,5,8);
chk.i(M).o([1,1,1,5,1,8],[1,5,8],40)
%
% All true - Nx1xN thin sheet (smallest dim = cols, w=1)
% iszV=[6,1,8]: idm=2 (cols). idmPerm=[1,3,2]. jszR=6,jszC=8,jszP=1.
% Single slab (one col), 2D footprint=true(6,8), area=48. vol=48.
% bestBox (perm)=[1,6,1,8,1,1]. invPerm=[1,3,2].
% pos1<-pos1=[1,6](rows), pos2<-pos3=[1,1](cols), pos3<-pos2=[1,8](pages).
% Final bbox=[1,6,1,1,1,8]. dims=[6,1,8].
M = true(6,1,8);
chk.i(M).o([1,6,1,1,1,8],[6,1,8],48)
%
% All true - NxNx1 thin sheet (smallest dim = pages, d=1)
M = true(6,7,1);
chk.i(M).o([1,6,1,7,1,1],[6,7,1],42)
%
% All true - thin rod 1x1xN
% iszV=[1,1,10]: min=1, tied at positions 1 and 2; MATLAB min returns idm=1.
% Slab over rows (jszP=1). Single slab = true(1,10) [cols x pages].
% area=10, vol=10. bestBox perm=[1,1,1,10,1,1].
% invPerm=[3,1,2]: bbox=[1,1,1,1,1,10]. dims=[1,1,10].
M = true(1,1,10);
chk.i(M).o([1,1,1,1,1,10],[1,1,10],10)
%
%% Edge Cases: Single Elements %%
%
% Single element - true
M = true(1,1,1);
chk.i(M).o([1,1,1,1,1,1],[1,1,1],1)
%
% Single element - false
M = false(1,1,1);
chk.i(M).o([],[],0)
%
% Single true voxel inside a larger all-false array
% iszV=[5,5,5]: idm=1 (tied). Slab over rows.
% At ii=3, jj=3: slice of row 3 has one true at col=3, page=3.
% findLargestBox2D -> [3,3,3,3], area=1. vol=1.
% bestBox perm=[3,3,3,3,3,3]. invPerm=[3,1,2]: bbox=[3,3,3,3,3,3].
M = false(5,5,5);
M(3,3,3) = true;
chk.i(M).o([3,3,3,3,3,3],[1,1,1],1)
%
% Single false voxel in an otherwise all-true 5x5x5 array.
% Best box avoids the hole; many equal-volume candidates exist.
% iszV=[5,5,5]: idm=1. Testing only with maxN=1 for determinism.
% Best for thickness=5 (all rows): 2D footprint = 5x5 with (3,3) false.
%   Best 2D rect in 5x5 missing (3,3): 5x2=10 or 2x5=10 or 4x2=8...
%   Actually the best rectangle avoiding (3,3) in a 5x5 grid:
%   rows 1:5, cols 1:2 -> area=10; or rows 1:5, cols 4:5 -> area=10;
%   or rows 1:2, cols 1:5 -> area=10; or rows 4:5, cols 1:5 -> area=10.
%   All give area=10, vol=10*5=50. The first found (leftmost) is rows 1:5, cols 1:2 (pages).
%   In original coords: r=1:5, c=1:5, p=1:2.
M = true(5,5,5);
M(3,3,3) = false;
chk.i(M,'maxN',1).o([1,2,1,5,1,5],[2,5,5],50)
%
%% Documentation Example %%
%
% Two overlapping boxes; the larger 3x5x4=60 dominates the smaller 2x4x3=24.
% The 3x5x4 box is entirely within the true region.
M = false(9,9,9);
M(2:3, 2:5, 2:4) = true;  % 2x4x3 (vol=24)
M(3:5, 3:7, 3:6) = true;  % 3x5x4 (vol=60)
chk.i(M).o([3,5,3,7,3,6],[3,5,4],60)
%
%% Simple Geometric Patterns %%
%
% Single box in corner: rows 1:3, cols 1:4, pages 1:5 -> 3x4x5=60
M = false(8,8,8);
M(1:3, 1:4, 1:5) = true;
chk.i(M).o([1,3,1,4,1,5],[3,4,5],60)
%
% Single box in center: rows 4:6, cols 3:7, pages 2:8 -> 3x5x7=105
M = false(10,10,10);
M(4:6, 3:7, 2:8) = true;
chk.i(M).o([4,6,3,7,2,8],[3,5,7],105)
%
% Two non-overlapping boxes; find the larger one (3x4x3=36).
% Array [8,8,6]: pages=6 is smallest (idm=3).
M = false(8,8,6);
M(1:2, 1:2, 1:3) = true;  % 2x2x3=12
M(5:7, 5:8, 4:6) = true;  % 3x4x3=36
chk.i(M).o([5,7,5,8,4,6],[3,4,3],36)
%
% Cube in center: rows 3:5, cols 3:5, pages 3:5 -> 3x3x3=27
M = false(9,9,9);
M(3:5, 3:5, 3:5) = true;
chk.i(M).o([3,5,3,5,3,5],[3,3,3],27)
%
% Three boxes of different sizes; the largest (3x5x4=60) should be returned.
M = false(12,12,12);
M(1:2,  1:3,  1:2)  = true;  % 2x3x2=12
M(5:7,  5:9,  5:8)  = true;  % 3x5x4=60
M(9:10, 9:11, 9:11) = true;  % 2x3x3=18
chk.i(M).o([5,7,5,9,5,8],[3,5,4],60)
%
%% Index Input Format %%
%
% A single 3x5x4=60 box, passed as index vectors.
M = false(9,9,9);
M(3:5, 3:7, 3:6) = true;
[vxR, vxC, vxP] = ind2sub(size(M), find(M));
chk.i(vxR, vxC, vxP).o([3,5,3,7,3,6],[3,5,4],60)
%
% Single voxel as index vectors.
M = false(5,5,5);
M(3,3,3) = true;
[vxR, vxC, vxP] = ind2sub(size(M), find(M));
chk.i(vxR, vxC, vxP).o([3,3,3,3,3,3],[1,1,1],1)
%
% Two disjoint equal-volume boxes as index vectors; maxN=1 returns the first found.
% Both boxes are 3x3x3=27.  The lower-index box is found first.
M = false(10,10,10);
M(1:3, 1:3, 1:3) = true;
M(7:9, 7:9, 7:9) = true;
[vxR, vxC, vxP] = ind2sub(size(M), find(M));
chk.i(vxR, vxC, vxP, 'maxN',1).o([1,3,1,3,1,3],[3,3,3],27)
%
%% Options Tests %%
%
% All options tests use a reference block where pages is the smallest array
% dimension (idm=3), so that the option semantics map cleanly:
%   minHeight/maxHeight  -> rows    (2D height in permuted space = original rows)
%   minWidth/maxWidth    -> columns (2D width  in permuted space = original cols)
%   minDepth/maxDepth    -> pages   (slab thickness = original pages)
%
% Reference block: M = false(10,10,5);  M(2:5, 3:7, 2:4) = true;
%   h=4 (rows 2:5), w=5 (cols 3:7), d=3 (pages 2:4), vol=60.
%   iszV=[10,10,5]: pages=5 is smallest -> idm=3. Slab iterates pages.
%
%% Options Passed as a Scalar Struct %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;
%
% Struct with minDepth=2 and maxN=1: d=3 >= 2, result unchanged.
opts = struct('minDepth',2, 'maxN',1);
chk.i(M,opts).o([2,5,3,7,2,4],[4,5,3],60)
%
% Struct with maxHeight=3 and maxN=1: h capped at 3; best 3x5x3=45.
opts = struct('maxHeight',3, 'maxN',1);
chk.i(M,opts).o([2,4,3,7,2,4],[3,5,3],45)
%
% Struct with multiple dimension constraints, all satisfied.
opts = struct('minHeight',1, 'maxHeight',5, 'minWidth',1, 'maxWidth',6, ...
              'minDepth',1, 'maxDepth',5, 'minVolume',1, 'maxVolume',100, 'maxN',1);
chk.i(M,opts).o([2,5,3,7,2,4],[4,5,3],60)
%
%% maxN Option %%
%
% Two equal-volume blocks (2x3x2=12 each), non-overlapping.
% Array [8,8,5]: pages=5 is smallest (idm=3); slab iterates pages.
% Block 1 (pages 1:2) is found first; Block 2 (pages 3:4) appended for maxN>=2.
M = false(8,8,5);
M(1:2, 1:3, 1:2) = true;  % Block 1: rows 1:2, cols 1:3, pages 1:2  (2x3x2=12)
M(5:6, 5:7, 3:4) = true;  % Block 2: rows 5:6, cols 5:7, pages 3:4  (2x3x2=12)
%
% maxN=1: only the first block is returned.
chk.i(M,'maxN',1).o([1,2,1,3,1,2],[2,3,2],12)
%
% maxN=2: both equal-volume blocks are returned (Block 1 first).
chk.i(M,'maxN',2).o([1,2,1,3,1,2; 5,6,5,7,3,4],[2,3,2; 2,3,2],12)
%
%% minVolume / maxVolume Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % 4x5x3=60
%
% minVolume=59: 60 >= 59, result unchanged.
chk.i(M,'minVolume',59).o([2,5,3,7,2,4],[4,5,3],60)
%
% minVolume=60: 60 == 60, boundary - result unchanged.
chk.i(M,'minVolume',60).o([2,5,3,7,2,4],[4,5,3],60)
%
% minVolume=61: 60 < 61, no qualifying cuboid found.
chk.i(M,'minVolume',61).o([],[],0)
%
% maxVolume=61: 60 <= 61, result unchanged.
chk.i(M,'maxVolume',61).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxVolume=60: 60 <= 60, boundary - result unchanged.
chk.i(M,'maxVolume',60).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxVolume=59: vol=60 excluded.
%   For thickness=3 (pages 2:4): maxArea2 = floor(59/3) = 19.
%   The 10x10 slab footprint has a 4x5 true block at rows 2:5, cols 3:7.
%   findLargestBox2D with maxArea=19 on this footprint:
%     bar heights [4,4,4,4,4] (local cols 1:5 within block), Hmax=4, Wmax=floor(19/4)=4.
%     Best constrained rect: 4x4=16 at rows 2:5 (local r=1:4), cols 3:6 (local c=1:4).
%   vol = 16*3 = 48.
chk.i(M,'maxVolume',59,'maxN',1).o([2,5,3,6,2,4],[4,4,3],48)
%
% maxVolume=20: only single-page slabs can qualify; best is 4x5=20 at page 2. Vol=20.
chk.i(M,'maxVolume',20,'maxN',1).o([2,5,3,7,2,2],[4,5,1],20)
%
%% minHeight / maxHeight Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % h=4
%
% minHeight=4: h=4 >= 4, result unchanged.
chk.i(M,'minHeight',4).o([2,5,3,7,2,4],[4,5,3],60)
%
% minHeight=5: h=4 < 5, no qualifying cuboid.
chk.i(M,'minHeight',5).o([],[],0)
%
% maxHeight=4: h=4 <= 4, result unchanged.
chk.i(M,'maxHeight',4).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxHeight=3: height capped at 3; best 3x5=15 at rows 2:4 (topmost 3 of the 4-row block).
%   vol = 15 * 3 = 45.
chk.i(M,'maxHeight',3,'maxN',1).o([2,4,3,7,2,4],[3,5,3],45)
%
% maxHeight=2: best 2x5=10 at rows 2:3. vol = 10*3 = 30.
chk.i(M,'maxHeight',2,'maxN',1).o([2,3,3,7,2,4],[2,5,3],30)
%
%% minWidth / maxWidth Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % w=5
%
% minWidth=5: w=5 >= 5, result unchanged.
chk.i(M,'minWidth',5).o([2,5,3,7,2,4],[4,5,3],60)
%
% minWidth=6: w=5 < 6, no qualifying cuboid.
chk.i(M,'minWidth',6).o([],[],0)
%
% maxWidth=5: w=5 <= 5, result unchanged.
chk.i(M,'maxWidth',5).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxWidth=4: width capped at 4; best 4x4=16 at cols 3:6 (leftmost 4 of the 5-col block).
%   vol = 16*3 = 48.
chk.i(M,'maxWidth',4,'maxN',1).o([2,5,3,6,2,4],[4,4,3],48)
%
% maxWidth=3: best 4x3=12 at cols 3:5 (leftmost 3). vol = 12*3 = 36.
chk.i(M,'maxWidth',3,'maxN',1).o([2,5,3,5,2,4],[4,3,3],36)
%
%% minDepth / maxDepth Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % d=3 (pages 2:4)
%
% minDepth=3: d=3 >= 3, result unchanged.
chk.i(M,'minDepth',3).o([2,5,3,7,2,4],[4,5,3],60)
%
% minDepth=4: slab thickness never reaches 4 without AND becoming empty
%   (the block spans only pages 2:4; pages outside are all false).
%   No qualifying cuboid is found.
chk.i(M,'minDepth',4).o([],[],0)
%
% maxDepth=3: d=3 <= 3, result unchanged.
chk.i(M,'maxDepth',3).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxDepth=2: only thickness <= 2 allowed.
%   For ii=2, jj=3 (thickness=2): AND(page2, page3) = full 4x5 block. area=20. vol=40.
%   For jj=4: thickness=3 > 2, break.  Best is vol=40 at pages 2:3.
chk.i(M,'maxDepth',2,'maxN',1).o([2,5,3,7,2,3],[4,5,2],40)
%
% maxDepth=1: only single-page slabs; best 4x5=20 at page 2. vol=20.
chk.i(M,'maxDepth',1,'maxN',1).o([2,5,3,7,2,2],[4,5,1],20)
%
%% Combined Constraints %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % h=4, w=5, d=3, vol=60
%
% minHeight=3, maxHeight=4: h in [3,4]; best is still 4x5x3=60.
chk.i(M,'minHeight',3,'maxHeight',4,'maxN',1).o([2,5,3,7,2,4],[4,5,3],60)
%
% minWidth=3, maxWidth=4: w in [3,4]; best is 4x4x3=48 (cols 3:6).
chk.i(M,'minWidth',3,'maxWidth',4,'maxN',1).o([2,5,3,6,2,4],[4,4,3],48)
%
% minDepth=2, maxDepth=3: d in [2,3]; best is still 4x5x3=60.
chk.i(M,'minDepth',2,'maxDepth',3,'maxN',1).o([2,5,3,7,2,4],[4,5,3],60)
%
% minVolume=45, maxVolume=60: vol in [45,60]; best is 60.
chk.i(M,'minVolume',45,'maxVolume',60,'maxN',1).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxHeight=3, maxWidth=4: best 3x4=12 at rows 2:4, cols 3:6. vol=12*3=36.
chk.i(M,'maxHeight',3,'maxWidth',4,'maxN',1).o([2,4,3,6,2,4],[3,4,3],36)
%
% maxHeight=3, maxDepth=2: best 3x5=15, thickness=2. vol=15*2=30.
%   rows 2:4, cols 3:7, pages 2:3.
chk.i(M,'maxHeight',3,'maxDepth',2,'maxN',1).o([2,4,3,7,2,3],[3,5,2],30)
%
% minVolume=61 with any other constraint: no qualifying cuboid.
chk.i(M,'minVolume',61,'maxVolume',100).o([],[],0)
%
% maxDepth=1, maxHeight=2: single-page slabs with h<=2; best 2x5=10. vol=10.
chk.i(M,'maxDepth',1,'maxHeight',2,'maxN',1).o([2,3,3,7,2,2],[2,5,1],10)
%
%% Complex Patterns %%
%
% L-shaped 3D region; best box spans one arm of the L.
% Array [10,10,5]: idm=3 (pages).
% Vertical arm:   rows 2:8, cols 2:4, pages 1:5  (7x3x5=105)
% Horizontal arm: rows 2:4, cols 2:8, pages 1:5  (3x7x5=105)
% Union fully covers rows 2:4, cols 2:8 (overlap of both arms).
% Best rectangle: rows 2:4, cols 2:8, pages 1:5 -> 3x7x5=105.
% OR rows 2:8, cols 2:4, pages 1:5 -> 7x3x5=105.  Both equal; maxN=1 returns first found.
% Slab iterates pages (all five pages identical and fully within the union).
% For full thickness=5: 2D footprint (10x10) has L-shape. Best 2D rect = 3x7=21 or 7x3=21.
% In 2D rows=original rows, cols=original cols.  Bar-height approach finds 3x7 first.
% (rows 2:4, cols 2:8 form the widest contiguous rectangle).
M = false(10,10,5);
M(2:8, 2:4, 1:5) = true;
M(2:4, 2:8, 1:5) = true;
chk.i(M,'maxN',1).o([2,4,2,8,1,5],[3,7,5],105)
%
% Cross pattern (two perpendicular slabs through all pages).
% Array [10,10,3]: pages=3 is smallest (idm=3).
% Vertical col-slab:   all rows, cols 4:6, all pages (10x3x3=90).
% Horizontal row-slab: rows 4:6, all cols, all pages (3x10x3=90).
% Best rectangle: rows 1:10, cols 4:6, pages 1:3 (10x3x3=90)
%   OR rows 4:6, cols 1:10, pages 1:3 (3x10x3=90). Both 90; maxN=1 returns first.
% Histogram: for full pages 1:3, 2D footprint has cross shape.  In 10x10 cross,
%   the widest all-true column strip is cols 4:6 (width 3) across all 10 rows -> 30.
%   vs the tallest all-true row strip is rows 4:6 (height 3) across all 10 cols -> 30.
%   Both area 30, vol 90.  Leftmost bar-discharge finds cols 4:6 first -> rows 1:10.
M = false(10,10,3);
M(:,4:6,:)  = true;
M(4:6,:,:)  = true;
chk.i(M,'maxN',1).o([4,6,1,10,1,3],[3,10,3],90)
%
% Hollow cube shell: all-true outer shell, false interior.
% iszV=[8,8,8]: idm=1 (tied).  Slab over rows.
% For thickness=1 (any single outer row or col-page slice):
%   slab footprint = one 8x8 layer. findLargestBox2D returns 8x8=64, vol=64.
% For thickness=2 (rows 1:2 or 7:8): AND of two outer row slices = 8x8 true (both solid). vol=128.
% For thickness=7 (rows 1:7): AND includes interior -> cols 2:7, pages 2:7 false.
%   Actually row 1 is all true and row 7 is all true but for rows 1:7 AND, row slices 2:6
%   have the hollow (cols 2:7, pages 2:7 = false).  AND = only outer ring.
%   In 2D (8x8): outer ring pattern.  Best rect in ring = 8x1=8 border strip.
% Best global: thickness=1 or 2 along rows.  For thickness=2 (rows 1:2 or 7:8): vol=128.
% After inv perm [3,1,2]: rows 1:2, cols 1:8, pages 1:8 -> bbox=[1,2,1,8,1,8], vol=128.
M = true(8,8,8);
M(2:7, 2:7, 2:7) = false;
chk.i(M,'maxN',1).o([1,1,1,8,1,8],[1,8,8],64)
%
%% Dense Arrays with Holes %%
%
% All-true 9x9x9 with one page entirely removed (page 5).
% iszV=[9,9,9]: idm=1 (tied). Slab over rows.
% For full thickness (rows 1:9): 2D footprint (cols x pages, 9x9) has col 5 (pages) all false.
% Best 2D rect not crossing col 5: 9 rows (original cols) x 4 cols (original pages 1:4). Area=36.
% vol=36*9=324.
% inv perm [3,1,2]: r=1:9 (from slab), c=1:9 (from 2D rows=original cols), p=1:4 (2D cols).
M = true(9,9,9);
M(:,:,5) = false;
chk.i(M,'maxN',1).o([1,9,1,9,1,4],[9,9,4],324)
%
% All-true 8x8x8 with one entire row plane removed (row 4).
% Slab over rows (idm=1).  Best range avoids row 4.
% Rows 5:8 (thickness=4): AND = all-true 8x8. area=64. vol=256.
% Rows 1:3 (thickness=3): area=64. vol=192.  Best = 256.
% inv perm: r=5:8 (slab=rows 5:8), c=1:8, p=1:8.
M = true(8,8,8);
M(4,:,:) = false;
chk.i(M,'maxN',1).o([5,8,1,8,1,8],[4,8,8],256)
%
%% LeetCode 2D Example Extended to 3D %%
%
% Classic 4x5 binary matrix repeated through 5 pages.
% Array size [4,5,5]: min(4,5,5)=4 at position 1, so idm=1. Slab over rows.
% For thickness=2 (rows 2:3):
%   Row 2 slice (cols x pages): M(2,:,:) = repmat([1,0,1,1,1],[1,1,5]) => 5x5 with col2=false.
%   Row 3 slice: M(3,:,:) = repmat([1,1,1,1,1],[1,1,5]) => all-true 5x5.
%   AND = 5x5 with col 2 false (from row 2).
%   2D footprint (jszR=5 cols, jszC=5 pages): pattern [1,0,1,1,1] repeated across 5 page-cols.
%   Best rect: cols 3:5 (original cols), all 5 pages -> 2D area = 3*5=15. vol=15*2=30.
%   inv perm [3,1,2]: r=2:3 (slab rows), c=3:5 (2D rows=original cols), p=1:5 (2D cols=pages).
%   bbox=[2,3, 3,5, 1,5]. dims=[2,3,5]. vol=30.
M2D = logical([1,0,1,0,0; 1,0,1,1,1; 1,1,1,1,1; 1,0,0,1,0]);
M = repmat(M2D, [1,1,5]);
chk.i(M,'maxN',1).o([2,3,3,5,1,5],[2,3,5],30)
%
%% Options Tests %%
%
% Reference block for all options tests:
%   M = false(10,10,5);  M(2:5, 3:7, 2:4) = true;
%   h=4 (rows 2:5), w=5 (cols 3:7), d=3 (pages 2:4), vol=60.
%   iszV=[10,10,5]: pages is the smallest dimension (idm=3).
%   Therefore: 2D rows=original rows, 2D cols=original cols, slab=pages.
%
%% Options as a Scalar Struct %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;
%
% Struct with multiple fields; minDepth=2 and maxN=1 should leave result unchanged.
opts = struct('minDepth',2, 'maxN',1);
chk.i(M,opts).o([2,5,3,7,2,4],[4,5,3],60)
%
% Struct with maxHeight=3 (should constrain; see maxHeight tests below)
opts = struct('maxHeight',3, 'maxN',1);
chk.i(M,opts).o([2,4,3,7,2,4],[3,5,3],45)
%
%% maxN Option %%
%
% Two equal-volume blocks (2x3x2=12 each), separated in all dimensions.
% Array size [8,8,5]: pages=5 is smallest (idm=3), slab over pages.
% Block 1 found first (pages 1:2), Block 2 found later (pages 3:4).
M = false(8,8,5);
M(1:2, 1:3, 1:2) = true;  % Block 1: 2x3x2=12
M(5:6, 5:7, 3:4) = true;  % Block 2: 2x3x2=12
%
% maxN=1: only first block returned
chk.i(M,'maxN',1).o([1,2,1,3,1,2],[2,3,2],12)
%
% maxN=2: both equal-volume blocks returned (block1 first, block2 second)
chk.i(M,'maxN',2).o([1,2,1,3,1,2; 5,6,5,7,3,4],[2,3,2; 2,3,2],12)
%
%% minVolume / maxVolume Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % 4x5x3=60
%
% minVolume=59: 60 >= 59, result unchanged
chk.i(M,'minVolume',59).o([2,5,3,7,2,4],[4,5,3],60)
%
% minVolume=60: 60 == 60, result unchanged (boundary)
chk.i(M,'minVolume',60).o([2,5,3,7,2,4],[4,5,3],60)
%
% minVolume=61: 60 < 61, no qualifying cuboid
chk.i(M,'minVolume',61).o([],[],0)
%
% maxVolume=61: 60 <= 61, result unchanged
chk.i(M,'maxVolume',61).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxVolume=60: 60 <= 60, result unchanged (boundary)
chk.i(M,'maxVolume',60).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxVolume=59: 60 excluded; for thickness=3, maxArea2=floor(59/3)=19.
%   In the 10x10 slab footprint (true only at rows 2:5, cols 3:7 = 4x5),
%   best rect with area<=19 is 4x4=16 at rows 2:5, cols 3:6. Vol=16*3=48.
chk.i(M,'maxVolume',59,'maxN',1).o([2,5,3,6,2,4],[4,4,3],48)
%
% maxVolume=20: only single-page slabs qualify; 4x5=20 at page 2. Vol=20.
chk.i(M,'maxVolume',20,'maxN',1).o([2,5,3,7,2,2],[4,5,1],20)
%
%% minHeight / maxHeight Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % h=4
%
% minHeight=4: h=4 >= 4, result unchanged
chk.i(M,'minHeight',4).o([2,5,3,7,2,4],[4,5,3],60)
%
% minHeight=5: h=4 < 5, no result
chk.i(M,'minHeight',5).o([],[],0)
%
% maxHeight=4: h=4 <= 4, result unchanged
chk.i(M,'maxHeight',4).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxHeight=3: h capped at 3; best is 3x5=15 at rows 2:4 (topmost). Vol=15*3=45.
chk.i(M,'maxHeight',3,'maxN',1).o([2,4,3,7,2,4],[3,5,3],45)
%
% maxHeight=2: best 2x5=10 at rows 2:3. Vol=10*3=30.
chk.i(M,'maxHeight',2,'maxN',1).o([2,3,3,7,2,4],[2,5,3],30)
%
%% minWidth / maxWidth Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % w=5
%
% minWidth=5: w=5 >= 5, result unchanged
chk.i(M,'minWidth',5).o([2,5,3,7,2,4],[4,5,3],60)
%
% minWidth=6: w=5 < 6, no result
chk.i(M,'minWidth',6).o([],[],0)
%
% maxWidth=5: w=5 <= 5, result unchanged
chk.i(M,'maxWidth',5).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxWidth=4: best 4x4=16 at cols 3:6 (leftmost). Vol=16*3=48.
chk.i(M,'maxWidth',4,'maxN',1).o([2,5,3,6,2,4],[4,4,3],48)
%
% maxWidth=3: best 4x3=12 at cols 3:5 (leftmost). Vol=12*3=36.
chk.i(M,'maxWidth',3,'maxN',1).o([2,5,3,5,2,4],[4,3,3],36)
%
%% minDepth / maxDepth Options %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % d=3 (pages 2:4)
%
% minDepth=3: d=3 >= 3, result unchanged
chk.i(M,'minDepth',3).o([2,5,3,7,2,4],[4,5,3],60)
%
% minDepth=4: d=3 < 4; no slab thickness >= 4 possible (max slab = 5 pages but
%   the block only spans 3 pages, so AND becomes empty before thickness=4).
%   Actually: all pages outside the block are false so AND empties at thickness>3.
%   Result: no qualifying cuboid.
chk.i(M,'minDepth',4).o([],[],0)
%
% maxDepth=3: d=3 <= 3, result unchanged
chk.i(M,'maxDepth',3).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxDepth=2: only thickness<=2; best is 4x5=20 at pages 2:3. Vol=20*2=40.
chk.i(M,'maxDepth',2,'maxN',1).o([2,5,3,7,2,3],[4,5,2],40)
%
% maxDepth=1: only single slabs; best is 4x5=20 at page 2. Vol=20.
chk.i(M,'maxDepth',1,'maxN',1).o([2,5,3,7,2,2],[4,5,1],20)
%
%% Combined Constraints %%
%
M = false(10,10,5);
M(2:5, 3:7, 2:4) = true;  % h=4, w=5, d=3, vol=60
%
% minHeight=3, maxHeight=4: h in [3,4], best is still 4x5x3=60
chk.i(M,'minHeight',3,'maxHeight',4,'maxN',1).o([2,5,3,7,2,4],[4,5,3],60)
%
% minWidth=3, maxWidth=4: w in [3,4], best is 4x4x3=48 (at cols 3:6)
chk.i(M,'minWidth',3,'maxWidth',4,'maxN',1).o([2,5,3,6,2,4],[4,4,3],48)
%
% minDepth=2, maxDepth=3: d in [2,3], best is still 4x5x3=60
chk.i(M,'minDepth',2,'maxDepth',3,'maxN',1).o([2,5,3,7,2,4],[4,5,3],60)
%
% minVolume=45, maxVolume=60: vol in [45,60], best is 60
chk.i(M,'minVolume',45,'maxVolume',60,'maxN',1).o([2,5,3,7,2,4],[4,5,3],60)
%
% maxHeight=3, maxWidth=4: best 3x4=12 at rows 2:4, cols 3:6. Vol=12*3=36.
chk.i(M,'maxHeight',3,'maxWidth',4,'maxN',1).o([2,4,3,6,2,4],[3,4,3],36)
%
% maxHeight=3, maxDepth=2: best 3x5x2=30 at rows 2:4, cols 3:7, pages 2:3.
chk.i(M,'maxHeight',3,'maxDepth',2,'maxN',1).o([2,4,3,7,2,3],[3,5,2],30)
%
% minVolume=61 and maxVolume=100: no cuboid in the block has vol>=61 (next
%   candidate after 60 would require extra voxels that don't exist).
chk.i(M,'minVolume',61,'maxVolume',100).o([],[],0)
%
%% Complex Patterns %%
%
% L-shape (two arms meeting at a corner); best box spans the overlap.
% Array size [10,10,5] keeps idm=3.
M = false(10,10,5);
M(2:8, 2:4, 1:5) = true;  % Vertical arm: 7x3x5=105
M(2:4, 2:8, 1:5) = true;  % Horizontal arm: 3x7x5=105
% Bounding box of the overlap region (rows 2:4, cols 2:8 OR rows 2:8, cols 2:4).
% Best rectangle in the union: rows 2:4, cols 2:8, pages 1:5 (3x7x5=105)
%   OR rows 2:8, cols 2:4, pages 1:5 (7x3x5=105). Both give vol=105. maxN=1.
chk.i(M,'maxN',1).o([2,4,2,8,1,5],[3,7,5],105)
%
% Cross pattern (two slabs crossing through an axis).
% Horizontal slab rows 4:6 fills all cols & pages; vertical slab cols 4:6 fills all rows & pages.
% Array size [10,10,3]: pages=3 is smallest (idm=3).
M = false(10,10,3);
M(:,4:6,:) = true;    % Vertical slab: 10x3x3=90
M(4:6,:,:) = true;    % Horizontal slab: 3x10x3=90
% Best rect in the union: rows 1:10, cols 4:6, pages 1:3 (10x3x3=90)
%   OR rows 4:6, cols 1:10, pages 1:3 (3x10x3=90). Both give 90. maxN=1.
chk.i(M,'maxN',1).o([4,6,1,10,1,3],[3,10,3],90)
%
%% Dense Arrays with Holes %%
%
% All-true array with one page removed (plane hole).
% iszV=[9,9,9]: idm=1 (rows, tied). Slab over rows.
% Best rect: across all 9 rows, in col-page 2D space (9x9) with col=page5 all-false.
% Best 2D rect not crossing col 5: rows 1:9 (2D rows=original cols), cols 1:4
%   (2D cols=original pages). After inv perm: r=1:9, c=1:9, p=1:4. Vol=9*9*4=324.
M = true(9,9,9);
M(:,:,5) = false;
chk.i(M,'maxN',1).o([1,9,1,9,1,4],[9,9,4],324)
%
% All-true array with a wall of voxels removed along one row.
% iszV=[8,8,8]: idm=1 (tied). Slab over rows. Row 4 is excluded entirely.
% Best rect spans rows 5:8 (thickness=4) or rows 1:3 (thickness=3) in 2D = 8x8 footprint.
% Rows 5:8 give thickness 4, 2D footprint for those rows = all 8x8 = 8x8, area=64, vol=256.
% Rows 1:3 give thickness 3, area=64, vol=192. Best = 256 at rows 5:8.
% Wait: the slab is over original rows, and the footprint = AND of each row slice.
% Rows 5:8: M(5:8,:,:)=true(4,8,8), so slices are all-true 8x8. AND = true 8x8. area=64.
% Slab rows 5:8, all cols, all pages => [5,8, 1,8, 1,8], dims=[4,8,8], vol=256.
M = true(8,8,8);
M(4,:,:) = false;
chk.i(M,'maxN',1).o([5,8,1,8,1,8],[4,8,8],256)
%
%% LeetCode 2D Example Extended to 3D %%
%
% Classic 2D example repeated through 5 pages; best 2D rect is 2x3=6 (rows 2:3, cols 3:5).
% Extended through 5 pages: vol=6*5=30. Array size [4,5,5]: pages=5 tied with rows=4... 
% Actually [4,5,5]: min=4 at row (idm=1). Slab over rows.
% For all 4 rows AND: only positions true in ALL rows. Row 4 = [1,0,0,1,0] in 2D, 
%   which kills the "always-true" region.
% Best rect for thickness=2 (rows 2:3): slab AND(row2, row3) = ...
%   Row 2: [1,0,1,1,1] * 5 pages, row 3: [1,1,1,1,1] * 5 pages.
%   AND(row2,row3) = [1,0,1,1,1] per page, repeated 5 pages.
%   In 2D (cols x pages): [1,0,1,1,1; 1,0,1,1,1; 1,0,1,1,1; 1,0,1,1,1; 1,0,1,1,1] transposed.
%   Actually: jszR=cols(5), jszC=pages(5). 2D matrix = [1,0,1,1,1] along rows for each page.
%   Best 2D rect in [1,0,1,1,1] (5-row matrix, all 5 pages identical pattern):
%   Pattern per col (in 2D row direction): [1,0,1,1,1]. Best rect crosses cols 3:5 (all 5 pages).
%   2D area = 3*5=15 (rows=cols 3:5 of original, cols=pages 1:5). Vol=15*2=30. 
%   bbox in perm space: [3,5, 1,5, 2,3]. Inv perm [3,1,2]: r=2:3, c=3:5, p=1:5.
M2D = logical([1,0,1,0,0; 1,0,1,1,1; 1,1,1,1,1; 1,0,0,1,0]);
M = repmat(M2D, [1,1,5]);
chk.i(M,'maxN',1).o([2,3,3,5,1,5],[2,3,5],30)
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