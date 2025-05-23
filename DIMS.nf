#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// get functions and include parameters that are independent of dataset
include { AssignToBins } from './CustomModules/DIMS/AssignToBins.nf'
include { AverageTechReplicates } from './CustomModules/DIMS/AverageTechReplicates.nf' params(
    nr_replicates:"$params.nr_replicates", 
    matrix:"$params.matrix"
)
include { CollectFilled } from './CustomModules/DIMS/CollectFilled.nf' params(
    scripts_dir:"$params.scripts_dir", 
    ppm:"$params.ppm", 
    zscore:"$params.zscore"
)
include { CollectSumAdducts } from './CustomModules/DIMS/CollectSumAdducts.nf'
include { ConvertRawFile } from './CustomModules/DIMS/ThermoRawFileParser.nf'
include { extractRawfilesFromDir } from './CustomModules/DIMS/Utils/RawFiles.nf'
include { FillMissing } from './CustomModules/DIMS/FillMissing.nf' params(
    scripts_dir:"$params.scripts_dir", 
    thresh:"$params.thresh", 
    resolution:"$params.resolution", 
    ppm:"$params.ppm"
)
include { GenerateBreaks } from './CustomModules/DIMS/GenerateBreaks.nf' params(
    trim:"$params.trim", 
    resolution:"$params.resolution"
)
include { GenerateExcel } from './CustomModules/DIMS/GenerateExcel.nf' params(
    analysis_id:"$params.analysis_id", 
    zscore:"$params.zscore", 
    matrix:"$params.matrix",
    sst_components_file:"$params.sst_components_file"
)
include { GenerateViolinPlots } from './CustomModules/DIMS/GenerateViolinPlots.nf' params(
    analysis_id:"$params.analysis_id", 
    scripts_dir:"$params.scripts_dir", 
    zscore:"$params.zscore", 
    path_metabolite_groups:"$params.path_metabolite_groups",
    file_ratios_metabolites:"$params.file_ratios_metabolites",
    file_expected_biomarkers_IEM:"$params.file_expected_biomarkers_IEM",
    file_explanation:"$params.file_explanation",
    file_isomers:"$params.file_isomers"
)
include { HMDBparts } from './CustomModules/DIMS/HMDBparts.nf' params(
    hmdb_parts_files:"$params.hmdb_parts_files", 
    standard_run:"$params.standard_run", 
    ppm:"$params.ppm"
)
include { HMDBparts_main } from './CustomModules/DIMS/HMDBparts_main.nf'
include { MakeInit } from './CustomModules/DIMS/MakeInit.nf'
include { PeakFinding } from './CustomModules/DIMS/PeakFinding.nf' params(
    resolution:"$params.resolution", 
    scripts_dir:"$params.scripts_dir"
)
include { PeakGrouping } from './CustomModules/DIMS/PeakGrouping.nf' params(
    ppm:"$params.ppm"
)
include { SpectrumPeakFinding } from './CustomModules/DIMS/SpectrumPeakFinding.nf'
include { SumAdducts } from './CustomModules/DIMS/SumAdducts.nf' params(
    scripts_dir:"$params.scripts_dir", 
    zscore:"$params.zscore"
)
include { UnidentifiedCalcZscores } from './CustomModules/DIMS/UnidentifiedCalcZscores.nf' params(
    scripts_dir:"$params.scripts_dir", 
    ppm:"$params.ppm", 
    zscore:"$params.zscore"
)
include { UnidentifiedCollectPeaks } from './CustomModules/DIMS/UnidentifiedCollectPeaks.nf' params(
    ppm:"$params.ppm"
)
include { UnidentifiedFillMissing } from './CustomModules/DIMS/UnidentifiedFillMissing.nf' params(
    scripts_dir:"$params.scripts_dir", 
    thresh:"$params.thresh", 
    resolution:"$params.resolution", 
    ppm:"$params.ppm"
)
include { UnidentifiedPeakGrouping } from './CustomModules/DIMS/UnidentifiedPeakGrouping.nf' params(
    resolution:"$params.resolution", 
    ppm:"$params.ppm"
)
include { VersionLog } from './CustomModules/Utils/VersionLog.nf'
// include { Workflow_Export_Params } from './assets/workflow.nf'
include { ExportParams as Workflow_ExportParams } from './assets/workflow.nf'

// define parameters
def raw_files = extractRawfilesFromDir(params.rawfiles_path)
def analysis_id = params.outdir.split('/')[-1]
def matrix = params.matrix

workflow {
    // create init.RData file with info on technical replicates
    MakeInit(params.samplesheet, params.nr_replicates)

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
    AverageTechReplicates(AssignToBins.out.rdata_file.collect(),
                          AssignToBins.out.tic_txt_file.collect(),
                          MakeInit.out,
                          params.nr_replicates, 
                          analysis_id,
                          matrix,
                          GenerateBreaks.out.highest_mz,
                          GenerateBreaks.out.breaks)

    // Send e-mail with TIC plot PDF right after its creation
    AverageTechReplicates.out.tic_plots_pdf.map { tic_plots_pdf ->
         sendMail {
              to params.email.trim()
              attach tic_plots_pdf
              subject "TIC plots for run ${analysis_id}"
              body "Check TIC plots for run ${analysis_id} for technical replicates that should be removed from the run"
         }
    }

    // Peak finding per sample
    PeakFinding(AverageTechReplicates.out.binned_files.collect().flatten().combine(GenerateBreaks.out.breaks))

    // Spectrum peak finding per sample
    SpectrumPeakFinding(PeakFinding.out.collect(), AverageTechReplicates.out.pattern_files)

    // Peak grouping over samples: identified part
    // PeakGrouping(HMDBparts.out.collect().flatten(), SpectrumPeakFinding.out, AverageTechReplicates.out.pattern_files)
    PeakGrouping(HMDBparts.out.flatten(), SpectrumPeakFinding.out, AverageTechReplicates.out.pattern_files)

    // Fill missing values in peak group list: identified part
    FillMissing(PeakGrouping.out.grouped_identified, AverageTechReplicates.out.pattern_files)

    // Collect filled peak group list: identified part
    CollectFilled(FillMissing.out.collect(), AverageTechReplicates.out.pattern_files)

    // Sum adducts of each metabolite per scan mode: identfied part
    SumAdducts(CollectFilled.out.filled_pgrlist, 
               AverageTechReplicates.out.pattern_files, 
               HMDBparts_main.out.collect().flatten())

    // Collect summed adducts parts
    CollectSumAdducts(SumAdducts.out.collect())

    // Generate final Excel file with Z-scores on adduct sums (pos + neg)
    GenerateExcel(CollectSumAdducts.out.collect(), CollectFilled.out.filled_pgrlist.collect(), MakeInit.out, analysis_id, params.relevance_file)

    // Generate violin plots 
    GenerateViolinPlots(GenerateExcel.out.excel_files, analysis_id)

    // Collect unidentified peaks
    UnidentifiedCollectPeaks(SpectrumPeakFinding.out, PeakGrouping.out.peaks_used.collect())

    // Peak grouping: unidentified part
    UnidentifiedPeakGrouping(UnidentifiedCollectPeaks.out.flatten(), AverageTechReplicates.out.pattern_files)

    // Fill missing values in peak group list: unidentified part
    UnidentifiedFillMissing(UnidentifiedPeakGrouping.out.grouped_unidentified, AverageTechReplicates.out.pattern_files)

    // Calculate Z-scores for unidentified peak group list
    UnidentifiedCalcZscores(UnidentifiedFillMissing.out.collect(), AverageTechReplicates.out.pattern_files)

    // Create log files: Repository versions and Workflow params
    VersionLog(
        Channel.of(
            "${workflow.projectDir}/",
            "${workflow.projectDir}/CustomModules/"
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
