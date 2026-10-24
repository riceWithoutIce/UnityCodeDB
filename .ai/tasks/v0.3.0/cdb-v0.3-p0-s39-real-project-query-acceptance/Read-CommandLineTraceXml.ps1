param([Parameter(Mandatory=$true)][string]$DecodedXml)
$ErrorActionPreference='Stop'
# Read-only summarizer for tracerpt XML; it never starts a recorder or emits raw argv.
$settings=New-Object Xml.XmlReaderSettings
$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit
$settings.XmlResolver=$null
$settings.MaxCharactersInDocument=128MB
$reader=[Xml.XmlReader]::Create([IO.Path]::GetFullPath($DecodedXml),$settings)
$processGuid='3d6fa8d0-fe05-11d0-9dda-00c04fd7ba7c'
$events=0; $processEvents=0; $argvFields=0; $nonemptyArgv=0; $errors=0; $headers=@(); $candidates=@()
try {
    while ($reader.Read()) {
        if ($reader.NodeType -ne [Xml.XmlNodeType]::Element -or $reader.LocalName -ne 'Event') { continue }
        $sub=$reader.ReadSubtree()
        try { $doc=New-Object Xml.XmlDocument; $doc.XmlResolver=$null; $doc.Load($sub) } finally { $sub.Dispose() }
        $events++
        $ns=New-Object Xml.XmlNamespaceManager($doc.NameTable)
        $ns.AddNamespace('e','http://schemas.microsoft.com/win/2004/08/events/event')
        if ($null -ne $doc.SelectSingleNode('//*[local-name()="ProcessingErrorData"]')) { $errors++ }
        $provider=$doc.SelectSingleNode('/e:Event/e:System/e:Provider',$ns)
        $eventGuid=$doc.SelectSingleNode('//*[local-name()="ExtendedTracingInfo"]/*[local-name()="EventGuid"]')
        $data=@{}
        foreach ($d in $doc.SelectNodes('/e:Event/e:EventData/e:Data',$ns)) { $data[$d.GetAttribute('Name')]=$d.InnerText.Trim() }
        if ($data.ContainsKey('EventsLost')) {
            $headers+=[pscustomobject]@{events_lost=$data['EventsLost'];buffers_lost=$data['BuffersLost'];buffers_written=$data['BuffersWritten'];max_file_size=$data['MaxFileSize']}
        }
        $isProcess=($null -ne $provider -and $provider.GetAttribute('Guid').Trim('{}') -ieq $processGuid) -or
                   ($null -ne $eventGuid -and $eventGuid.InnerText.Trim('{}') -ieq $processGuid)
        if (!$isProcess) { continue }
        $processEvents++
        if ($data.ContainsKey('CommandLine')) { $argvFields++; if ($data['CommandLine']) { $nonemptyArgv++ } }
        $cmd=$data['CommandLine']
        # This is deliberately labelled a text candidate, not resolved argv/project identity.
        if ($cmd -and $cmd -match '(?i)(?:^|\s)"?AIWork[\\/]codedb[\\/]wrapper[\\/]codedb-project-wrapper\.mjs"?(?=\s|$)') {
            $candidates+=[pscustomobject]@{
                event_index=$events; pid=$data['ProcessId']; parent_pid=$data['ParentId']; process_key=$data['UniqueProcessKey']
                time=$doc.SelectSingleNode('/e:Event/e:System/e:TimeCreated',$ns).GetAttribute('SystemTime')
                opcode=$doc.SelectSingleNode('/e:Event/e:System/e:Opcode',$ns).InnerText
                version=$doc.SelectSingleNode('/e:Event/e:System/e:Version',$ns).InnerText
                image=$data['ImageFileName']; exit_status=$data['ExitStatus']
                entry_text_match=$true; root_dot_text_match=($cmd -match '(?:^|\s)--root\s+"?\."?(?=\s|$)')
                commandline_characters=$cmd.Length; attribution='TEXT_CANDIDATE_ONLY_NO_CWD_OR_PROJECT_IDENTITY'
            }
        }
    }
} finally { $reader.Dispose() }
[pscustomobject]@{
    events=$events;process_events=$processEvents;commandline_fields=$argvFields;nonempty_commandlines=$nonemptyArgv
    processing_error_events=$errors;headers=$headers;entry_text_candidates=$candidates
    interpretation='Check loss, circular overwrite, versions, parent/time/thread and scoped argv before attribution; no absence or query PASS implied'
} | ConvertTo-Json -Depth 7
