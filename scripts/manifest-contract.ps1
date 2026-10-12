# A syntax scanner preserves top-level tokens and ordinal keys on PS 5.1 / 7.
# Unknown nested objects are validated without imposing top-level uniqueness.
if (-not ('EllenJsonScanner' -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
public sealed class EllenJsonScanner {
    readonly string text; int pos; int depth;
    EllenJsonScanner(string value) { text = value.TrimStart('\uFEFF'); }
    void White() { while(pos < text.Length && " \t\r\n".IndexOf(text[pos]) >= 0) pos++; }
    void Need(char c) { White(); if(pos >= text.Length || text[pos++] != c) throw new FormatException("Invalid JSON punctuation"); }
    bool Take(char c) { White(); if(pos < text.Length && text[pos] == c) { pos++; return true; } return false; }
    string String() {
        Need('"'); var result = new StringBuilder();
        while(pos < text.Length) {
            char c = text[pos++];
            if(c == '"') return result.ToString();
            if(c < 32) throw new FormatException("Invalid JSON string");
            if(c != '\\') { result.Append(c); continue; }
            if(pos >= text.Length) break;
            c = text[pos++];
            switch(c) {
                case '"': case '\\': case '/': result.Append(c); break;
                case 'b': result.Append('\b'); break; case 'f': result.Append('\f'); break;
                case 'n': result.Append('\n'); break; case 'r': result.Append('\r'); break;
                case 't': result.Append('\t'); break;
                case 'u':
                    if(pos+4 > text.Length || !Regex.IsMatch(text.Substring(pos,4), "\\A[0-9A-Fa-f]{4}\\z")) throw new FormatException("Invalid Unicode escape");
                    result.Append((char)Convert.ToInt32(text.Substring(pos,4),16)); pos+=4; break;
                default: throw new FormatException("Invalid JSON escape");
            }
        }
        throw new FormatException("Unterminated JSON string");
    }
    void Value() {
        White(); if(pos >= text.Length || ++depth > 128) throw new FormatException("Invalid JSON depth/value");
        char c = text[pos];
        if(c == '"') String();
        else if(c == '{') Object(false);
        else if(c == '[') { pos++; if(!Take(']')) { do { Value(); } while(Take(',')); Need(']'); } }
        else {
            var m = Regex.Match(text.Substring(pos), "\\A(?:true|false|null|-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)");
            if(!m.Success) throw new FormatException("Invalid JSON value"); pos += m.Length;
        }
        depth--;
    }
    Dictionary<string,string> Object(bool top) {
        Need('{'); var result = new Dictionary<string,string>(StringComparer.Ordinal);
        if(Take('}')) return result;
        do {
            string key = String(); Need(':'); White(); int start=pos; Value();
            if(top && result.ContainsKey(key)) throw new FormatException("Duplicate top-level key");
            result[key]=text.Substring(start,pos-start);
        } while(Take(','));
        Need('}'); return result;
    }
    public static Dictionary<string,string> Parse(string text) {
        var s = new EllenJsonScanner(text); var value = s.Object(true); s.White();
        if(s.pos != s.text.Length) throw new FormatException("Trailing JSON data"); return value;
    }
    public static string DecodeString(string text) {
        var s=new EllenJsonScanner(text); string value=s.String(); s.White();
        if(s.pos != s.text.Length) throw new FormatException("Expected JSON string"); return value;
    }
}
"@
}
function Read-ApprovedPetHash([string]$ManifestPath, [string]$AssetLockPath) {
    $encoding = New-Object Text.UTF8Encoding($false, $true)
    $manifest = [EllenJsonScanner]::Parse([IO.File]::ReadAllText($ManifestPath, $encoding))
    foreach ($pair in @(@('id','ellen-joe-pixel'), @('displayName','Ellen Joe Pixel'), @('spritesheetPath','spritesheet.webp'))) {
        if (-not $manifest.ContainsKey($pair[0]) -or -not [StringComparer]::Ordinal.Equals([EllenJsonScanner]::DecodeString($manifest[$pair[0]]), $pair[1])) { throw ('Invalid manifest ' + $pair[0]) }
    }
    if (-not $manifest.ContainsKey('spriteVersionNumber') -or $manifest['spriteVersionNumber'] -cne '2') { throw 'spriteVersionNumber must be integer 2' }
    if (-not $manifest.ContainsKey('description') -or [string]::IsNullOrWhiteSpace([EllenJsonScanner]::DecodeString($manifest['description']))) { throw 'Invalid description' }
    $lock = [EllenJsonScanner]::Parse([IO.File]::ReadAllText($AssetLockPath, $encoding))
    if ($lock.Count -ne 3 -or -not $lock.ContainsKey('schemaVersion') -or -not $lock.ContainsKey('petId') -or -not $lock.ContainsKey('spritesheetSha256')) { throw 'Invalid asset lock fields' }
    if ($lock['schemaVersion'] -cne '1' -or [EllenJsonScanner]::DecodeString($lock['petId']) -cne 'ellen-joe-pixel') { throw 'Invalid asset lock identity/version' }
    $hash = [EllenJsonScanner]::DecodeString($lock['spritesheetSha256'])
    if ($hash -cnotmatch '\A[0-9a-f]{64}\z') { throw 'Invalid spritesheetSha256' }
    return $hash
}
