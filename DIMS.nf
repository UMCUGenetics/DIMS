#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// get functions and include parameters that are independent of dataset
include extractRawfilesFromDir from './CustomModules/DIMS/Utils/RawFiles.nf'
include MakeInit from './CustomModules/DIMS/MakeInit.nf'
include AssignToBins from './CustomModules/DIMS/AssignToBins.nf'
include ConvertRawFile from './CustomModules/DIMS/ThermoRawFileParser.nf'
include GenerateBreaks from './CustomModules/DIMS/GenerateBreaks.nf' params(trim:"$params.trim", resolution:"$params.resolution")
include HMDBparts from './CustomModules/DIMS/HMDBparts.nf' params(standard_run:"$params.standard_run", ppm:"$params.ppm")
include AverageTechReplicates from './CustomModules/DIMS/AverageTechReplicates.nf' params(nr_replicates:"$params.nr_replicates")
include PeakFinding from './CustomModules/DIMS/PeakFinding.nf' params(resolution:"$params.resolution", scripts_dir:"$params.scripts_dir")
include SpectrumPeakFinding from './CustomModules/DIMS/SpectrumPeakFinding.nf'
include PeakGrouping from './CustomModules/DIMS/PeakGrouping.nf' params(ppm:"$params.ppm")
include FillMissing from './CustomModules/DIMS/FillMissing.nf' params(scripts_dir:"$params.scripts_dir", thresh:"$params.thresh", resolution:"$params.resolution", ppm:"$params.ppm")


// define parameters
def samplesheet   = params.samplesheet
def nr_replicates = params.nr_replicates
def raw_files     = extractRawfilesFromDir(params.rawfiles_path)
def analysis_id   = params.outdir.split('/')[-1]
def resolution    = params.resolution
def hmdb_db_file  = params.hmdb_db_file
def ppm           = params.ppm
def standard_run  = params.standard_run
def scripts_dir   = params.scripts_dir
def thresh        = params.thresh


workflow {
    // create init.RData file with info on technical replicates
    MakeInit(tuple(samplesheet, nr_replicates))

    // Read raw files and convert to mzML format
    ConvertRawFile(raw_files)
    
    // Generate breaks on the mzML files
    GenerateBreaks(ConvertRawFile.out.take(1))

    // Generate HMDB parts
    HMDBparts(hmdb_db_file, GenerateBreaks.out)

    // Assign intensities to bins (breaks)
    AssignToBins(ConvertRawFile.out.combine(GenerateBreaks.out))

    // Average intensities over technical replicates
    AverageTechReplicates(AssignToBins.out.collect(), MakeInit.out)

    // Peak finding
    PeakFinding(AverageTechReplicates.out.binned.collect().flatten().combine(GenerateBreaks.out))

    // Spectrum peak finding
    SpectrumPeakFinding(PeakFinding.out.collect(), AverageTechReplicates.out.patterns)

    // Peak grouping: identified part
    PeakGrouping(HMDBparts.out.collect().flatten(), SpectrumPeakFinding.out, AverageTechReplicates.out.patterns)

    // Fill missing: identified part
    FillMissing(PeakGrouping.out.grouped_identified, AverageTechReplicates.out.patterns)

    // Create log files: Repository versions and Workflow params
    //VersionLog(
    //    Channel.of(
    //        "${workflow.projectDir}/",
    //        "${params.rawfiles_path}/",
    //    ).collect()
    //)
    //Workflow_ExportParams()
}

// Workflow completion notification
workflow.onComplete {
    // HTML Template
    def template = new File("$baseDir/assets/workflow_complete.html")
    def binding = [
        runName: analysis_id,
        workflow: workflow
    ]
    def engine = new groovy.text.GStringTemplateEngine()
    def email_html = engine.createTemplate(template).make(binding).toString()

    // Send email
    if (workflow.success) {
        def subject = "DIMS Workflow Successful: ${analysis_id}"
        sendMail(to: params.email.trim(), subject: subject, body: email_html)
    } else {
        def subject = "DIMS Workflow Failed: ${analysis_id}"
        sendMail(to: params.email.trim(), subject: subject, body: email_html)
    }
}
