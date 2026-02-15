%% |FINDLARGESTBOX2D| Examples
% The function <https://www.mathworks.com/matlabcentral/fileexchange/######
% |findLargestBox2D|> finds the maximum-area axis-aligned rectangle within
% a 2D logical mask using an efficient 
% <https://en.wikipedia.org/wiki/Big_O_notation O(rows*cols)> histogram-
% based algorithm. The function accepts input as a logical matrix,
% a sparse matrix, or as row index and column index vectors.
% This document demonstrates the different input formats and output
% arguments with practical examples.
%
%% Basic Usage: Logical 2D Matrix
% |findLargestBox2D| accepts a 2D logical matrix where TRUE indicates
% usable pixels and FALSE indicates blocked pixels. The function returns
% the bounding box corners of the largest rectangle consisting entirely of
% TRUE pixels. The output |bbox| is a 2x2 matrix [r1,r2; c1,c2] where
% 
% * r1 and r2 are the first and last row indices, and 
% * c1 and c2 are the first and last column indices.
%
% The largest rectangle spans from pixel (r1,c1) to pixel (r2,c2) inclusive:
mask = false(9,9);
mask(2:3, 2:5) = true;  % 2x4 rectangle (area 8)
mask(3:5, 3:7) = true   % 3x5 rectangle (area 15)
bbox = findLargestBox2D(mask)
%% Input Index Vector
% Instead of providing a matrix, you can supply two vectors containing the
% row and column indices of usable pixels. This is particularly useful when
% working with the output of |find| or when you already have index data.
% In general this format provides memory savings compared to a full matrix.
[rows, cols] = find(mask);
bbox = findLargestBox2D(rows, cols)
%% Input Sparse Matrix
% For large matrices this input format may provide memory savings.
% The function processes one row at a time rather than converting the
% entire sparse matrix to full.
% Note that for sparse matrices any non-zero value is treated as TRUE
% (usable), while zero values are treated as FALSE (blocked).
mask = sparse(10000, 10000);
mask(1000:1010, 2000:2050) = 1;  % 11x51 rectangle
bbox = findLargestBox2D(mask)
%% 2nd Output: Area
% The second output returns the area of the largest rectangle in pixels:
[~, area] = findLargestBox2D(mask)
%% 3rd Output: Information Structure
% The third output |info| provides data about the function execution:
[~, ~, info] = findLargestBox2D(mask) % 11x51 = 561
%% 3rd Output: Box Substructure
% If a rectangle is found then the |info.box| substructure provides
% comprehensive geometric information about the rectangle.
% The |corners| field gives fractional coordinates (pixel centers are at
% integer coordinates, so corners are offset by 0.5). The |center| field
% indicates where the diagonals of the rectangle intersect.
info.box
%% Empty or No Valid Rectangle
% If the input contains no usable pixels (e.g. all FALSE), the function
% returns an empty |bbox| and zero area:
mask = false(5,5);  % all blocked pixels
[bbox, area] = findLargestBox2D(mask)
%% Complex Pattern Example
% A more complex mask demonstrating the algorithm finding the optimal
% rectangle among multiple irregular regions:
mask = false(15,15);
mask(2:4, 2:6) = true;    % 3x5 rectangle
mask(6:9, 8:14) = true;   % 4x7 rectangle (largest: area 28)
mask(11:13, 2:4) = true;  % 3x3 rectangle
[bbox, area] = findLargestBox2D(mask)
%% Efficiency of Indices and Sparse Data
% The function is particularly efficient for index data. Using the
% index vector input or sparse matrix input avoids creating full matrices.
%
% Note that runtime is heavily dependent on the data density, the number
% of rectangles, the provided data type, etc. There is no simple way to
% predict which format will require the least memory or runtime.
%
% For example, a 9999x9999 mask with a small usable region:
mask = false(9999,9999);
mask(8888,8888) = true;
mask(432:456,543:567) = true;
[bboxL, areaL, infoL] = findLargestBox2D(mask);

[rows,cols] = find(mask);
[bboxI, areaI, infoI] = findLargestBox2D(rows, cols);

[rows, cols] = meshgrid(432:456, 543:567);
rows = [rows(:);8888];
cols = [cols(:);8888];
[bboxJ, areaJ, infoJ] = findLargestBox2D(rows, cols);

mask = sparse(rows,cols,1);
[bboxS, areaS, infoS] = findLargestBox2D(mask);

isequal(bboxL,bboxI,bboxJ,bboxS)
isequal(areaL,areaI,areaJ,areaS)

fprintf('%9.6f seconds for %s\n',...
	infoL.timeTotal, 'logical matrix',...
	infoI.timeTotal, 'indices (from logical matrix)',...
	infoJ.timeTotal, 'indices (from meshgrid)',...
	infoS.timeTotal, 'sparse matrix')
