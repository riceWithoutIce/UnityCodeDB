using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace CodeDB.S39.CommandLineV1
{
    [StructLayout(LayoutKind.Sequential)]
    public struct WnodeHeader
    {
        public uint BufferSize, ProviderId;
        public ulong HistoricalContext;
        public long TimeStamp;
        public Guid Guid;
        public uint ClientContext, Flags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct TraceProperties
    {
        public WnodeHeader Wnode;
        public uint BufferSize, MinimumBuffers, MaximumBuffers, MaximumFileSize;
        public uint LogFileMode, FlushTimer, EnableFlags, AgeLimit;
        public uint NumberOfBuffers, FreeBuffers, EventsLost, BuffersWritten;
        public uint LogBuffersLost, RealTimeBuffersLost;
        public IntPtr LoggerThreadId;
        public uint LogFileNameOffset, LoggerNameOffset;
    }

    // Creating/marshalling a block makes no native ETW call.
    public sealed class PropertyBlock : IDisposable
    {
        public IntPtr Pointer { get; private set; }
        public PropertyBlock(string name, string path, Guid id)
        {
            if (IntPtr.Size != 8 || Marshal.SizeOf(typeof(TraceProperties)) != 120)
                throw new PlatformNotSupportedException("Only the validated x64 layout is supported");
            if (name.Length > 1023 || path.Length > 1023) throw new ArgumentException("Trace name/path too long");
            int size = 120 + 4096 + 4096;
            Pointer = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.Copy(new byte[size], 0, Pointer, size);
                TraceProperties p = new TraceProperties();
                p.Wnode.BufferSize = (uint)size;
                p.Wnode.Guid = id;
                p.Wnode.ClientContext = 1; // QPC timestamps
                p.Wnode.Flags = 0x00020000; // WNODE_FLAG_TRACED_GUID
                p.BufferSize = 64; p.MinimumBuffers = 4; p.MaximumBuffers = 16;
                p.MaximumFileSize = 16; p.FlushTimer = 1;
                p.LogFileMode = 0x02000002; // SYSTEM_LOGGER_MODE | FILE_MODE_CIRCULAR
                p.EnableFlags = 0x00000001; // EVENT_TRACE_FLAG_PROCESS only
                p.LoggerNameOffset = 120; p.LogFileNameOffset = 120 + 4096;
                Marshal.StructureToPtr(p, Pointer, false);
                Marshal.Copy((name + '\0').ToCharArray(), 0, IntPtr.Add(Pointer, 120), name.Length + 1);
                Marshal.Copy((path + '\0').ToCharArray(), 0, IntPtr.Add(Pointer, 4216), path.Length + 1);
            }
            catch { Dispose(); throw; }
        }
        public TraceProperties Read() { return (TraceProperties)Marshal.PtrToStructure(Pointer, typeof(TraceProperties)); }
        public void Dispose() { if (Pointer != IntPtr.Zero) { Marshal.FreeHGlobal(Pointer); Pointer = IntPtr.Zero; } }
    }

    public interface ITraceApi
    {
        bool IsNative { get; }
        uint Query(string name, IntPtr properties);
        uint Start(out ulong handle, string name, IntPtr properties);
        uint Stop(ulong ownedHandle, IntPtr properties);
    }
    public interface IDeadlineScheduler { IDisposable Schedule(Action stop, double remainingMilliseconds); }

    public sealed class NativeApi : ITraceApi
    {
        public static int Calls;
        public bool IsNative { get { return true; } }
        [DllImport("advapi32.dll", EntryPoint = "StartTraceW", CharSet = CharSet.Unicode, ExactSpelling = true)]
        private static extern uint StartTrace(out ulong handle, string name, IntPtr properties);
        [DllImport("advapi32.dll", EntryPoint = "ControlTraceW", CharSet = CharSet.Unicode, ExactSpelling = true)]
        private static extern uint ControlTrace(ulong handle, string name, IntPtr properties, uint control);
        public uint Query(string name, IntPtr p) { Interlocked.Increment(ref Calls); return ControlTrace(0, name, p, 0); }
        public uint Start(out ulong h, string name, IntPtr p) { Interlocked.Increment(ref Calls); return StartTrace(out h, name, p); }
        public uint Stop(ulong h, IntPtr p) { Interlocked.Increment(ref Calls); return ControlTrace(h, null, p, 1); }
    }
    public sealed class TimerScheduler : IDeadlineScheduler
    {
        public IDisposable Schedule(Action stop, double ms)
        {
            return new Timer(delegate(object ignored) { stop(); }, null, (int)Math.Max(1, Math.Ceiling(ms)), Timeout.Infinite);
        }
    }

    public sealed class TraceState
    {
        public bool IsNative, StartAttempted, Owned, StopAttempted, DeadlineReached, Finished;
        public uint? InitialQueryCode, StartCode, StopCode, FinalQueryCode;
        public uint? EventsLost, LogBuffersLost, RealTimeBuffersLost, BuffersWritten;
        public string StartedUtc, StoppedUtc, Error;
        public double ElapsedSeconds;
    }

    // Sole stop authority is the nonzero handle from a successful StartTrace.
    // A failed start never establishes ownership, even if a same-name query succeeds.
    public sealed class Controller
    {
        private readonly object gate = new object();
        private readonly ITraceApi api;
        private readonly IDeadlineScheduler scheduler;
        private readonly string name, path;
        private readonly Guid id;
        private readonly Stopwatch watch = new Stopwatch();
        private readonly TraceState state = new TraceState();
        private ulong handle;
        private IDisposable deadline;
        private bool begun;
        public Controller(string sessionName, string tracePath, Guid sessionGuid, ITraceApi traceApi, IDeadlineScheduler stopScheduler)
        {
            if (!System.Text.RegularExpressions.Regex.IsMatch(sessionName, "^CodeDB-S39-Cmd-[a-f0-9]{32}$")) throw new ArgumentException("Invalid owned name");
            if (sessionGuid == Guid.Empty || sessionGuid == new Guid("9e814aad-3204-11d2-9a82-006008a86939")) throw new ArgumentException("Reserved/empty GUID");
            name = sessionName; path = pathFull(tracePath); id = sessionGuid;
            api = traceApi; scheduler = stopScheduler; state.IsNative = api.IsNative;
        }
        private static string pathFull(string p)
        {
            if (!System.IO.Path.IsPathRooted(p)) throw new ArgumentException("Absolute trace path required");
            return System.IO.Path.GetFullPath(p);
        }
        public static Controller CreateNative(string name, string path, Guid id)
        { return new Controller(name, path, id, new NativeApi(), new TimerScheduler()); }
        private uint Query()
        { using (PropertyBlock p = new PropertyBlock(name, path, id)) return api.Query(name, p.Pointer); }
        public void Begin()
        {
            lock (gate)
            {
                if (begun || state.Finished) throw new InvalidOperationException("No restart/reuse");
                begun = true;
                state.InitialQueryCode = Query();
                if (state.InitialQueryCode != 4201) return; // ERROR_WMI_INSTANCE_NOT_FOUND only
                using (PropertyBlock p = new PropertyBlock(name, path, id))
                {
                    watch.Start(); state.StartedUtc = DateTime.UtcNow.ToString("o"); state.StartAttempted = true;
                    ulong h;
                    state.StartCode = api.Start(out h, name, p.Pointer);
                    if (state.StartCode != 0) return;
                    if (h == 0) throw new InvalidOperationException("Successful start returned no handle; ownership unknown");
                    handle = h; state.Owned = true;
                }
                double remaining = 60000 - watch.Elapsed.TotalMilliseconds;
                if (remaining <= 0) StopLocked(true);
                else deadline = scheduler.Schedule(DeadlineStop, remaining);
            }
        }
        private void DeadlineStop()
        {
            // Never allow an exception on a timer thread to terminate the recorder host.
            lock (gate) { if (state.Finished) return; try { StopLocked(true); } catch (Exception ex) { state.Error = ex.Message; } }
        }
        private void StopLocked(bool expired)
        {
            if (expired) state.DeadlineReached = true;
            if (!state.Owned || state.StopAttempted) return;
            state.StopAttempted = true;
            try
            {
                using (PropertyBlock p = new PropertyBlock(name, path, id))
                {
                    state.StopCode = api.Stop(handle, p.Pointer);
                    if (state.StopCode == 0)
                    {
                        TraceProperties result = p.Read();
                        state.EventsLost = result.EventsLost; state.LogBuffersLost = result.LogBuffersLost;
                        state.RealTimeBuffersLost = result.RealTimeBuffersLost; state.BuffersWritten = result.BuffersWritten;
                        state.Owned = false;
                    }
                }
            }
            finally { state.StoppedUtc = DateTime.UtcNow.ToString("o"); watch.Stop(); }
        }
        public void Finish()
        {
            lock (gate)
            {
                if (state.Finished) return;
                if (deadline != null) deadline.Dispose();
                try { StopLocked(false); }
                catch (Exception ex) { state.Error = ex.Message; }
                finally
                {
                    if (state.StartAttempted)
                    {
                        try { state.FinalQueryCode = Query(); }
                        catch (Exception ex) { state.Error = ex.Message; }
                    }
                    watch.Stop(); state.Finished = true;
                }
            }
        }
        public TraceState Snapshot()
        {
            lock (gate)
            {
                state.ElapsedSeconds = watch.Elapsed.TotalSeconds;
                // A detached copy keeps receipt serialization free of timer races.
                TraceState s = new TraceState();
                foreach (var f in typeof(TraceState).GetFields()) f.SetValue(s, f.GetValue(state));
                return s;
            }
        }
    }
}
