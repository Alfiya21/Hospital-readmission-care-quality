"""End-to-end pipeline: load -> validate -> clean views -> risk model -> tiers -> Tableau exports."""
import sqlite3, pandas as pd, numpy as np, json, pathlib
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GroupKFold
from sklearn.metrics import roc_auc_score, average_precision_score
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

ROOT = pathlib.Path(__file__).resolve().parents[1]
DB = ROOT/"readmission.db"
if DB.exists(): DB.unlink()
con = sqlite3.connect(DB)
pd.read_csv(ROOT/"data/diabetic_data.csv", dtype={"diag_1":str,"diag_2":str,"diag_3":str}).to_sql("raw_encounters", con, index=False)

# 1. Validation
checks = []
for stmt in (ROOT/"sql/01_validation.sql").read_text().split(";"):
    if stmt.strip():
        n, v, note = con.execute(stmt).fetchone(); checks.append((n, v, note))
dq = pd.DataFrame(checks, columns=["check","count","note"]); dq.to_csv(ROOT/"docs/data_quality_checks.csv", index=False)

# 2. Clean + views
con.executescript((ROOT/"sql/02_clean_and_views.sql").read_text())
df = pd.read_sql("SELECT * FROM v_encounters_clean", con)

# 3. Risk model (patient-grouped out-of-fold scores so every encounter gets an honest score)
num = ["los_days","num_lab_procedures","num_procedures","num_medications","number_outpatient","number_emergency","number_inpatient","number_diagnoses"]
cat = ["age_group","race","gender","admission_type","admission_source","discharge_group","specialty","a1c_result","insulin","med_change","on_diabetes_med","primary_dx_group"]
X = pd.get_dummies(df[num+cat], columns=cat, dtype=float); y = df["readmit_30d"].values; g = df["patient_nbr"].values
oof_gb = np.zeros(len(df)); oof_lr = np.zeros(len(df))
for tr, te in GroupKFold(5).split(X, y, g):
    gb = HistGradientBoostingClassifier(max_depth=4, learning_rate=0.06, max_iter=250, l2_regularization=1.0, random_state=42).fit(X.iloc[tr], y[tr])
    oof_gb[te] = gb.predict_proba(X.iloc[te])[:,1]
    lr = make_pipeline(StandardScaler(), LogisticRegression(max_iter=500, C=0.1)).fit(X.iloc[tr], y[tr])
    oof_lr[te] = lr.predict_proba(X.iloc[te])[:,1]
metrics = {"gb_auc": roc_auc_score(y, oof_gb), "gb_pr_auc": average_precision_score(y, oof_gb),
           "lr_auc": roc_auc_score(y, oof_lr), "lr_pr_auc": average_precision_score(y, oof_lr), "base_rate": float(y.mean())}
df["risk_score"] = oof_gb
p50, p85 = np.quantile(oof_gb, [0.50, 0.85])
df["risk_tier"] = np.where(df.risk_score>=p85, "High", np.where(df.risk_score>=p50, "Medium", "Low"))
df[["encounter_id","risk_score","risk_tier"]].to_sql("risk_scores", con, index=False, if_exists="replace")
con.executescript("""
CREATE VIEW v_risk_tiers AS
SELECT s.risk_tier, COUNT(*) AS encounters, ROUND(100.0*AVG(c.readmit_30d),2) AS actual_readmit_30d_pct,
       ROUND(100.0*SUM(c.readmit_30d)/(SELECT SUM(readmit_30d) FROM v_encounters_clean),1) AS pct_of_all_readmissions
FROM risk_scores s JOIN v_encounters_clean c USING(encounter_id)
GROUP BY s.risk_tier ORDER BY CASE s.risk_tier WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;
""")
metrics["tier_cutoffs"] = [float(p50), float(p85)]

# top drivers via permutation importance on one fold-out sample
from sklearn.inspection import permutation_importance
tr, te = next(GroupKFold(5).split(X, y, g))
gbf = HistGradientBoostingClassifier(max_depth=4, learning_rate=0.06, max_iter=250, l2_regularization=1.0, random_state=42).fit(X.iloc[tr], y[tr])
pi = permutation_importance(gbf, X.iloc[te].sample(6000, random_state=1), y[te][X.iloc[te].index.map(lambda i: True)][:0].tolist() or y[te][:6000] if False else y[te][pd.Index(X.iloc[te].index).get_indexer(X.iloc[te].sample(6000, random_state=1).index)], scoring="roc_auc", n_repeats=3, random_state=1)
imp = pd.Series(pi.importances_mean, index=X.columns).sort_values(ascending=False).head(10)
metrics["top_drivers"] = {k: round(float(v),4) for k,v in imp.items()}

# 4. Exports for Tableau
out = ROOT/"tableau_exports"
df.drop(columns=["risk_score"]).assign(risk_score=df.risk_score.round(4)).to_csv(out/"encounters_scored.csv", index=False)
for v in ["v_kpi_overview","v_by_age","v_by_diagnosis","v_by_admission_type","v_by_discharge","v_by_prior_inpatient","v_by_a1c_med","v_risk_tiers"]:
    pd.read_sql(f"SELECT * FROM {v}", con).to_csv(out/f"{v}.csv", index=False)
json.dump(metrics, open(ROOT/"docs/model_metrics.json","w"), indent=2)
con.commit()
print(dq.to_string(index=False)); print(json.dumps(metrics, indent=1))
for v in ["v_kpi_overview","v_by_age","v_by_diagnosis","v_by_admission_type","v_by_discharge","v_by_prior_inpatient","v_risk_tiers"]:
    print("\n##", v); print(pd.read_sql(f"SELECT * FROM {v}", con).to_string(index=False))
