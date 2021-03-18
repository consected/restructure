#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

message("Starting script")
if (length(args)!=1) {
  stop("One arguments must be supplied (input file).", call.=FALSE)
}

infile = args[1]

outfiles <- vector()
# Add any number of output files, changing the file extension
outfiles <- c(outfiles, tempfile(pattern = "meaningful-filename", fileext = ".csv"))
outfiles <- c(outfiles, tempfile(pattern = "anothing-meaningful-filename", fileext = ".txt"))

message("Temp files have been created")

# Main script

# Do something here reading data from the infile, and outputting to the appropriate outfiles
# Do not print or write to stdout. Only the output filenames should be output, which is 
# handled at the end of the script.
# Do not write to any files other than tempfiles, since they will not be cleaned up automatically,
# and will clog the filesystem. They also will not be retained.

# End of main script

for (fn in outfiles) {
  write(fn, stdout())
}

message("Exiting script successfully")
