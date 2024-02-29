#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// nextflow.preview.dsl=2

// get functions and include parameters that are independent of dataset
include { extractRawfilesFromDir } from './CustomModules/DIMS/Utils/RawFiles.nf'
include { MakeInit } from './CustomModules/DIMS/MakeInit.nf'
include { ConvertRawFile } from './CustomModules/DIMS/ThermoRawFileParser.nf'
include { GenerateBreaks } from './CustomModules/DIMS/GenerateBreaks.nf' params(trim:"$params.trim", resolution:"$params.resolution")
include { HMDBparts } from './CustomModules/DIMS/HMDBparts.nf' params(hmdb_parts_files:"$params.hmdb_parts_files", standard_run:"$params.standard_run", ppm:"$params.ppm")
include { HMDBparts_main } from './CustomModules/DIMS/HMDBparts_main.nf'
include { AssignToBins } from './CustomModules/DIMS/AssignToBins.nf'
include { AverageTechReplicates } from './CustomModules/DIMS/AverageTechReplicates.nf' params(nr_replicates:"$params.nr_replicates", matrix:"$params.matrix")
include { PeakFinding } from './CustomModules/DIMS/PeakFinding.nf' params(resolution:"$params.resolution", scripts_dir:"$params.scripts_dir")
include { SpectrumPeakFinding } from './CustomModules/DIMS/SpectrumPeakFinding.nf'
include { PeakGrouping } from './CustomModules/DIMS/PeakGrouping.nf' params(ppm:"$params.ppm")
include { FillMissing } from './CustomModules/DIMS/FillMissing.nf' params(scripts_dir:"$params.scripts_dir", thresh:"$params.thresh", resolution:"$params.resolution", ppm:"$params.ppm")
include { CollectFilled } from './CustomModules/DIMS/CollectFilled.nf' params(scripts_dir:"$params.scripts_dir", ppm:"$params.ppm", zscore:"$params.zscore")
include { SumAdducts } from './CustomModules/DIMS/SumAdducts.nf' params(scripts_dir:"$params.scripts_dir", zscore:"$params.zscore")
include { CollectSumAdducts } from './CustomModules/DIMS/CollectSumAdducts.nf'
include { GenerateExcel } from './CustomModules/DIMS/GenerateExcel.nf' params(analysis_id:"$params.analysis_id", zscore:"$params.zscore", matrix:"$params.matrix")
include { GenerateViolinPlots } from './CustomModules/DIMS/GenerateViolinPlots.nf' params(analysis_id:"$params.analysis_id", scripts_dir:"$params.scripts_dir", zscore:"$params.zscore")
include { UnidentifiedCollectPeaks } from './CustomModules/DIMS/UnidentifiedCollectPeaks.nf' params(ppm:"$params.ppm")
include { UnidentifiedPeakGrouping } from './CustomModules/DIMS/UnidentifiedPeakGrouping.nf' params(resolution:"$params.resolution", ppm:"$params.ppm")
include { UnidentifiedFillMissing } from './CustomModules/DIMS/UnidentifiedFillMissing.nf' params(scripts_dir:"$params.scripts_dir", thresh:"$params.thresh", resolution:"$params.resolution", ppm:"$params.ppm")
include { UnidentifiedCalcZscores } from './CustomModules/DIMS/UnidentifiedCalcZscores.nf' params(scripts_dir:"$params.scripts_dir", ppm:"$params.ppm", zscore:"$params.zscore")

// define parameters
def raw_files       = extractRawfilesFromDir(params.rawfiles_path)
def analysis_id     = params.outdir.split('/')[-1]
def matrix          = params.matrix

workflow {
    // create init.RData file with info on technical replicates
    MakeInit(tuple(params.samplesheet, params.nr_replicates))

    // Read raw files and convert to mzML format
    ConvertRawFile(raw_files)
    
    // Generate breaks on one of the mzML files
    GenerateBreaks(ConvertRawFile.out.take(1))

    // Generate HMDB parts for parallel processing in SumAdducts step
    // HMDB without adducts, without isotopes, only main entry for each metabolite
    HMDBparts_main(params.hmdb_db_file, GenerateBreaks.out.breaks)

    // Generate HMDB parts for parallel processing in PeakGrouping step
    HMDBparts(params.hmdb_db_file, GenerateBreaks.out.breaks)

    // Assign intensities to bins (breaks) per mzML file
    AssignToBins(ConvertRawFile.out.combine(GenerateBreaks.out.breaks))

    // Average intensities over technical replicates for each sample
    AverageTechReplicates(AssignToBins.out.RData_files.collect(),
                          AssignToBins.out.TIC_txt_files.collect(),
                          MakeInit.out,
                          params.nr_replicates, 
                          analysis_id,
                          matrix,
                          GenerateBreaks.out.highest_mz)

    // Peak finding per sample
    PeakFinding(AverageTechReplicates.out.binned.collect().flatten().combine(GenerateBreaks.out.breaks))

    // Spectrum peak finding per sample
    SpectrumPeakFinding(PeakFinding.out.collect(), AverageTechReplicates.out.patterns)

    // Peak grouping over samples: identified part
    // PeakGrouping(HMDBparts.out.collect().flatten(), SpectrumPeakFinding.out, AverageTechReplicates.out.patterns)
    PeakGrouping(HMDBparts.out.flatten(), SpectrumPeakFinding.out, AverageTechReplicates.out.patterns)

    // Fill missing values in peak group list: identified part
    FillMissing(PeakGrouping.out.grouped_identified, AverageTechReplicates.out.patterns)

    // Collect filled peak group list: identified part
    CollectFilled(FillMissing.out.collect(), AverageTechReplicates.out.patterns)

    // Sum adducts of each metabolite per scan mode: identfied part
    SumAdducts(CollectFilled.out.filled_pgrlist, 
               AverageTechReplicates.out.patterns, 
               HMDBparts_main.out.collect().flatten())

    // Collect summed adducts parts
    CollectSumAdducts(SumAdducts.out.collect())

    // Generate final Excel file with Z-scores on adduct sums (pos + neg)
    GenerateExcel(CollectSumAdducts.out.collect(), CollectFilled.out.filled_pgrlist.collect(), MakeInit.out, analysis_id, params.relevance_file)

    // Generate violin plots 
    GenerateViolinPlots(GenerateExcel.out.excel_file, analysis_id)

    // Collect unidentified peaks
    UnidentifiedCollectPeaks(SpectrumPeakFinding.out, PeakGrouping.out.peaks_used.collect())

    // Peak grouping: unidentified part
    UnidentifiedPeakGrouping(UnidentifiedCollectPeaks.out.collect(), AverageTechReplicates.out.patterns)

    // Fill missing values in peak group list: unidentified part
    UnidentifiedFillMissing(UnidentifiedPeakGrouping.out.grouped_unidentified, AverageTechReplicates.out.patterns)

    // Calculate Z-scores for unidentified peak group list
    UnidentifiedCalcZscores(UnidentifiedFillMissing.out, AverageTechReplicates.out.patterns)

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
