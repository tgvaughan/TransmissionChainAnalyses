# Sequence file directory

Multiple sequence alignment files named `max_chains.fasta` and
`min_chains.fasta` should be added to this directory.

These files must be FASTA files containing SARS-CoV-2 sequences
with the accession numbers matching those in the files
`max_chains_names.txt` and `min_chains_names.txt`, respectively.

The entries in the FASTA files should also contain the precise
IDs given in the `*_names.txt` files, as the final "|"-delimited
field represents the ID of the transmission cluster to which the
sequence has been assigned.
