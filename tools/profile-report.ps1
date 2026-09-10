[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileJson,
    [string]$BaselineResult,
    [double]$BaselineSeconds = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProfileJson = [IO.Path]::GetFullPath($ProfileJson)
if (-not (Test-Path -LiteralPath $ProfileJson -PathType Leaf)) {
    throw "Profile JSON was not found: '$ProfileJson'."
}

$profile = Get-Content -LiteralPath $ProfileJson -Raw | ConvertFrom-Json
if ([int]$profile.schema -ne 1) {
    throw "Unsupported profile schema '$($profile.schema)'."
}

$nodes = @{}
foreach ($node in @($profile.nodes)) {
    $nodes[[string]$node.id] = $node
}
if (-not $nodes.ContainsKey('frame')) {
    throw "Profile JSON does not contain the frame node."
}

$frameSeconds = [double]$nodes['frame'].inclusive_seconds
if ($frameSeconds -le 0) {
    $frameSeconds = [double]$profile.benchmark.demo_seconds
}

function Format-Percent {
    param([double]$Value)
    return ('{0,6:0.00}%' -f $Value)
}

function Write-ProfileTree {
    param(
        [AllowNull()][string]$ParentId,
        [int]$Depth,
        [string[]]$Path
    )

    $children = @($profile.edges | Where-Object {
        $edgeParent = [string]$_.parent
        if ([string]::IsNullOrEmpty($ParentId)) {
            [string]::IsNullOrEmpty($edgeParent)
        }
        else {
            $edgeParent -eq $ParentId
        }
    } | Sort-Object { [double]$_.inclusive_seconds } -Descending)

    foreach ($edge in $children) {
        $childId = [string]$edge.child
        if (-not $nodes.ContainsKey($childId)) {
            continue
        }
        $node = $nodes[$childId]
        $edgeSeconds = [double]$edge.inclusive_seconds
        $selfSeconds = [double]$edge.self_seconds
        $edgePercent = if ($frameSeconds -gt 0) {
            $edgeSeconds * 100.0 / $frameSeconds
        }
        else { 0 }
        $selfPercent = if ($frameSeconds -gt 0) {
            $selfSeconds * 100.0 / $frameSeconds
        }
        else { 0 }
        $indent = ' ' * ($Depth * 2)
        Write-Host (("{0}{1,-20} inc {2,9:0.000000}s self {3,9:0.000000}s " +
            "inc {4} self {5} calls {6,7} work {7,9} bytes {8,9}") -f
            $indent, $childId, $edgeSeconds, $selfSeconds,
            (Format-Percent $edgePercent), (Format-Percent $selfPercent),
            $edge.calls, $node.work_items, $node.work_bytes)

        if (($Path -notcontains $childId) -and ($Depth -lt 20)) {
            Write-ProfileTree -ParentId $childId -Depth ($Depth + 1) -Path ($Path + $childId)
        }
    }
}

Write-Host ("Profile benchmark: {0} frames, {1:0.000000}s, {2:0.000000} fps" -f
    $profile.benchmark.demo_frames, $profile.benchmark.demo_seconds,
    $profile.benchmark.demo_fps)
Write-Host (("Profile timer reads: {0}; maximum stack depth: {1}; stack errors: {2}/{3}; " +
    "timedemo-exit discarded scopes: {4}") -f
    $profile.profiler.timer_reads, $profile.profiler.max_depth,
    $profile.profiler.stack_overflows, $profile.profiler.bad_leaves,
    $profile.profiler.discarded_scopes)
Write-Host ''
Write-Host 'Parent -> children performance tree (inclusive edge time; self node time):'
Write-ProfileTree -ParentId $null -Depth 0 -Path @()

Write-Host ''
Write-Host 'Ranked hotspots by self time:'
$rank = 0
foreach ($node in @($profile.nodes | Where-Object { [double]$_.self_seconds -gt 0 } |
        Sort-Object { [double]$_.self_seconds } -Descending | Select-Object -First 12)) {
    $rank++
    $selfPercent = if ($frameSeconds -gt 0) {
        [double]$node.self_seconds * 100.0 / $frameSeconds
    }
    else { 0 }
    Write-Host ("{0,2}. {1,-20} self {2,9:0.000000}s {3} inc {4,9:0.000000}s calls {5,7} work {6,9} bytes {7,9}" -f
        $rank, $node.id, $node.self_seconds, (Format-Percent $selfPercent),
        $node.inclusive_seconds, $node.calls, $node.work_items, $node.work_bytes)
}

Write-Host ''
Write-Host 'Ranked hotspots by inclusive time:'
$rank = 0
foreach ($node in @($profile.nodes | Where-Object { [double]$_.inclusive_seconds -gt 0 } |
        Sort-Object { [double]$_.inclusive_seconds } -Descending | Select-Object -First 12)) {
    $rank++
    $inclusivePercent = if ($frameSeconds -gt 0) {
        [double]$node.inclusive_seconds * 100.0 / $frameSeconds
    }
    else { 0 }
    Write-Host ("{0,2}. {1,-20} inc  {2,9:0.000000}s {3} self {4,9:0.000000}s calls {5,7}" -f
        $rank, $node.id, $node.inclusive_seconds,
        (Format-Percent $inclusivePercent), $node.self_seconds, $node.calls)
}

Write-Host ''
Write-Host 'Workload metrics:'
foreach ($metric in @(
        'frames', 'bsp_nodes', 'bsp_solid_culls', 'bsp_visibility_culls',
        'bsp_leaf_nodes', 'bsp_internal_nodes', 'bsp_surface_tests',
        'scanlines', 'edge_insert_calls', 'edge_remove_calls',
        'edge_step_calls', 'span_flushes', 'surfaces', 'surface_span_count',
        'surface_span_pixels', 'surface_span_segments', 'surface_sky',
        'surface_background', 'surface_turbulent', 'surface_normal',
        'surface_solid', 'texture_spans', 'texture_pixels',
        'texture_segments', 'alias_models', 'alias_vertices', 'particles',
        'present_rects', 'present_pixels', 'sound_updates', 'sound_mixes')) {
    $value = $profile.metrics.$metric
    Write-Host ("  {0,-24} {1}" -f $metric, $value)
}

$baselineSecondsValue = [double]$BaselineSeconds
if (-not [string]::IsNullOrWhiteSpace($BaselineResult)) {
    $baselinePath = [IO.Path]::GetFullPath($BaselineResult)
    if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
        throw "Baseline result was not found: '$baselinePath'."
    }
    $baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
    $baselineValues = @($baseline.results | ForEach-Object { [double]$_.seconds })
    if ($baselineValues.Count -gt 0) {
        $baselineSecondsValue = [double](@($baselineValues | Measure-Object -Average).Average)
    }
}

if ($baselineSecondsValue -gt 0) {
    $overheadPercent = ($profile.benchmark.demo_seconds / $baselineSecondsValue - 1.0) * 100.0
    Write-Host ''
    Write-Host (("Estimated profiling overhead: {0:+0.00;-0.00;0.00}% " +
        "({1:0.000000}s profiled vs {2:0.000000}s release baseline)") -f
        $overheadPercent, $profile.benchmark.demo_seconds, $baselineSecondsValue)
}
else {
    Write-Host ''
    Write-Host 'Estimated profiling overhead: supply -BaselineResult or -BaselineSeconds for a matched comparison.'
}
