# CH Phylodynamic Analysis Files

This directory contains the files necessary to reproduce the
Swiss SARS-CoV-2 phylodynamic analyses presented in Nadeau et al.

After following the instructions contained in `sequences/README.md`
to add the sequence data to that directory, running the following
commands from the command line will reproduce the results.

## Step 1: Sequence date extraction

```bash
$ ./extract_sequence_data.sh
```

### Step 2: Data pre-processing

```bash
$ R CMD BATCH preprocessing.R
```

## Step 3: BEAST 2 Analysis

```bash
$ ./run_analyses.sh
```

**Warning**: This step will take a long time - you may wish to use a
dedicated cluster.

## Step 4: Results post-processing

```bash
$ R CMD BATCH postprocessing.R
```

## Results

The figures produced by the analysis will be left in the directory
`figures/`.
