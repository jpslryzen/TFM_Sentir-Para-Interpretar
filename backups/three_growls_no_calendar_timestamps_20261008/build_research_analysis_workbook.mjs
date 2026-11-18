import fs from "node:fs/promises";
import path from "node:path";
import { Workbook, SpreadsheetFile } from "file:///C:/Users/Ryzen/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const sourceCsv = "C:/Users/Ryzen/Documents/Prototipo/Interface Atividades/UserInterface_bHaptics_processing/data/research_logs/research_data.csv";
const outputPath = "C:/Users/Ryzen/Documents/Prototipo/Interface Atividades/UserInterface_bHaptics_processing/data/research_logs/analise_dados_instrumento.xlsx";

const OLD_CUE_PATTERN = /Som grave|Som cont[ií]nuo|Pausas curtas|Som mais agudo|Som intermitente|Pausas longas|Rosnado curto|Ritmo r[aá]pido|Intensidade baixa|Rosnado prolongado|Ritmo lento|Intensidade alta/i;
const activity3Names = [
  "Ameaça: cenário 1",
  "Ameaça: cenário 2",
  "Guarda de alimento: cenário 1",
  "Guarda de alimento: cenário 2",
  "Lúdico: cenário 1",
  "Lúdico: cenário 2",
];
const activity4Names = [
  "Abaixamento corporal",
  "Afastamento",
  "Desvio de olhar e cabeça",
  "Levantamento de pata dianteira",
  "Recuo corporal",
];

function parseDelimited(text) {
  const rows = [];
  let row = [];
  let field = "";
  let inQuotes = false;

  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    if (char === '"') {
      if (inQuotes && text[i + 1] === '"') {
        field += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ";" && !inQuotes) {
      row.push(field);
      field = "";
    } else if ((char === "\n" || char === "\r") && !inQuotes) {
      if (char === "\r" && text[i + 1] === "\n") i++;
      row.push(field);
      if (row.some((value) => value !== "")) rows.push(row);
      row = [];
      field = "";
    } else {
      field += char;
    }
  }
  if (field !== "" || row.length) {
    row.push(field);
    if (row.some((value) => value !== "")) rows.push(row);
  }
  return rows;
}

function rowsFromCsv(text) {
  const parsed = parseDelimited(text.replace(/^\uFEFF/, ""));
  const headers = parsed.shift();
  return parsed.map((cells, index) => {
    const record = { _index: index };
    headers.forEach((header, column) => {
      record[header] = cells[column] ?? "";
    });
    return record;
  });
}

function numeric(value) {
  if (value === null || value === undefined || value === "") return null;
  const result = Number(value);
  return Number.isFinite(result) ? result : null;
}

function seconds(value) {
  const milliseconds = numeric(value);
  return milliseconds === null ? null : milliseconds / 1000;
}

function yesNo(value) {
  if (value === true || String(value).toLowerCase() === "true") return "Sim";
  if (value === false || String(value).toLowerCase() === "false") return "Não";
  return "";
}

function mean(values) {
  const valid = values.filter((value) => value !== null && value !== undefined);
  if (!valid.length) return null;
  return valid.reduce((sum, value) => sum + value, 0) / valid.length;
}

function detailsValue(details, key) {
  const match = String(details ?? "").match(new RegExp(`(?:^|;)${key}=([^;]*)`));
  return match ? match[1] : "";
}

function activityName(activityId, scenarioIndex) {
  const index = numeric(scenarioIndex);
  if (activityId === "activity3") return activity3Names[index] ?? `Cenário ${index + 1}`;
  if (activityId === "activity4") return activity4Names[index] ?? `Cenário ${index + 1}`;
  return "";
}

function recordCondition(records) {
  const row = records.find((record) => record.condition);
  if (!row) return "";
  const condition = row.condition.toLowerCase();
  if (condition.includes("multi") || condition === "avh") return "Multissensorial (AVH)";
  if (condition.includes("control") || condition === "av") return "Controlo (AV)";
  return row.condition;
}

function firstNonEmpty(records, field) {
  return records.find((record) => record[field])?.[field] ?? "";
}

function schemaVersion(text) {
  return OLD_CUE_PATTERN.test(String(text ?? "")) ? "V1: 12 pistas" : "V2: 6 pistas";
}

function choiceSequence(value, kind = "answer") {
  if (!value) return "";
  try {
    const entries = JSON.parse(value);
    if (!Array.isArray(entries)) return "";
    return entries.map((entry) => {
      const elapsed = numeric(entry.elapsed_ms);
      const label = entry.answer ?? "";
      if (kind === "time" && label !== "") return `00:${(Number(label) / 1000).toFixed(1).padStart(4, "0")}`;
      return elapsed === null ? label : `${label} (${(elapsed / 1000).toFixed(1)} s)`;
    }).join(" > ");
  } catch {
    return "";
  }
}

function addSheetTitle(sheet, title, note) {
  sheet.showGridLines = false;
  sheet.getRange("A2").values = [[title]];
  sheet.getRange("A2").format = {
    font: { name: "Arial", size: 15, bold: true, color: "#1F2937" },
    verticalAlignment: "center",
  };
  sheet.getRange("A3").values = [[note]];
  sheet.getRange("A3").format = {
    font: { name: "Arial", size: 10, italic: true, color: "#4B5563" },
    verticalAlignment: "center",
  };
  sheet.getRange("A2:Z2").format.borders = { bottom: { style: "thin", color: "#CBD5E1" } };
}

function writeTable(sheet, startRow, headers, values, tableName, widths = {}) {
  const startColumn = 0;
  const rows = [headers, ...values];
  sheet.getRangeByIndexes(startRow, startColumn, rows.length, headers.length).values = rows;
  const tableRange = sheet.getRangeByIndexes(startRow, startColumn, rows.length, headers.length);
  const table = sheet.tables.add(tableRange, true, tableName);
  table.style = "TableStyleMedium2";
  const headerRange = sheet.getRangeByIndexes(startRow, startColumn, 1, headers.length);
  headerRange.format = {
    fill: "#1F4E78",
    font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    wrapText: true,
  };
  const bodyRange = sheet.getRangeByIndexes(startRow + 1, startColumn, Math.max(values.length, 1), headers.length);
  bodyRange.format.font = { name: "Arial", size: 10, color: "#1F2937" };
  bodyRange.format.verticalAlignment = "center";
  bodyRange.format.wrapText = true;
  for (const [column, width] of Object.entries(widths)) {
    sheet.getRange(`${column}:${column}`).format.columnWidth = width;
  }
  sheet.freezePanes.freezeRows(startRow + 1);
  return { table, headerRow: startRow + 1, endRow: startRow + rows.length };
}

function colorCorrectness(sheet, range) {
  sheet.getRange(range).conditionalFormats.add("containsText", {
    text: "Sim",
    format: { fill: "#DCFCE7", font: { color: "#166534", bold: true } },
  });
  sheet.getRange(range).conditionalFormats.add("containsText", {
    text: "Não",
    format: { fill: "#FEE2E2", font: { color: "#991B1B", bold: true } },
  });
}

const csvText = await fs.readFile(sourceCsv, "utf8");
const rows = rowsFromCsv(csvText);
const participantIds = [...new Set(rows.map((row) => row.participant_id).filter(Boolean))].sort();

const participantRows = [];
const activity3Rows = [];
const activity4Rows = [];
const ratingRows = [];

for (const participantId of participantIds) {
  const participantRecords = rows.filter((row) => row.participant_id === participantId);
  const condition = recordCondition(participantRecords);
  const a3Growls = participantRecords.filter((row) => row.activity_id === "activity3" && row.record_type === "response" && row.step === "growl_choice");
  const a3Behaviors = participantRecords.filter((row) => row.activity_id === "activity3" && row.record_type === "response" && row.step === "justification_behavior");
  const a4Marks = participantRecords.filter((row) => row.activity_id === "activity4" && row.record_type === "response" && row.step === "interpretation");
  const ratings = participantRecords.filter((row) => row.event === "scenario_ratings_confirm");
  const a3Plays = participantRecords.filter((row) => row.event === "activity3_growl_sound_play");
  const a3Repeats = participantRecords.filter((row) => row.event === "observation_repeat" && (row.activity === "activity3" || row.activity_id === "activity3"));
  const a4Repeats = participantRecords.filter((row) => row.event === "observation_repeat" && (row.activity === "activity4" || row.activity_id === "activity4"));

  participantRows.push([
    participantId,
    condition,
    a3Behaviors.filter((row) => String(row.is_correct).toLowerCase() === "true").length,
    a3Plays.length,
    a3Repeats.length,
    a4Marks.filter((row) => detailsValue(row.details, "behavior_ok") === "true").length,
    a4Repeats.length,
    mean(ratings.map((row) => numeric(row.interpretation_confidence))),
    mean(ratings.map((row) => numeric(row.mental_effort))),
    mean(ratings.map((row) => numeric(row.perceived_difficulty))),
  ]);

  for (const growlRow of a3Growls) {
    const scenario = numeric(growlRow.scenario_index);
    const behaviorRow = a3Behaviors.find((row) => numeric(row.scenario_index) === scenario);
    const soundRow = participantRecords.find((row) => row.activity_id === "activity3" && row.record_type === "response" && row.step === "justification_sound_cues" && numeric(row.scenario_index) === scenario);
    const choiceConfirmedIndex = participantRecords.find((row) => row.event === "task_confirmed" && row.activity_id === "activity3" && row.step === "growl_choice" && numeric(row.scenario_index) === scenario)?._index ?? Number.MAX_SAFE_INTEGER;
    const justificationConfirmedIndex = participantRecords.find((row) => row.event === "task_confirmed" && row.activity_id === "activity3" && row.step === "justification" && numeric(row.scenario_index) === scenario)?._index ?? Number.MAX_SAFE_INTEGER;
    const allPlays = a3Plays.filter((row) => numeric(row.scenario_index) === scenario);
    const screen2Plays = allPlays.filter((row) => row._index > choiceConfirmedIndex && row._index < justificationConfirmedIndex);

    activity3Rows.push([
      participantId,
      condition,
      scenario + 1,
      activityName("activity3", scenario),
      growlRow.selected_answer,
      numeric(growlRow.answer_changes),
      allPlays.length,
      allPlays.map((row) => detailsValue(row.details, "growl")).filter(Boolean).join(" > "),
      screen2Plays.length,
      soundRow?.selected_answer ?? "",
      choiceSequence(soundRow?.answer_sequence ?? ""),
      behaviorRow?.selected_answer ?? "",
      yesNo(behaviorRow?.is_correct),
      behaviorRow?.error_type ?? "",
      numeric(behaviorRow?.answer_changes),
      choiceSequence(behaviorRow?.answer_sequence ?? ""),
      participantRecords.filter((row) => row.event === "observation_repeat" && (row.activity === "activity3" || row.activity_id === "activity3") && numeric(row.scenario_index) === scenario).length,
    ]);
  }

  for (const row of a4Marks) {
    const scenario = numeric(row.scenario_index);
    activity4Rows.push([
      participantId,
      condition,
      scenario + 1,
      activityName("activity4", scenario),
      numeric(row.mark_order),
      detailsValue(row.details, "marked_time"),
      row.selected_answer,
      yesNo(detailsValue(row.details, "behavior_ok")),
      numeric(row.timeline_answer_changes),
      choiceSequence(row.timeline_answer_sequence, "time"),
      numeric(row.answer_changes),
      choiceSequence(row.answer_sequence),
      numeric(row.mark_order) === 1 ? participantRecords.filter((repeat) => repeat.event === "observation_repeat" && (repeat.activity === "activity4" || repeat.activity_id === "activity4") && numeric(repeat.scenario_index) === scenario).length : "",
    ]);
  }

  for (const rating of ratings) {
    const scenario = numeric(rating.scenario_index);
    ratingRows.push([
      participantId,
      condition,
      rating.activity_id === "activity3" ? "Rosnados caninos" : "Mudança de comportamento",
      scenario + 1,
      activityName(rating.activity_id, scenario),
      numeric(rating.interpretation_confidence),
      numeric(rating.mental_effort),
      numeric(rating.perceived_difficulty),
    ]);
  }

}

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Resumo");
const activity3 = workbook.worksheets.add("Atividade 3");
const activity4 = workbook.worksheets.add("Atividade 4");
const ratingsSheet = workbook.worksheets.add("Escalas");

addSheetTitle(summary, "Resumo das medidas", "Apenas medidas previstas para a análise quantitativa no protocolo.");

const summaryHeaders = [
  "Participante", "Condição", "A3: comportamentos corretos", "A3: audições", "A3: repetições", "A4: comportamentos corretos", "A4: repetições", "Confiança média (1-5)", "Esforço mental médio (1-9)", "Dificuldade média (1-5)",
];
writeTable(summary, 4, summaryHeaders, participantRows, "ResumoParticipantes", {
  A: 18, B: 22, C: 22, D: 14, E: 16, F: 23, G: 16, H: 18, I: 22, J: 22,
});
summary.getRange(`H6:J${5 + participantRows.length}`).format.numberFormat = "0.0";

addSheetTitle(activity3, "Atividade 3: Rosnados caninos", "Uma linha por cenário, com as respostas e dados complementares definidos no protocolo.");
const a3Headers = [
  "Participante", "Condição", "Cenário", "Nome do cenário", "Rosnado escolhido", "Alterações na escolha", "N.º de audições", "Ordem das audições", "Audições no 2.º ecrã", "Pistas selecionadas", "Histórico das pistas selecionadas", "Comportamento selecionado", "Comportamento correto", "Tipo de erro no comportamento", "Alterações no comportamento", "Histórico da escolha do comportamento", "Repetições da observação",
];
writeTable(activity3, 4, a3Headers, activity3Rows, "TabelaAtividade3", {
  A: 18, B: 22, C: 10, D: 28, E: 18, F: 16, G: 14, H: 34, I: 17, J: 42, K: 34, L: 30, M: 20, N: 24, O: 20, P: 34, Q: 20,
});
colorCorrectness(activity3, `M6:M${5 + activity3Rows.length}`);

addSheetTitle(activity4, "Atividade 4: Mudança de comportamento", "Uma linha por marcação temporal. O cenário de desvio de olhar e cabeça tem duas marcações.");
const a4Headers = [
  "Participante", "Condição", "Cenário", "Nome do cenário", "Marcação", "Tempo escolhido", "Comportamento selecionado", "Comportamento correto", "Alterações na linha temporal", "Histórico das marcações temporais", "Alterações no comportamento", "Histórico da escolha do comportamento", "Repetições da observação",
];
writeTable(activity4, 4, a4Headers, activity4Rows, "TabelaAtividade4", {
  A: 18, B: 22, C: 10, D: 30, E: 11, F: 15, G: 30, H: 18, I: 22, J: 34, K: 22, L: 34, M: 22,
});
colorCorrectness(activity4, `H6:H${5 + activity4Rows.length}`);

addSheetTitle(ratingsSheet, "Escalas após cada cenário", "Confiança: 1 a 5. Esforço mental: 1 a 9. Dificuldade percebida: 1 a 5.");
const ratingHeaders = ["Participante", "Condição", "Atividade", "Cenário", "Nome do cenário", "Confiança", "Esforço mental", "Dificuldade percebida"];
writeTable(ratingsSheet, 4, ratingHeaders, ratingRows, "TabelaEscalas", { A: 18, B: 22, C: 26, D: 10, E: 30, F: 13, G: 16, H: 21 });
ratingsSheet.getRange(`F6:H${5 + ratingRows.length}`).format.horizontalAlignment = "center";

workbook.recalculate();

const checks = [
  await workbook.inspect({ kind: "table", range: "Resumo!A2:L12", include: "values,formulas", tableMaxRows: 12, tableMaxCols: 12 }),
  await workbook.inspect({ kind: "table", range: "Atividade 3!A2:T16", include: "values,formulas", tableMaxRows: 16, tableMaxCols: 20 }),
  await workbook.inspect({ kind: "table", range: "Atividade 4!A2:N18", include: "values,formulas", tableMaxRows: 18, tableMaxCols: 14 }),
  await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!", options: { useRegex: true, maxResults: 100 }, summary: "final formula error scan" }),
];

for (const check of checks) {
  if (check.ndjson) console.log(check.ndjson);
}

await fs.mkdir(path.dirname(outputPath), { recursive: true });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);

const previewRanges = {
  "Resumo": "A1:L12",
  "Atividade 3": "A1:T18",
  "Atividade 4": "A1:N18",
  "Escalas": "A1:H20",
};
const previewDir = "C:/Users/Ryzen/Documents/Codex/2026-07-30/es/workbook_previews";
await fs.mkdir(previewDir, { recursive: true });
for (const [sheetName, range] of Object.entries(previewRanges)) {
  const preview = await workbook.render({ sheetName, range, scale: 1, format: "png" });
  const previewPath = path.join(previewDir, `preview_${sheetName.replace(/ /g, "_")}.png`);
  await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));
}
console.log(`OUTPUT=${outputPath}`);
