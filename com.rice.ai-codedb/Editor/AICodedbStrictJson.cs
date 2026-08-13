using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbStrictJson
    {
        internal static Dictionary<string, object> ReadObject(
            string path,
            long maximumBytes,
            string label)
        {
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
                throw new InvalidOperationException(label + " does not exist.");

            var file = new FileInfo(path);
            if (file.Length <= 0 || file.Length > maximumBytes || file.Length > int.MaxValue)
                throw new InvalidOperationException(label + " has an invalid size.");

            byte[] bytes;
            using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                if (stream.Length <= 0 || stream.Length > maximumBytes || stream.Length > int.MaxValue)
                    throw new InvalidOperationException(label + " changed to an invalid size while it was read.");

                bytes = new byte[(int)stream.Length];
                var offset = 0;
                while (offset < bytes.Length)
                {
                    var read = stream.Read(bytes, offset, bytes.Length - offset);
                    if (read <= 0)
                        throw new InvalidOperationException(label + " could not be read completely.");
                    offset += read;
                }
                if (stream.ReadByte() != -1)
                    throw new InvalidOperationException(label + " changed while it was read.");
            }

            if (bytes.Length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf)
                throw new InvalidOperationException(label + " must be UTF-8 without a byte-order mark.");

            string text;
            try
            {
                text = new UTF8Encoding(false, true).GetString(bytes);
            }
            catch (DecoderFallbackException exception)
            {
                throw new InvalidOperationException(label + " is not valid UTF-8.", exception);
            }
            return ParseObject(text, label);
        }

        internal static Dictionary<string, object> ParseObject(string text, string label)
        {
            var parser = new Parser(text ?? string.Empty, label ?? "JSON document");
            var value = parser.ParseDocument();
            var result = value as Dictionary<string, object>;
            if (result == null)
                throw new InvalidOperationException((label ?? "JSON document") + " must contain one JSON object.");
            return result;
        }

        internal static string GetRequiredString(Dictionary<string, object> value, string name, string label)
        {
            var property = GetRequiredProperty(value, name, label);
            var result = property as string;
            if (result == null)
                throw new InvalidOperationException(label + " property " + name + " must be a JSON string.");
            return result;
        }

        internal static int GetRequiredInt32(Dictionary<string, object> value, string name, string label)
        {
            var property = GetRequiredProperty(value, name, label);
            if (!(property is long) || (long)property < int.MinValue || (long)property > int.MaxValue)
                throw new InvalidOperationException(label + " property " + name + " must be a signed 32-bit JSON integer.");
            return (int)(long)property;
        }

        internal static long GetRequiredInt64(Dictionary<string, object> value, string name, string label)
        {
            var property = GetRequiredProperty(value, name, label);
            if (!(property is long))
                throw new InvalidOperationException(label + " property " + name + " must be a signed 64-bit JSON integer.");
            return (long)property;
        }

        internal static bool GetRequiredBoolean(Dictionary<string, object> value, string name, string label)
        {
            var property = GetRequiredProperty(value, name, label);
            if (!(property is bool))
                throw new InvalidOperationException(label + " property " + name + " must be a JSON boolean.");
            return (bool)property;
        }

        internal static List<object> GetRequiredArray(Dictionary<string, object> value, string name, string label)
        {
            var property = GetRequiredProperty(value, name, label);
            var result = property as List<object>;
            if (result == null)
                throw new InvalidOperationException(label + " property " + name + " must be a JSON array.");
            return result;
        }

        internal static Dictionary<string, object> RequireObject(object value, string label)
        {
            var result = value as Dictionary<string, object>;
            if (result == null)
                throw new InvalidOperationException(label + " must be a JSON object.");
            return result;
        }

        internal static string GetOptionalNullableString(
            Dictionary<string, object> value,
            string name,
            string label)
        {
            object property;
            if (!value.TryGetValue(name, out property) || property == null)
                return null;
            var result = property as string;
            if (result == null)
                throw new InvalidOperationException(label + " property " + name + " must be a JSON string or null.");
            return result;
        }

        internal static string GetRequiredNullableString(
            Dictionary<string, object> value,
            string name,
            string label)
        {
            var property = GetRequiredProperty(value, name, label);
            if (property == null)
                return null;
            var result = property as string;
            if (result == null)
                throw new InvalidOperationException(label + " property " + name + " must be a JSON string or null.");
            return result;
        }

        internal static string[] GetRequiredStringArray(
            Dictionary<string, object> value,
            string name,
            string label)
        {
            var values = GetRequiredArray(value, name, label);
            var result = new string[values.Count];
            for (var index = 0; index < values.Count; index++)
            {
                result[index] = values[index] as string;
                if (result[index] == null)
                {
                    throw new InvalidOperationException(
                        label + " property " + name + " must contain only JSON strings.");
                }
            }
            return result;
        }

        internal static int? GetOptionalNullableInt32(
            Dictionary<string, object> value,
            string name,
            string label)
        {
            object property;
            if (!value.TryGetValue(name, out property) || property == null)
                return null;
            if (!(property is long) || (long)property < int.MinValue || (long)property > int.MaxValue)
                throw new InvalidOperationException(label + " property " + name + " must be a signed 32-bit JSON integer or null.");
            return (int)(long)property;
        }

        internal static bool GetOptionalBoolean(
            Dictionary<string, object> value,
            string name,
            string label,
            bool defaultValue)
        {
            object property;
            if (!value.TryGetValue(name, out property))
                return defaultValue;
            if (!(property is bool))
                throw new InvalidOperationException(label + " property " + name + " must be a JSON boolean.");
            return (bool)property;
        }

        private static object GetRequiredProperty(Dictionary<string, object> value, string name, string label)
        {
            object property;
            if (value == null || !value.TryGetValue(name, out property))
                throw new InvalidOperationException(label + " is missing required property " + name + ".");
            return property;
        }

        private sealed class Parser
        {
            private readonly string _text;
            private readonly string _label;
            private int _index;
            private int _depth;

            internal Parser(string text, string label)
            {
                _text = text;
                _label = label;
            }

            internal object ParseDocument()
            {
                var value = ParseValue();
                SkipWhitespace();
                if (_index != _text.Length)
                    Fail("contains trailing content at character " + _index + ".");
                return value;
            }

            private object ParseValue()
            {
                SkipWhitespace();
                if (_index >= _text.Length)
                    Fail("contains an incomplete JSON value.");
                _depth++;
                if (_depth > 64)
                    Fail("exceeds the accepted nesting depth.");
                try
                {
                    var character = _text[_index];
                    if (character == '{')
                        return ParseObjectValue();
                    if (character == '[')
                        return ParseArray();
                    if (character == '"')
                        return ParseString();
                    if (character == 't')
                        return ParseLiteral("true", true);
                    if (character == 'f')
                        return ParseLiteral("false", false);
                    if (character == 'n')
                        return ParseLiteral("null", null);
                    return ParseNumber();
                }
                finally
                {
                    _depth--;
                }
            }

            private Dictionary<string, object> ParseObjectValue()
            {
                _index++;
                var result = new Dictionary<string, object>(StringComparer.Ordinal);
                var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                SkipWhitespace();
                if (Consume('}'))
                    return result;
                while (true)
                {
                    if (_index >= _text.Length || _text[_index] != '"')
                        Fail("expected a quoted JSON property name at character " + _index + ".");
                    var name = ParseString();
                    if (!names.Add(name))
                        Fail("contains a duplicate or case-ambiguous JSON property: " + name + ".");
                    SkipWhitespace();
                    if (!Consume(':'))
                        Fail("expected : after JSON property " + name + ".");
                    result.Add(name, ParseValue());
                    SkipWhitespace();
                    if (Consume('}'))
                        return result;
                    if (!Consume(','))
                        Fail("expected , between JSON object properties.");
                    SkipWhitespace();
                }
            }

            private List<object> ParseArray()
            {
                _index++;
                var result = new List<object>();
                SkipWhitespace();
                if (Consume(']'))
                    return result;
                while (true)
                {
                    result.Add(ParseValue());
                    SkipWhitespace();
                    if (Consume(']'))
                        return result;
                    if (!Consume(','))
                        Fail("expected , between JSON array values.");
                    SkipWhitespace();
                }
            }

            private string ParseString()
            {
                if (!Consume('"'))
                    Fail("expected a JSON string at character " + _index + ".");
                var result = new StringBuilder();
                while (_index < _text.Length)
                {
                    var character = _text[_index++];
                    if (character == '"')
                        return result.ToString();
                    if (character < 0x20)
                        Fail("contains an unescaped JSON control character.");
                    if (character == '\\')
                    {
                        AppendEscape(result);
                        continue;
                    }
                    if (char.IsHighSurrogate(character))
                    {
                        if (_index >= _text.Length || !char.IsLowSurrogate(_text[_index]))
                            Fail("contains an unpaired high surrogate.");
                        result.Append(character);
                        result.Append(_text[_index++]);
                        continue;
                    }
                    if (char.IsLowSurrogate(character))
                        Fail("contains an unpaired low surrogate.");
                    result.Append(character);
                }
                Fail("contains an unclosed JSON string.");
                return null;
            }

            private void AppendEscape(StringBuilder result)
            {
                if (_index >= _text.Length)
                    Fail("contains an incomplete JSON escape.");
                var escape = _text[_index++];
                switch (escape)
                {
                    case '"': result.Append('"'); return;
                    case '\\': result.Append('\\'); return;
                    case '/': result.Append('/'); return;
                    case 'b': result.Append('\b'); return;
                    case 'f': result.Append('\f'); return;
                    case 'n': result.Append('\n'); return;
                    case 'r': result.Append('\r'); return;
                    case 't': result.Append('\t'); return;
                    case 'u':
                        var high = ReadHexCodeUnit();
                        if (high >= 0xd800 && high <= 0xdbff)
                        {
                            if (_index + 2 > _text.Length || _text[_index] != '\\' || _text[_index + 1] != 'u')
                                Fail("contains an unpaired high-surrogate JSON escape.");
                            _index += 2;
                            var low = ReadHexCodeUnit();
                            if (low < 0xdc00 || low > 0xdfff)
                                Fail("contains an unpaired high-surrogate JSON escape.");
                            result.Append((char)high);
                            result.Append((char)low);
                            return;
                        }
                        if (high >= 0xdc00 && high <= 0xdfff)
                            Fail("contains an unpaired low-surrogate JSON escape.");
                        result.Append((char)high);
                        return;
                    default:
                        Fail("contains an unsupported JSON escape.");
                        return;
                }
            }

            private int ReadHexCodeUnit()
            {
                if (_index + 4 > _text.Length)
                    Fail("contains an incomplete JSON Unicode escape.");
                var value = 0;
                for (var offset = 0; offset < 4; offset++)
                {
                    var digit = HexValue(_text[_index + offset]);
                    if (digit < 0)
                        Fail("contains an invalid JSON Unicode escape.");
                    value = (value << 4) | digit;
                }
                _index += 4;
                return value;
            }

            private object ParseNumber()
            {
                var start = _index;
                if (Consume('-') && _index >= _text.Length)
                    Fail("contains an incomplete JSON number.");
                if (Consume('0'))
                {
                    if (_index < _text.Length && IsDigit(_text[_index]))
                        Fail("contains a JSON number with a leading zero.");
                }
                else
                {
                    if (_index >= _text.Length || _text[_index] < '1' || _text[_index] > '9')
                        Fail("contains an unsupported JSON token at character " + start + ".");
                    while (_index < _text.Length && IsDigit(_text[_index]))
                        _index++;
                }

                var isInteger = true;
                if (Consume('.'))
                {
                    isInteger = false;
                    if (_index >= _text.Length || !IsDigit(_text[_index]))
                        Fail("contains an incomplete JSON fraction.");
                    while (_index < _text.Length && IsDigit(_text[_index]))
                        _index++;
                }
                if (_index < _text.Length && (_text[_index] == 'e' || _text[_index] == 'E'))
                {
                    isInteger = false;
                    _index++;
                    if (_index < _text.Length && (_text[_index] == '+' || _text[_index] == '-'))
                        _index++;
                    if (_index >= _text.Length || !IsDigit(_text[_index]))
                        Fail("contains an incomplete JSON exponent.");
                    while (_index < _text.Length && IsDigit(_text[_index]))
                        _index++;
                }

                var text = _text.Substring(start, _index - start);
                if (isInteger)
                {
                    long integer;
                    if (!long.TryParse(text, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out integer))
                        Fail("contains a JSON integer outside the signed 64-bit range.");
                    return integer;
                }

                double number;
                if (!double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out number)
                    || double.IsNaN(number)
                    || double.IsInfinity(number))
                    Fail("contains a non-finite or out-of-range JSON number.");
                return number;
            }

            private object ParseLiteral(string literal, object value)
            {
                if (_index + literal.Length > _text.Length
                    || !string.Equals(_text.Substring(_index, literal.Length), literal, StringComparison.Ordinal))
                    Fail("contains an unsupported JSON token at character " + _index + ".");
                _index += literal.Length;
                return value;
            }

            private void SkipWhitespace()
            {
                while (_index < _text.Length)
                {
                    var character = _text[_index];
                    if (character != ' ' && character != '\t' && character != '\r' && character != '\n')
                        return;
                    _index++;
                }
            }

            private bool Consume(char expected)
            {
                if (_index >= _text.Length || _text[_index] != expected)
                    return false;
                _index++;
                return true;
            }

            private static bool IsDigit(char value)
            {
                return value >= '0' && value <= '9';
            }

            private static int HexValue(char value)
            {
                if (value >= '0' && value <= '9') return value - '0';
                if (value >= 'a' && value <= 'f') return value - 'a' + 10;
                if (value >= 'A' && value <= 'F') return value - 'A' + 10;
                return -1;
            }

            private void Fail(string detail)
            {
                throw new InvalidOperationException(_label + " " + detail);
            }
        }
    }
}
