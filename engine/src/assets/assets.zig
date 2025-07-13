const fData = @import("fontData.zig");
pub const FontDirHeader = fData.FontDirHeader;
pub const TableEntry = fData.TableEntry;
pub const HeadTable = fData.HeadTable;
pub const CmapHeader = fData.CmapHeader;
pub const CmapEncoding = fData.CmapEncoding;
pub const CmapFormat4Header = fData.CmapFormat4Header;
pub const HheaTable = fData.HheaTable;
pub const Hmetric = fData.Hmetric;
pub const GlyfHeader = fData.GlyfHeader;
pub const GlyphFlag = fData.GlyphFlag;
pub const MaxPTable = fData.MaxPTable;
pub const FilteredGlyph = fData.FilteredGlyph;

pub const FontReader = @import("fontReader.zig").FontReader;

pub const V2 = @import("math").V2;

pub const AssetManager = @import("assetManager.zig").AssetManager;

pub const Font = @import("font.zig").Font;
