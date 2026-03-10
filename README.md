# `findLargestBox2D` & `findLargestBox3D` #

Two MATLAB functions for finding the largest axis-aligned rectangle (2D) or rectangular cuboid (3D) within boolean occupancy grids.

## Overview ##

These MATLAB functions solve the classic computational geometry problem of finding the largest axis-aligned 2D rectangles or 3D boxes within a boolean mask. The 2D version finds the maximum-area rectangles, while the 3D version finds the maximum-volume cuboids. Both functions use efficient algorithms with polynomial time complexity and are designed to be memory-conscious, supporting multiple input formats including logical matrices/arrays, numeric matrices/arrays, sparse matrices (2D only), and coordinate index vectors.

The [largest empty rectangle](https://en.wikipedia.org/wiki/Largest_empty_rectangle) problem has applications in VLSI design, computer graphics, image processing, robotics, architecture, data visualization, and manufacturing. The naive approach of checking every possible rectangle has exponential complexity, but these functions implement well-known efficient algorithms that find the globally optimal solution in polynomial time.

---

## Algorithms ##

### 2D: Histogram-Based Method ###

The `findLargestBox2D` function uses a histogram-based algorithm that treats each row as the base of a histogram. For each row, the algorithm maintains a height array where each element represents the number of consecutive usable cells above that position in its column. When a blocked cell is encountered, the height resets to zero. The algorithm then uses a stack-based method to find the largest rectangle that fits under each histogram in linear time. The key insight is that every rectangle has some row serving as its bottom edge, so by checking all possible bottom edges efficiently, we can find the global optimum.

### 3D: Slab-Collapse Method ###

The `findLargestBox3D` function extends the 2D algorithm using an exact slab-collapse approach. The algorithm first identifies the smallest dimension to use for iteration, which minimises the O(N²) cost of checking all thickness ranges. For each pair of slabs defining a thickness, the algorithm computes a 2D footprint by taking the logical AND of all slabs in that range, then calls `findLargestBox2D` on this footprint to find the maximum area. The volume is calculated as area times thickness. An early exit optimisation stops iteration when a slab becomes empty, since no thicker box is possible from that starting slab. Finally, the result is mapped back to the original coordinate system.

---

## What These Functions Can Do ##

These functions find one or more rectangles or cuboids of the same maximum size. Both functions accept flexible input formats including logical matrices or arrays, sparse matrices (2D only, since MATLAB does not support native 3D sparse arrays), and index vectors specifying coordinates. An optional `maxN` parameter controls how many equal-maximum-size results are returned.

The algorithms find exact, globally optimal solutions. They do not use heuristics or approximations, so the returned rectangle or box is guaranteed to have the maximum possible area or volume among all axis-aligned candidates. Both functions also accept optional size constraints (minimum/maximum area or volume, height, width, and depth) to restrict results to a desired range.

## What These Functions Cannot Do ##

The algorithms work exclusively with axis-aligned shapes. They cannot find rotated rectangles or boxes, even when a rotated shape would have a larger area or volume — for example, a diagonal corridor at 45 degrees might allow a large rotated rectangle, but these functions will only find the largest axis-aligned one. Finding rotated shapes requires completely different algorithms such as rotating calipers or convex hull methods.

The functions operate on binary masks where cells are either usable or blocked. They cannot handle weighted grids or grayscale images where different cells have different costs or values. All usable cells are treated equally, so optimisation based on cell values or minimising cost is not supported.

Finally, while the theoretical limit is 2^53 pixels or voxels (about 9 quadrillion), memory constraints will be restrictive long before that limit.

---

## Syntax ##

### `findLargestBox2D` ###

	bbox = findLargestBox2D(mask)
	bbox = findLargestBox2D(pixR, pixC)
	bbox = findLargestBox2D(..., <name-value options>)
	[bbox, dims, area, info] = findLargestBox2D(...)

### `findLargestBox3D` ###

	bbox = findLargestBox3D(mask)
	bbox = findLargestBox3D(vxR, vxC, vxP)
	bbox = findLargestBox3D(..., <name-value options>)
	[bbox, dims, volume, info] = findLargestBox3D(...)

---

## Options ##

Both functions accept the similar options, supplied either as a scalar structure or as comma-separated name-value pairs. Field names and string values are case-insensitive.

| Field Name  | Default | Description                                      |
|-------------|---------|--------------------------------------------------|
| `display`   | `'silent'` | Feedback level: `'silent'`, `'verbose'`, or `'waitbar'` |
| `maxN`      | `Inf`   | Maximum number of rectangles/cuboids to return   |
| `minArea`   | `1`     | Minimum rectangle area in pixels (2D only)       |
| `maxArea`   | `Inf`   | Maximum rectangle area in pixels (2D only)       |
| `minVolume` | `1`     | Minimum cuboid volume in voxels (3D only)        |
| `maxVolume` | `Inf`   | Maximum cuboid volume in voxels (3D only)        |
| `minHeight` | `1`     | Minimum height in rows                           |
| `maxHeight` | `Inf`   | Maximum height in rows                           |
| `minWidth`  | `1`     | Minimum width in columns                         |
| `maxWidth`  | `Inf`   | Maximum width in columns                         |
| `minDepth`  | `1`     | Minimum depth in pages (3D only)                 |
| `maxDepth`  | `Inf`   | Maximum depth in pages (3D only)                 |

---

## Examples ##

From `findLargestBox2D.m`:

	>> mask = sparse(10000, 10000);
	>> mask(1000:1010, 2000:2050) = 1; % 11x51
	>> [bbox, dims, area] = findLargestBox2D(mask)
	bbox = [1000,1010, 2000,2050]
	dims = [11, 51]
	area = 561

	>> mask = false(9,9);
	>> mask(2:5, 2:3) = true; % 4x2
	>> mask(5:7, 3:8) = true; % 3x6
	>> [bbox, dims, area] = findLargestBox2D(mask)
	bbox = [5,7, 3,8]
	dims = [3, 6]
	area = 18

	>> [rows, cols] = find(mask);
	>> [bbox, dims, area] = findLargestBox2D(rows, cols)
	bbox = [5,7, 3,8]
	dims = [3, 6]
	area = 18

	>> [~, ~, ~, info] = findLargestBox2D(mask);
	>> info.box.height    = 3
	>> info.box.width     = 6
	>> info.box.area      = 18

From `findLargestBox3D.m`:

	>> mask = false(9,9,9);
	>> mask(2:3, 2:5, 2:4) = true; % 2x4x3
	>> mask(3:5, 3:7, 3:6) = true; % 3x5x4
	>> [bbox, dims, volume] = findLargestBox3D(mask)
	bbox = [3,5, 3,7, 3,6]
	dims = [3, 5, 4]
	volume = 60

	>> [vxR, vxC, vxP] = ind2sub(size(mask), find(mask));
	>> [bbox, dims, volume] = findLargestBox3D(vxR, vxC, vxP)
	bbox = [3,5, 3,7, 3,6]
	dims = [3, 5, 4]
	volume = 60

	>> [~, ~, ~, info] = findLargestBox3D(mask);
	>> info.box.height    = 3
	>> info.box.width     = 5
	>> info.box.depth     = 4
	>> info.box.volume    = 60

---

## Output Arguments ##

### `findLargestBox2D` ###

| Output | Size  | Description |
|--------|-------|-------------|
| `bbox` | N×4   | `[r1, r2, c1, c2]` — first and last row and column indices of each rectangle. Empty (`[]`) if none found. |
| `dims` | N×2   | `[height, width]` — size of each rectangle in pixels. Empty (`[]`) if none found. |
| `area` | scalar | Area of the largest rectangle(s), in pixels. Zero if none found. |
| `info` | struct | Geometry and diagnostic information (see below). |

The `info` structure contains:

- `.box.indices`   — same as `bbox`
- `.box.corners`   — pixel-edge coordinates `[r1-½, r2+½, c1-½, c2+½]`
- `.box.center`    — centroid coordinates
- `.box.height`    — number of pixel rows
- `.box.width`     — number of pixel columns
- `.box.area`      — same as `area`
- `.box.perimeter` — perimeter length
- `.box.diagonal`  — distance between the farthest corners
- `.options`       — the option set used
- `.inputFormat`   — `'matrix'`, `'sparse'`, or `'indices'`
- `.rowsProcessed` — number of mask rows processed
- `.numBoxes`      — number of rectangles found
- `.timeTotal`     — total execution time in seconds

### `findLargestBox3D` ###

| Output   | Size  | Description |
|----------|-------|-------------|
| `bbox`   | N×6   | `[r1, r2, c1, c2, p1, p2]` — first and last row, column, and page indices of each cuboid. Empty (`[]`) if none found. |
| `dims`   | N×3   | `[height, width, depth]` — size of each cuboid in voxels. Empty (`[]`) if none found. |
| `volume` | scalar | Volume of the largest cuboid(s), in voxels. Zero if none found. |
| `info`   | struct | Geometry and diagnostic information (see below). |

The `info` structure contains:

- `.box.indices`    — same as `bbox`
- `.box.corners`    — voxel-edge coordinates `[r1-½, r2+½, c1-½, c2+½, p1-½, p2+½]`
- `.box.center`     — centroid coordinates
- `.box.height`     — number of voxel rows
- `.box.width`      — number of voxel columns
- `.box.depth`      — number of voxel pages
- `.box.volume`     — same as `volume`
- `.box.area`       — total surface area of the cuboid
- `.box.diagonal`   — distance between the farthest corners
- `.options`        — the option set used
- `.inputFormat`    — `'array'` or `'indices'`
- `.slabDimension`  — dimension used for slab iteration (1, 2, or 3)
- `.slabsProcessed` — total slab pairs processed
- `.numBoxes`       — number of cuboids found
- `.time2DFun`      — cumulative time spent in `findLargestBox2D`, in seconds
- `.timeTotal`      — total execution time in seconds

---

## Performance Characteristics ##

The 2D function has O(rows × cols) time complexity, which is optimal since every cell must be examined. In practice, performance varies with data patterns, as masks with many consecutive usable cells benefit from better cache performance and fewer stack operations. For sparse or index-based inputs, only one row at a time is constructed in memory, providing significant memory savings.

The 3D function has O(M × N²) complexity where N is the minimum dimension and M is the product of the other two. The automatic selection of the smallest dimension for iteration can noticeably impact performance. For a 100×200×50 mask, iterating along the smallest dimension (50) requires about 50 million operations, whereas iterating along the largest dimension (200) would require about 200 million operations — a 4-fold difference.

Memory usage is carefully optimised in both functions. The 2D function requires only O(cols) working memory regardless of input format. The 3D function stores one 2D slab whose size is determined by the two largest dimensions when using array input, or performs coordinate set operations without creating full masks when using index input. For very large sparse datasets, index input can reduce memory requirements by orders of magnitude.
