import ROOT
import json
ROOT.gStyle.SetOptStat(0)

# Load original JSON dictionary
with open("FullCLs_limits_summary.json") as f:
    data = json.load(f)

# Load full CLs JSON dictionary
#with open("limits_json_fullcls.json") as f:
#    data_cls = json.load(f)

# Sort mass points
masses = sorted(float(m) for m in data.keys())

# Graphs
g_exp = ROOT.TGraph()
g_obs = ROOT.TGraph()
g_1sigma = ROOT.TGraphAsymmErrors()
g_2sigma = ROOT.TGraphAsymmErrors()

#g_exp_cls = ROOT.TGraph()
#g_obs_cls = ROOT.TGraph()

for i, mass in enumerate(masses):
    mass_str = str(mass)
    values = data[mass_str]
    #values_cls = data_cls[mass_str]

    # Original (asymptotic) values
    g_obs.SetPoint(i, mass, values["obs"])
    g_exp.SetPoint(i, mass, values["exp0"])

    # ±1σ band
    err1_up = values["exp+1"] - values["exp0"]
    err1_dn = values["exp0"] - values["exp-1"]
    g_1sigma.SetPoint(i, mass, values["exp0"])
    g_1sigma.SetPointError(i, 0, 0, err1_dn, err1_up)

    # ±2σ band
    err2_up = values["exp+2"] - values["exp0"]
    err2_dn = values["exp0"] - values["exp-2"]
    g_2sigma.SetPoint(i, mass, values["exp0"])
    g_2sigma.SetPointError(i, 0, 0, err2_dn, err2_up)

    # Full CLs values
    #g_obs_cls.SetPoint(i, mass, values_cls["obs"])
    #g_exp_cls.SetPoint(i, mass, values_cls["exp0"])

# Style settings for original (black)
g_2sigma.SetFillColor(ROOT.TColor.GetColor("#85D1FB"))
g_2sigma.SetLineColor(ROOT.TColor.GetColor("#85D1FB"))

g_1sigma.SetFillColor(ROOT.TColor.GetColor("#FFDF7F"))
g_1sigma.SetLineColor(ROOT.TColor.GetColor("#FFDF7F"))

g_exp.SetLineStyle(2)
g_exp.SetLineWidth(2)
g_exp.SetLineColor(ROOT.kBlack)

g_obs.SetLineWidth(2)
g_obs.SetLineColor(ROOT.kBlack)
g_obs.SetMarkerStyle(20)
g_obs.SetMarkerSize(1.2)
g_obs.SetMarkerColor(ROOT.kBlack)

# Style settings for full CLs (red)
#g_exp_cls.SetLineStyle(2)
#g_exp_cls.SetLineWidth(2)
#g_exp_cls.SetLineColor(ROOT.kRed)

#g_obs_cls.SetLineWidth(2)
#g_obs_cls.SetLineColor(ROOT.kRed)
#g_obs_cls.SetMarkerStyle(20)
#g_obs_cls.SetMarkerSize(1.2)
#g_obs_cls.SetMarkerColor(ROOT.kRed)

# Frame
frame = ROOT.TH1F("frame", "", 1, min(masses)*0.95, max(masses)*1.05)
frame.SetMinimum(0.1)
frame.SetMaximum(10000)
frame.GetXaxis().SetTitle("M_{X} (GeV)")
frame.GetYaxis().SetTitle("#sigma_{95%} (X #rightarrow HH) (fb)")
frame.GetYaxis().SetTitleOffset(1.4)
frame.GetXaxis().SetTitleOffset(1.3)
frame.GetXaxis().SetLabelSize(0.04)
frame.GetYaxis().SetLabelSize(0.04)

# Canvas
c = ROOT.TCanvas("c", "", 800, 800)
c.SetLeftMargin(0.10)
#c.SetRightMargin(0.12)
c.SetTicky(1)
c.SetTickx(1)
c.SetLogy()
frame.Draw()

# Draw graphs
g_2sigma.Draw("3 SAME")
g_1sigma.Draw("3 SAME")
g_exp.Draw("L SAME")
g_obs.Draw("PL SAME")
#g_exp_cls.Draw("L SAME")
#g_obs_cls.Draw("PL SAME")

# Legend
#For Full CLS + Asymptotic
leg = ROOT.TLegend(0.46, 0.54, 0.78, 0.84)
#For only Full CLS or Asymptotic
leg = ROOT.TLegend(0.60, 0.54, 0.85, 0.84)
leg.SetBorderSize(0)
leg.SetFillStyle(0)
leg.SetTextFont(42)
leg.SetTextSize(0.037)
#leg.AddEntry(g_exp, "Expected (Asymptotic)", "PL")
leg.AddEntry(g_obs, "Observed", "PL")
leg.AddEntry(g_exp, "Expected", "PL")
#leg.AddEntry(g_obs_cls, "Observed (Full CLs)", "L")
#leg.AddEntry(g_exp_cls, "Expected (Full CLs)", "PL")
#leg.AddEntry(g_1sigma, "68% expected (Asymptotic)", "F")
#leg.AddEntry(g_2sigma, "95% expected (Asymptotic)", "F")
leg.AddEntry(g_1sigma, "#pm1 #sigma", "F")
leg.AddEntry(g_2sigma, "#pm2 #sigma", "F")
leg.Draw()

# CMS label
latex = ROOT.TLatex()
latex.SetNDC()
latex.SetTextFont(61)
latex.SetTextSize(0.05)
#latex.DrawLatex(0.10, 0.91, "CMS")
latex.DrawLatex(0.13, 0.82, "CMS")
latex.SetTextFont(52)
latex.SetTextSize(0.04)
#latex.DrawLatex(0.21, 0.91, "Preliminary")
latex.DrawLatex(0.24, 0.82, "Preliminary")
latex.SetTextFont(42)
latex.DrawLatex(0.63, 0.91, "138 fb^{-1} (13 TeV)")
latex.SetTextSize(0.035)
latex.DrawLatex(0.13, 0.75, "All channels combined")
latex.DrawLatex(0.13, 0.70, "spin - 0")

# Save
c.SaveAs("limit_plot_combined_FullCLs_paper.root")
c.SaveAs("limit_plot_combined_FullCLs_paper.pdf")
c.SaveAs("limit_plot_combined_FullCLs_paper.png")

