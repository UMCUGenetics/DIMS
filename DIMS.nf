#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// get functions and include parameters that are independent of dataset
include { AssignToBins } from './CustomModules/DIMS/AssignToBins.nf' params(
    resolution:"$params.resolution"
)
include { AveragePeaks } from './CustomModules/DIMS/AveragePeaks.nf'
include { CollectAveraged } from './CustomModules/DIMS/CollectAveraged.nf'
include { CollectFilled } from './CustomModules/DIMS/CollectFilled.nf' params(
    preprocessing_scripts_dir:"$params.preprocessing_scripts_dir",
    ppm:"$params.ppm", 
    zscore:"$params.zscore"
)
include { CollectSumAdducts } from './CustomModules/DIMS/CollectSumAdducts.nf'
include { ConvertRawFile } from './CustomModules/DIMS/ThermoRawFileParser.nf'
include { EvaluateTics } from './CustomModules/DIMS/EvaluateTics.nf' params(
    nr_replicates:"$params.nr_replicates", 
    matrix:"$params.matrix",
    preprocessing_scripts_dir:"$params.preprocessing_scripts_dir"
)
include { extractRawfilesFromDir } from './CustomModules/DIMS/Utils/RawFiles.nf'
include { FillMissing } from './CustomModules/DIMS/FillMissing.nf' params(
    preprocessing_scripts_dir:"$params.preprocessing_scripts_dir",
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
    export_scripts_dir:"$params.export_scripts_dir",
    path_metabolite_groups:"$params.path_metabolite_groups"
)
include { GenerateQCOutput } from './CustomModules/DIMS/GenerateQCOutput.nf' params(
    analysis_id:"$params.analysis_id",
    zscore:"$params.zscore",
    matrix:"$params.matrix",
    sst_components_file:"$params.sst_components_file",
    export_scripts_dir:"$params.export_scripts_dir"
)
include { GenerateViolinPlots } from './CustomModules/DIMS/GenerateViolinPlots.nf' params(
    analysis_id:"$params.analysis_id", 
    export_scripts_dir:"$params.export_scripts_dir",
    path_metabolite_groups:"$params.path_metabolite_groups",
    file_ratios_metabolites:"$params.file_ratios_metabolites",
    file_expected_biomarkers_IEM:"$params.file_expected_biomarkers_IEM",
    file_explanation:"$params.file_explanation"
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
    preprocessing_scripts_dir:"$params.preprocessing_scripts_dir"
)
include { PeakGrouping } from './CustomModules/DIMS/PeakGrouping.nf' params(
    preprocessing_scripts_dir:"$params.preprocessing_scripts_dir",
    ppm:"$params.ppm"
)
include { SumAdducts } from './CustomModules/DIMS/SumAdducts.nf' params(
    preprocessing_scripts_dir:"$params.preprocessing_scripts_dir",
    zscore:"$params.zscore"
)
include { VersionLog } from './CustomModules/Utils/VersionLog.nf'
// include { Workflow_Export_Params } from './assets/workflow.nf'
include { ExportParams as Workflow_ExportParams } from './assets/workflow.nf'

// define parameters
def analysis_id = params.outdir.split('/')[-1]
def matrix = params.matrix
def raw_files = Channel
    .fromPath(params.samplesheet)
    .splitCsv(header: true, sep: '\t')
    .map { row ->
        def file_id = row.File_Name
        def raw_file = file("${params.rawfiles_path}/${file_id}.raw", checkIfExists: true)
        tuple(file_id, raw_file)
     }

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
    AssignToBins(ConvertRawFile.out.combine(GenerateBreaks.out.breaks).combine(GenerateBreaks.out.trim_params))

    // Evaluate quality of TIC plots for each technical replicate
    EvaluateTics(AssignToBins.out.rdata_file.collect(),
                 AssignToBins.out.tic_txt_file.collect(),
                 MakeInit.out,
                 analysis_id,
                 GenerateBreaks.out.highest_mz,
                 GenerateBreaks.out.trim_params)

    // Send e-mail with TIC plot PDF right after its creation
    EvaluateTics.out.tic_plots_pdf.map { tic_plots_pdf ->
         sendMail {
              to params.email.trim()
              attach tic_plots_pdf
              subject "TIC plots for run ${analysis_id}"
              body "Check TIC plots for run ${analysis_id} for technical replicates that should be removed from the run"
         }
    }

    // get info on sample with corresponding technical replicates
    ch_sample_techreps = EvaluateTics.out.sample_techreps
        .splitCsv(header:false)
        .splitCsv(sep: ';')
        .map { row ->
            def meta = [sample_id: row[0][0], tech_reps: row[1], scanmode: row[2]]
        }
        .view()

    // Peak finding per technical replicate
    PeakFinding(AssignToBins.out.rdata_file.collect().flatten(), EvaluateTics.out.sample_techreps)

    // AveragePeaks over technical replicates on peak level
    AveragePeaks(PeakFinding.out.peaklist_rdata.collect(), ch_sample_techreps)

    // Collect peak finding results for all samples
    CollectAveraged(AveragePeaks.out.collect())

    // Peak grouping over samples: identified part
    PeakGrouping(HMDBparts.out.flatten(), CollectAveraged.out.averaged_peaks.collect(), EvaluateTics.out.pattern_files)

    // Fill missing values in peak group list: identified part
    FillMissing(PeakGrouping.out.grouped_identified, EvaluateTics.out.pattern_files)

    // Collect filled peak group list: identified part
    CollectFilled(FillMissing.out.collect(), EvaluateTics.out.pattern_files)

    // Sum adducts of each metabolite per scan mode: identfied part
    SumAdducts(CollectFilled.out.filled_pgrlist, 
               HMDBparts_main.out.collect().flatten())

    // Collect summed adducts parts
    CollectSumAdducts(SumAdducts.out.collect())

    // Generate final Excel file with Z-scores on adduct sums (pos + neg)
    GenerateExcel(CollectSumAdducts.out.adductsums_combined, analysis_id, params.relevance_file)

    // Generate QC rapports
    GenerateQCOutput(GenerateExcel.out.outlist_zscores,
                     CollectSumAdducts.out.adductsums_scanmodes.collect(),
                     CollectFilled.out.filled_pgrlist.collect(),
                     MakeInit.out,
                     analysis_id)

    // Generate violin plots 
    if (params.zscore == 1) {
        GenerateViolinPlots(GenerateExcel.out.outlist_zscores, analysis_id)
    }

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
    def content_miss_infusions_negative = file("${params.outdir}/Bioinformatics/QC/miss_infusions_negative.txt").text
    def content_miss_infusions_positive = file("${params.outdir}/Bioinformatics/QC/miss_infusions_positive.txt").text
    def content_missing_mzrange = file("${params.outdir}/Bioinformatics/QC/missing_mz_warning.txt").text
    def content_missing_samples = file("${params.outdir}/Bioinformatics/QC/sample_names_nodata.txt").text
    def content_positive_controls = file("${params.outdir}/Bioinformatics/QC/positive_controls_warning.txt").text
    def content_sst_zscores = file("${params.outdir}/Bioinformatics/QC/sst_qc.txt").text
    def content_int_std_threshold = file("${params.outdir}/Bioinformatics/QC/internal_standards_below_threshold.txt").text

    def binding = [
        miss_infusions_negative: content_miss_infusions_negative,
        miss_infusions_positive: content_miss_infusions_positive,
        missing_mzrange: content_missing_mzrange,
        missing_samples: content_missing_samples,
        positive_controls: content_positive_controls,
        sst_zscores: content_sst_zscores,
        is_threshold: content_int_std_threshold,
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
        sendMail(
            to: params.email.trim(), 
            subject: subject, 
            body: email_html
        )
    }
}
