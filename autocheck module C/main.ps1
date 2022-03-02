function compress {
    [OutputType([String])]
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName='script',
                   Mandatory=$true,
                   ValueFromPipeline=$true)]
        [string]$script
    )
    $Data= foreach ($c in $script.ToCharArray()) { $c -as [Byte] }
    $ms = New-Object IO.MemoryStream
    $cs = New-Object System.IO.Compression.GZipStream ($ms, [Io.Compression.CompressionMode]"Compress")
    $cs.Write($Data, 0, $Data.Length)
    $cs.Close()
    [Convert]::ToBase64String($ms.ToArray())
    $ms.Close()
}

function payload {
    [OutputType([String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$script,
        [switch]$Linux,
        [switch]$Win
    )
    if($Linux){
      $vmscript = @(
        'PLAY=$(mktemp)'
        'echo {0} | base64 -d | zcat > $PLAY' -f $script
        'ANSIBLE_STDOUT_CALLBACK=json ansible-playbook --check -i localhost, -c local $PLAY | jq ''[.plays[].tasks[1:][]|{(.task.name):.hosts.localhost.changed|not}]|add'''
        'rm -f $PLAY'
      ) -join ';'
    }
    if($Win){
      $vmscript = @(
        '$scripttext="{0}"' -f $script
        '$binaryData = [System.Convert]::FromBase64String($scripttext)'
        '$ms = New-Object System.IO.MemoryStream'
        '$ms.Write($binaryData, 0, $binaryData.Length)'
        '$ms.Seek(0,0) | Out-Null'
        '$cs = New-Object System.IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]"Decompress")'
        '$sr = New-Object System.IO.StreamReader($cs)'
        '$sr.ReadToEnd() | Invoke-Expression'
      ) | Out-String
    }
    return $vmscript
}

function Get-Marks {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Object]$results
    )
    $marks = @(
        [pscustomobject]@{
            "Name" = "C1: docker install"; "Max" = 1.0; "Mark" = if($results.WEB1.docker_install -eq $true -and $results.WEB2.docker_install -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C2: database"; "Max" = 1.0; "Mark" = if($results.DB.database -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C3: app start on docker"; "Max" = 1.0; "Mark" = if($results.WEB1.docker_app -eq $true -and $results.WEB2.docker_app -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C4: http access site.unakbars.ru"; "Max" = 1.0; "Mark" = if($results.Master.http_access -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C5: http redirection"; "Max" = 1.0; "Mark" = if($results.Master.http_redirection -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C6: https access site.unakbars.ru"; "Max" = 1.0; "Mark" = if($results.Master.https_access -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C7: APP external link"; "Max" = 0.3; "Mark" = if($results.WEB1.docker_link -eq $true -and $results.WEB2.docker_link -eq $true)
                                                                        { 0.3 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C8: ntp client"; "Max" = 0.2; "Mark" = if($results.WEB1.ntp_status -eq $true -and $results.WEB2.ntp_status -eq $true -and $results.DB.ntp_status -eq $true)
                                                                        { 0.2 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C9: http loadbalance backend"; "Max" = 1.0; "Mark" = if($results.Master.loadbalance -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C10: Set local ips l-rtr, r-rtr"; "Max" = 0.2; "Mark" = if($results.Left_test.ping_test -eq $true -and $results.Right_test.ping_test -eq $true)
                                                                        { 0.2 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C11: dns client l-rtr / r-rtr"; "Max" = 0.4; "Mark" = if($results.Master.lrtr_dns -eq $true -and $results.Master.rrtr_dns -eq $true)
                                                                        { 0.4 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C12: gre tunnel"; "Max" = 0.7; "Mark" = if($results.Master.r_gre -eq $true -and $results.Master.gre_ping -eq $true)
                                                                        { 0.7 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C13: ipsec over gre"; "Max" = 1.0; "Mark" = if($results.Master.ipsec -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C14: PAT l-rtr"; "Max" = 0.8; "Mark" = if($results.Left_test.pat_test -eq $true)
                                                                        { 0.8 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C15: PAT r-rtr"; "Max" = 0.8; "Mark" = if($results.Right_test.pat_test -eq $true)
                                                                        { 0.8 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C16: left ipv4 connectivity"; "Max" = 0.7; "Mark" = if($results.Left_test.connect_test -eq $true)
                                                                        { 0.7 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C17: right ipv4 connectivity"; "Max" = 0.7; "Mark" = if($results.Right_test.connect_test -eq $true)
                                                                        { 0.7 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C18: left static nat port 2222"; "Max" = 1.0; "Mark" = if($results.Master.l_stnat -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C19: right static nat port 2222"; "Max" = 1.0; "Mark" = if($results.Master.r_stnat -eq $true)
                                                                        { 1.0 } else { 0 }
        },
        [pscustomobject]@{
            "Name" = "C20: ntp client csr"; "Max" = 0.2; "Mark" = if($results.Master.l_ntp -eq $true -and $results.Master.r_ntp -eq $true)
                                                                        { 0.2 } else { 0 }
        }
    )
    Write-Host $marks
    return $marks
}

Set-PowerCLIConfiguration -InvalidCertificateAction ignore -Confirm:$false
Connect-VIServer -Server 192.168.3.25 -User administrator@vsphere.local -Password Ваш_Пароль


$count = 10
while ($count -gt 0) {
$tasks=@()
$DB = Get-VM -Server 192.168.3.25 -Location "ansible_$count" -Name "DB"
$Master = Get-VM -Server 192.168.3.25 -Location "ansible_$count" -Name "Master"
$Left_test = Get-VM -Server 192.168.3.25 -Location "ansible_$count" -Name "Left-test"
$Right_test = Get-VM -Server 192.168.3.25 -Location "ansible_$count" -Name "Right-test"
$WEB1 = Get-VM -Server 192.168.3.25 -Location "ansible_$count" -Name "WEB1"
$WEB2 = Get-VM -Server 192.168.3.25 -Location "ansible_$count" -Name "WEB2"

$vmscript = Get-Content -Path .\WEB1.bash -Raw
$tasks += Invoke-VMScript -VM $WEB1 -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

$vmscript = Get-Content -Path .\WEB2.bash -Raw
$tasks += Invoke-VMScript -VM $WEB2 -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

$vmscript = Get-Content -Path .\DB.bash -Raw
$tasks += Invoke-VMScript -VM $DB -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

$vmscript = Get-Content -Path .\Master.bash -Raw
$tasks += Invoke-VMScript -VM $Master -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

$vmscript = Get-Content -Path .\Left.bash -Raw
$tasks += Invoke-VMScript -VM $Left_test -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

$vmscript = Get-Content -Path .\Right.bash -Raw
$tasks += Invoke-VMScript -VM $Right_test -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

#$vmscript = Get-Content -Path .\CLI.bash -Raw
#$tasks += Invoke-VMScript -VM $CLI -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType bash -RunAsync -Confirm:$false

#$vmscript = Get-Content -Path .\FILESERVER.ps1 -Raw | compress | payload -Win
#$tasks += Invoke-VMScript -VM $FILESERVER -ScriptText $vmscript -GuestUser Administrator -GuestPassword P@ssw0rd -ScriptType Powershell -RunAsync -Confirm:$false

#$vmscript = Get-Content -Path .\L-FW.bash -Raw
#$tasks += Invoke-VMScript -VM $L_FW -ScriptText $vmscript -GuestUser root -GuestPassword toor -ScriptType Bash -RunAsync:$true -Confirm:$false
while ($tasks.State -contains 'running') { Start-Sleep 1 }
    $results = @{ "WEB1" = $null; "WEB2" = $null; "DB" = $null; "Master" = $null; "Left_test" = $null; "Right_test" = $null; }

    foreach ($task in $tasks) {
        if($task.Result.VM.Name -like "*WEB1*"){
            Write-Host $task.Result.ScriptOutput
            $results.WEB1 = ( $task.Result.ScriptOutput.Split("`n") | ConvertFrom-Json )
        }
        elseif($task.Result.VM.Name -like "*WEB2*"){
            Write-Host $task.Result.ScriptOutput
            $results.WEB2 = ( $task.Result.ScriptOutput.Split("`n") | ConvertFrom-Json )
        }
        elseif($task.Result.VM.Name -like "*DB*"){
            Write-Host $task.Result.ScriptOutput
            $results.DB = ( $task.Result.ScriptOutput.Split("`n") | ConvertFrom-Json )
        }
        elseif($task.Result.VM.Name -like "*Master*"){
            Write-Host $task.Result.ScriptOutput
            $results.Master = ( $task.Result.ScriptOutput.Split("`n") | ConvertFrom-Json )
        }
        elseif($task.Result.VM.Name -like "*Left-test*"){
            Write-Host $task.Result.ScriptOutput
            $results.Left_test = ( $task.Result.ScriptOutput.Split("`n") | ConvertFrom-Json )
        }
        elseif($task.Result.VM.Name -like "*Right-test*"){
            Write-Host $task.Result.ScriptOutput
            $results.Right_test = ( $task.Result.ScriptOutput.Split("`n") | ConvertFrom-Json )
        }
        }
    #Write-Host ("stand_$count")
    #Write-Host ("DC: "+$results.DC)
    #Write-Host ("Inet-W: "+$results.Inet_W)
    #Write-Host ("FILESERVER: "+$results.FILESERVER)
    #Write-Host ("L-FW: "+$results.L_FW)
    #if ($results.L_FW.hostname -and $results.DC.hostname -and $results.FILESERVER.hostname) {Write-Host (0.3)} 
    #Write-Host ($results.DC.hostname)
    Get-Marks -results $results | ConvertTo-Json | Out-File -FilePath ".\Results\C_$($count).json"
    $count -= 1 
}