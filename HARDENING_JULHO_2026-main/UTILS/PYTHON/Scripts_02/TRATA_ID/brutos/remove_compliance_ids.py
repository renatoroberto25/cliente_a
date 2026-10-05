#!/usr/bin/env python3
"""Remove dos CSV/XLSX da pasta as linhas com IDs listados em todo.md."""

from __future__ import annotations

import re
from pathlib import Path

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent
TODO = BASE_DIR / "todo.md"
COLUMN = "compliance.audit_name"
OUTPUT_SUFFIX = "_sem_ids"


def load_ids() -> set[str]:
    if not TODO.is_file():
        raise FileNotFoundError(f"Arquivo não encontrado: {TODO}")

    return {
        str(int(value))
        for value in re.findall(r"\d+", TODO.read_text(encoding="utf-8"))
    }


def find_spreadsheets() -> list[Path]:
    exts = ("*.xlsx", "*.csv")
    files = []
    for ext in exts:
        files.extend(
            path
            for path in BASE_DIR.glob(ext)
            if not path.name.startswith("~$")
            and not path.stem.endswith(OUTPUT_SUFFIX)
        )
    return sorted(files)


def extract_id(series: pd.Series) -> pd.Series:
    values = series.astype("string").str.extract(r"^\s*0*(\d+)", expand=False)
    return values.str.lstrip("0").replace("", "0")


def process_frame(frame: pd.DataFrame, ids: set[str]) -> tuple[pd.DataFrame, int, bool]:
    if COLUMN not in frame.columns:
        return frame, 0, False
    remove = extract_id(frame[COLUMN]).isin(ids)
    removed = int(remove.sum())
    return frame.loc[~remove].copy(), removed, True


def main() -> None:
    ids = load_ids()
    files = find_spreadsheets()

    if not ids:
        raise RuntimeError("Nenhum ID numérico encontrado em todo.md")
    if not files:
        raise RuntimeError(f"Nenhuma planilha .xlsx/.csv encontrada em {BASE_DIR}")

    print(f"IDs carregados: {len(ids)}")
    print(f"Planilhas encontradas: {len(files)}")

    total_removed = 0
    for source in files:
        removed_from_file = 0
        column_found = False

        if source.suffix.lower() == ".csv":
            frame = pd.read_csv(source, low_memory=False)
            frame, removed_from_file, column_found = process_frame(frame, ids)
            output = source.with_name(f"{source.stem}{OUTPUT_SUFFIX}{source.suffix}")
            frame.to_csv(output, index=False)
        else:
            sheets = pd.read_excel(source, sheet_name=None)
            for sheet_name, frame in sheets.items():
                frame, removed, found = process_frame(frame, ids)
                sheets[sheet_name] = frame
                removed_from_file += removed
                column_found = column_found or found

            output = source.with_name(f"{source.stem}{OUTPUT_SUFFIX}{source.suffix}")
            with pd.ExcelWriter(output, engine="openpyxl") as writer:
                for sheet_name, frame in sheets.items():
                    frame.to_excel(writer, sheet_name=sheet_name, index=False)

        total_removed += removed_from_file
        note = "" if column_found else f" (coluna '{COLUMN}' não encontrada)"
        print(
            f"{source.name}: {removed_from_file} linhas removidas -> "
            f"{output.name}{note}"
        )

    print(f"Concluído: {total_removed} linhas removidas")


if __name__ == "__main__":
    main()