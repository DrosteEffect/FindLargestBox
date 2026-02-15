function [bbox,area,info] = findLargestBox2D(mask,varargin)
% Find the largest axis-aligned rectangle in a 2D boolean mask.
%
% Finds the maximum-area axis-aligned rectangle within a 2D mask
% using a reasonably efficient O(rows*cols) histogram-based algorithm.
% The mask uses TRUE for usable pixels and FALSE for unusable pixels.
%
%%% Syntax %%%
%
%   bbox = findLargestBox2D(mask)
%   bbox = findLargestBox2D(pxr,pxc)
%   bbox = findLargestBox2D(...,'waitbar')
%   [bbox,area,info] = findLargestBox2D(...)
%
%% Algorithm %%
%
% Uses the classic histogram-based "largest rectangle in histogram" method:
% 1. Build cumulative height histogram for each row,
% 2. For each row, find the largest rectangle in that histogram,
% 3. Track the global maximum across all rows.
%
% Time  complexity: O(rows*cols)
% Space complexity: O(cols)
%
% For sparse/index inputs, only one row at a time is created in full,
% providing significant memory savings for very sparse data.
%
%% Examples %%
%
%   >> mask = sparse(10000, 10000);
%   >> mask(1000:1010, 2000:2050) = 1;
%   >> [bbox, area] = findLargestBox2D(mask)
%   bbox = [1000,1010; 2000,2050]
%   area = 561
%
%   >> mask = false(9,9);
%   >> mask(2:3, 2:5) = true; % 2x4
%   >> mask(3:5, 3:7) = true; % 3x5
%   >> [bbox, area] = findLargestBox2D(mask)
%   bbox = [3,5; 3,7]
%   area = 15
%
%   >> [rows, cols] = find(mask);
%   >> [bbox, area] = findLargestBox2D(rows,cols)
%   bbox = [3,5; 3,7]
%   area = 15
%
%   >> [~,~,info] = findLargestBox2D(mask);
%   >> info.box.height   = 3
%   >> info.box.width    = 5
%
%% Input Arguments %%
%
%   mask = 2D logical or numeric or sparse matrix where:
%          TRUE / non-zero == empty/usable pixel
%          FALSE / zero    == blocked/unusable pixel
%   pxr  = NumericVector of N usable pixel row indices.
%   pxc  = NumericVector of N usable pixel column indices.
%   'waitbar' = Uses MATLAB progress-bar with estimated time remaining.
%
%% Output Arguments %%
%
%   bbox = NumericMatrix [r1,r2;c1,c2], the corner indices of the
%          largest rectangle box consisting of TRUE/~0 only, where:
%          r1,r2 = first and last row indices,
%          c1,c2 = first and last column indices.
%          If no box is found then bbox=[].
%   area = NumericScalar, the area of the box in pixels.
%   info = ScalarStruct with geometry information (if a box is found):
%          .box.area      : same as output <area>
%          .box.indices   : same as output <bbox>
%          .box.corners   : [r1-1/2,r2+1/2; c1-1/2,c2+1/2]
%          .box.diagonal  : distance between farthest corners
%          .box.center    : where the diagonals meet
%          .box.height    : number of pixel rows
%          .box.width     : number of pixel columns
%          .box.perimeter : perimeter length
%          and some useful information about the function:
%          .inputFormat   : 'matrix', 'sparse', or 'indices'
%          .rowsProcessed : number of mask rows processed
%          .timeTotal     : total execution time in seconds
%
%% Dependencies %%
%
% * MATLAB R2009b or later.
%
% See also FINDLARGESTBOX3D SPARSE FULL FIND SUB2IND ACCUMARRAY POLY2MASK
% REGIONPROPS IMFILL BWLABEL BWCONNCOMP BWAREAOPEN BWAREAFILT CONVHULL
tic0 = tic();
info = struct('rowsProcessed',0);
bbox = [];
area = 0;
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
		if issparse(mask)
			info.inputFormat = 'sparse';
			isx = true;
			assert(isreal(mask),...
				'SC:findLargestBox2D:mask:complexData',...
				'1st input <mask> must be real, not complex!')
			[pxr,pxc] = find(mask);
			minr = min(pxr);
			minc = min(pxc);
			maxr = max(pxr);
			maxc = max(pxc);
		else
			info.inputFormat = 'matrix';
			isx = false;
			assert(islogical(mask)||isnumeric(mask),...
				'SC:findLargestBox2D:mask:invalidType',...
				'1st input <mask> must be a logical, numeric, or a sparse matrix.')
			assert(ndims(mask)<3,...
				'SC:findLargestBox2D:mask:invalidSize',...
				'1st input <mask> must be a 2D matrix.') %#ok<ISMAT>
			tmpr = any(mask,2);
			tmpc = any(mask,1);
			minr = find(tmpr,1,'first');
			minc = find(tmpc,1,'first');
			maxr = find(tmpr,1,'last');
			maxc = find(tmpc,1,'last');
		end
	case 1
		info.inputFormat = 'indices';
		isx = true;
		pxr = flb2CheckIndex('1st','pxr',mask);
		pxc = flb2CheckIndex('2nd','pxc',varargin{1});
		assert(isequal(numel(pxr),numel(pxc)),...
			'SC:findLargestBox2D:indices:differentLengths',...
			'1st & 2nd inputs <pxr> & <pxc> must have the same length')
		minr = min(pxr);
		minc = min(pxc);
		maxr = max(pxr);
		maxc = max(pxc);
	otherwise
		error('SC:findLargestBox2D:unsupportedInputs',...
			'Either one matrix (mask) or two index vectors are supported')
end
%
if numel([minr,minc,maxr,maxc])~=4
	info.timeTotal = toc(tic0);
	return
elseif isx % sparse or indices
	rIdx = accumarray(pxr,pxc,[maxr,1], @(x){x}, {[]});
end
%
assert((maxr*maxc)<=9007199254740992,... flintmax('double') = 2^53
	'SC:findLargestBox2D:areaTooLarge',...
	'Index area (%dx%d) exceeds 2^53, use smaller dimensions.',maxr,maxc);
%
if isw
	rItr = 1+maxr-minr;
	cItr = 1+maxc-minc;
	tItr = rItr*cItr;
	wBar = waitbar(0,'Starting ...');
end
%
%% Histogram-Based Rectangle Finding %%
%
heights  = zeros(1,maxc);
stackPos = zeros(1,maxc+1);
stackHgt = zeros(1,maxc+1);
%
rCnt   = 0;
area   = 0;
bestR1 = 0;
bestC1 = 0;
bestH  = 0;
bestW  = 0;
%
for rr = minr:maxr
	%
	rCnt = rCnt + 1;
	if isx % sparse or indices
		rOne = false(1,maxc);
		rOne(rIdx{rr}) = true;
	else % logical or numeric
		rOne = logical(mask(rr,1:maxc));
	end
	% Update cumulative heights
	heights(rOne)  = heights(rOne) + 1;
	heights(~rOne) = 0;
	% Find largest rectangle in current histogram using stack-based algorithm
	stackSize = 0;
	%
	for cc = minc:maxc
		%
		if isw
			nItr = (cc-minc) + (rr-minr) * cItr;
			tETR = flb2TimeText(ceil(toc(tic0)*(tItr-nItr)./nItr));
			tTmp = sprintf('%d of %d    %s',nItr+1,tItr,tETR);
			waitbar(nItr./tItr, wBar, tTmp)
		end
		%
		hh = heights(cc);
		start = cc;
		% Pop elements from stack while they're taller than current height
		while stackSize>0 && stackHgt(stackSize)>hh
			popH = stackHgt(stackSize);
			popC = stackPos(stackSize);
			stackSize = stackSize - 1;
			% Calculate area of popped rectangle
			width = cc - popC;
			popA = width * popH;
			% Update best if this is larger
			if popA>area
				area = popA;
				bestH  = popH;
				bestW  = width;
				bestR1 = rr - popH + 1;
				bestC1 = popC;
			end
			start = popC;
		end
		% Push current height onto stack if it is positive and different
		if hh>0 && (stackSize==0 || stackHgt(stackSize)<hh)
			stackSize = stackSize + 1;
			stackPos(stackSize) = start;
			stackHgt(stackSize) = hh;
		end
	end
	% Process remaining elements in stack (end of row)
	cEnd = maxc + 1;
	while stackSize>0
		popH = stackHgt(stackSize);
		popC = stackPos(stackSize);
		stackSize = stackSize - 1;
		%
		width = cEnd - popC;
		popA = width * popH;
		%
		if popA>area
			area = popA;
			bestH  = popH;
			bestW  = width;
			bestR1 = rr - popH + 1;
			bestC1 = popC;
		end
	end
end
%
if isw
	delete(wBar)
end
%
%% Outputs %%
%
if area
	r1 = bestR1;
	r2 = bestR1 + bestH - 1;
	c1 = bestC1;
	c2 = bestC1 + bestW - 1;
	bbox = [r1,r2;c1,c2];
end
%
if nargout>2
	if area
		info.box = flb2Geometry(r1,r2,c1,c2);
	end
	info.rowsProcessed = rCnt;
	info.timeTotal = toc(tic0);
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox2D
function out = flb2CheckIndex(ord,anm,inp)
assert(isnumeric(inp)&&isreal(inp)&&isvector(inp),...
	sprintf('SC:findLargestBox2D:%s:notRealNumericVector',anm),...
	'%s input <%s> must be a real numeric vector',ord,anm)
assert(isinteger(inp) || all(fix(inp)==inp),...
	sprintf('SC:findLargestBox2D:%s:fractionalValues',anm),...
	'%s input <%s> must not contain fractional values',ord,anm)
assert(all(inp>0),...
	sprintf('SC:findLargestBox2D:%s:negativeValues',anm),...
	'%s input <%s> must not contain zero/negative values',ord,anm)
out = double(inp(:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2CheckIndex
function ss = flb2Geometry(r1,r2,c1,c2)
% Return basic geometry information about the provided rectangle.
hh = (1+r2-r1);
ww = (1+c2-c1);
ss = struct('indices',[r1,r2; c1,c2]);
ss.corners = [...
	r1-0.5,r2+0.5;...
	c1-0.5,c2+0.5];
ss.center = sum(ss.corners,2)./2;
ss.height = hh;
ss.width  = ww;
ss.area   = hh * ww;
ss.perimeter = 2*(hh + ww);
ss.diagonal  = sqrt(hh.^2 + ww.^2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2Geometry
function str = flb2TimeText(toa)
dpf = 1e2;
spl = [0,0,0,ceil(toa*dpf)./dpf]; % s.f
spl(3:4) = flb2FixRem(spl(4),60); % m:s
spl(2:3) = flb2FixRem(spl(3),60); % h:m
spl(1:2) = flb2FixRem(spl(2),24); % d:h
idx = spl~=0 | [false(1,3),~any(spl)];
spl(2,:) = 'dhms';
str = sprintf('%g%c',spl(:,idx));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2TimeText
function V = flb2FixRem(N,D)
V = [fix(N./D),rem(N,D)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2FixRem
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license