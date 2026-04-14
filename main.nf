#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { ConvertRawFile } from './modules/local/dims/ThermoRawFileParser.nf'
include { CreateBins } from './modules/local/dims/CreateBins.nf' params(
    trim:"$params.trim", 
    resolution:"$params.resolution"
)
include { ParseSamplesheet } from './modules/local/dims/ParseSamplesheet.nf'
include { VersionLog } from './assets/VersionLog.nf'
include { ExportParams as Workflow_ExportParams } from './assets/workflow.nf'

def analysis_id = params.outdir.split('/')[-1]
def matrix = params.matrix
def raw_files = Channel
    .fromPath(params.samplesheet)
    .splitCsv(header: true, sep: '\t')
    .map { row ->
        def file_id = row.file_name
        def raw_file = file("${params.rawfiles_path}/${file_id}.raw", checkIfExists: true)
        tuple(file_id, raw_file)
     }

workflow {
    // create init.RData file with info on technical replicates
    ParseSamplesheet(params.samplesheet)

    // Read raw files and convert to mzML format
    ConvertRawFile(raw_files)
    
    // Generate breaks on one of the mzML files
    CreateBins(ConvertRawFile.out.take(1))

    // Create log files: Repository versions and Workflow params
    VersionLog(
        Channel.of(
            "${workflow.projectDir}/"// ,
            // "${workflow.projectDir}/CustomModules/"
        ).collect()
    )
    Workflow_ExportParams()
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
        sendMail(
            to: params.email.trim(), 
            subject: subject, 
            body: email_html,
            attach: "${params.outdir}/Bioinformatics/${analysis_id}_TICplots.pdf"
        )
    } else {
        def subject = "DIMS Workflow Failed: ${analysis_id}"
        sendMail(to: params.email.trim(), subject: subject, body: email_html)
    }
}

