<# Prove project/runtime CODE boundaries, actual relocated instructions and embedded startup code. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$BuildRoot,
    [Parameter(Mandatory=$true)][string]$ObjectRoot,
    [Parameter(Mandatory=$true)][string[]]$ObjectNames,
    [Parameter(Mandatory=$true)][string]$MapPath,
    [Parameter(Mandatory=$true)][string]$ProjectProofIndex,
    [Parameter(Mandatory=$true)][string]$ReportRoot,
    [string]$ExecutableName='quake.exe',
    [string]$ToolRoot,
    [string]$HostCompiler
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$bundle=Join-Path $PSScriptRoot 'isa-runtime-reference'
$toolParameters=@{}
if(-not [string]::IsNullOrWhiteSpace($ToolRoot)){$toolParameters.ToolRoot=$ToolRoot}
& (Join-Path $PSScriptRoot 'isa-audit-linked.ps1') @toolParameters -BuildRoot $BuildRoot -ObjectRoot $ObjectRoot `
    -ObjectNames $ObjectNames -MapPath $MapPath -ExecutableName $ExecutableName -ReportRoot $ReportRoot `
    -ObjectCodeDataProofJson $ProjectProofIndex -RuntimeSourceBundle $bundle -MaxIsa i486
$linkedPath=Join-Path $ReportRoot 'isa-audit-linked.json'
$linked=Get-Content -LiteralPath $linkedPath -Raw | ConvertFrom-Json
if(-not $linked.pass -or -not $linked.sourceBoundCodeData){throw 'The exact source-bound linked audit did not pass.'}
$runId=Get-Date -Format 'yyyyMMdd-HHmmssfff'
$finalRoot=Join-Path $ReportRoot ('relocated-' + $runId)
& python (Join-Path $PSScriptRoot 'final-executable-isa-ranges.py') --linked-report $linkedPath `
    --proof-index $linked.objectCodeDataProofJson --output $finalRoot
if($LASTEXITCODE -ne 0){throw 'Source-to-final instruction boundary mapping failed.'}
$finalIsa=Join-Path $finalRoot 'strict-isa.json'
& (Join-Path $PSScriptRoot 'isa-audit.ps1') @toolParameters -BuildRoot $BuildRoot -ExeName $ExecutableName `
    -ExecutableOnly -AddressRangesJson (Join-Path $finalRoot 'isa-ranges.json') -MaxIsa i486 -FailOnViolation -OutputJson $finalIsa
$final=Get-Content -LiteralPath $finalIsa -Raw | ConvertFrom-Json
if([int]$final.instructionCount -ne [int]$linked.instructionAudit.linkedInstructionsVerified){
    throw 'The relocated executable and input instruction counts differ.'
}
$djasmRoot=Join-Path $ReportRoot ('djasm-host-' + $runId)
$hostArguments=@()
if(-not [string]::IsNullOrWhiteSpace($HostCompiler)){$hostArguments=@('--host-compiler',$HostCompiler)}
& python (Join-Path $PSScriptRoot 'djgpp-assembler-tool.py') --bundle $bundle @hostArguments --output $djasmRoot
if($LASTEXITCODE -ne 0){throw 'Primary DJGPP startup assembler compilation failed.'}
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
if([string]::IsNullOrWhiteSpace($ToolRoot)){$ToolRoot=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) '486quake/tools'}
$objdump=Join-Path (Join-Path $ToolRoot $manifest.djgpp.installDirectory) $manifest.djgpp.objdump
$crt=@($linked.runtimeInputs | Where-Object {$_.kind -eq 'runtime-object' -and [IO.Path]::GetFileName($_.path) -eq 'crt0.o'})
if($crt.Count -ne 1){throw 'Exactly one linked CRT object must provide the embedded 16-bit startup helpers.'}
$startupRoot=Join-Path $ReportRoot ('startup-' + $runId)
& python (Join-Path $PSScriptRoot 'startup-linked-proof.py') --archive (Join-Path $bundle 'primary/djlsr205.zip') `
    --executable (Join-Path $BuildRoot $ExecutableName) --map $MapPath --crt-object $crt[0].path `
    --djasm (Join-Path $djasmRoot 'djasm-host.exe') --objdump $objdump --output $startupRoot
if($LASTEXITCODE -ne 0){throw 'Primary startup sources do not match their final executable bytes.'}
$startupCount=0
foreach($unit in @('loader','crt-helpers/sbrk16','crt-helpers/exit16')){
    $path=Join-Path $startupRoot $unit
    $name=if($unit -eq 'loader'){'loader-audit.obj'}else{'helper-audit.obj'}
    $report=Join-Path $path 'strict-isa.json'
    & (Join-Path $PSScriptRoot 'isa-audit.ps1') @toolParameters -BuildRoot $path -ExeName $name -ExecutableOnly `
        -AddressRangesJson (Join-Path $path 'isa-ranges.json') -MaxIsa i486 -FailOnViolation -OutputJson $report
    $audit=Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
    $startupCount+=[int]$audit.instructionCount
}
$startupProof=Get-Content -LiteralPath (Join-Path $startupRoot 'startup-linked-proof.json') -Raw | ConvertFrom-Json
if($startupCount -ne [int]$startupProof.instructionRows){throw 'Embedded startup instruction coverage is incomplete.'}
$linked | Add-Member -NotePropertyName actualRelocatedIsa -NotePropertyValue ([ordered]@{
    report=$finalIsa;reportSha256=(Get-FileHash -LiteralPath $finalIsa -Algorithm SHA256).Hash;
    instructionCount=[int]$final.instructionCount;sourceBound=$true;instructionExemptions=0})
$linked | Add-Member -NotePropertyName embeddedStartupIsa -NotePropertyValue ([ordered]@{
    proof=(Join-Path $startupRoot 'startup-linked-proof.json');
    proofSha256=(Get-FileHash -LiteralPath (Join-Path $startupRoot 'startup-linked-proof.json') -Algorithm SHA256).Hash;
    instructionCount=$startupCount;
    loadedBytes=[int]$startupProof.loadedStartupBytesProved;exactFinalBytes=$true;instructionExemptions=0})
$providerRoot=Join-Path $ReportRoot ('provider-' + $runId)
$providerPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../src/cwsdpmi.exe'))
$compiler=Join-Path (Join-Path $ToolRoot $manifest.djgpp.installDirectory) $manifest.djgpp.compiler
& python (Join-Path $PSScriptRoot 'cws-provider-proof.py') --executable $providerPath --compiler $compiler `
    --output $providerRoot --tool-root $ToolRoot
if($LASTEXITCODE -ne 0){throw 'The external DPMI provider has no complete i486 instruction proof.'}
$providerProofPath=Join-Path $providerRoot 'provider-proof.json'
$providerProof=Get-Content -LiteralPath $providerProofPath -Raw | ConvertFrom-Json
$linked | Add-Member -NotePropertyName externalDpmiProvider -NotePropertyValue ([ordered]@{
    proof=$providerProofPath;proofSha256=(Get-FileHash -LiteralPath $providerProofPath -Algorithm SHA256).Hash;
    executable=$providerPath;executableSha256=$providerProof.executableSha256;
    instructionCount=[int]$providerProof.instructionCount;runtimeVariantInstructions=[int]$providerProof.runtimeVariantInstructions;
    exactMaintainedProvider=$true;instructionExemptions=0})
$linked | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $linkedPath -Encoding UTF8
Write-Host ('Complete executable ISA gate PASS: {0} relocated instructions, {1} startup rows and {2} provider instructions; zero exemptions.' -f $final.instructionCount,$startupCount,$providerProof.instructionCount)
