#!/usr/bin/env nextflow
nextflow.preview.dsl=2

include extractRawfilesFromDir from './NextflowModules/Utils/RawFiles.nf'
include MakeInit from './CustomModules/DIMS/MakeInit.nf'
include AssignToBins from './CustomModules/DIMS/AssignToBins.nf'


def samplesheet = params.samplesheet
def nr_replicates = params.nr_replicates
def raw_files = extractRawfilesFromDir(params.rawfiles_path)
def analysis_id = params.outdir.split('/')[-1]
def resolution = params.resolution

// get functions and include parameters
include ConvertRawFile from './NextflowModules/ConvertRawFiles.nf'
include GenerateBreaks from './CustomModules/DIMS/GenerateBreaks.nf' params(trim:"$params.trim", resolution:"$params.resolution")

workflow {
    // create init.RData file with info on technical replicates
    MakeInit(tuple(samplesheet, nr_replicates))

    // Read raw files and convert to mzML format
    ConvertRawFile(raw_files)
    
    // Generate breaks on the mzML files
    GenerateBreaks(ConvertRawFile.out.take(1))

    // Assign intensities to bins (breaks)
    AssignToBins(ConvertRawFile.out, GenerateBreaks.out, resolution)

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
