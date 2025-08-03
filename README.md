## Instructions (TO BE RUN ON LXPLUS): 

First, we need to set up **COMBINE** and **COMBINE harvester** followed by this repository:

```bash
cmsrel CMSSW_14_1_0_pre4
cd CMSSW_14_1_0_pre4/src
cmsenv
```

## Check out (as this can change) the recommended tag on the link below for COMBINE:
```bash
git -c advice.detachedHead=false clone --depth 1 --branch v10.2.1 https://github.com/cms-analysis/HiggsAnalysis-CombinedLimit.git HiggsAnalysis/CombinedLimit
```
## Checkout (As this can change) the recommended tag on the link below for COMBINE HARVESTOR

```bash
git clone https://github.com/cms-analysis/CombineHarvester.git CombineHarvester
cd CombineHarvester/
git checkout v3.0.0-pre1
cd $CMSSW_BASE/src
scram b -j 8
```


## Next, check out this Full CLs scripts repository:

```bash
cd $CMSSW_BASE/src
git clone https://github.com/gparida/FullCLs_scripts_XHbbtautau.git 
cd FullCLs_scripts_XHbbtautau/BTagVetoRegionForGraviton/Run2_Unblinding_forApproval_spin2
```

### IMPORTANT: Please check the contents of mass_grid_config_GravitonforApproval.txt. The commented mass points (starting with "#") will not be submitted to Condor. Please change that accordingly to which mass points you want to submit the jobs for..

### Command usage:
### source submit_condor_fullCLs.sh <config_file> <remote_workspace_path_scp_from_uwlogin> <UW login user name>

## Example for Spin-2 Graviton - Please run the following command (Please use/replace in the command your uwlogin username instead of "parida" which is shown in the example.):

```bash
source submit_condor_fullCLs_splitbatches.sh mass_grid_config_GravitonforApproval.txt /afs/hep.wisc.edu/user/parida/public/HHbbtt_Analysis_Scripts/StatisticalToolsCombine/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/FinalizingResultsForPreApp/BTagVetoRegionForGraviton/UNBLINDED_RESULTS/Run2_unblinded_May5/workspaces_run2 parida
```

### Note 1 : "/afs/hep.wisc.edu/user/parida/public/HHbbtt_Analysis_Scripts/StatisticalToolsCombine/CMSSW_11_3_4/src/HiggsAnalysis/CombinedLimit/FinalizingResultsForPreApp/BTagVetoRegionForGraviton/UNBLINDED_RESULTS/Run2_unblinded_May5/workspaces_run2" - this is the location where the workspaces for full run-2 cards are located on UWLOGIN for spin-2. They will be scp to lxplus by the bash script.

### Note 2: Although all the workspace files will be copied from UW, only the "UNCOMMENTED" mass points from "mass_grid_config_GravitonforApproval.txt" will be run

