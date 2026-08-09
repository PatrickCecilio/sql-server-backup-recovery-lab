[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepositoryRoot = Split-Path -Parent $PSScriptRoot

$RequiredFiles = @(
    'README.md',
    '.gitignore',
    '.gitattributes',
    '.github/workflows/validate.yml',
    'docs/RUNBOOK.md',
    'docs/TROUBLESHOOTING.md',
    'scripts/config.sql',
    'scripts/00-preflight.sql',
    'scripts/01-create-lab.sql',
    'scripts/02-full-backup.sql',
    'scripts/03-differential-backup.sql',
    'scripts/04-log-backup.sql',
    'scripts/05-simulate-incident.sql',
    'scripts/06-point-in-time-restore.sql',
    'scripts/07-validate-recovery.sql',
    'scripts/08-audit-history.sql',
    'scripts/99-cleanup.sql'
)

$Errors = [System.Collections.Generic.List[string]]::new()

foreach ($RelativePath in $RequiredFiles) {
    $FullPath = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $FullPath -PathType Leaf)) {
        $Errors.Add("Required file is missing: $RelativePath")
    }
}

$SqlDirectory = Join-Path $RepositoryRoot 'scripts'
$SqlFiles = Get-ChildItem -LiteralPath $SqlDirectory -Filter '*.sql' -File | Sort-Object Name

foreach ($SqlFile in $SqlFiles) {
    $Content = Get-Content -Raw -LiteralPath $SqlFile.FullName

    if ($SqlFile.Name -ne 'config.sql' -and $Content -notmatch '(?im)^SET NOCOUNT ON;') {
        $Errors.Add("SET NOCOUNT ON is missing: scripts/$($SqlFile.Name)")
    }

    if ($SqlFile.Name -ne 'config.sql' -and $Content -notmatch '(?im)^:r \.\\scripts\\config\.sql$') {
        $Errors.Add("Central configuration include is missing: scripts/$($SqlFile.Name)")
    }

    if ($Content -match '(?im)\bPASSWORD\s*=') {
        $Errors.Add("Possible embedded password found: scripts/$($SqlFile.Name)")
    }

    if ($SqlFile.Name -ne '99-cleanup.sql' -and $Content -match '(?im)\bDROP\s+DATABASE\b') {
        $Errors.Add("DROP DATABASE is only allowed in scripts/99-cleanup.sql: scripts/$($SqlFile.Name)")
    }
}

$CleanupPath = Join-Path $SqlDirectory '99-cleanup.sql'
if (Test-Path -LiteralPath $CleanupPath) {
    $CleanupContent = Get-Content -Raw -LiteralPath $CleanupPath
    if ($CleanupContent -notmatch '(?im)^DECLARE @ConfirmCleanup bit = 0;$') {
        $Errors.Add('Cleanup must remain disabled by default.')
    }
}

$GitIgnorePath = Join-Path $RepositoryRoot '.gitignore'
if (Test-Path -LiteralPath $GitIgnorePath) {
    $GitIgnore = Get-Content -Raw -LiteralPath $GitIgnorePath
    foreach ($Pattern in @('*.bak', '*.trn', '*.mdf', '*.ldf')) {
        if ($GitIgnore -notmatch [regex]::Escape($Pattern)) {
            $Errors.Add("Backup or data pattern is not ignored: $Pattern")
        }
    }
}

$MarkdownFiles = Get-ChildItem -LiteralPath $RepositoryRoot -Filter '*.md' -File -Recurse
$LinkPattern = '\]\((?<target>(?!https?://|#)[^)]+)\)'

foreach ($MarkdownFile in $MarkdownFiles) {
    $Content = Get-Content -Raw -LiteralPath $MarkdownFile.FullName
    foreach ($Match in [regex]::Matches($Content, $LinkPattern)) {
        $Target = $Match.Groups['target'].Value.Split('#')[0]
        if ([string]::IsNullOrWhiteSpace($Target)) {
            continue
        }

        $DecodedTarget = [Uri]::UnescapeDataString($Target)
        $ResolvedTarget = Join-Path $MarkdownFile.DirectoryName $DecodedTarget
        if (-not (Test-Path -LiteralPath $ResolvedTarget)) {
            $RelativeMarkdown = [IO.Path]::GetRelativePath($RepositoryRoot, $MarkdownFile.FullName)
            $Errors.Add("Broken Markdown link in ${RelativeMarkdown}: $Target")
        }
    }
}

if ($Errors.Count -gt 0) {
    $Errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Repository validation passed: $($RequiredFiles.Count) required files and $($SqlFiles.Count) SQL scripts."
