function [bbox,volume,info] = findLargestBox3D(mask,varargin)
% Find the largest empty axis-aligned box in a 3D boolean mask.
%
% Finds the maximum-volume axis-aligned box (rectangular cuboid) within a
% 3D logical mask using exact slab-collapse along the smallest dimension.
% The mask uses TRUE for usable voxels and FALSE for unusable voxels.
% For each slab range, a 2D footprint is analyzed using findLargestBox2D.
%
%%% Syntax %%%
%
%   bbox = findLargestBox3D(mask)
%   bbox = findLargestBox3D(vxr,vxc,vxp)
%   bbox = findLargestBox3D(...,'waitbar')
%   [bbox,volume,info] = findLargestBox3D(...)
%
%% Algorithm %%
%
% Exact slab-collapse method:
% 1. Choose the smallest dimension for slab iteration (minimize N^2 cost)
% 2. For each starting slab k1:
%    a. For each ending slab k2 >= k1:
%       - Compute 2D footprint via logical AND of slabs k1:k2
%       - Call findLargestBox2D to find max area in footprint
%       - Calculate volume = area * thickness
%       - Track global maximum
%       - Apply upper bound pruning and empty-slab early exit
% 3. Map final bounding box back to original coordinate system
%
% Time complexity:  O(M*N^2) where N = min dimension, M = product of other dims
% Space complexity: O(M) for the 2D slab footprint
%
% For index inputs, no explicit mask matrices are created - all processing
% is done using coordinate intersection, providing massive memory savings.
%
%% Examples %%
%
%   >> mask = false(9,9,9);
%   >> mask(2:3, 2:5, 2:4) = true; % 2x4x3
%   >> mask(3:5, 3:7, 3:6) = true; % 3x5x4
%   >> [bbox, volume] = findLargestBox3D(mask)
%   bbox = [3,5; 3,7; 3,6]
%   volume = 60
%
%   >> [vxr,vxc,vxp] = ind2sub(size(mask), find(mask));
%   >> [bbox, volume] = findLargestBox3D(vxr,vxc,vxp)
%   bbox = [3,5; 3,7; 3,6]
%   volume = 60
%
%   >> [~,~,info] = findLargestBox3D(mask);
%   >> info.box.height   = 3
%   >> info.box.width    = 5
%   >> info.box.depth    = 4
%
%% Input Arguments %%
%
%   mask = 3D logical or numeric array where:
%          TRUE / non-zero == empty/usable voxel
%          FALSE / zero    == blocked/unusable voxel
%   vxr  = NumericVector of N usable voxel row indices.
%   vxc  = NumericVector of N usable voxel column indices.
%   vxp  = NumericVector of N usable voxel page indices.
%   'waitbar' = Uses MATLAB progress-bar with estimated time remaining.
%
%% Output Arguments %%
%
%   bbox   = NumericMatrix [r1,r2; c1,c2; p1,p2], the corner indices of
%            the largest cuboid box consisting of TRUE only, where:
%            r1,r2 = first and last row indices,
%            c1,c2 = first and last column indices,
%            p1,p2 = first and last page indices.
%            If no box is found then bbox=[].
%   volume = NumericScalar, the volume of the box in voxels.
%   info   = ScalarStruct with geometry information (if a box is found):
%            .box.volume    : same as output <volume>
%            .box.indices   : same as output <bbox>
%            .box.corners   : [r1-1/2,r2+1/2; c1-1/2,c2+1/2; p1-1/2,p2+1/2]
%            .box.diagonal  : distance between farthest corners
%            .box.center    : where the diagonals meet
%            .box.height    : number of voxel rows
%            .box.width     : number of voxel columns
%            .box.depth     : number of voxel pages
%            .box.area      : total surface area
%            and some useful information about the function:
%            .inputFormat   : 'logical' or 'indices'
%            .slabDimension : dimension used for slab iteration (1, 2, or 3)
%            .slabsProcessed: total slab pairs processed
%            .timeTotal     : total execution time in seconds
%            .time2DFun     : 2D function execution time in seconds
%
%% Dependencies %%
%
% * findLargestBox2D.m
% * MATLAB R2009b or later.
%
% See also FINDLARGESTBOX2D SPARSE FULL FIND IND2SUB ACCUMARRAY PERMUTE
% REGIONPROPS3 IMFILL BWLABELN BWCONNCOMP BWAREAOPEN CONVHULLN ALPHASHAPE
tic0 = tic();
info = struct('slabsProcessed',0);
bbox = [];
volume = 0;
time2D = 0;
%
%% Input Wrangling %%
%
isw = false;
try %#ok<TRYNC>
	isw = strcmpi(varargin{end},'waitbar');
end
isw = isscalar(isw) && isw;
if isw
	varargin(end) = [];
end
%
switch numel(varargin)
	case 0
		info.inputFormat = 'array';
		isx = false;
		assert(islogical(mask)||isnumeric(mask),...
			'SC:findLargestBox3D:mask:invalidType',...
			'1st input <mask> must be a logical or numeric array.')
		assert(ndims(mask)<4,...
			'SC:findLargestBox3D:mask:invalidSize',...
			'1st input <mask> must be a 3D array.')
		iszV = size(mask);
		iszV(end+1:3) = 1;
	case 2
		info.inputFormat = 'indices';
		isx = true;
		vxr = flb3CheckIndex('1st','vxr',mask);
		vxc = flb3CheckIndex('2nd','vxc',varargin{1});
		vxp = flb3CheckIndex('3rd','vxp',varargin{2});
		assert(isequal(numel(vxr),numel(vxc),numel(vxp)),...
			'SC:findLargestBox3D:indices:differentLengths',...
			'Inputs <vxr>, <vxc>, & <vxp> must have the same length')
		iszV = [max(vxr), max(vxc), max(vxp)];
	otherwise
		error('SC:findLargestBox3D:unsupportedInputs',...
			'Either one 3D array (mask) or three index vectors are supported')
end
%
nTotal = prod(iszV);
%
if numel(iszV)~=3 || ~nTotal
	info.timeTotal = toc(tic0);
	return
end
%
assert(nTotal <= 9007199254740992,... % flintmax('double') = 2^53
	'SC:findLargestBox3D:volumeTooLarge',...
	'Mask volume (%dx%dx%d) exceeds 2^53, use smaller dimensions.',...
	iszV(1), iszV(2), iszV(3));
%
%% Identify Smallest Dimension and Setup Iteration %%
%
[~,idm] = min(iszV);
info.slabDimension = idm;
%
% Determine permutation to move smallest dimension to position 3
% idmPerm maps original positions to permuted positions
idmPerm = [1:idm-1, idm+1:3, idm];
% invPerm maps permuted positions back to original positions
invPerm = idmPerm;
invPerm(idmPerm) = 1:3;
%
% Size in permuted space (smallest dimension is now in position 3)
jszV = iszV(idmPerm);
jszr = jszV(1);
jszc = jszV(2);
jszp = jszV(3);
%
% For index inputs, organize voxels by slab
if isx
	% Determine which original coordinate corresponds to slab dimension
	vxAll = {vxr, vxc, vxp};
	vxDim1 = vxAll{idmPerm(1)}; % First dimension in 2D slice
	vxDim2 = vxAll{idmPerm(2)}; % Second dimension in 2D slice
	vxSlab = vxAll{idmPerm(3)}; % The dimension to iterate through
	%
	% Organize indices by slab for fast lookup
	tmp = 1:numel(vxSlab);
	slabIdx = accumarray(vxSlab, tmp(:), [jszp,1], @(x){x}, {[]});
end
%
if isw
	tItr = jszp * (jszp + 1) / 2;
	wBar = waitbar(0,'Starting ...');
end
%
%% Histogram-Based Box Finding via Slab Collapse %%
%
slabCnt = 0;
bestVol = 0;
bestBox = [0,0;0,0;0,0]; % [r1,r2;c1,c2;s1,s2] in permuted space
%
for ii = 1:jszp
	%
	% Initialize slab accumulator
	if isx % indices
		% do nothing
	else % logical or numeric
		slab = true(jszr,jszc);
	end
	%
	for jj = ii:jszp
		slabCnt = slabCnt + 1;
		%
		if isw
			nItr = (ii-1) * (2*jszp - ii + 2) / 2 + (jj - ii + 1);
			tETR = flb3TimeText(ceil(toc(tic0)*(tItr-nItr)./nItr));
			tTmp = sprintf('%d of %d    %s',nItr+1,tItr,tETR);
			waitbar(nItr./tItr, wBar, tTmp)
		end
		%
		if isx % indices
			%
			% Compute intersection of coordinates across slabs ii:jj
			if isempty(slabIdx{ii})
				break % First slab is empty
			end
			%
			% Start with first slab
			idx = slabIdx{ii};
			slabCoords = unique([vxDim1(idx), vxDim2(idx)], 'rows');
			%
			% Intersect with each subsequent slab
			for kk = ii+1:jj
				if isempty(slabCoords)
					break % Intersection already empty
				end
				if isempty(slabIdx{kk})
					slabCoords = []; % Empty slab means empty intersection
					break;
				end
				%
				idx = slabIdx{kk};
				nextCoords = unique([vxDim1(idx), vxDim2(idx)], 'rows');
				slabCoords = intersect(slabCoords, nextCoords, 'rows');
			end
			%
			if isempty(slabCoords)
				break % No intersection across all slabs
			end
			%
			% Pass to 2D function as indices
			tic2 = tic();
			[bbox2,area2] = findLargestBox2D(slabCoords(:,1),slabCoords(:,2));
			time2D = time2D + toc(tic2);
			%
		else % logical or numeric
			%
			% Extract jj-th slab from original mask and permute
			switch idm
				case 1 % Iterating through rows
					slice2D = permute(mask(jj,:,:),[2,3,1]);
				case 2 % Iterating through columns
					slice2D = permute(mask(:,jj,:),[1,3,2]);
				case 3 % Iterating through pages
					slice2D = mask(:,:,jj);
			end
			%
			% Accumulate via logical AND
			slab = slab & logical(slice2D);
			%
			if ~any(slab(:))
				break % Empty footprint, no point continuing
			end
			%
			% Pass to 2D function as logical mask
			tic2 = tic();
			[bbox2,area2] = findLargestBox2D(slab);
			time2D = time2D + toc(tic2);
		end
		%
		if ~area2
			continue
		end
		%
		% Calculate volume
		thickness = jj - ii + 1;
		tempVol = area2 * thickness;
		%
		% Update best if temp is larger
		if tempVol>bestVol
			bestVol = tempVol;
			bestBox = [bbox2(1,:);bbox2(2,:);ii,jj];
		end
		%
	end
	%
end
%
if isw
	delete(wBar)
end
%
%% Outputs %%
%
volume = bestVol;
%
if volume
	bbox = bestBox(invPerm,:);
end
%
if nargout>2
	if volume
		info.box = flb3Geometry(bbox);
	end
	info.slabsProcessed = slabCnt;
	info.time2DFun = time2D;
	info.timeTotal = toc(tic0);
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox3D
function out = flb3CheckIndex(ord,anm,inp)
assert(isnumeric(inp)&&isreal(inp)&&isvector(inp),...
	sprintf('SC:findLargestBox3D:%s:notRealNumericVector',anm),...
	'%s input <%s> must be a real numeric vector', ord, anm)
assert(isinteger(inp) || all(fix(inp)==inp),...
	sprintf('SC:findLargestBox3D:%s:fractionalValues',anm),...
	'%s input <%s> must not contain fractional values', ord, anm)
assert(all(inp>0),...
	sprintf('SC:findLargestBox3D:%s:negativeValues',anm),...
	'%s input <%s> must not contain zero/negative values', ord, anm)
out = double(inp(:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3CheckIndex
function ss = flb3Geometry(bbox)
% Return basic geometry information about the provided box.
hh = 1 + bbox(1,2) - bbox(1,1);
ww = 1 + bbox(2,2) - bbox(2,1);
dd = 1 + bbox(3,2) - bbox(3,1);
ss = struct('indices',bbox);
ss.corners = [...
	bbox(1,1)-0.5, bbox(1,2)+0.5;...
	bbox(2,1)-0.5, bbox(2,2)+0.5;...
	bbox(3,1)-0.5, bbox(3,2)+0.5];
ss.center = sum(ss.corners,2)./2;
ss.height = hh;
ss.width  = ww;
ss.depth  = dd;
ss.volume = hh * ww * dd;
ss.area   = 2*(hh*ww + hh*dd + ww*dd);
ss.diagonal = sqrt(hh.^2 + ww.^2 + dd.^2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3Geometry
function str = flb3TimeText(toa)
dpf = 1e2;
spl = [0,0,0,ceil(toa*dpf)./dpf]; % s.f
spl(3:4) = flb3FixRem(spl(4),60); % m:s
spl(2:3) = flb3FixRem(spl(3),60); % h:m
spl(1:2) = flb3FixRem(spl(2),24); % d:h
idx = spl~=0 | [false(1,3),~any(spl)];
spl(2,:) = 'dhms';
str = sprintf('%g%c',spl(:,idx));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3TimeText
function V = flb3FixRem(N,D)
V = [fix(N./D),rem(N,D)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3FixRem
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license