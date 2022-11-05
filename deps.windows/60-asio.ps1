param(
    [string] $Name = 'asio',
    [string] $Version = '1.20.0',
    [string] $Uri = 'https://github.com/chriskohlhoff/asio.git',
    [string] $Hash = "b73dc1d2c0ecb9452a87c26544d7f71e24342df6"
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location "$Path/asio"

    New-Item -Path "$($ConfigData.OutputPath)/include" -ItemType Directory -Force *> $null

    $Item = @{
        Path = "include"
        Destination = "$($ConfigData.OutputPath)"
        Recurse = $true
        ErrorAction = 'SilentlyContinue'
    }

    Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
    Copy-Item @Item
    
    Remove-Item -Path "$($ConfigData.OutputPath)/include/Makefile.am" -Force
}
