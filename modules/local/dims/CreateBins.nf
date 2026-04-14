process CreateBins {
    tag "DIMS CreateBins"
    label 'CreateBins'
    container = 'docker://umcugenbioinf/dims:1.4'

    input:
       tuple(val(file_id), path(mzML_file))


    output:
       path('bins.RData'), emit: bins
       path('trim_params.RData'), emit: trim_params
       path('highest_mz.RData'), emit: highest_mz

    script:
        """
        echo "PWD: \$(pwd)"
        echo "Script full path: ${projectDir}"
        echo "Resolved path: \$(readlink -f ${projectDir}/modules/local/dims/resources/usr/bin/CreateBins.R)"
        Rscript ${projectDir}/modules/local/dims/resources/usr/bin/CreateBins.R \
                --mzML_filepath $mzML_file \
                --trim_param $params.trim \
                --resolution $params.resolution 
        """
}
