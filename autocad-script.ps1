# Coding languague: English | EN
# User displayed language: Portuguese | PT
# Script created: 14/04/2023
# Script updated: 09/05/2023

clear

$fileData = Get-Content autocad.log

$pattern = '(?<=\").+?(?=\@)'

for($r=0; $r -lt $fileData.Length; $r++)
{
    #Looks for anything that has a time with the format dd/mm/yyyy and grabs it
    if($fileData[$r] -match '\d\d\/\d\d/\d\d\d\d' -OR $fileData[$r] -match '\d\d\/\d/\d\d\d\d' -OR $fileData[$r] -match '\d\/\d/\d\d\d\d' -OR $fileData[$r] -match '\d\/\d\d/\d\d\d\d')
    {
        #This removes repeated dates and dates that have no information
        if($lineDate -eq $fileData[$r].split(" ")[4])
        {
            continue

        }elseif($fileData[$r+1] -match '\d\d\/\d\d/\d\d\d\d' -OR $fileData[$r+1] -match '\d\d\/\d/\d\d\d\d' -OR $fileData[$r+1] -match '\d\/\d/\d\d\d\d' -OR $fileData[$r+1] -match '\d\/\d\d/\d\d\d\d')
        {
            continue
        }
        $lineDate = $fileData[$r].split(" ")[4]
        if($lineDate)
        {
            # Converts american date time to european
            $dateFormat = [DateTime] $lineDate
            $dateFormat = "{0:dd/MM/yyyy}" -f $dateFormat

            $lineClean += "TIMESTAMP $dateFormat`n"
        }
    }else
    {
        #Looks for all the names of the users who connected
        if([regex]::Matches($fileData[$r], "IN:").Value  )
        {
            if([regex]::Matches($fileData[$r], $pattern).Value)
            {
                $lineFilter = [regex]::Matches($fileData[$r], $pattern).Value
                $lineClean += $lineFilter.split(" ")[1]
                $lineClean += "`n"
            }
        }
    }
}
if(!$lineClean)
{
    Write-Host "`nScript Terminado... Não existe nenhum dado!"
    exit
}

$lineUnique = $lineClean.Split("`n") | Select-Object -Unique
$lineClean = $lineClean.Split("`n")
$lineDelete = $lineUnique.psobject.Copy()

foreach($line in $lineClean)
{
    # If a TIMESTAMP is found, restarts user login verification
    if($line -match '\d\d\/\d\d/\d\d\d\d')
    {
        $info += "`n$line`n"

        # Resets the comparing list with all the names previously saved
        $lineDelete = $lineUnique.psobject.Copy()
    }else
    {
        for($k=0; $k -lt $lineDelete.Length-1; $k++)
        {
            # If a user is found, by comparing with another list, it is saved
            if($line -eq $lineDelete[$k])
            {
                $info += $line + "`n"

                # After the user is found, the list that is used to compare, gets the name removed so that it doesn't count it again, until a TIMESTAMP is found
                $lineDelete[$k] = "0"
            }
        }
    }
}

# This line will turn the the string to a list to be able to use for each line loop
$info = $info.Split("`n")

# This loop will filter so that each month only has one timestamp and how many people logged in that month
foreach($line in $info)
{
    # If its a timestamp, checks if the month is the same as previous
    if($line -match '\d\d\/\d\d/\d\d\d\d')
    {
        # Grabs only the month and year, and saves it
        if($data -ne $line.Substring($line.Length - 7))
        {
            $data = $line.Substring($line.Length - 7)
            $monthList += "`n`n" + $line.Substring($line.Length - 7) + "`n"
        }
    }else
    {
        # Saves the user
        if($line)
        {
            $monthList += $line + "`n"
        }
    }
}

$monthList = $monthList.Split("`n")
$i = 0
$array = @{}

# This loop will have european time format
foreach($line in $monthList)
{
    if($line -match '\d\d/\d\d\d\d')
    {
       $info2 += "`n" + $line + "`n"
       $i++
       $monthOnly += $line + "`n"
    }else
    {
        if($line)
        {
            $info2 += $line + "`n"
            $userOnly += $line + "`n"
        }else
        {
            if($info2)
            {
               $array[$i] += $info2 + "`n"
               $info2 = ""
            }
        }
    }
}

$monthOnly = $monthOnly.Split("`n")
$userOnly = $userOnly.Split() | Select-Object -Unique
$loginData = @()

# This loop will count logins and creates an array
for($w=1; $w -lt $array.keys.Count+1; $w++)
{
    # turns a string into a list
    $array[$w] = $array[$w].split("`n")

    # defines the month to analyze
    $month = $monthOnly[$w-1]

    # loop through each user and count how many times they logged in
    foreach ($user in $userOnly)
    {
        if($user)
        {
            $loginCount = 0
            $array[$w] | Where-Object { $_ -match $user } | ForEach-Object { $loginCount++ }
            $loginData += @{Month=$month;Username=$user;LoginCount=$loginCount}
        }
    }
}

Write-Host "`nNúmero de entradas de cada utilizador a cada mês:"
$allObjects = @()

# This loop will add together the names, logins counter and the month together in the right position and shows it to the user and then saves it into an CSV file
for($i=0; $i -lt $loginData.Month.Count; $i++)
{
    if($loginData[$i].Month -ne $loginData[$i-1].Month)
    {
        if($loginData[$i].LoginCount -ne 0)
        {
            $output += "`n`n" + $loginData[$i].Month + "`n" + $loginData[$i].Username + " " + $loginData[$i].LoginCount + "`n"
        }else
        {
            $output += "`n`n" + $loginData[$i].Month + "`n"
        }
    }else
    {
        if($loginData[$i].LoginCount -ne 0)
        {
            $output += $loginData[$i].Username + " " + $loginData[$i].LoginCount + "`n"
        }
    }
    if($loginData[$i].LoginCount -ne 0)
    {
        $serverList | ForEach-Object {
            $allObjects += [pscustomobject]@{
                Nome = $loginData[$i].Username
                Entradas = $loginData[$i].LoginCount
                Mes = (Get-Culture).DateTimeFormat.GetAbbreviatedMonthName($loginData[$i].Month.Substring(0,2))
                Ano = $loginData[$i].Month.Substring(3,4)
            }
        }
     }
}
$output
$allObjects | Export-Csv -Path "outfile.csv" -NoTypeInformation

if($?){    Write-Host "`nO ficheiro foi criado/alterado com sucesso em: $pwd\outfile.cvs"}else{    Write-Host "`nNão foi possivel criar/guardar o ficheiro em: $pwd\outfile.cvs`nOcurreu o seguinte erro:`n"    $error[0]}
Write-Host "`nScript Terminado..."
Clear-Variable -Name "lineFilter", "lineClean", "lineUnique", "info", "lineDate", "line", "lineDelete", "monthList", "monthOnly", "output", "loginData"
