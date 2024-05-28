$data = Invoke-RestMethod -Uri "https://api.openopus.org/work/dump.json" -Method Get
$keyWorks = [System.Collections.ArrayList]@()
$keysStr = "D flat major|D minor|E flat major|C minor|A minor|A major|G flat major|B flat major|C major|F major|G minor|D major|G major|E minor|E major|B minor|F minor|F sharp minor|C sharp major|A flat major|C sharp minor|E flat minor|B flat minor|B major|F sharp major|A flat minor|G sharp minor"
$keys = [System.Collections.ArrayList]$keysStr.Split("|")
$keyMappings = @{
    'C sharp major' = 'D flat major'
    'A flat minor' = 'G sharp minor'
    'G flat major' = 'F sharp major'
}
foreach($comp in $data.composers){
    foreach($work in $comp.works){
        foreach($key in $keys){
            if($work.title -match $key){
                if($keyWorks.title -contains $work.title -and $keyWorks.composer -contains $comp.complete_name){
                    break
                }
                $fixedKey = $key
                if($keyMappings.ContainsKey($fixedKey)){
                    $fixedKey = $keyMappings[$fixedKey]
                }
                $work | Add-Member -MemberType NoteProperty -Name 'key' -Value $fixedKey -Force
                $work | Add-Member -MemberType NoteProperty -Name 'composer' -Value $comp.complete_name -Force
                $work | Add-Member -MemberType NoteProperty -Name 'period' -Value $comp.epoch -Force
                $popularity = "Popular"
                if($work.popular -eq 0){
                    $popularity = "Nonpopular"
                }
                $work | Add-Member -MemberType NoteProperty -Name 'popularity' -Value $popularity -Force

                $keyWorks.Add($work)
                break
            }    
        }
    }
}
foreach($k in $keyMappings.Keys){
    $keys.Remove($k)
}

$composers = $data.composers.complete_name
$period = @("Medieval", "Renaissance", "Baroque", "Classical", "Early Romantic", "Romantic", "Late Romantic", "20th Century", "Post-War", "21st Century")
$popularity = @("Popular", "Nonpopular")
$genres = @("Chamber", "Keyboard", "Orchestral", "Stage", "Vocal")
$allNodesList = $composers + $period + $popularity + $genres + $keys
$allNodesTable = @{}
$worksTable = @{}
foreach($node in $allNodesList){
    $allNodesTable.Add($node, $allNodesTable.Count+1)
}
foreach($work in $keyWorks){
    $worksTable.Add("$($work.title)|$($work.composer)", $allNodesTable.Count+$worksTable.Count+1)
}

$edges = [System.Collections.ArrayList]@()
foreach($work in $keyWorks){
    $keyID = $allNodesTable[$work.key]
    $composerID = $allNodesTable[$work.composer]
    $workID = $worksTable["$($work.title)|$($work.composer)"]
    $periodID = $allNodesTable[$work.period]
    $genreID = $allNodesTable[$work.genre]
    $popularID = $allNodesTable[$work.popularity]
    $edges.Add("$workID $keyID")
    $edges.Add("$workID $composerID")
    $edges.Add("$workID $periodID")
    $edges.Add("$workID $genreID")
    $edges.Add("$workID $popularID")
}

$file = "$PSScriptRoot\works.net"
$lines = [System.Collections.ArrayList]@()
$lines.Add("*Vertices $($allNodesTable.Count + $worksTable.Count)")
$sorted = $allNodesTable.GetEnumerator() | Sort-Object Value
$current = 0
for($i = 0; $i -lt $composers.Count; $i++){
    $str = "$($sorted[$current].Value)!$($sorted[$current].Name)!Composer"
    $lines.Add($str)
    $current++
}
for($i = 0; $i -lt $period.Count; $i++){
    $str = "$($sorted[$current].Value)!$($sorted[$current].Name)!Period"
    $lines.Add($str)
    $current++
}
for($i = 0; $i -lt $popularity.Count; $i++){
    $str = "$($sorted[$current].Value)!$($sorted[$current].Name)!Popularity"
    $lines.Add($str)
    $current++
}
for($i = 0; $i -lt $genres.Count; $i++){
    $str = "$($sorted[$current].Value)!$($sorted[$current].Name)!Genre"
    $lines.Add($str)
    $current++
}
for($i = 0; $i -lt $keys.Count; $i++){
    $str = "$($sorted[$current].Value)!$($sorted[$current].Name)!Key"
    $lines.Add($str)
    $current++
}
#$allNodes.GetEnumerator() | Sort-Object Value | ForEach-Object {
#    $str = "$($_.Value) `"$($_.Name)`""
#    $lines.Add($str)
#}
$worksTable.GetEnumerator() | Sort-Object Value | ForEach-Object {
    $str = "$($_.Value)!$(($_.Name.split("|"))[0])!Work"
    $lines.Add($str)
}
$lines.Add("*Edges $($edges.Count)")
$lines = $lines + $edges
Out-File -FilePath $file -InputObject $lines -Encoding utf8 -Force
