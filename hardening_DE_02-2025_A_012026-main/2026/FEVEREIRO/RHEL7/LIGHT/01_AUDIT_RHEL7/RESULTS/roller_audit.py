import pandas as pd

df = pd.read_csv("export.csv")

# Flags
df["is_pass"] = (df["compliance_result"] == "PASSED").astype(int)
df["is_fail"] = (df["compliance_result"] == "FAILED").astype(int)

# Score severidade
score_map = {"Alta": 3, "Média": 2, "Baixa": 1}
df["risk_score"] = df["compliance.info"].map(score_map).fillna(0)
df["risk_score_fail"] = df["risk_score"] * df["is_fail"]

# Chave composta
df["control_key"] = (
    df["compliance.audit_file"].astype(str)
    + "_"
    + df["compliance.control_id"].astype(str)
)

result = df[[
    "asset.id",
    "asset.host_name",
    "compliance.audit_file",
    "compliance.audit_see_also",
    "compliance.audit_solution",
    "compliance.control_id",
    "control_key",
    "compliance.info",
    "compliance_result",
    "is_pass",
    "is_fail",
    "risk_score",
    "risk_score_fail",
    "first_seen",
    "last_observed",
    "last_fixed"
]].copy()

result.columns = [
    "asset_id",
    "hostname",
    "audit_file",
    "baseline",
    "domain",
    "control_id",
    "control_key",
    "severity",
    "result",
    "is_pass",
    "is_fail",
    "risk_score",
    "risk_score_fail",
    "first_seen",
    "last_observed",
    "last_fixed"
]

with pd.ExcelWriter("RESULT.xlsx", engine="openpyxl") as writer:
    result.to_excel(writer, sheet_name="RESULT", index=False)
