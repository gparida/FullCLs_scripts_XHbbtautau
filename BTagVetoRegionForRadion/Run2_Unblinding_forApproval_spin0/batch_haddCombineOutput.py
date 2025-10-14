#!/usr/bin/env python3

import os
import glob
import subprocess
import ROOT
from tqdm import tqdm

# Pattern for mass point directories
mass_point_dirs = sorted(glob.glob("fullCLs_mass_*"))

# File pattern
pattern = "higgsCombine_obsAsimov*.root"

# Max files per hadd
batch_size = 2000

for mass_dir in mass_point_dirs:
    print(f"\n==============================")
    print(f"📦 Processing mass point: {mass_dir}")
    print(f"==============================")

    # Gather all ROOT files from all batch_* subdirectories
    subdirs = sorted(glob.glob(os.path.join(mass_dir, "batch_*")))
    if not subdirs:
        print(f"⚠️ No batch_* directories found in {mass_dir}, skipping...")
        continue

    all_files = []
    print (f"All the subdirectories inside {mass_dir} = ",subdirs)
    for sub in subdirs:
        found = sorted(glob.glob(os.path.join(sub, pattern)))
        all_files.extend(found)

    print(f"Total ROOT files found: {len(all_files)}")

    # Validate ROOT files
    valid_files = []
    print("🔍 Validating ROOT files...\n")
    for f in tqdm(all_files, desc="Checking files", unit="file"):
        try:
            tf = ROOT.TFile.Open(f, "READ")
            if tf and not tf.IsZombie() and tf.IsOpen():
                valid_files.append(f)
                tf.Close()
            else:
                print(f"\n⚠️ Skipping corrupted file: {f}")
                if tf:
                    tf.Close()
        except Exception as e:
            print(f"\n❌ Error with file {f}: {e}")

    print(f"\n✅ Total valid ROOT files: {len(valid_files)}")

    if not valid_files:
        print(f"⚠️ No valid files for {mass_dir}, skipping...")
        continue

    # Output dirs
    output_dir = os.path.join(mass_dir, "BatchMerged_output")
    os.makedirs(output_dir, exist_ok=True)

    chunk_files = []

    # Merge in batches of <= 2000
    for i in range(0, len(valid_files), batch_size):
        batch = valid_files[i:i + batch_size]
        batch_num = i // batch_size + 1
        output_file = os.path.join(output_dir, f"merged_chunk_{batch_num}.root")

        print(f"\n🔄 Merging {len(batch)} files into: {output_file}")
        cmd = ["hadd", "-f", output_file] + batch
        result = subprocess.run(cmd)

        if result.returncode != 0:
            print(f"❌ Error: hadd failed for chunk {batch_num}")
            break
        else:
            print(f"✅ Chunk {batch_num} completed")
            chunk_files.append(output_file)

    # Final merge of all chunk files
    if chunk_files:
        final_dir = os.path.join(output_dir, "FinalMergedFull")
        os.makedirs(final_dir, exist_ok=True)
        final_output = os.path.join(final_dir, "final_merged.root")

        print(f"\n🔄 Final merge into: {final_output}")
        cmd = ["hadd", "-f", final_output] + chunk_files
        result = subprocess.run(cmd)

        if result.returncode == 0:
            print(f"🎯 Final merged file created: {final_output}")
        else:
            print(f"❌ Error in final merge for {mass_dir}")

print("\n🎉 All done.")
