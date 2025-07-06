const std = @import("std");
const fData = @import("fontData.zig");
const FontDirHeader = fData.FontDirHeader;
const TableDirectory = fData.TableDirectory;
const HeadTable = fData.HeadTable;
const CmapHeader = fData.CmapHeader;
const CmapEncoding = fData.CmapEncoding;
const CmapFormat4Header = fData.CmapFormat4Header;
const HHEATable = fData.HHEATable;
const HMetric = fData.HMetric;
const GlyfHeader = fData.GlyfHeader;
const GlyphFlag = fData.GlyphFlag;

const rend = @import("renderer");
const Point = rend.Point;
const Polygon = rend.Polygon;

const TableLookup = enum(u8) {
    HEAD = 0,
    CMAP = 1,
    HHEA = 2,
    HMTX = 3,
    LOCA = 4,
    GLYF = 5,
};

const HEAD = std.mem.bigToNative(u32, @bitCast([4]u8{ 'h', 'e', 'a', 'd' }));
const CMAP = std.mem.bigToNative(u32, @bitCast([4]u8{ 'c', 'm', 'a', 'p' }));
const HHEA = std.mem.bigToNative(u32, @bitCast([4]u8{ 'h', 'h', 'e', 'a' }));
const HMTX = std.mem.bigToNative(u32, @bitCast([4]u8{ 'h', 'm', 't', 'x' }));
const LOCA = std.mem.bigToNative(u32, @bitCast([4]u8{ 'l', 'o', 'c', 'a' }));
const GLYF = std.mem.bigToNative(u32, @bitCast([4]u8{ 'g', 'l', 'y', 'f' }));

const MAX_POINTS_PER_GLYPH: usize = 50;

pub const Font = struct {
    alloc: std.mem.Allocator,
    unitsPerEm: u16, // from head

    // from hhea table
    ascender: i16,
    descender: i16,
    lineGap: i16,

    asciiToGlyph: [96]u16, // from cmap ASCII 32-126
    glyphAdvanceWidths: [96]HMetric, // how far to advance per char
    glyphShapes: [96][MAX_POINTS_PER_GLYPH]?Polygon, // actual renderable shape (could be null);

    pub fn init(alloc: *std.mem.Allocator, path: []const u8) !Font {
        // find the file and read it in
        var pathBuffer: [std.fs.max_path_bytes]u8 = undefined;
        var exeBuffer: [std.fs.max_path_bytes]u8 = undefined;
        const cwd = try std.process.getCwd(&exeBuffer);
        const joinedPath = try std.fmt.bufPrint(&pathBuffer, "{s}/zig-out/bin/resources/{s}", .{ cwd, path });
        const file = try std.fs.openFileAbsolute(joinedPath, .{});
        defer file.close();
        const fileSize = try file.getEndPos();
        const rawData = try alloc.alloc(u8, fileSize);
        defer alloc.free(rawData);
        const dataRead = try file.readAll(rawData);
        std.debug.assert(dataRead == fileSize);

        // TODO: get to this point - shrink this manual crap down to 20 lines
        // fn parseTable(comptime T: type, comptime validator: fn(T) bool) ParseResult(T)

        var font = Font{
            .alloc = alloc.*,
            .unitsPerEm = undefined,
            .ascender = undefined,
            .descender = undefined,
            .lineGap = undefined,
            .asciiToGlyph = undefined,
            .glyphAdvanceWidths = undefined,
            .glyphShapes = undefined,
        };

        // parse the header
        const fontDirHeader = fromBigEndian(FontDirHeader, rawData[0..@sizeOf(FontDirHeader)]);
        // printData(FontDirHeader, fontDirHeader, "FONTDIRHEADER");

        // const MAX_NUMBER_OF_TABLES = 32; // safe number for complex fonts
        const MAX_NUMBER_OF_TABLES = 6; // used for this simple font parser
        var tableDirectory: [MAX_NUMBER_OF_TABLES]TableDirectory = undefined;

        var offset: usize = 12; // Right after font directory header
        for (0..fontDirHeader.numTables) |_| {
            const rawEntry: TableDirectory = @bitCast(rawData[offset .. offset + 16][0..16].*);
            const rawTable = swapEndianness(TableDirectory, rawEntry);
            offset += 16;
            switch (rawTable.tag) {
                HEAD => tableDirectory[@intFromEnum(TableLookup.HEAD)] = rawTable,
                CMAP => tableDirectory[@intFromEnum(TableLookup.CMAP)] = rawTable,
                HHEA => tableDirectory[@intFromEnum(TableLookup.HHEA)] = rawTable,
                HMTX => tableDirectory[@intFromEnum(TableLookup.HMTX)] = rawTable,
                LOCA => tableDirectory[@intFromEnum(TableLookup.LOCA)] = rawTable,
                GLYF => tableDirectory[@intFromEnum(TableLookup.GLYF)] = rawTable,
                else => {}, // Ignoring other tables not needed for this mini-implementation
                // TODO: autogenerate the tables/storage based on what is found
            }
        }

        const headOffset: usize = tableDirectory[@intFromEnum(TableLookup.HEAD)].offset;
        const headSize: usize = @sizeOf(HeadTable);
        const headEnd: usize = tableDirectory[@intFromEnum(TableLookup.HEAD)].offset + headSize;
        const rawHead: HeadTable = @bitCast(rawData[headOffset..headEnd][0..headSize].*);
        const headTable = swapEndianness(HeadTable, rawHead);
        font.unitsPerEm = headTable.unitsPerEm;
        // printData(HeadTable, headTable, "HEADTABLE");

        const cmapOffset: usize = tableDirectory[@intFromEnum(TableLookup.CMAP)].offset;
        const cmapSize: usize = @sizeOf(CmapHeader);
        const cmapEnd: usize = tableDirectory[@intFromEnum(TableLookup.CMAP)].offset + cmapSize;
        const rawCmap: CmapHeader = @bitCast(rawData[cmapOffset..cmapEnd][0..cmapSize].*);
        const cmapHeader = swapEndianness(CmapHeader, rawCmap);
        // printData(CmapHeader, cmapHeader, "CMAPHEADER");

        const hheaOffset: usize = tableDirectory[@intFromEnum(TableLookup.HHEA)].offset;
        const hheaSize: usize = @sizeOf(HHEATable);
        const hheaEnd: usize = tableDirectory[@intFromEnum(TableLookup.HHEA)].offset + hheaSize;
        const rawHhea: HHEATable = @bitCast(rawData[hheaOffset..hheaEnd][0..hheaSize].*);
        const hheaTable = swapEndianness(HHEATable, rawHhea);
        font.ascender = hheaTable.ascender;
        font.descender = hheaTable.descender;
        // printData(HHEATable, hheaTable, "HHEATABLE");

        const cmapEncoding = blk: for (0..cmapHeader.numTables) |i| {
            const cmapEncodeOffset: usize = cmapOffset + 4 + (8 * i);
            const cmapEncodeSize: usize = @sizeOf(CmapEncoding);
            const cmapEncodeEnd: usize = cmapEncodeOffset + cmapEncodeSize;
            const rawCmapEncode: CmapEncoding = @bitCast(rawData[cmapEncodeOffset..cmapEncodeEnd][0..cmapEncodeSize].*);
            const cmapEncode = swapEndianness(CmapEncoding, rawCmapEncode);

            // Unicode Basic Multilingual Plane
            if ((cmapEncode.platformID == 0 and cmapEncode.encodingID == 3)) {
                // std.debug.print("Selected CMAPEN CODING: PlatformID: {d}   EncodingID: {d}\n", .{ cmapEncode.platformID, cmapEncode.encodingID });
                break :blk cmapEncode;
            }
        } else {
            return error.NoUnicodeEncoding;
        };

        const subTableOffset = cmapOffset + cmapEncoding.offset;
        const rawFormat: u16 = @bitCast(rawData[subTableOffset .. subTableOffset + 2][0..2].*);
        const cmapFormat = std.mem.bigToNative(u16, rawFormat);
        // std.debug.print("CMAP Format = {d}\n", .{cmapFormat});
        switch (cmapFormat) {
            0, 6, 10, 12 => {},
            4 => {
                const format4Offset: usize = cmapOffset + cmapEncoding.offset;
                const format4Size: usize = @sizeOf(CmapFormat4Header);
                const format4End: usize = format4Offset + format4Size;
                const rawfmt4Header: CmapFormat4Header = @bitCast(rawData[format4Offset..format4End][0..format4Size].*);
                const fmt4Header = swapEndianness(CmapFormat4Header, rawfmt4Header);
                // std.debug.print("Format4 Data  format: {d} length: {d}\n", .{ fmt4Header.format, fmt4Header.length });

                const segmentCount = fmt4Header.segCountx2 / 2;
                const arraySize: usize = segmentCount * 2;
                var endCountOffset = format4Offset + 14;
                var startCountOffset = endCountOffset + arraySize + 2;
                var idDeltaOffset = startCountOffset + arraySize;
                var idRangeOffset = idDeltaOffset + arraySize;
                const glyphIDArray = idRangeOffset + arraySize;
                for (0..segmentCount) |segment| {
                    endCountOffset += 2;
                    startCountOffset += 2;
                    idDeltaOffset += 2;
                    idRangeOffset += 2;

                    const endCount: u16 = std.mem.bigToNative(u16, @bitCast(rawData[endCountOffset .. endCountOffset + 2][0..2].*));
                    const startCount: u16 = std.mem.bigToNative(u16, @bitCast(rawData[startCountOffset .. startCountOffset + 2][0..2].*));
                    const idDelta: u16 = std.mem.bigToNative(u16, @bitCast(rawData[idDeltaOffset .. idDeltaOffset + 2][0..2].*));
                    const idRange: u16 = std.mem.bigToNative(u16, @bitCast(rawData[idRangeOffset .. idRangeOffset + 2][0..2].*));
                    if (startCount >= 32 and endCount <= 127) {
                        // std.debug.print(
                        //     "endCount: {d}  startCount: {d}  idDeltaOffset: {d} idRangeOffset: {d}\n",
                        //     .{ endCount, startCount, idDelta, idRange },
                        // );
                        var c = startCount;
                        while (c <= endCount) : (c += 1) {
                            const char: u16 = @intCast(c);
                            if (idRange == 0) {
                                font.asciiToGlyph[c - 32] = @truncate(char + idDelta);
                            } else {
                                const glyphArrayIndex = (idRange / 2) + (char - startCount) + segment;
                                const glyphOffset = glyphIDArray + (glyphArrayIndex * 2);
                                const glyphIndex: u16 = std.mem.bigToNative(u16, @bitCast(rawData[glyphOffset .. glyphOffset + 2][0..2].*));
                                font.asciiToGlyph[c - 32] = glyphIndex;
                                // std.debug.print(
                                //     "segment: {d} char: {d}  idRangeVal: {d}   startCountVal: {d}  glyphArrayIndex: {d}   glyphIndex: {d}\n",
                                //     .{ segment, c, idRange, startCount, glyphArrayIndex, glyphIndex },
                                // );
                            }
                        }
                    }
                }
            },
            else => unreachable,
        }

        // std.debug.print("numMetrics: {d}\n", .{hheaTable.numberOfHMetrics});
        const hmtxOffset: usize = tableDirectory[@intFromEnum(TableLookup.HMTX)].offset;
        const numMetrics = hheaTable.numberOfHMetrics;
        for (0..font.asciiToGlyph.len) |i| {
            const glyphIndex = font.asciiToGlyph[i];

            if (glyphIndex == 0) {
                font.glyphAdvanceWidths[i] = HMetric{ .advanceWidth = 0, .lsb = 0 };
            } else if (glyphIndex < numMetrics) {
                const metricByteOffset = hmtxOffset + (glyphIndex * 4);
                const rawMetric: HMetric = @bitCast(rawData[metricByteOffset .. metricByteOffset + 4][0..4].*);
                const metric: HMetric = swapEndianness(HMetric, rawMetric);
                font.glyphAdvanceWidths[i] = metric;
                // std.debug.print("metric: {any}\n", .{metric});
            } else {
                const lastMetricOffset = hmtxOffset + ((numMetrics - 1) * 4);
                const rawMetric: HMetric = @bitCast(rawData[lastMetricOffset .. lastMetricOffset + 4][0..4].*);
                const metric: HMetric = swapEndianness(HMetric, rawMetric);
                font.glyphAdvanceWidths[i] = metric;
                // std.debug.print("metric: {any}\n", .{metric});
            }
        }

        // std.debug.print("headTable.indexToLocFormat: {d}\n", .{headTable.indexToLocFormat});
        const locaOffset = tableDirectory[@intFromEnum(TableLookup.LOCA)].offset;
        // std.debug.print("LOCAOffset: {d}\n", .{locaOffset});

        // std.debug.print("GLYF table offset: {d}\n", .{tableDirectory[@intFromEnum(TableLookup.GLYF)].offset});
        for (0..font.asciiToGlyph.len) |i| {
            const index = font.asciiToGlyph[i];
            if (index == 0) continue;

            const offsetSize: usize = if (headTable.indexToLocFormat == 0) 2 else 4;
            const startByteOffset = locaOffset + (index * offsetSize);
            const endByteOffset = locaOffset + ((index + 1) * offsetSize);

            const start: u32 = if (headTable.indexToLocFormat == 0)
                std.mem.bigToNative(u16, @bitCast(rawData[startByteOffset .. startByteOffset + 2][0..2].*))
            else
                std.mem.bigToNative(u32, @bitCast(rawData[startByteOffset .. startByteOffset + 4][0..4].*));

            const end: u32 = if (headTable.indexToLocFormat == 0)
                std.mem.bigToNative(u16, @bitCast(rawData[endByteOffset .. endByteOffset + 2][0..2].*))
            else
                std.mem.bigToNative(u32, @bitCast(rawData[endByteOffset .. endByteOffset + 4][0..4].*));

            const glyphOffset = tableDirectory[@intFromEnum(TableLookup.GLYF)].offset +
                if (headTable.indexToLocFormat == 0) (start * 2) else start; // const startByteOffset = locaOffset + (index * 2);

            const glyphLen = end - start;
            // std.debug.print("Letter index {d}, glyph index {d}, start offset {d}, end offset {d}\n", .{ i, index, start, end });
            _ = glyphLen;

            // const glyphOffset = tableDirectory[@intFromEnum(TableLookup.GLYF)].offset + (start * 2);
            // std.debug.print("glyphOffset: {d}\n", .{glyphOffset});
            const rawHeader: GlyfHeader = @bitCast(rawData[glyphOffset .. glyphOffset + 10][0..10].*);
            const glyfHeader = swapEndianness(GlyfHeader, rawHeader);
            // std.debug.print("Glyph header: numberOfContours={d}, xMin={d}, yMin={d}, xMax={d}, yMax={d}\n", .{
            //     glyfHeader.numberOfContours,
            //     glyfHeader.xMin,
            //     glyfHeader.yMin,
            //     glyfHeader.xMax,
            //     glyfHeader.yMax,
            // });

            // std.debug.print("Reading glyph header at absolute address: {d}\n", .{glyphOffset});
            // std.debug.print("GLYF base: {d}, calculated offset: {d}\n", .{ tableDirectory[@intFromEnum(TableLookup.GLYF)].offset, glyphOffset - tableDirectory[@intFromEnum(TableLookup.GLYF)].offset });
            // std.debug.print("Raw glyph header bytes: ", .{});
            // for (0..10) |x| {
            //     std.debug.print("{d} ", .{rawData[glyphOffset + x]});
            // }
            // std.debug.print("\n", .{});
            // Only check a few characters for comparison
            // if (i != 14 and i != 44 and i != 16 and i != 41) continue; // period, L, and digit '0'

            // std.debug.print("\n=== CHARACTER {c} (ASCII {d}, array index {d}) ===\n", .{ @as(u8, @intCast(i + 32)), i + 32, i });
            // std.debug.print("Glyph index: {d}\n", .{index});
            // std.debug.print("LOCA start: {d}, end: {d}\n", .{ start, end });
            // std.debug.print("Calculated glyphOffset: {d}\n", .{glyphOffset});

            // Read and print first 10 bytes of glyph data
            // std.debug.print("Raw glyph header bytes: ", .{});
            // for (0..10) |b| {
            //     std.debug.print("{d} ", .{rawData[glyphOffset + b]});
            // }
            // std.debug.print("\n", .{});
            var endPointOffset = glyphOffset + 10;
            const numberOfContours: usize = @intCast(if (glyfHeader.numberOfContours > 0) glyfHeader.numberOfContours else 0);
            var arena = std.heap.ArenaAllocator.init(alloc.*);
            defer arena.deinit();
            const endPts = try arena.allocator().alloc(u16, numberOfContours);
            for (0..numberOfContours) |c| {
                endPts[c] = std.mem.bigToNative(u16, @bitCast(rawData[endPointOffset .. endPointOffset + 2][0..2].*));
                endPointOffset += 2;
            }
            const totalPoints = if (numberOfContours > 0) endPts[numberOfContours - 1] + 1 else 0;
            if (totalPoints == 0) continue;

            // std.debug.print("Contour endpoints: ", .{});
            // for (0..numberOfContours) |c| {
            //     std.debug.print("[{d}]={d} ", .{ c, endPts[c] });
            // }
            // std.debug.print("\n", .{});
            // std.debug.print("Glyph data length: {d} bytes\n", .{glyphLen});
            // std.debug.print("Expected contours from header: {d}\n", .{glyfHeader.numberOfContours});
            // std.debug.print("Total points calculated: {d}\n", .{totalPoints});

            const instOffset = endPointOffset;
            // std.debug.print("instOffset: {d}\n", .{instOffset});
            const instructionLen = std.mem.bigToNative(u16, @bitCast(rawData[instOffset .. instOffset + 2][0..2].*));

            const flagsData = instOffset + 2 + instructionLen;
            // std.debug.print("flagsData: {d}\n", .{flagsData});
            const flags = try arena.allocator().alloc(GlyphFlag, totalPoints);
            var flagIndex: usize = 0;
            var rawBytePos: usize = flagsData;
            while (flagIndex < totalPoints) {
                const rawFlag = rawData[rawBytePos];
                const flag: GlyphFlag = @bitCast(rawFlag);
                flags[flagIndex] = flag;
                flagIndex += 1;
                rawBytePos += 1;

                if (flag.repeat == 1) {
                    const repeatCount = rawData[rawBytePos];
                    rawBytePos += 1; // Skip the repeat count byte

                    // Copy flag to next repeatCount positions
                    for (0..repeatCount) |_| {
                        flags[flagIndex] = flag;
                        flagIndex += 1;
                    }
                }
            }

            const coordsMem = try arena.allocator().alloc(i16, totalPoints * 2);
            // keep using rawBytePos because it is at the right spot
            var currentX: i16 = 0;
            var deltaX: i16 = 0;
            var xIndex: usize = 0;
            while (xIndex < totalPoints) {
                const flag = flags[xIndex];
                if (flag.xSameOrPos == 0 and flag.xShort == 0) {
                    deltaX = std.mem.bigToNative(i16, @bitCast(rawData[rawBytePos .. rawBytePos + 2][0..2].*));
                    rawBytePos += 2;
                    currentX += deltaX;
                } else if (flag.xShort == 1) {
                    const rawByte: u8 = rawData[rawBytePos];
                    const castByte: i16 = @intCast(rawByte);
                    deltaX = if (flag.xSameOrPos == 1) castByte else -castByte;
                    rawBytePos += 1;
                    currentX += deltaX;
                } else {}
                // Store coordinate and advance to next point
                coordsMem[xIndex] = currentX;
                xIndex += 1;
            }

            var currentY: i16 = 0;
            var deltaY: i16 = 0;
            var yIndex: usize = 0;
            while (yIndex < totalPoints) {
                const flag = flags[yIndex];
                if (flag.ySameOrPos == 0 and flag.yShort == 0) {
                    deltaY = std.mem.bigToNative(i16, @bitCast(rawData[rawBytePos .. rawBytePos + 2][0..2].*));
                    rawBytePos += 2;
                    currentY += deltaY;
                } else if (flag.yShort == 1) {
                    const rawByte: u8 = rawData[rawBytePos];
                    const castByte: i16 = @intCast(rawByte);
                    deltaY = if (flag.ySameOrPos == 1) castByte else -castByte;
                    rawBytePos += 1;
                    currentY += deltaY;
                } else {}
                // Store coordinate and advance to next point
                coordsMem[totalPoints + yIndex] = currentY;
                yIndex += 1;
            }

            const MAX_CONTOURS_PER_GLYPH: usize = 15;
            const BoundsType = struct { xMin: i16, xMax: i16, yMin: i16, yMax: i16 };
            const initBounds = BoundsType{ .xMin = std.math.maxInt(i16), .xMax = -std.math.maxInt(i16), .yMin = std.math.maxInt(i16), .yMax = -std.math.maxInt(i16) };
            var contourBounds = [_]BoundsType{initBounds} ** MAX_CONTOURS_PER_GLYPH;
            var currentContour: usize = 0;
            for (0..totalPoints) |loc| {
                if (flags[loc].onCurve == 1) {
                    var bounds = &contourBounds[currentContour];
                    const x: i16 = coordsMem[loc];
                    const y: i16 = coordsMem[totalPoints + loc];
                    bounds.xMin = @min(bounds.xMin, x);
                    bounds.xMax = @max(bounds.xMax, x);
                    bounds.yMin = @min(bounds.yMin, y);
                    bounds.yMax = @max(bounds.yMax, y);
                }

                if (currentContour < numberOfContours and loc == endPts[currentContour]) {
                    // std.debug.print("contourBounds: {any}\n", .{contourBounds[currentContour]});
                    currentContour += 1;
                }
            }

            var pointCount: usize = 0;
            const baseSize = 0.25;
            const scale = baseSize / @as(f32, @floatFromInt(headTable.unitsPerEm));
            var p: Point = undefined;
            const points = try arena.allocator().alloc(Point, MAX_POINTS_PER_GLYPH);
            currentContour = 0;
            for (0..totalPoints) |loc| {
                const whichContour = currentContour;
                if (flags[loc].onCurve == 1) {
                    const rawx: f32 = @floatFromInt(coordsMem[loc]);
                    const rawy: f32 = @floatFromInt(coordsMem[totalPoints + loc]);

                    // const x = rawx / @as(f32, @floatFromInt(headTable.unitsPerEm));
                    // const y = -rawy / @as(f32, @floatFromInt(headTable.unitsPerEm)); // Just flip Y
                    const centerX = @as(f32, @floatFromInt(contourBounds[whichContour].xMax + contourBounds[whichContour].xMin)) / 2.0;
                    const centerY = @as(f32, @floatFromInt(contourBounds[whichContour].yMax + contourBounds[whichContour].yMin)) / 2.0;
                    const x = (rawx - centerX) * scale;
                    const y = (rawy - centerY) * scale * -1.0;
                    p = .{ .x = x, .y = y };
                    // p = .{ .x = rawx / 1000.0, .y = rawy / 1000.0 };
                    points[pointCount] = p;
                    pointCount += 1;
                    // std.debug.print("CurrentContour [{d}]  rawX: {d}   rawY: {d}\n", .{ currentContour, rawx, rawy });
                    // std.debug.print("CurrentContour [{d}]  translated: {d}   translated: {d}\n", .{ currentContour, x, y });
                }
                if (currentContour < numberOfContours and loc == endPts[currentContour]) {
                    // font.glyphShapes[i][currentContour] = try Polygon.init(alloc.*, points[0..pointCount]);
                    // if (currentContour == 0 and loc == endPts[currentContour]) {
                    //     // font.glyphShapes[i][0] = try Polygon.init(alloc.*, points[0..pointCount]);
                    //     currentContour += 1;
                    //     pointCount = 0;
                    // }
                    currentContour += 1;
                    pointCount = 0;
                }
            }
        }
        // printData(Font, font, "FONT DATA");
        return font;
    }

    fn printData(comptime T: type, value: T, label: []const u8) void {
        std.debug.print("{s}\n", .{label});
        inline for (@typeInfo(T).@"struct".fields) |field| {
            std.debug.print("{s}: {any}\n", .{ field.name, @field(value, field.name) });
        }
    }

    fn swapEndianness(comptime T: type, value: T) T {
        var result: T = undefined;
        inline for (@typeInfo(T).@"struct".fields) |field| {
            @field(result, field.name) = std.mem.bigToNative(field.type, @field(value, field.name));
        }
        return result;
    }

    fn fromBigEndian(comptime T: type, bytes: []const u8) T {
        const raw: T = @bitCast(bytes[0..@sizeOf(T)].*);
        return swapEndianness(T, raw);
    }
};
