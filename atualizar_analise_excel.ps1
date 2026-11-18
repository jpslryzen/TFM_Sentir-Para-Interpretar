param(
  [Parameter(Mandatory = $true)][string]$RawCsvPath,
  [Parameter(Mandatory = $true)][string]$WorkbookPath
)

$ErrorActionPreference = 'Stop'

function Get-Field($row, [string]$name) {
  $property = $row.PSObject.Properties[$name]
  if ($null -eq $property -or $null -eq $property.Value) { return '' }
  return [string]$property.Value
}

function Get-ScenarioName([string]$activity, [string]$scenario) {
  $index = 0
  if (-not [int]::TryParse($scenario, [ref]$index)) { return '' }
  if ($activity -eq 'activity3') {
    $names = @('Ameaca 1', 'Ameaca 2', 'Guarda alimento 1', 'Guarda alimento 2', 'Ludico 1', 'Ludico 2')
    if ($index -ge 0 -and $index -lt $names.Count) { return $names[$index] }
  }
  if ($activity -eq 'activity4') {
    $names = @('Abaixamento corporal', 'Afastamento', 'Desvio de cabeca e olhar', 'Levantamento de pata dianteira', 'Recuo corporal')
    if ($index -ge 0 -and $index -lt $names.Count) { return $names[$index] }
  }
  return ''
}

function Get-Sequence([string]$json, [bool]$timeline) {
  if ([string]::IsNullOrWhiteSpace($json)) { return '' }
  try {
    $entries = $json | ConvertFrom-Json
    $values = @()
    foreach ($entry in @($entries)) {
      $answer = [string]$entry.answer
      if ($timeline) {
        $milliseconds = 0.0
        if ([double]::TryParse($answer, [ref]$milliseconds)) {
          $answer = ('{0:N1} s' -f ($milliseconds / 1000.0)).Replace(',', '.')
        }
      }
      if ($answer) { $values += $answer }
    }
    return ($values -join ' > ')
  } catch { return '' }
}

function Get-LastTimelineValue([string]$json) {
  $sequence = Get-Sequence $json $true
  if ([string]::IsNullOrWhiteSpace($sequence)) { return '' }
  return ($sequence -split ' > ')[-1]
}

function Get-GrowlFromDetails([string]$details) {
  if ($details -match '(?:^|;)growl=([^;]+)') { return $Matches[1] }
  return ''
}

function Write-Table($workbook, [string]$sheetName, [string]$tableName, [object[]]$rows, [int[]]$textColumns = @()) {
  $sheet = $workbook.Worksheets.Item($sheetName)
  $table = $sheet.ListObjects.Item($tableName)
  $columnCount = $table.ListColumns.Count
  $topLeft = $table.Range.Cells.Item(1, 1)
  $rowCount = [Math]::Max($rows.Count, 1)
  $bottomRight = $sheet.Cells.Item($topLeft.Row + $rowCount, $topLeft.Column + $columnCount - 1)
  $table.Resize($sheet.Range($topLeft, $bottomRight))
  $table.DataBodyRange.ClearContents()
  foreach ($columnIndex in $textColumns) {
    $table.ListColumns.Item($columnIndex).DataBodyRange.NumberFormat = '@'
  }
  if ($rows.Count -eq 0) { return }

  $matrix = New-Object 'object[,]' $rows.Count, $columnCount
  for ($rowIndex = 0; $rowIndex -lt $rows.Count; $rowIndex++) {
    $values = @($rows[$rowIndex])
    for ($columnIndex = 0; $columnIndex -lt $columnCount; $columnIndex++) {
      $matrix[$rowIndex, $columnIndex] = if ($columnIndex -lt $values.Count) { $values[$columnIndex] } else { '' }
    }
  }
  $table.DataBodyRange.Value2 = $matrix
}

if (-not (Test-Path -LiteralPath $RawCsvPath)) { throw "CSV de dados nao encontrado: $RawCsvPath" }
if (-not (Test-Path -LiteralPath $WorkbookPath)) { throw "Livro de analise nao encontrado: $WorkbookPath" }

$allRows = @(Import-Csv -LiteralPath $RawCsvPath -Delimiter ';' -Encoding UTF8)
for ($i = 0; $i -lt $allRows.Count; $i++) {
  Add-Member -InputObject $allRows[$i] -NotePropertyName '_row_index' -NotePropertyValue $i -Force
}

$responses = @($allRows | Where-Object { (Get-Field $_ 'record_type') -eq 'response' })
$events = @($allRows | Where-Object { (Get-Field $_ 'record_type') -eq 'event' })

$activity3Rows = New-Object System.Collections.Generic.List[object]
$a3BehaviorRows = @($responses | Where-Object {
  (Get-Field $_ 'activity_id') -eq 'activity3' -and (Get-Field $_ 'response_stage') -eq 'justification_behavior'
})
foreach ($behavior in $a3BehaviorRows) {
  $participant = Get-Field $behavior 'participant_id'
  $session = Get-Field $behavior 'session_id'
  $scenario = Get-Field $behavior 'scenario_index'
  $matchingResponses = @($responses | Where-Object {
    (Get-Field $_ 'participant_id') -eq $participant -and
    (Get-Field $_ 'session_id') -eq $session -and
    (Get-Field $_ 'activity_id') -eq 'activity3' -and
    (Get-Field $_ 'scenario_index') -eq $scenario
  })
  $growl = @($matchingResponses | Where-Object { (Get-Field $_ 'response_stage') -eq 'growl_choice' } | Select-Object -Last 1)[0]
  $cues = @($matchingResponses | Where-Object { (Get-Field $_ 'response_stage') -eq 'justification_sound_cues' } | Select-Object -Last 1)[0]
  $matchingEvents = @($events | Where-Object {
    (Get-Field $_ 'participant_id') -eq $participant -and
    (Get-Field $_ 'session_id') -eq $session -and
    (Get-Field $_ 'activity') -eq 'activity3' -and
    (Get-Field $_ 'scenario_index') -eq $scenario
  })
  $plays = @($matchingEvents | Where-Object { (Get-Field $_ 'event') -eq 'activity3_growl_sound_play' })
  $playLabels = @($plays | ForEach-Object { Get-GrowlFromDetails (Get-Field $_ 'details') } | Where-Object { $_ })
  $afterGrowl = if ($null -ne $growl) { @($plays | Where-Object { $_._row_index -gt $growl._row_index }) } else { @() }
  $scenarioLabel = if ($scenario -match '^\d+$') { 'Cenario ' + ([int]$scenario + 1) } else { $scenario }
  $activity3Rows.Add(@(
    $participant,
    (Get-Field $behavior 'condition'),
    $scenarioLabel,
    (Get-ScenarioName 'activity3' $scenario),
    (Get-Field $growl 'selected_answer'),
    (Get-Field $growl 'answer_changes'),
    $plays.Count,
    ($playLabels -join ' > '),
    $afterGrowl.Count,
    (Get-Field $cues 'selected_answer'),
    (Get-Sequence (Get-Field $cues 'answer_sequence') $false),
    (Get-Field $behavior 'selected_answer'),
    (Get-Field $behavior 'correct_answer'),
    (Get-Field $behavior 'error_type'),
    (Get-Field $behavior 'answer_changes'),
    (Get-Sequence (Get-Field $behavior 'answer_sequence') $false),
    @($matchingEvents | Where-Object { (Get-Field $_ 'event') -eq 'observation_repeat' }).Count
  ))
}

$activity4Rows = New-Object System.Collections.Generic.List[object]
$a4InterpretationRows = @($responses | Where-Object {
  (Get-Field $_ 'activity_id') -eq 'activity4' -and (Get-Field $_ 'response_stage') -eq 'interpretation'
})
foreach ($interpretation in $a4InterpretationRows) {
  $participant = Get-Field $interpretation 'participant_id'
  $session = Get-Field $interpretation 'session_id'
  $scenario = Get-Field $interpretation 'scenario_index'
  $matchingEvents = @($events | Where-Object {
    (Get-Field $_ 'participant_id') -eq $participant -and
    (Get-Field $_ 'session_id') -eq $session -and
    (Get-Field $_ 'activity') -eq 'activity4' -and
    (Get-Field $_ 'scenario_index') -eq $scenario
  })
  $scenarioLabel = if ($scenario -match '^\d+$') { 'Cenario ' + ([int]$scenario + 1) } else { $scenario }
  $activity4Rows.Add(@(
    $participant,
    (Get-Field $interpretation 'condition'),
    $scenarioLabel,
    (Get-ScenarioName 'activity4' $scenario),
    (Get-Field $interpretation 'mark_order'),
    (Get-LastTimelineValue (Get-Field $interpretation 'timeline_answer_sequence')),
    (Get-Field $interpretation 'selected_answer'),
    (Get-Field $interpretation 'correct_answer'),
    (Get-Field $interpretation 'timeline_answer_changes'),
    (Get-Sequence (Get-Field $interpretation 'timeline_answer_sequence') $true),
    (Get-Field $interpretation 'answer_changes'),
    (Get-Sequence (Get-Field $interpretation 'answer_sequence') $false),
    @($matchingEvents | Where-Object { (Get-Field $_ 'event') -eq 'observation_repeat' }).Count
  ))
}

$ratingRows = New-Object System.Collections.Generic.List[object]
foreach ($rating in @($responses | Where-Object { (Get-Field $_ 'response_stage') -eq 'scenario_ratings' })) {
  $activity = Get-Field $rating 'activity_id'
  $scenario = Get-Field $rating 'scenario_index'
  $activityLabel = if ($activity -eq 'activity3') { 'Rosnados' } elseif ($activity -eq 'activity4') { 'Mudanca de comportamento' } else { $activity }
  $scenarioLabel = if ($scenario -match '^\d+$') { 'Cenario ' + ([int]$scenario + 1) } else { $scenario }
  $ratingRows.Add(@(
    (Get-Field $rating 'participant_id'),
    (Get-Field $rating 'condition'),
    $activityLabel,
    $scenarioLabel,
    (Get-ScenarioName $activity $scenario),
    (Get-Field $rating 'interpretation_confidence'),
    (Get-Field $rating 'mental_effort'),
    (Get-Field $rating 'perceived_difficulty')
  ))
}

$summaryRows = New-Object System.Collections.Generic.List[object]
$participants = @($responses | ForEach-Object { [PSCustomObject]@{ Id = Get-Field $_ 'participant_id'; Condition = Get-Field $_ 'condition' } } | Sort-Object Id, Condition -Unique)
foreach ($entry in $participants) {
  $participantResponses = @($responses | Where-Object { (Get-Field $_ 'participant_id') -eq $entry.Id -and (Get-Field $_ 'condition') -eq $entry.Condition })
  $participantEvents = @($events | Where-Object { (Get-Field $_ 'participant_id') -eq $entry.Id -and (Get-Field $_ 'condition') -eq $entry.Condition })
  $a3Behavior = @($participantResponses | Where-Object { (Get-Field $_ 'activity_id') -eq 'activity3' -and (Get-Field $_ 'response_stage') -eq 'justification_behavior' })
  $a4Behavior = @($participantResponses | Where-Object { (Get-Field $_ 'activity_id') -eq 'activity4' -and (Get-Field $_ 'response_stage') -eq 'interpretation' })
  $ratings = @($participantResponses | Where-Object { (Get-Field $_ 'response_stage') -eq 'scenario_ratings' })
  $confidence = @($ratings | ForEach-Object { $value = 0.0; if ([double]::TryParse((Get-Field $_ 'interpretation_confidence'), [ref]$value)) { $value } })
  $effort = @($ratings | ForEach-Object { $value = 0.0; if ([double]::TryParse((Get-Field $_ 'mental_effort'), [ref]$value)) { $value } })
  $difficulty = @($ratings | ForEach-Object { $value = 0.0; if ([double]::TryParse((Get-Field $_ 'perceived_difficulty'), [ref]$value)) { $value } })
  $confidenceAverage = if ($confidence.Count) { [Math]::Round((($confidence | Measure-Object -Average).Average), 2) } else { '' }
  $effortAverage = if ($effort.Count) { [Math]::Round((($effort | Measure-Object -Average).Average), 2) } else { '' }
  $difficultyAverage = if ($difficulty.Count) { [Math]::Round((($difficulty | Measure-Object -Average).Average), 2) } else { '' }
  $summaryRows.Add(@(
    $entry.Id,
    $entry.Condition,
    (@($a3Behavior | Where-Object { (Get-Field $_ 'is_correct') -eq 'true' }).Count.ToString() + '/' + $a3Behavior.Count),
    @($participantEvents | Where-Object { (Get-Field $_ 'event') -eq 'activity3_growl_sound_play' }).Count,
    @($participantEvents | Where-Object { (Get-Field $_ 'activity') -eq 'activity3' -and (Get-Field $_ 'event') -eq 'observation_repeat' }).Count,
    (@($a4Behavior | Where-Object { (Get-Field $_ 'is_correct') -eq 'true' }).Count.ToString() + '/' + $a4Behavior.Count),
    @($participantEvents | Where-Object { (Get-Field $_ 'activity') -eq 'activity4' -and (Get-Field $_ 'event') -eq 'observation_repeat' }).Count,
    $confidenceAverage,
    $effortAverage,
    $difficultyAverage
  ))
}

$excel = $null
$workbook = $null
try {
  $excel = New-Object -ComObject Excel.Application
  $excel.Visible = $false
  $excel.DisplayAlerts = $false
  $workbook = $excel.Workbooks.Open((Resolve-Path -LiteralPath $WorkbookPath).Path)
  Write-Table $workbook 'Resumo' 'ResumoParticipantes' $summaryRows.ToArray() @(3, 6)
  Write-Table $workbook 'Atividade 3' 'TabelaAtividade3' $activity3Rows.ToArray()
  Write-Table $workbook 'Atividade 4' 'TabelaAtividade4' $activity4Rows.ToArray()
  Write-Table $workbook 'Escalas' 'TabelaEscalas' $ratingRows.ToArray()
  $workbook.Save()
  $workbook.Close($true)
  $workbook = $null
} finally {
  if ($null -ne $workbook) { $workbook.Close($false) }
  if ($null -ne $excel) {
    $excel.Quit()
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($excel)
  }
}
