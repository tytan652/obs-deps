param(
    [string] $Name = 'ads',
    [string] $Version = '4.2.1',
    [string] $Uri = 'https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git',
    [string] $Hash = 'ec018a4c7063b3f9d7a24f32d73b1428c450851e',
    [switch] $ForceStatic = $true
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    if ( $ForceStatic -and $script:Shared ) {
        $Shared = $false
    } else {
        $Shared = $script:Shared.isPresent
    }

    $OffOn = @('ON', 'OFF')
    $Options = @(
        $CmakeOptions
        "-DBUILD_STATIC=$($OffOn[$Shared])"
        '-DBUILD_EXAMPLES=OFF'
    )

    if ( $Configuration -eq 'Debug' ){
        $Options += '-DCMAKE_DEBUG_POSTFIX=d'
    }

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}
