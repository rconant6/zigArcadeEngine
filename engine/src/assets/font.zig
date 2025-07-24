const std = @import("std");
const asset = @import("assets.zig");
const CmapEncoding = asset.CmapEncoding;
const CmapFormat4Header = asset.CmapFormat4Header;
const CmapHeader = asset.CmapHeader;
const FilteredGlyph = asset.FilteredGlyph;
const FontDirHeader = asset.FontDirHeader;
const FontReader = asset.FontReader;
const GlyfHeader = asset.GlyfHeader;
const GlyphFlag = asset.GlyphFlag;
const HeadTable = asset.HeadTable;
const HheaTable = asset.HheaTable;
const Hmetric = asset.Hmetric;
const MaxPTable = asset.MaxPTable;
const TableEntry = asset.TableEntry;
const V2 = asset.V2;

fn loadFile(alloc: std.mem.Allocator, path: []const u8) ![]const u8 {
    var pathBuffer: [std.fs.max_path_bytes]u8 = undefined;
    var exeBuffer: [std.fs.max_path_bytes]u8 = undefined;

    const cwd = try std.process.getCwd(&exeBuffer);
    const joinedPath = try std.fmt.bufPrint(&pathBuffer, "{s}/zig-out/bin/{s}", .{ cwd, path });

    const file = try std.fs.openFileAbsolute(joinedPath, .{});
    defer file.close();

    const fileSize = try file.getEndPos();
    const rawData = try alloc.alloc(u8, fileSize);
    const dataRead = try file.readAll(rawData);
    std.debug.assert(dataRead == fileSize);

    return rawData;
}

fn parseFontDir(reader: *FontReader) !FontDirHeader {
    const header = reader.readStruct(FontDirHeader);
    reader.rewind(getBytesOfPadding(FontDirHeader));
    return header;
}

fn parseTableEntry(reader: *FontReader) !TableEntry {
    const tableEntry = reader.readStruct(TableEntry);
    reader.rewind(getBytesOfPadding(TableEntry));
    return tableEntry;
}

fn parseLocaTable(reader: *FontReader, alloc: *std.mem.Allocator, entry: TableEntry, numGlyphs: u16) ![]u32 {
    reader.seek(entry.offset);

    const actualChecksum = reader.calculateChecksum(entry.offset, entry.length, false);
    if (actualChecksum != entry.checksum) return error.LocaTableCorrupted;

    var offsets = try alloc.alloc(u32, numGlyphs + 1);
    for (0..numGlyphs + 1) |i| {
        const shortOffset = reader.readU16BigEndian();
        offsets[i] = @as(u32, shortOffset) * 2; // Convert to actual byte offset
    }

    return offsets;
}

fn parseHeadTable(reader: *FontReader, entry: TableEntry) !HeadTable {
    reader.seek(entry.offset);

    std.debug.assert(entry.offset + entry.length <= reader.remaining());

    const headTable = reader.readStruct(HeadTable);

    const actualChecksum = reader.calculateChecksum(entry.offset, entry.length, true);
    if (actualChecksum != entry.checksum) return error.HeadTableCorrupted;
    if (headTable.magicNumber != 0x5f0f3cf5) return error.InvalidTTFMagicNumber;

    reader.rewind(getBytesOfPadding(HeadTable));

    return headTable;
}

fn parseHheaTable(reader: *FontReader, entry: TableEntry) !HheaTable {
    reader.seek(entry.offset);

    std.debug.assert(entry.offset + entry.length <= reader.remaining());

    const hheaTable = reader.readStruct(HheaTable);

    const actualChecksum = reader.calculateChecksum(entry.offset, entry.length, false);
    if (actualChecksum != entry.checksum) return error.HheaTableCorrupted;

    reader.rewind(getBytesOfPadding(HheaTable));

    return hheaTable;
}

fn parseHmetrics(
    reader: *FontReader,
    metrics: *std.ArrayList(Hmetric),
    entry: TableEntry,
    numberOfGlyphs: u16,
    numberOfHMetrics: u16,
) !void {
    reader.seek(entry.offset);

    std.debug.assert(entry.offset + entry.length <= reader.remaining());

    const actualChecksum = reader.calculateChecksum(entry.offset, entry.length, false);
    if (actualChecksum != entry.checksum) return error.HmtxTableCorrupted;

    for (0..numberOfHMetrics) |_| {
        const hMetric = reader.readStruct(Hmetric);
        reader.rewind(getBytesOfPadding(Hmetric));
        metrics.appendAssumeCapacity(hMetric);
    }

    const remainingGlyphs = numberOfGlyphs - numberOfHMetrics;
    for (0..remainingGlyphs) |_| {
        const lsb = reader.readI16BigEndian();
        metrics.appendAssumeCapacity(Hmetric{
            .advanceWidth = metrics.items[numberOfHMetrics - 1].advanceWidth,
            .lsb = lsb,
        });
    }
}

fn parseMaxpTable(reader: *FontReader, entry: TableEntry) !MaxPTable {
    reader.seek(entry.offset);

    std.debug.assert(entry.offset + entry.length <= reader.remaining());

    const actualChecksum = reader.calculateChecksum(entry.offset, entry.length, false);
    if (actualChecksum != entry.checksum) return error.MaxPTableCorrupted;

    const maxpTable = reader.readStruct(MaxPTable);
    reader.rewind(getBytesOfPadding(MaxPTable));

    return maxpTable;
}

fn parseCmapTable(reader: *FontReader, entry: TableEntry) !CmapFormat4Header {
    reader.seek(entry.offset);

    std.debug.assert(entry.offset + entry.length <= reader.remaining());

    const actualChecksum = reader.calculateChecksum(entry.offset, entry.length, false);
    if (actualChecksum != entry.checksum) return error.CmapTableCorrupted;

    const cmapHeader = reader.readStruct(CmapHeader);
    reader.rewind(getBytesOfPadding(CmapHeader));

    const cmapEncoding = find_encoding: {
        var fallback: ?CmapEncoding = null;
        for (0..cmapHeader.numTables) |_| {
            const encoding = reader.readStruct(CmapEncoding);
            reader.rewind(getBytesOfPadding(CmapEncoding));
            if (encoding.platformID == 3 and encoding.encodingID == 1) {
                break :find_encoding encoding; // Prefer this
            }
            if (encoding.platformID == 0 and encoding.encodingID == 3) {
                fallback = encoding; // But accept this
            }
        }
        break :find_encoding fallback orelse return error.NoValidCmapEncoding;
    };

    reader.seek(entry.offset + cmapEncoding.offset);

    const cmapFormat4Header = reader.readStruct(CmapFormat4Header);
    reader.rewind(getBytesOfPadding(CmapFormat4Header));

    return cmapFormat4Header;
}

fn parseCmapFormatData(
    reader: *FontReader,
    map: *std.AutoHashMap(u32, u16),
    alloc: std.mem.Allocator,
    header: CmapFormat4Header,
) !void {
    const numSegments: u16 = header.segCountx2 / 2;

    var endCounts = try alloc.alloc(u16, numSegments);
    var startCounts = try alloc.alloc(u16, numSegments);
    var idDeltas = try alloc.alloc(u16, numSegments);
    var idRangeOffsets = try alloc.alloc(u16, numSegments);
    for (0..numSegments) |segment| {
        endCounts[segment] = reader.readU16BigEndian();
    }
    const pad = reader.readU16BigEndian();
    std.debug.assert(pad == 0);
    for (0..numSegments) |segment| {
        startCounts[segment] = reader.readU16BigEndian();
    }
    for (0..numSegments) |segment| {
        idDeltas[segment] = reader.readU16BigEndian();
    }
    for (0..numSegments) |segment| {
        idRangeOffsets[segment] = reader.readU16BigEndian();
    }

    const glyphArraySize = header.length - (14 + numSegments * 2 * 4 + 2); // header, data, pad
    const glyphs = glyphArraySize / 2;
    var glyphIdArray = try alloc.alloc(u16, glyphs);
    for (0..glyphs) |glyphId| {
        glyphIdArray[glyphId] = reader.readU16BigEndian();
    }

    for (0..0x10000) |char| {
        var segment: usize = 0;
        while (segment < numSegments) : (segment += 1) {
            const start = startCounts[segment];
            const end = endCounts[segment];
            if (start <= char and char <= end) break;
        }

        if (segment >= numSegments) {
            continue;
        }

        var glyphIndex: u16 = 0;
        if (idRangeOffsets[segment] == 0) {
            glyphIndex = @as(u16, @intCast(char)) +% idDeltas[segment];
        } else {
            const arrayIndex = (idRangeOffsets[segment] / 2) + (char - startCounts[segment]) - (numSegments - segment);

            if (arrayIndex < glyphIdArray.len) {
                const glyphId = glyphIdArray[arrayIndex];
                glyphIndex = glyphId +% idDeltas[segment];
            }
        }

        try map.put(@as(u32, @intCast(char)), glyphIndex);
    }
}

fn parseGlyph(
    reader: *FontReader,
    alloc: std.mem.Allocator, // main engine allocator
    talloc: std.mem.Allocator, // temp arena
    header: GlyfHeader,
    unitsPerEm: u16,
) !FilteredGlyph {
    const numberOfContours: u16 = if (header.numberOfContours < 0) 0 else @intCast(header.numberOfContours);
    if (header.numberOfContours > 0) {
        var contourEndPts = try talloc.alloc(u16, numberOfContours);
        for (0..numberOfContours) |i| {
            contourEndPts[i] = reader.readU16BigEndian();
        }

        const totalPoints = contourEndPts[numberOfContours - 1] + 1;

        const instLen = reader.readU16BigEndian();
        reader.skip(instLen);

        var flags = try talloc.alloc(GlyphFlag, totalPoints);
        var flagIndex: usize = 0;

        while (flagIndex < totalPoints) {
            const rawFlag = reader.readU8();
            const flag: GlyphFlag = @bitCast(rawFlag);
            flags[flagIndex] = flag;
            flagIndex += 1;

            if (flag.repeat != 0) {
                const repeatCount = reader.readU8();
                for (0..repeatCount) |_| {
                    if (flagIndex >= totalPoints) break;
                    flags[flagIndex] = flag;
                    flagIndex += 1;
                }
            }
        }

        var xCoords = try talloc.alloc(i32, totalPoints);
        var yCoords = try talloc.alloc(i32, totalPoints);

        // Parse X coordinates
        for (0..totalPoints) |i| {
            if (flags[i].xShort == 1) {
                const delta = reader.readU8();
                xCoords[i] = if (flags[i].xSameOrPos == 1) @as(i32, delta) else -@as(i32, delta);
            } else if (flags[i].xSameOrPos == 1) {
                xCoords[i] = 0; // Same as previous
            } else {
                xCoords[i] = reader.readI16BigEndian();
            }
        }

        // Parse Y coordinates
        for (0..totalPoints) |i| {
            if (flags[i].yShort == 1) {
                const delta = reader.readU8();
                yCoords[i] = if (flags[i].ySameOrPos == 1) @as(i32, delta) else -@as(i32, delta);
            } else if (flags[i].ySameOrPos == 1) {
                yCoords[i] = 0; // Same as previous
            } else {
                yCoords[i] = reader.readI16BigEndian();
            }
        }

        var absX: i32 = 0;
        var absY: i32 = 0;
        var filteredContourEndPts = try std.ArrayList(u16).initCapacity(alloc, contourEndPts.len);
        errdefer filteredContourEndPts.deinit();
        var filteredPoints = try std.ArrayList(V2).initCapacity(alloc, totalPoints);
        errdefer filteredPoints.deinit();
        var filteredPointCount: u16 = 0;
        var filteredIndex: usize = 0;
        for (0..totalPoints) |i| {
            absX += xCoords[i];
            absY += yCoords[i];

            if (flags[i].onCurve == 1) {
                const fx: f32 = @as(f32, @floatFromInt(absX));
                const fy: f32 = @as(f32, @floatFromInt(absY));
                const fEm: f32 = @as(f32, @floatFromInt(unitsPerEm));

                const gameX = (fx / fEm) * 20.0 - 10.0;
                const gameY = (fy / fEm) * 20.0 - 10.0;

                filteredPoints.appendAssumeCapacity(V2{ .x = gameX, .y = gameY });
                filteredPointCount += 1;
                filteredIndex += 1;
            }

            for (contourEndPts) |endPt| {
                if (i == endPt) {
                    _ = filteredContourEndPts.pop();
                    filteredContourEndPts.appendAssumeCapacity(filteredPointCount - 1);
                }
            }
        }

        return FilteredGlyph{
            .points = try filteredPoints.toOwnedSlice(),
            .contourEnds = try filteredContourEndPts.toOwnedSlice(),
            .contourCount = numberOfContours,
            .totalPoints = filteredPointCount,
        };
    }
    return FilteredGlyph{};
}

pub const Font = struct {
    alloc: std.mem.Allocator,
    unitsPerEm: u16 = undefined, // from head

    // from hhea table
    ascender: i16 = undefined,
    descender: i16 = undefined,
    lineGap: i16 = undefined,

    charToGlyph: std.AutoHashMap(u32, u16) = undefined, // from cmap
    glyphAdvanceWidths: std.ArrayList(Hmetric) = undefined, // horizontal spacing data
    glyphShapes: std.AutoHashMap(u16, FilteredGlyph) = undefined, // data for shapes of glyphs

    pub fn init(alloc: std.mem.Allocator, path: []const u8) !Font {
        var arena = std.heap.ArenaAllocator.init(alloc);
        defer arena.deinit();

        var tempAlloc = arena.allocator();
        var tableDirectory = std.AutoArrayHashMap(u32, TableEntry).init(tempAlloc);

        const rawData = try loadFile(tempAlloc, path);

        var reader = FontReader{ .data = rawData };

        const fontDirHeader = try parseFontDir(&reader);
        const numberOfTables = fontDirHeader.numTables;
        for (0..numberOfTables) |_| {
            const tableEntry = try parseTableEntry(&reader);
            try tableDirectory.put(tableEntry.tag, tableEntry);
        }

        const headEntry = getTable(&tableDirectory, "head") orelse return error.HeadTableNotFound;
        const headTable = try parseHeadTable(&reader, headEntry);
        const indexToLoc = headTable.indexToLocFormat;
        const unitsPerEm = headTable.unitsPerEm;
        _ = indexToLoc;

        const maxpEntry = getTable(&tableDirectory, "maxp") orelse return error.MaxpTableNotFound;
        const maxpTable = try parseMaxpTable(&reader, maxpEntry);
        const numberOfGlyphs = maxpTable.numGlyphs;

        const hheaEntry = getTable(&tableDirectory, "hhea") orelse return error.HheaTableNotFound;
        const hheaTable = try parseHheaTable(&reader, hheaEntry);
        const numberOfHMetrics = hheaTable.numberOfHMetrics;

        const hmtxEntry = getTable(&tableDirectory, "hmtx") orelse return error.HmtxTableNotFound;
        var hMetrics = try std.ArrayList(Hmetric).initCapacity(alloc, numberOfGlyphs);
        errdefer hMetrics.deinit();
        try parseHmetrics(&reader, &hMetrics, hmtxEntry, numberOfGlyphs, numberOfHMetrics);

        const cmapEntry = getTable(&tableDirectory, "cmap") orelse return error.CmapTableNotFound;
        const cmapFormat4Header = try parseCmapTable(&reader, cmapEntry);
        var mapIndices = std.AutoHashMap(u32, u16).init(alloc);
        errdefer mapIndices.deinit();
        try parseCmapFormatData(&reader, &mapIndices, tempAlloc, cmapFormat4Header);

        const glyfEntry = getTable(&tableDirectory, "glyf") orelse return error.GlyfTableNotFound;

        const locaEntry = getTable(&tableDirectory, "loca") orelse return error.LocaTableNotFound;
        const offsets = try parseLocaTable(&reader, &tempAlloc, locaEntry, numberOfGlyphs);

        var glyphs = std.AutoHashMap(u16, FilteredGlyph).init(alloc);
        errdefer glyphs.deinit();
        for (0..numberOfGlyphs) |glyphIndex| {
            const start = offsets[glyphIndex];
            const end = offsets[glyphIndex + 1];
            if (start == end) continue; // Skip empty glyphs

            reader.seek(glyfEntry.offset + start);
            const header = reader.readStruct(GlyfHeader);
            reader.rewind(getBytesOfPadding(GlyfHeader));

            const glyphData = try parseGlyph(&reader, alloc, tempAlloc, header, unitsPerEm);
            try glyphs.put(@intCast(glyphIndex), glyphData);
        }

        return Font{
            .alloc = alloc,
            .unitsPerEm = unitsPerEm,
            .ascender = hheaTable.ascender,
            .descender = hheaTable.descender,
            .lineGap = hheaTable.lineGap,
            .charToGlyph = mapIndices,
            .glyphAdvanceWidths = hMetrics,
            .glyphShapes = glyphs,
        };
    }

    pub fn deinit(self: *Font) void {
        self.glyphAdvanceWidths.deinit();
        self.charToGlyph.deinit();
        var iter = self.glyphShapes.iterator();
        while (iter.next()) |entry| {
            const glyph = entry.value_ptr.*;
            self.alloc.free(glyph.points);
            self.alloc.free(glyph.contourEnds);
        }
        self.glyphShapes.deinit();
    }
};

// MARK: Helpers
fn getBytesOfPadding(comptime T: type) usize {
    return switch (T) {
        HheaTable => 96 / 8,
        CmapFormat4Header => 16 / 8,
        HeadTable => 80 / 8,
        FontDirHeader => 32 / 8,
        GlyfHeader => 48 / 8,
        else => 0,
    };
}

fn getTable(tables: *const std.AutoArrayHashMap(u32, TableEntry), name: []const u8) ?TableEntry {
    const tag = std.mem.readInt(u32, name[0..4], .big);
    return tables.get(tag);
}

fn printData(comptime T: type, value: T, label: []const u8) void {
    std.debug.print("{s}\n", .{label});
    inline for (@typeInfo(T).@"struct".fields) |field| {
        std.debug.print("{s}: {any}\n", .{ field.name, @field(value, field.name) });
    }
}
