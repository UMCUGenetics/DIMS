#!/usr/bin/Rscript

# load required packages 
# none 

# define parameters 
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) cat("  ", arg, "\n")

outdir <- cmd_args[1]
scanmode <- cmd_args[2]
db <- cmd_args[3]

# Cut up entire HMDB into small parts based on the new binning/breaks and adducts

load(db)
load(paste(outdir, "breaks.fwhm.RData", sep = "/"))
outdir <- paste(outdir, "hmdb_part_adductSums", sep = "/")
dir.create(outdir, showWarnings = FALSE)


if (scanmode=="negative"){
  label = "MNeg"
  HMDB_add_iso=HMDB_add_iso.Neg
  fileName = "Intensity_all_peaks_negative_norm"
} else {
  label = "Mpos"
  HMDB_add_iso=HMDB_add_iso.Pos
  fileName = "Intensity_all_peaks_positive_norm"
}


# filter mass range meassured!!!
HMDB_add_iso = HMDB_add_iso[which(HMDB_add_iso[,label]>=breaks.fwhm[1] & HMDB_add_iso[,label]<=breaks.fwhm[length(breaks.fwhm)]),]

outlist=HMDB_add_iso

# remove adducts for summing the adducts!
outlist_IS = outlist[grep("IS",rownames(outlist),fixed=TRUE),]
outlist = outlist[grep("HMDB",rownames(outlist),fixed=TRUE),]
outlist = outlist[-grep("_",rownames(outlist),fixed=TRUE),]
outlist = rbind(outlist_IS, outlist)
outlist = outlist[order(outlist[,label]),]

n=dim(outlist)[1]
sub=300
end=0
check=0

if (n>=sub & (floor(n/sub))>=2){
  for (i in 1:floor(n/sub)){
    start=-(sub-1)+i*sub
    end=i*sub
    
    # message(paste("start:",start))
    # message(paste("end:",end))
    
    outlist_part = outlist[c(start:end),]
    save(outlist_part, file=paste(outdir, paste(scanmode, paste("hmdb",i,"RData", sep="."), sep="_"), sep="/"))
  }
}

start = end + 1
end = n

# message(paste("start:",start))
# message(paste("end:",end))

outlist_part = outlist[c(start:end),]
save(outlist_part, file=paste(outdir, paste(scanmode, paste("hmdb",i+1,"RData", sep="."), sep="_"), sep="/"))
