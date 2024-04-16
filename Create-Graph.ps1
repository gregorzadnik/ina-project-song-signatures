$data = Invoke-RestMethod -Uri "https://api.openopus.org/work/dump.json" -Method Get
$keyWorks = [System.Collections.ArrayList]@()
$keysStr = "D flat major|D minor|E flat major|C minor|A minor|A major|G flat major|B flat major|C major|F major|G minor|D major|G major|E minor|E major|B minor|F minor|F sharp minor|C sharp major|A flat major|C sharp minor|E flat minor|B flat minor|B major|F sharp major|A flat minor|G sharp minor"
$keys = $keysStr.Split("|")
foreach($comp in $data.composers){
    foreach($work in $comp.works){
        $allWorks += 1
        foreach($key in $keys){
            if($work.title -match $key){
                $work | Add-Member -MemberType NoteProperty -Name 'key' -Value $key -Force
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

$composers = $data.composers.complete_name
$period = @("Medieval", "Renaissance", "Baroque", "Classical", "Early Romantic", "Romantic", "Late Romantic", "20th Century", "Post-War", "21st Century")
$popular = @("Popular", "Nonpopular")
$genres = @("Chamber", "Keyboard", "Orchestral", "Stage", "Vocal")
$allNodesList = $composers + $period + $popular + $genres + $keys
$allNodes = @{}
$worksTable = @{}
foreach($node in $allNodesList){
    $allNodes.Add($node, $allNodes.Count+1)
}
foreach($work in $keyWorks){
    $worksTable.Add("$($work.title)$($work.composer)", $allNodes.Count+$worksTable.Count+1)
}

$edges = [System.Collections.ArrayList]@()
foreach($work in $keyWorks){
    $keyID = $allNodes[$work.key]
    $composerID = $allNodes[$work.composer]
    $workID = $worksTable["$($work.title)$($work.composer)"]
    $periodID = $allNodes[$work.period]
    $genreID = $allNodes[$work.genre]
    $popularID = $allNodes[$work.popularity]
    $edges.Add("$workID $keyID")
    $edges.Add("$workID $composerID")
    $edges.Add("$workID $periodID")
    $edges.Add("$workID $genreID")
    $edges.Add("$workID $popularID")
}

$file = "$PSScriptRoot\works.net"
$lines = [System.Collections.ArrayList]@()
$lines.Add("*Vertices $($allNodes.Count + $worksTable.Count)")
$allNodes.GetEnumerator() | Sort-Object Value | ForEach-Object {
    $str = "$($_.Value) `"$($_.Name)`""
    $lines.Add($str)
}
$worksTable.GetEnumerator() | Sort-Object Value | ForEach-Object {
    $str = "$($_.Value) `"$($_.Name)`""
    $lines.Add($str)
}
$lines.Add("*arcs")
$lines = $lines + $edges
$lines | Out-File -FilePath $file -Encoding utf8 -Force
