using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace Rice.AI.Codedb.Editor
{
    // Diagnostic data only. No Unity API, product commands or readiness authority.
    internal sealed class AICodedbManagerTransitionEvidence
    {
        internal const int MaximumRecords = 64;
        internal const int MaximumBytes = 128 * 1024;
        private readonly object _gate = new object();
        private readonly string _root;
        private readonly Action<string, string> _publish;
        private readonly List<Dictionary<string, string>> _records = new List<Dictionary<string, string>>();
        private readonly Dictionary<string, string> _keys = new Dictionary<string, string>();
        private readonly string _session = Guid.NewGuid().ToString("N");
        private int _reservedBytes = 4096;
        private bool _writing;
        private bool _pending;
        private bool _stopped;
        private string _disposition = "COMPLETE_WITHIN_SCOPE";

        internal AICodedbManagerTransitionEvidence(string projectRoot, Action<string, string> publish = null)
        {
            _root = projectRoot;
            _publish = publish ?? PublishAtomic;
        }

        internal string Disposition { get { lock (_gate) return _disposition; } }
        internal bool IsWriting { get { lock (_gate) return _writing; } }
        internal int Count { get { lock (_gate) return _records.Count; } }

        internal static string SemanticKey(string headerKind, string severity, bool actionOverride, string activityKind)
        {
            return headerKind + "|" + severity + "|" + actionOverride + "|" + activityKind;
        }

        // Called only with in-memory, bounded enum/identity data. No serialization or IO.
        internal void Capture(string window, string semanticKey, Dictionary<string, string> fields)
        {
            lock (_gate)
            {
                if (_stopped || (_keys.TryGetValue(window, out var previous) && previous == semanticKey))
                    return;
                if (string.IsNullOrWhiteSpace(_root))
                {
                    _disposition = "INCOMPLETE_MISSING_PROJECT_CONTEXT";
                    _stopped = true;
                    return;
                }
                var record = new Dictionary<string, string>();
                foreach (var pair in fields)
                    record.Add(Limit(pair.Key), Limit(pair.Value));
                record["window"] = Limit(window);
                record["previous_presentation"] = previous;
                record["presentation"] = Limit(semanticKey);
                record["event"] = previous == null ? "BASELINE" : "TRANSITION";
                record["sequence"] = (_records.Count + 1).ToString(CultureInfo.InvariantCulture);
                // Worst-case JSON escaping is six ASCII bytes per UTF-16 code unit.
                // Reserve before admission so every admitted record fits the output cap.
                var reservation = 8;
                foreach (var pair in record)
                    reservation += 8 + 6 * (pair.Key.Length + (pair.Value == null ? 4 : pair.Value.Length));
                if (_records.Count >= MaximumRecords || _reservedBytes + reservation > MaximumBytes)
                {
                    _disposition = "INCOMPLETE_CAP_REACHED";
                    _stopped = true;
                }
                else
                {
                    _records.Add(record);
                    _keys[window] = Limit(semanticKey);
                    _reservedBytes += reservation;
                }
                _pending = true;
                if (_writing) return;
                _writing = true;
                Task.Run((Action)Drain);
            }
        }

        private static string Limit(string value)
        {
            return value == null || value.Length <= 160 ? value : value.Substring(0, 160);
        }

        private void Drain()
        {
            try
            {
                while (true)
                {
                    Dictionary<string, string>[] records;
                    string disposition;
                    lock (_gate)
                    {
                        if (!_pending) { _writing = false; return; }
                        _pending = false;
                        records = _records.ToArray();
                        disposition = _disposition;
                    }
                    var json = Serialize(records, disposition);
                    if (Encoding.UTF8.GetByteCount(json) > MaximumBytes)
                        throw new InvalidOperationException("Diagnostic output bound exceeded.");
                    var path = Path.Combine(_root, "Library", "CodeDB", "Diagnostics",
                        "manager-ui-transition-" + _session + ".json");
                    _publish(path, json);
                }
            }
            catch (Exception)
            {
                // Filesystem failure cannot be recorded in that same failed sink.
                // Expose it in memory, stop admission and never retry or recover product state.
                lock (_gate)
                {
                    _disposition = "INCOMPLETE_OUTPUT_FAILED";
                    _stopped = true;
                    _pending = false;
                    _writing = false;
                }
            }
        }

        private string Serialize(Dictionary<string, string>[] records, string disposition)
        {
            var text = new StringBuilder();
            text.Append("{\"schema_version\":1,\"evidence\":\"MANAGER_RENDER_INPUT\",\"session\":");
            Quote(text, _session);
            text.Append(",\"disposition\":"); Quote(text, disposition);
            text.Append(",\"boundary_lossless\":false,\"admitted_records\":").Append(records.Length);
            text.Append(",\"records\":[");
            for (var i = 0; i < records.Length; i++)
            {
                if (i != 0) text.Append(',');
                text.Append('{');
                var first = true;
                foreach (var pair in records[i])
                {
                    if (!first) text.Append(',');
                    first = false;
                    Quote(text, pair.Key); text.Append(':'); Quote(text, pair.Value);
                }
                text.Append('}');
            }
            return text.Append("]}").ToString();
        }

        private static void Quote(StringBuilder text, string value)
        {
            if (value == null) { text.Append("null"); return; }
            text.Append('"');
            foreach (var c in value)
            {
                if (c == '"' || c == '\\') text.Append('\\').Append(c);
                else if (c < 32 || char.IsSurrogate(c))
                    text.Append("\\u").Append(((int)c).ToString("x4", CultureInfo.InvariantCulture));
                else text.Append(c);
            }
            text.Append('"');
        }

        private static void PublishAtomic(string path, string json)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            var temporary = path + ".tmp";
            try
            {
                File.WriteAllText(temporary, json, new UTF8Encoding(false));
                if (File.Exists(path)) File.Replace(temporary, path, null);
                else File.Move(temporary, path);
            }
            finally { if (File.Exists(temporary)) File.Delete(temporary); }
        }
    }
}
