# Unlock_AD_Account.ps1
# objetivo: Desbloquear conta de usuario
# criado por: moisesroth@gmail.com
# 14/03/2014

# -------------------------------------- Funcoes --------------------------------------

function Test-Credential(){
    $cred = Get-Credential #Read credentials
    $username = $cred.username
    $password = $cred.GetNetworkCredential().password

    # Get current domain using logged-on user's credentials
    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)

    if ($domain.name -eq $null) {
        write-host "Authentication failed - please verify your username and password."
    }
    else {
        write-host "Successfully authenticated with domain $domain.name"
    }
}


function Unlock-ADUser([string]$userID)
{
    $ln = "`n-------------------------------------------------------------------------------`n"
    $blocked = Search-ADAccount -LockedOut
    $encontrado = "false"

    foreach($id in $blocked) {     
        if($id.SamAccountName -eq $userID) {
            $encontrado = "true"
            #$ln; $answer = Read-Host ">> Deseja desbloquear"$id.SamAccountName"? S para sim"
            
            $title = $ln+"`nConfirmar o desbloqueio para "+$id.SamAccountName
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($sim, $nao)
            $answer = $host.ui.PromptForChoice($title, $message, $options, $default_answer) 

            if($answer -eq 0) {
                $ln; Write-Host ">>"$id.Name"sera desbloqueado"

                $error.clear()
                $erroractionpreference = "SilentlyContinue"
                
                Unlock-ADAccount -Identity $userID
                if ($? -eq $false) {
                    Write-Host $ln;">> Voce nao tem provilegios para efetuar desbloqueios com o usuario"; [Environment]::UserName
                    $sudo_user = Read-Host "`n>> Informe usuario administrativo"

                    runas /profile /user:gnet\$sudo_user "powershell -command Import-Module ActiveDirectory; Unlock-ADAccount -Identity $userID; if ('$?' -eq '$false') {'`n>> ERRO ao desbloeuar $userID'}else{'`n>> SUCESSO ao desbloquear $userID'}; Read-Host '`n>> Pressione ENTER para SAIR'"
    
                    Read-Host "--"
                    clear
                }
            } else {
                $ln; Write-Host ">> Desbloqueio cancelado"
            }
        }
    }

    if($encontrado -eq "false") {
        $ln; Write-Host ">> Nao foi possivel encontrar $userID"
    }

}


# -------------------------------------- Inicio Script --------------------------------------
clear
$ln = "`n-------------------------------------------------------------------------------`n"
$title = $ln+"`nActive Directory"
$message = " "
$default_answer = 0

$o0  = New-Object System.Management.Automation.Host.ChoiceDescription "List"    , ` "Listar usuarios bloquados"
$o1  = New-Object System.Management.Automation.Host.ChoiceDescription "&Unlock" , ` "Desbloquear usuario"
$o2  = New-Object System.Management.Automation.Host.ChoiceDescription "&Limpar" , ` "Limpar a tela"
$o3  = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit"   , ` "Fechar o programa"
$sim = New-Object System.Management.Automation.Host.ChoiceDescription "&Sim"    , ` "Confirmar"
$nao = New-Object System.Management.Automation.Host.ChoiceDescription "&Nao"    , ` "Cancelar"


Import-Module ActiveDirectory
# apenas para evitar menus diferentes durante a execucao (titulos que so aparecem na primeira vez que o comando Search for executado)
Search-ADAccount -LockedOut |Select-Object name,SamAccountName
clear


$options = [System.Management.Automation.Host.ChoiceDescription[]]($o0, $o1, $o2, $o3)

$x = 0
:OuterLoop do { 
    $result = $host.ui.PromptForChoice($title, $message, $options, $default_answer) 

    switch ($result) {
        0 { # List
            $dt= Get-Date
            clear
            $ln; Write-Host ">> Usuarios atualmente bloqueados", $dt, "`n"
            Search-ADAccount -LockedOut |Select-Object name,SamAccountName
        }

        1 { # Unlock
            clear
            do {
                $dt= Get-Date
                $ln; Write-Host ">> Usuarios atualmente bloqueados", $dt, "`n"
                Search-ADAccount -LockedOut |Select-Object name,SamAccountName
                
                $ln; $userID = Read-Host ">> Informe o eruid que deseja desbloquear"
                clear
                if ($userID -ne "") {
                   Unlock-ADUser -userID $userID
                }
            }
            while ($userID -ne "")
        }

        2 { # Limpar
            clear
        }        

        3 { # Exit
            break OuterLoop
        }
    }
} while ($x -ne 1)
