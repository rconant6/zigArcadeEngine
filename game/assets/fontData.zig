const V2 = @import("../math.zig").V2;

// # TrueType File Structure (Top-Down)
// ## Font Directory Header (File Start)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u32  | sfntVersion     | 0x00010000 for TrueType
// 4      | u16  | numTables       | Number of tables in font
// 6      | u16  | searchRange     | (max power of 2 <= numTables) × 16
// 8      | u16  | entrySelector   | log2(max power of 2 <= numTables)
// 10     | u16  | rangeShift      | numTables × 16 - searchRange
pub const FontDirHeader = packed struct {
    sfntVersion: u32,
    numTables: u16,
    searchRange: u16,
    entrySelector: u16,
    rangeShift: u16,
    padding: u32,
};
// ## Table Directory Entry (12 bytes each, numTables entries)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u32  | tag             | 4-character table identifier
// 4      | u32  | checksum        | CheckSum for this table
// 8      | u32  | offset          | Offset from beginning of font file
// 12     | u32  | length          | Length of this table in bytes
pub const TableEntry = packed struct {
    tag: u32,
    checksum: u32,
    offset: u32,
    length: u32,
};
// ## Head Table Structure
// Offset | Size | Field              | Description
// -------|------|--------------------|----------------------------------
// 0      | u32  | version            | 0x00010000
// 4      | u32  | fontRevision       | Font revision
// 8      | u32  | checksumAdjustment | Checksum adjustment
// 12     | u32  | magicNumber        | 0x5F0F3CF5
// 16     | u16  | flags              | Font flags
// 18     | u16  | unitsPerEm         | Units per em (64-16384)
// 20     | u64  | created            | Creation date
// 28     | u64  | modified           | Modification date
// 36     | i16  | xMin               | Minimum x coordinate
// 38     | i16  | yMin               | Minimum y coordinate
// 40     | i16  | xMax               | Maximum x coordinate
// 42     | i16  | yMax               | Maximum y coordinate
// 44     | u16  | macStyle           | Font style bits
// 46     | u16  | lowestRecPPEM      | Smallest readable size
// 48     | i16  | fontDirectionHint  | Font direction hint
// 50     | i16  | indexToLocFormat   | 0=short offsets, 1=long offsets
// 52     | i16  | glyphDataFormat    | Glyph data format
pub const HeadTable = packed struct {
    version: u32,
    fontRevision: u32,
    checksumAdjust: u32,
    magicNumber: u32,
    flags: u16,
    unitsPerEm: u16,
    created: u64,
    modified: u64,
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
    macStyle: u16,
    lowestRecPPEM: u16,
    fontDirectionHint: i16,
    indexToLocFormat: i16,
    glyphDataFormat: i16,
    padding: u80,
};

// ## MAXP Table Structure (Maximum Profile)
// Offset | Size | Field              | Description
// -------|------|--------------------|----------------------------------
// 0      | u32  | version            | 0x00005000 for TrueType fonts
// 4      | u16  | numGlyphs          | Number of glyphs in the font
// 6      | u16  | maxPoints          | Maximum points in a non-composite glyph
// 8      | u16  | maxContours        | Maximum contours in a non-composite glyph
// 10     | u16  | maxCompositePoints | Maximum points in a composite glyph
// 12     | u16  | maxCompositeContours| Maximum contours in a composite glyph
// 14     | u16  | maxZones           | 1 if instructions do not use the twilight zone, 2 if they do
// 16     | u16  | maxTwilightPoints  | Maximum points used in Z0
// 18     | u16  | maxStorage         | Number of Storage Area locations
// 20     | u16  | maxFunctionDefs    | Number of FDEFs
// 22     | u16  | maxInstructionDefs | Number of IDEFs
// 24     | u16  | maxStackElements   | Maximum stack depth
// 26     | u16  | maxSizeOfInstructions | Maximum byte count for glyph instructions
// 28     | u16  | maxComponentElements  | Maximum number of components in composite glyph
// 30     | u16  | maxComponentDepth     | Maximum levels of recursion in composites
pub const MaxPTable = packed struct {
    version: u32,
    numGlyphs: u16,
    maxPoints: u16,
    maxContours: u16,
    maxComponsitePoints: u16,
    maxComponsiteContours: u16,
    maxZones: u16,
    maxTwilightPoints: u16,
    maxStorage: u16,
    maxFunctionDefs: u16,
    maxInstructionDefs: u16,
    maxStackElements: u16,
    maxSizeOfInstructions: u16,
    maxComponentElements: u16,
    maxComponentDepth: u16,
};

// ## CMAP Table Header
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u16  | version         | Table version (0)
// 2      | u16  | numTables       | Number of encoding tables
pub const CmapHeader = packed struct {
    version: u16,
    numTables: u16,
};

// ## CMAP Encoding Record (8 bytes each, numTables entries)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u16  | platformID      | Platform identifier
// 2      | u16  | encodingID      | Platform-specific encoding
// 4      | u32  | offset          | Byte offset to subtable
pub const CmapEncoding = packed struct {
    platformID: u16,
    encodingID: u16,
    offset: u32,
};

// ## CMAP Format 4 Subtable Header
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u16  | format          | Format number (4)
// 2      | u16  | length          | Length in bytes
// 4      | u16  | language        | Language code
// 6      | u16  | segCountX2      | 2 × segCount
// 8      | u16  | searchRange     | 2 × (2^floor(log2(segCount)))
// 10     | u16  | entrySelector   | log2(searchRange/2)
// 12     | u16  | rangeShift      | 2 × segCount - searchRange
pub const CmapFormat4Header = packed struct {
    format: u16,
    length: u16,
    language: u16,
    segCountx2: u16,
    searchRange: u16,
    entrySelector: u16,
    rangeShift: u16,
    padding: u16,
};

// ## CMAP Format 4 Segment Arrays (Variable Length)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 14     | u16[segCount] | endCount    | End character code for each segment
// varies | u16  | reservedPad     | Set to 0
// varies | u16[segCount] | startCount  | Start character code for each segment
// varies | u16[segCount] | idDelta     | Delta for all character codes in segment
// varies | u16[segCount] | idRangeOffset | Offsets into glyphIdArray or 0
// varies | u16[] | glyphIdArray   | Glyph index array (variable length)

// ## HHEA Table Structure (Horizontal Header)
// Offset | Size | Field              | Description
// -------|------|--------------------|----------------------------------
// 0      | u32  | version            | 0x00010000
// 4      | i16  | ascender           | Distance from baseline to highest ascender
// 6      | i16  | descender          | Distance from baseline to lowest descender
// 8      | i16  | lineGap            | Gap between lines
// 10     | i16  | advanceWidthMax    | Maximum advance width
// 12     | i16  | minLeftSideBearing | Minimum left side bearing
// 14     | i16  | minRightSideBearing| Minimum right side bearing
// 16     | i16  | xMaxExtent         | Max(lsb + (xMax - xMin))
// 18     | i16  | caretSlopeRise     | Caret slope rise
// 20     | i16  | caretSlopeRun      | Caret slope run
// 22     | i16  | caretOffset        | Caret offset
// 24     | i16  | reserved1          | Set to 0
// 26     | i16  | reserved2          | Set to 0
// 28     | i16  | reserved3          | Set to 0
// 30     | i16  | reserved4          | Set to 0
// 32     | i16  | metricDataFormat   | 0 for current format
// 34     | u16  | numberOfHMetrics   | Number of hMetric entries
pub const HheaTable = packed struct {
    version: u32,
    ascender: i16,
    descender: i16,
    lineGap: i16,
    advanceWidthMax: i16,
    minLeftSideBearing: i16,
    minRightSideBearing: i16,
    xMaxExtent: i16,
    caretSlopeRise: i16,
    caretSlopeRun: i16,
    caretOffset: i16,
    reserved1: i16,
    reserved2: i16,
    reserved3: i16,
    reserved4: i16,
    metricDataFormat: i16,
    numberOfHMetrics: u16,
    padding: u96,
};

// ## HMTX Table Structure (Horizontal Metrics)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | hMetric[numberOfHMetrics] | hMetrics | Horizontal metrics
// varies | i16[numGlyphs - numberOfHMetrics] | leftSideBearing | Left side bearings

// ## HMetric Entry (4 bytes each)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u16  | advanceWidth    | Advance width in font design units
// 2      | i16  | lsb             | Left side bearing in font design units
pub const Hmetric = packed struct {
    advanceWidth: u16,
    lsb: i16,
};

// ## LOCA Table Structure (Index to Location)
// ### Short Format (indexToLocFormat = 0)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u16[numGlyphs + 1] | offsets | Glyph data offsets ÷ 2

// ### Long Format (indexToLocFormat = 1)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | u32[numGlyphs + 1] | offsets | Glyph data offsets

// ## GLYF Table Structure (Glyph Data)
// ### Glyph Header (10 bytes)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 0      | i16  | numberOfContours| -1 for composite, >= 0 for simple
// 2      | i16  | xMin            | Minimum x for coordinate data
// 4      | i16  | yMin            | Minimum y for coordinate data
// 6      | i16  | xMax            | Maximum x for coordinate data
// 8      | i16  | yMax            | Maximum y for coordinate data

pub const GlyfHeader = packed struct {
    numberOfContours: i16,
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
    padding: u48,
};

// ### Simple Glyph Data (follows header)
// Offset | Size | Field           | Description
// -------|------|-----------------|----------------------------------
// 10     | u16[numberOfContours] | endPtsOfContours | End points of each contour
// varies | u16  | instructionLength | Length of instructions
// varies | u8[instructionLength] | instructions | TrueType instructions
// varies | u8[] | flags           | Point flags (variable encoding)
// varies | variable | xCoordinates | X coordinates (variable encoding)
// varies | variable | yCoordinates | Y coordinates (variable encoding)

// Bit | Description
// ----|----------------------------------
// 0   | ON_CURVE_POINT (1 = on curve, 0 = control point)
// 1   | X_SHORT_VECTOR (1 = x coord delta is 1 byte, 0 = 2 bytes)
// 2   | Y_SHORT_VECTOR (1 = y coord delta is 1 byte, 0 = 2 bytes)
// 3   | REPEAT_FLAG (1 = next byte is repeat count for this flag)
// 4   | X_SAME_OR_POSITIVE_X_SHORT_VECTOR (if X_SHORT=1: sign bit, if X_SHORT=0: same as previous)
// 5   | Y_SAME_OR_POSITIVE_Y_SHORT_VECTOR (if Y_SHORT=1: sign bit, if Y_SHORT=0: same as previous)
// 6   | Reserved (set to 0)
// 7   | Reserved (set to 0)
//
// Coordinate Encoding:
// - All coordinates are deltas from previous point (always accumulate)
// - If SAME flag=1 & SHORT flag=0: delta is 0 (read 0 bytes)
// - If SHORT flag=1: delta is signed byte (read 1 byte, use SAME bit as sign)
// - If SHORT flag=0 & SAME flag=0: delta is signed i16 (read 2 bytes)
pub const GlyphFlag = packed struct {
    onCurve: u1,
    xShort: u1,
    yShort: u1,
    repeat: u1,
    xSameOrPos: u1,
    ySameOrPos: u1,
    pad: u2,
};

pub const FilteredGlyph = struct {
    points: []V2,
    contourEnds: []u16,

    contourCount: u16,
    totalPoints: u16,
};
