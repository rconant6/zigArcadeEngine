const std = @import("std");

pub const FontReader = struct {
    data: []const u8,
    pos: usize = 0,

    pub fn readStruct(self: *FontReader, comptime T: type) T {
        const size = @sizeOf(T);
        if (self.pos + size > self.data.len) @panic("Read past end of data");

        const result = fromBigEndian(T, self.data[self.pos .. self.pos + size]);
        self.pos += size;

        return result;
    }

    pub fn readU8(self: *FontReader) u8 {
        if (self.pos + 1 > self.data.len) @panic("Read past end of data");

        const result = self.data[self.pos];
        self.pos += 1;

        return result;
    }
    pub fn readU16BigEndian(self: *FontReader) u16 {
        if (self.pos + 2 > self.data.len) @panic("Read past end of data");

        const bytes = self.data[self.pos .. self.pos + 2];
        const result = std.mem.bigToNative(u16, @bitCast(bytes[0..2].*));

        self.pos += 2;

        return result;
    }

    pub fn readU32BigEndian(self: *FontReader) u32 {
        if (self.pos + 4 > self.data.len) @panic("Read past end of data");

        const bytes = self.data[self.pos .. self.pos + 4];
        const result = std.mem.bigToNative(u32, @bitCast(bytes[0..4].*));

        self.pos += 4;

        return result;
    }

    pub fn readI16BigEndian(self: *FontReader) i16 {
        if (self.pos + 2 > self.data.len) @panic("Read past end of data");

        const bytes = self.data[self.pos .. self.pos + 2];
        const result = std.mem.bigToNative(i16, @bitCast(bytes[0..2].*));

        self.pos += 2;

        return result;
    }

    pub fn readI32BigEndian(self: *FontReader) i32 {
        if (self.pos + 4 > self.data.len) @panic("Read past end of data");

        const bytes = self.data[self.pos .. self.pos + 4];
        const result = std.mem.bigToNative(i32, @bitCast(bytes[0..4].*));

        self.pos += 4;

        return result;
    }

    pub fn readU64BigEndian(self: *FontReader) u64 {
        if (self.pos + 8 > self.data.len) @panic("Read past end of data");

        const bytes = self.data[self.pos .. self.pos + 8];
        const result = std.mem.bigToNative(u64, @bitCast(bytes[0..8].*));

        self.pos += 8;

        return result;
    }

    pub fn seek(self: *FontReader, offset: usize) void {
        if (offset > self.data.len) @panic("Read past end of data");
        self.pos = offset;
    }

    pub fn rewind(self: *FontReader, negOffset: usize) void {
        self.pos -= negOffset;
    }

    pub fn skip(self: *FontReader, bytes: usize) void {
        if (self.pos + bytes > self.data.len) @panic("Read past end of data");
        self.pos += bytes;

        return;
    }

    pub fn remaining(self: *const FontReader) usize {
        return self.data.len - self.pos;
    }

    pub fn calculateChecksum(
        self: *FontReader,
        offset: usize,
        length: usize,
        isHead: bool,
    ) u32 {
        const oldLoc = self.pos;

        var sum: u32 = 0;
        var pos: u32 = 0;

        self.seek(offset);
        if (self.pos + length > self.data.len) @panic("Read past end of data");

        while (pos + 4 <= length) {
            var value = self.readU32BigEndian();
            if (pos == 8 and isHead) value = 0;
            sum = sum +% value;
            pos += 4;
        }

        if (pos < length) {
            var finalBytes: [4]u8 = .{ 0, 0, 0, 0 };
            var i: u32 = 0;
            while (pos + i < length) {
                finalBytes[i] = self.data[self.pos + i];
                i += 1;
            }
            const finalValue = std.mem.bigToNative(u32, @bitCast(finalBytes));
            sum = sum +% finalValue;
        }

        self.pos = oldLoc;

        return sum;
    }
};

fn swapEndianness(comptime T: type, value: T) T {
    var result: T = undefined;
    inline for (@typeInfo(T).@"struct".fields) |field| {
        @field(result, field.name) = std.mem.bigToNative(
            field.type,
            @field(value, field.name),
        );
    }

    return result;
}

fn fromBigEndian(comptime T: type, bytes: []const u8) T {
    const raw: T = @bitCast(bytes[0..@sizeOf(T)].*);
    return swapEndianness(T, raw);
}
