# `findLargestBox2D` & `findLargestBox3D` #

Two MATLAB functions for finding the largest axis-aligned rectangle (2D) or rectangular cuboid (3D) within boolean occupancy grids.

## Overview ##

These MATLAB functions solve the classic computational geometry problem of finding the largest axis-aligned rectangle or box within a boolean mask. The 2D version finds the maximum-area rectangle, while the 3D version finds the maximum-volume cuboid. Both functions use efficient algorithms with polynomial time complexity and are designed to be memory-conscious, supporting multiple input formats including logical matrices/arrays, numeric matrices/arrays, sparse matrices (2D only), and coordinate index vectors.

The [largest empty rectangle](https://en.wikipedia.org/wiki/Largest_empty_rectangle) problem has applications in VLSI design, computer graphics, image processing, robotics, architecture, data visualization, and manufacturing. The naive approach of checking every possible rectangle has exponential complexity, but these functions implement well-known efficient algorithms that find the globally optimal solution in polynomial time.

---

## Algorithms ##

### 2D: Histogram-Based Method ###

The `findLargestBox2D` function uses a histogram-based algorithm that treats each row as the base of a histogram. For each row, the algorithm maintains a height array where each element represents the number of consecutive usable cells above that position in its column. When a blocked cell is encountered, the height resets to zero. The algorithm then uses a stack-based method to find the largest rectangle that fits under each histogram in linear time. The key insight is that every rectangle has some row serving as its bottom edge, so by checking all possible bottom edges efficiently, we can find the global optimum.

The time complexity is O(rows × cols), which is optimal since every cell must be examined at least once. The space complexity is O(cols), as only the current histogram and a stack are stored. For sparse or index-based inputs, only one row at a time is constructed in memory, providing significant memory savings.

### 3D: Slab-Collapse Method ###

The `findLargestBox3D` function extends the 2D algorithm using an exact slab-collapse approach. The algorithm first identifies the smallest dimension to use for iteration, which minimizes the O(N²) cost of checking all thickness ranges. For each pair of slabs defining a thickness, the algorithm computes a 2D footprint by taking the logical AND of all slabs in that range, then calls `findLargestBox2D` on this footprint to find the maximum area. The volume is calculated as area times thickness. An early exit optimization stops iteration when a slab becomes empty, since no thicker box is possible. Finally, the result is mapped back to the original coordinate system.

The time complexity is O(M × N²), where N is the minimum dimension and M is the product of the other two dimensions. For example, a 100×200×50 array would be O(20,000 × 50²) = 50000000 = 50 million operations, which is 4 times faster than iterating along the largest dimension. The space complexity is O(M) for storing the 2D footprint. For index inputs, coordinate intersection operations are used instead of explicit matrices, dramatically reducing memory usage for sparse data.

---

## What These Functions Can Do ##

These functions find only a single rectangle or box, specifically the one with maximum area or volume. These functions accept flexible input formats including logical matrices or arrays, sparse matrices (2D only, since MATLAB does not provide native 3D sparse arrays), and index vectors specifying coordinates.

The algorithms find exact, globally optimal solutions. They do not use heuristics or approximations, so the returned rectangle or box is guaranteed to have the maximum possible area or volume among all axis-aligned candidates.


## What These Functions Cannot Do ##

Even if the mask contains multiple disconnected regions of the same size, only one will be returned.

The algorithms work exclusively with axis-aligned shapes. They cannot find rotated rectangles or boxes, even when a rotated shape would have larger area or volume, e.g. a diagonal corridor at 45 degrees might allow a large rotated rectangle, but these functions will only find the smaller axis-aligned one. Finding rotated shapes requires completely different algorithms like rotating calipers or convex hull methods.

The functions operate on binary masks where cells are either usable or blocked. They cannot handle weighted grids or grayscale images where different cells have different costs or values. All usable cells are treated equally, so optimization based on cell values or minimizing cost is not supported.

No shape constraints can be enforced. The functions maximize area or volume without considering aspect ratio or dimensional requirements. If you need an approximately square rectangle or a box with specific proportions, you must add post-processing logic, as the function might return a very long thin shape if that maximizes area.

Finally, while the theoretical limit is 2^53 pixels or voxels (about 9 quadrillion), memory constraints will be restrictive long before that limit.

---

## Examples ##

From `findLargestBox2D.m`:

	>> mask = sparse(10000, 10000);
	>> mask(1000:1010, 2000:2050) = 1;
	>> [bbox, area] = findLargestBox2D(mask)
	bbox = [1000,1010; 2000,2050]
	area = 561
	
	>> mask = false(9,9);
	>> mask(2:3, 2:5) = true; % 2x4
	>> mask(3:5, 3:7) = true; % 3x5
	>> [bbox, area] = findLargestBox2D(mask)
	bbox = [3,5; 3,7]
	area = 15
	
	>> [rows, cols] = find(mask);
	>> [bbox, area] = findLargestBox2D(rows,cols)
	bbox = [3,5; 3,7]
	area = 15
	
	>> [~,~,info] = findLargestBox2D(mask);
	>> info.box.height   = 3
	>> info.box.width    = 5

From `findLargestBox3D.m`:

	>> mask = false(9,9,9);
	>> mask(2:3, 2:5, 2:4) = true; % 2x4x3
	>> mask(3:5, 3:7, 3:6) = true; % 3x5x4
	>> [bbox, volume] = findLargestBox3D(mask)
	bbox = [3,5; 3,7; 3,6]
	volume = 60
	
	>> [vxr,vxc,vxp] = ind2sub(size(mask), find(mask));
	>> [bbox, volume] = findLargestBox3D(vxr,vxc,vxp)
	bbox = [3,5; 3,7; 3,6]
	volume = 60
	
	>> [~,~,info] = findLargestBox3D(mask);
	>> info.box.height   = 3
	>> info.box.width    = 5
	>> info.box.depth    = 4

---

## Performance Characteristics ##

The 2D function has O(rows × cols) time complexity, which is optimal since every cell must be examined. In practice, a 100×100 mask processes in under 1 millisecond, a 1,000×1,000 mask takes 10-50 milliseconds, and a 10,000×10,000 mask requires 1-5 seconds. Performance varies with data patterns, as masks with many consecutive usable cells benefit from better cache performance and fewer stack operations.

The 3D function has O(M × N²) complexity where N is the minimum dimension and M is the product of the other two. The automatic selection of the smallest dimension for iteration can dramatically impact performance. For a 100×200×50 mask, iterating along the smallest dimension (50) requires about 50 million operations, while the worst choice would require 20 billion operations, a 200-fold difference.

Memory usage is carefully optimized in both functions. The 2D function requires only O(cols) working memory regardless of input format. The 3D function stores one 2D slab whose size is determined by the two largest dimensions when using logical input, or performs coordinate set operations without creating full masks when using index input. For very large sparse datasets, index input can reduce memory requirements by orders of magnitude.