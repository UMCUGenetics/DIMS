process ParseSamplesheet {
    tag "DIMS ParseSamplesheet"
    label 'ParseSamplesheet'
    container = 'docker://umcugenbioinf/dims:1.4'

    input:
       path(samplesheet) 

    output:
       path('replication_pattern.RData')

    script:
        """
        echo "PWD: \$(pwd)"
        echo "Script full path: ${projectDir}"
        echo "Resolved path: \$(readlink -f ${projectDir}/modules/local/dims/resources/usr/bin/CreateBins.R)"
        Rscript ${projectDir}/modules/local/dims/resources/usr/bin/ParseSamplesheet.R \
                --samplesheet $samplesheet \
        """
}
