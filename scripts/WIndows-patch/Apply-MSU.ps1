<# apply all .msu in current directory (non-recursive)
   Run as Administrator. #>
Get-ChildItem -LiteralPath . -Filter *.msu -File |
  ForEach-Object {
    Write-Host "Applying: $($_.FullName)"
    & "$env:WINDIR\system32\wusa.exe" "`"$($_.FullName)`"" /quiet /norestart
  }
