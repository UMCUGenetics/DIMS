#!/usr/bin/env nextflow
nextflow.preview.dsl=2

// get functions and include parameters
include extractRawfilesFromDir from './NextflowModules/Utils/RawFiles.nf'
include MakeInit from './CustomModules/DIMS/MakeInit.nf'
include AssignToBins from './CustomModules/DIMS/AssignToBins.nf'
include ConvertRawFile from './CustomModules/DIMS/ThermoRawFileParser.nf'
include GenerateBreaks from './CustomModules/DIMS/GenerateBreaks.nf' params(trim:"$params.trim", resolution:"$params.resolution")
include HMDBparts from './CustomModules/DIMS/HMDBparts.nf'
include AverageTechReplicates from './CustomModules/DIMS/AverageTechReplicates.nf' params(nr_replicates:"$params.nr_replicates")
include PeakFinding from './CustomModules/DIMS/PeakFinding.nf'
include SpectrumPeakFinding from './CustomModules/DIMS/SpectrumPeakFinding.nf'
include PeakGroupingIdentified from './CustomModules/DIMS/PeakGroupingIdentified.nf'


// define parameters
def samplesheet = params.samplesheet
def nr_replicates = params.nr_replicates
def raw_files = extractRawfilesFromDir(params.rawfiles_path)
def analysis_id = params.outdir.split('/')[-1]
def resolution = params.resolution
def hmdb_db_file = params.hmdb_db_file
def ppm = params.ppm

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
    AssignToBins(ConvertRawFile.out.combine(GenerateBreaks.out), resolution)

    // Average intensities over technical replicates
    AverageTechReplicates(AssignToBins.out.collect(), MakeInit.out, nr_replicates)

    // Peak finding
    // PeakFinding(AverageTechReplicates.out.binned.flatten().combine(GenerateBreaks.out), resolution, params.scripts)

    // Spectrum peak finding
    //SpectrumPeakFinding(PeakFinding.out.collect())

    // Peak grouping: identified part
    //PeakGroupingIdentified(SpectrumPeakFinding.out.collect(), HMDBparts.out, PeakFinding.out.pattern.flatten().combine(GenerateBreaks.out), resolution, ppm)

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
